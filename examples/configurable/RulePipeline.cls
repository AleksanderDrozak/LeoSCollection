@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class RulePipeline {

    /**
     * A pipeline whose steps are configuration rows instead of Apex.
     *
     * Each row of Rule__mdt describes one step, and toStep() turns that row into a step object the library
     * already knows how to apply. The whole rule set for a batch then becomes pipe(steps) - so adding a rule,
     * reordering rules, or switching a rule off is a metadata change, not a deploy. That is the one thing
     * this library gives you that a hand-written loop cannot: a step is a value, so steps can be stored,
     * reordered and built at runtime.
     *
     * Compare with what this replaces, where each rule is an if and the rule set is the source file:
     *
     *     for (Account candidate : batch) {
     *         if (candidate.NumberOfEmployees > 5) {                    // adding a rule = a new deploy
     *             if (candidate.Rating == 'Hot') {                       // reordering = moving code
     *                 kept.add(candidate);
     *             }
     *         }
     *     }
     *
     * The per-rule condition and the per-rule derivation are formulas, so a new rule needs no new Apex class
     * either - see FormulaFilterFunction and FormulaMapFunction for why that matters in Apex.
     *
     * A FILTER rule can be spelled either as a formula (expressive, no class per rule) or as
     * field/operator/value (the operator comes from a closed set, so it fits a metadata picklist). Both run
     * anywhere the pipeline runs, triggers and batch included.
     *
     * A rule's formula is compiled once per transaction, keyed by its text, and reused - so neither a second
     * batch nor a second read of the configuration pays for the parse and validation again.
     */
    /**
     * Runs a compiled step list over a data set and hands back the typed list, so no caller has to cast. The
     * pipeline builds a real List<Account> underneath; Apex only erases its static type, and the cast to put
     * that type back is one line, so it lives here once instead of at every call site.
     */
    global static List<Account> applyTo(List<Object> steps, List<Account> records) {
        return (List<Account>) Collection.of(records).pipe(steps).toList(Account.class);
    }

    /**
     * The seam. Everything above this line is plain Apex; everything below it is the only code that knows
     * Rule__mdt exists. A different configuration store - a custom setting, a JSON file in static resources -
     * replaces configuredRules() alone.
     */
    global static List<Object> configuredSteps(SObjectType targetType) {
        List<Rule> rules = new List<Rule>();

        for (Rule__mdt row : [
            SELECT Step__c, Target_Field__c, Formula__c, Return_Type__c, Direction__c, Comparator__c, Value__c
            FROM Rule__mdt
            WHERE Active__c = TRUE
            ORDER BY Order__c
        ]) {
            rules.add(new Rule(row));
        }

        return toSteps(targetType, rules);
    }

    global static List<Object> toSteps(SObjectType targetType, List<Rule> rules) {
        List<Object> steps = new List<Object>();
        for (Rule rule : rules) {
            steps.add(toStep(targetType, rule));
        }
        return steps;
    }

    global static Object toStep(SObjectType targetType, Rule rule) {

        switch on rule.step {
            when 'FILTER' {
                return (Object) toPredicate(targetType, rule);
            }
            when 'GROUP' {
                return (Object) new GroupByFieldFunction(fieldOf(targetType, rule.targetField));
            }
            when 'SORT' {
                return (Object) sortStep(targetType, rule);
            }
            when 'TAKE' {
                return (Object) new LimitToFunction(Integer.valueOf(rule.formula));
            }
            when 'TRANSFORM' {
                return (Object) new SetValueFromFunction(
                    fieldOf(targetType, rule.targetField),
                    new FormulaMapFunction(compileFormula(targetType, rule))
                );
            }
            when else {
                throw new LeoSCollectionException('Rule__mdt step not handled: ' + rule.step);
            }
        }
    }

    /**
     * One row of configuration, in a shape both the metadata query and a literal in code can build. Keeping
     * this separate from Rule__mdt is what lets demo() run without any metadata in the org.
     */
    global class Rule {

        global String step;
        global String targetField;
        global String formula;
        global String returnType;
        global String direction;
        global String comparator;
        global Object value;

        global Rule() {}

        /** one to one with the metadata row, so the query loop above stays a single line */
        global Rule(Rule__mdt row) {
            this.step = row.Step__c;
            this.targetField = row.Target_Field__c;
            this.formula = row.Formula__c;
            this.returnType = row.Return_Type__c;
            this.direction = row.Direction__c;
            this.comparator = row.Comparator__c;
            this.value = row.Value__c;
        }

    }

    /**
     * A FILTER rule has two spellings, for two kinds of condition.
     *
     * A formula needs no class per rule and can express anything the formula language can, including
     * relations between fields.
     *
     * The field/operator/value spelling costs nothing per record, because FilterByCondition compares the
     * values directly instead of evaluating a formula, and its operator comes from a closed set - which is
     * what makes the metadata picklist possible.
     */
    global static BooleanFunction toPredicate(SObjectType targetType, Rule rule) {

        if (String.isNotBlank(rule.formula)) {
            return new FormulaFilterFunction(compileFormula(targetType, rule));
        }

        return new FilterByFieldFunction().addFilterBy(
            fieldOf(targetType, rule.targetField),
            ComparationUtil.Comparators.valueOf(rule.comparator),
            rule.value
        );
    }

    /** Apex allows no static members on an inner class, so the shorthands live out here. */
    global static Rule filterRule(String formula) {
        Rule rule = new Rule();
        rule.step = 'FILTER';
        rule.formula = formula;
        return rule;
    }

    global static Rule filterByRule(SObjectField field, ComparationUtil.Comparators comparator, Object compareTo) {
        Rule rule = new Rule();
        rule.step = 'FILTER';
        /** taken off the token, the same text a metadata row would carry */
        rule.targetField = field.getDescribe().getName();
        rule.comparator = comparator.name();
        rule.value = compareTo;
        return rule;
    }

    global static Rule sortRule(String field, String direction) {
        Rule rule = new Rule();
        rule.step = 'SORT';
        rule.targetField = field;
        rule.direction = direction;
        return rule;
    }

    global static Rule takeRule(Integer limitRecords) {
        Rule rule = new Rule();
        rule.step = 'TAKE';
        rule.formula = String.valueOf(limitRecords);
        return rule;
    }

    global static Rule transformRule(String field, String returnType, String formula) {
        Rule rule = new Rule();
        rule.step = 'TRANSFORM';
        rule.targetField = field;
        rule.returnType = returnType;
        rule.formula = formula;
        return rule;
    }

    private static SortByFunction sortStep(SObjectType targetType, Rule rule) {

        SortByFunction sorting = new SortByFieldFunction(fieldOf(targetType, rule.targetField));
        return rule.direction == 'DESCENDING' ? sorting.setDescending() : sorting;
    }

    private static SObjectField fieldOf(SObjectType targetType, String apiName) {
        SObjectField field = targetType.getDescribe().fields.getMap().get(apiName);
        if (field == null) {
            /** a typo in a metadata row should say so, not fail as a null pointer three steps later */
            throw new LeoSCollectionException(apiName + ' is not a field on ' + targetType);
        }
        return field;
    }

    /**
     * Compiled formulas, kept for the transaction and keyed by what the formula is - context type, step,
     * expression and return type. A rule therefore costs one build() per transaction however many times the
     * configuration is read or applied, and a re-read of the same rule reuses the instance rather than
     * rebuilding it. build() parses and validates, which is the part worth hoisting; Apex statics live for
     * the transaction.
     *
     * The builder call lives here rather than in Rule because Rule has a field named formula, and Apex
     * identifiers are case-insensitive - inside the class, Formula would not resolve to the system class.
     */
    private static final Map<String, FormulaEval.FormulaInstance> COMPILED_FORMULAS = new Map<String, FormulaEval.FormulaInstance>();

    private static FormulaEval.FormulaInstance compileFormula(SObjectType targetType, Rule rule) {

        String key = String.valueOf(targetType) + '|' + rule.step + '|' + rule.returnType + '|' + rule.formula;

        if (!COMPILED_FORMULAS.containsKey(key)) {
            COMPILED_FORMULAS.put(key, Formula.builder()
                .withType(targetType)
                .withReturnType(
                    rule.step == 'FILTER'
                        ? FormulaEval.FormulaReturnType.BOOLEAN
                        : returnType(rule.returnType)
                )
                .withFormula(rule.formula)
                .build());
        }

        return COMPILED_FORMULAS.get(key);
    }

    private static FormulaEval.FormulaReturnType returnType(String configuredName) {
        return configuredName == null ? FormulaEval.FormulaReturnType.STRING : FormulaEval.FormulaReturnType.valueOf(configuredName);
    }

    global static void demo() {

        /**
         * The same four steps the metadata rows would describe, written out so this runs with an empty
         * Rule__mdt: keep the sizable ones, grade them, rank them, keep the top two.
         */
        List<Object> steps = toSteps(Account.SObjectType, new List<Rule> {
            filterRule('NumberOfEmployees > 5'),
            transformRule('Rating', 'STRING', 'IF(NumberOfEmployees > 100, "Hot", "Warm")'),
            filterByRule(Account.Rating, ComparationUtil.Comparators.EQUALS, 'Hot'),
            sortRule('NumberOfEmployees', 'DESCENDING'),
            takeRule(1)
        });

        List<Account> batch = new List<Account> {
            new Account(Name = 'Small', NumberOfEmployees = 3),
            new Account(Name = 'Large', NumberOfEmployees = 400),
            new Account(Name = 'Medium', NumberOfEmployees = 40),
            new Account(Name = 'Big', NumberOfEmployees = 250),
            new Account(Name = 'Unrated', NumberOfEmployees = 7)
        };

        for (Account account : applyTo(steps, batch)) {
            System.debug(account.Name + ' -> employees ' + account.NumberOfEmployees + ', rating ' + account.Rating);
        }
    }
}
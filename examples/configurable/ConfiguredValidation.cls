@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class ConfiguredValidation {

    /**
     * Which configured rule rejected the batch, and on which record.
     *
     * Every configured rule is checked the same way, formula or field/operator/value - both go through
     * RulePipeline.toPredicate, so the report is complete whatever spelling the metadata uses.
     *
     * The giveaway is NotFunction. A configured rule says what is allowed; a rejection check is the same
     * predicate negated. Without NotFunction the caller has to invert the operator itself - an eight-way
     * mapping from EQUALS to NOT_EQUALS, INCLUDES to NOT_INCLUDES, and so on, which is exactly the table
     * the library already carries. Here negation costs one wrapper.
     *
     * Compare with the negation table this replaces:
     *
     *     Boolean passes;
     *     switch on row.Comparator__c {
     *         when 'EQUALS'            { passes = candidate.get(field) == row.Value__c; }
     *         when 'NOT_EQUALS'        { passes = candidate.get(field) != row.Value__c; }
     *         when 'GREATER_THAN'      { passes = candidate.get(field) > (Decimal) row.Value__c; }  // cast wrong for text...
     *         when 'GREATER_OR_EQUALS' { ... }                                                     // ...and for dates
     *     }
     *
     * One metadata row per rule, one predicate per row, and the inverse is free.
     */
    global static List<Rejection> rejections(List<RulePipeline.Rule> rules, SObjectType targetType, List<SObject> batch) {

        List<Rejection> rejections = new List<Rejection>();

        for (RulePipeline.Rule rule : rules) {

            Rejection rejection = new Rejection(rule);

            /** find() stops at the first offender, so a bad batch of ten thousand rows costs one check per rule */
            Object offender = Collection.of(batch)
                .find(new NotFunction(RulePipeline.toPredicate(targetType, rule)));

            if (offender != null) {
                rejection.record = (SObject) offender;
                rejections.add(rejection);
            }
        }

        return rejections;
    }

    /**
     * A gate rather than a report: the caller wants to know whether the batch may proceed at all. every()
     * answers that without building the rejection list, and stops at the first rule that fails.
     */
    global static Boolean passesAll(List<RulePipeline.Rule> rules, SObjectType targetType, List<SObject> batch) {

        for (RulePipeline.Rule rule : rules) {
            if (!Collection.of(batch).every(RulePipeline.toPredicate(targetType, rule))) {
                return false;
            }
        }

        return true;
    }

    /** The seam: the only code here that knows Rule__mdt exists. */
    global static List<RulePipeline.Rule> configuredFilterRules() {

        List<RulePipeline.Rule> rules = new List<RulePipeline.Rule>();

        for (Rule__mdt row : [
            SELECT Step__c, Target_Field__c, Formula__c, Return_Type__c, Direction__c, Comparator__c, Value__c
            FROM Rule__mdt
            WHERE Active__c = TRUE AND Step__c = 'FILTER'
            ORDER BY Order__c
        ]) {
            rules.add(new RulePipeline.Rule(row));
        }

        return rules;
    }

    global class Rejection {

        global RulePipeline.Rule rule;
        global SObject record;

        global Rejection(RulePipeline.Rule rule) {
            this.rule = rule;
        }
    }

    global static void demo() {

        /**
         * Trigger.new is the case this is written for - records no query can see yet - but an unsaved list
         * behaves the same way, and needs no DML to demonstrate.
         */
        List<SObject> batch = new List<SObject> {
            new Account(Name = 'Complete', Rating = 'Hot', NumberOfEmployees = 40, Website = 'acme.example'),
            new Account(Name = 'No rating', Rating = null, NumberOfEmployees = 40, Website = 'acme.example'),
            new Account(Name = 'Too small', Rating = 'Hot', NumberOfEmployees = 2, Website = 'acme.example')
        };

        List<RulePipeline.Rule> rules = new List<RulePipeline.Rule> {
            RulePipeline.filterByRule(Account.Rating, ComparationUtil.Comparators.NOT_EQUALS, null),
            RulePipeline.filterByRule(Account.NumberOfEmployees, ComparationUtil.Comparators.GREATER_THAN, 5),
            RulePipeline.filterByRule(Account.Website, ComparationUtil.Comparators.INCLUDES, 'acme'),
            /** a formula rule: checked the same way as the field/operator/value ones */
            RulePipeline.filterRule('NumberOfEmployees > 10')
        };

        System.debug('allowed: ' + passesAll(rules, Account.SObjectType, batch));

        for (Rejection rejection : rejections(rules, Account.SObjectType, batch)) {
            System.debug('rejected: ' + (String) rejection.record.get('Name'));
        }
    }
}
@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class FormulaForQueryAndProcessing {

    /**
     * One formula, built once, handed to the framework twice: once to decide what the query fetches, once to
     * process what comes back.
     *
     * Building it separately is the whole point. build() parses and validates the expression, so that cost is
     * paid a single time, and the same FormulaInstance then serves both roles:
     *
     *   - the query: getReferencedFields() lists the fields the expression reads, so the SELECT asks for those
     *     and nothing else;
     *   - the processing: the same instance is the map step, turning each row into the derived value.
     *
     * The derivation stays in Apex because it has to - a query returns columns, and SOQL cannot add a computed
     * one. So the formula does not shape the query's WHERE (it is not a SOQL predicate); what it gives the
     * query is the list of inputs it needs.
     */
    global static FormulaEval.FormulaInstance followUpFormula() {

        return Formula.builder()
            .withType(Account.SObjectType)
            .withReturnType(FormulaEval.FormulaReturnType.STRING)
            .withFormula('Name & ": " & IF(AND(ISPICKVAL(Rating, "Hot"), NumberOfEmployees > 100), "Priority", "Standard")')
            .build();
    }

    global static List<String> followUps() {

        FormulaEval.FormulaInstance formula = followUpFormula();

        String selectedFields = String.join(new List<String>(formula.getReferencedFields()), ', ');

        return (List<String>) Collection.query('SELECT ' + selectedFields + ' FROM Account')
            .transform(new FormulaMapFunction(formula))
            .toList(String.class);
    }

    global static void demo() {

        for (String followUp : followUps()) {
            System.debug(followUp);
        }
    }
}

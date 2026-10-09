@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class FormulaMapFunction implements MapFunction {

    private final FormulaEval.FormulaInstance formula;

    /**
     * The mapper twin of FormulaFilterFunction: the value comes from a formula, so one class serves every
     * derivation a configuration row can describe. Pair it with SetValueFromFunction to land the result on a
     * field, and the whole derivation rule lives in configuration rather than in a new Apex class.
     *
     *     new FormulaMapFunction(
     *         Formula.builder()
     *             .withType(Account.class)
     *             .withReturnType(FormulaEval.FormulaReturnType.STRING)
     *             .withFormula('IF(NumberOfEmployees > 100, "Hot", "Warm")')
     *             .build()
     *     )
     *
     * Globals, template mode and numeric-null handling come from Apex's builder unchanged. Build the
     * instance once and reuse it, the same as the filter.
     */
    global FormulaMapFunction(FormulaEval.FormulaInstance formula) {
        this.formula = formula;
    }

    global Object mapValue(Object candidate) {
        return this.formula.evaluate(candidate);
    }
}

@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class FormulaFilterFunction implements BooleanFunction {

    private final FormulaEval.FormulaInstance formula;

    /**
     * A predicate whose body is a formula instead of a class.
     *
     * Apex has no lambdas, so every filter otherwise costs a BooleanFunction class. This adapter turns a
     * FormulaEval.FormulaInstance into one, so a single class covers every rule whose condition can be
     * written as a formula - and the class count stops growing with the rule count. That is what lets a
     * pipeline be assembled from configuration instead of from code.
     *
     * The formula is built with Apex's own builder, not a copy of it, so everything FormulaEval offers -
     * globals, template mode, numeric-null handling - is available here too:
     *
     *     Collection.of(batch).filter(new FormulaFilterFunction(
     *         Formula.builder()
     *             .withType(Account.class)
     *             .withReturnType(FormulaEval.FormulaReturnType.BOOLEAN)
     *             .withFormula('Rating = "Hot" AND OwnerId = $User.Id')
     *             .withGlobalVariables(new List<FormulaEval.FormulaGlobal>{ FormulaEval.FormulaGlobal.USER })
     *             .build()
     *     ));
     *
     * Build the instance once and reuse it: build() parses and validates, and paying that per record would
     * dominate the loop.
     *
     * If the context type is a custom Apex class, the class and every member the formula touches must be
     * global.
     */
    global FormulaFilterFunction(FormulaEval.FormulaInstance formula) {
        this.formula = formula;
    }

    global Boolean isTrueFor(Object candidate) {
        return (Boolean) this.formula.evaluate(candidate);
    }
}

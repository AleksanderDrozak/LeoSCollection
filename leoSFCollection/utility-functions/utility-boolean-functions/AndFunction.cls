@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class AndFunction implements BooleanFunction, FilterUtil.BooleanFunctionAgregatorDouble {

    private BooleanFunction functionToValidateA;
    private BooleanFunction functionToValidateB;

    @SuppressWarnings('PMD.EmptyStatementBlock')
    global AndFunction() {
    }

    global AndFunction(BooleanFunction functionToValidateA, BooleanFunction functionToValidateB) {
        this.initialize(functionToValidateA, functionToValidateB);
    }

    global BooleanFunction initialize(BooleanFunction functionToValidateA, BooleanFunction functionToValidateB) {
        this.functionToValidateA = functionToValidateA;
        this.functionToValidateB = functionToValidateB;
        return this;
    }

    global Boolean isTrueFor(Object obj) {
        return this.functionToValidateA.isTrueFor(obj) && this.functionToValidateB.isTrueFor(obj);
    }
}
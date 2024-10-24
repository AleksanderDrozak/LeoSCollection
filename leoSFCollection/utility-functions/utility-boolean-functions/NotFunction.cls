@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class NotFunction implements BooleanFunction, FilterUtil.BooleanFunctionAgregatorSingle {

    private BooleanFunction functionToNegate;

    @SuppressWarnings('PMD.EmptyStatementBlock')
    global NotFunction() {
    }

    global NotFunction(BooleanFunction functionToNegate) {
        this.initialize(functionToNegate);
    }

    global BooleanFunction initialize(BooleanFunction functionToNegate) {
        this.functionToNegate = functionToNegate;
        return this;
    }

    global Boolean isTrueFor(Object obj) {
        return !this.functionToNegate.isTrueFor(obj);
    }
}
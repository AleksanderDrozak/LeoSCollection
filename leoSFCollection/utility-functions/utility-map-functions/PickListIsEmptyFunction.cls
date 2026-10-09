@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class PickListIsEmptyFunction extends PickListApplyFunction implements BooleanFunction {

    public PickListIsEmptyFunction(SObjectField pickListObject, List<Object> functions) {
        super(pickListObject, functions, new IteratorToIsEmpty());
    }

    public PickListIsEmptyFunction(SObjectField pickListObject) {
        super(pickListObject, new IteratorToIsEmpty());
    }

    /** the same answer mapValue() gives, so the step can stand in a filter as well as a transform */
    global Boolean isTrueFor(Object o) {
        return (Boolean) this.mapValue(o);
    }
}
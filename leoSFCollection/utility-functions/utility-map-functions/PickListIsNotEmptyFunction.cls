@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class PickListIsNotEmptyFunction extends PickListApplyFunction implements BooleanFunction {

    public PickListIsNotEmptyFunction(SObjectField pickListObject, List<Object> functions) {
        super(pickListObject, functions, new IteratorToIsNotEmpty());
    }

    public PickListIsNotEmptyFunction(SObjectField pickListObject) {
        super(pickListObject, new IteratorToIsNotEmpty());
    }

    /** the same answer mapValue() gives, so the step can stand in a filter as well as a transform */
    global Boolean isTrueFor(Object o) {
        return (Boolean) this.mapValue(o);
    }
}
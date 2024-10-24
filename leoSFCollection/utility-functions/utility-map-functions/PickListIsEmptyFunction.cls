@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class PickListIsEmptyFunction extends PickListApplyFunction {

    public PickListIsEmptyFunction(SObjectField pickListObject, List<Object> functions) {
        super(pickListObject, functions, new IteratorToIsEmpty());
    }

    public PickListIsEmptyFunction(SObjectField pickListObject) {
        super(pickListObject, new IteratorToIsEmpty());
    }
}
@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class PickListIsNotEmptyFunction extends PickListApplyFunction {

    public PickListIsNotEmptyFunction(SObjectField pickListObject, List<Object> functions) {
        super(pickListObject, functions, new IteratorToIsNotEmpty());
    }

    public PickListIsNotEmptyFunction(SObjectField pickListObject) {
        super(pickListObject, new IteratorToIsNotEmpty());
    }
}
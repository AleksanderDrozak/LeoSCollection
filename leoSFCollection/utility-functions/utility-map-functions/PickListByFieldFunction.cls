@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing virtual class PickListByFieldFunction implements MapFunction {

    protected SObjectField pickListObject;

    global PickListByFieldFunction(SObjectField pickListObject) {
        this.pickListObject = pickListObject;
    }

    global Object mapValue(Object obj) {
        return mapValue((SObject) obj);
    }

    global virtual Object mapValue(SObject obj) {
        return obj.getSObjects(this.pickListObject);
    }
}
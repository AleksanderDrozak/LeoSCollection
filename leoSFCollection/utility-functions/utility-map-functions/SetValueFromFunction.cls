@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing virtual class SetValueFromFunction implements MapFunction {

    protected sobjectField setField;
    protected MapFunction getValueFunction;

    global SetValueFromFunction(sobjectField setField, MapFunction getValueFunction) {
        this.setField = setField;
        this.getValueFunction = getValueFunction;
    }

    global virtual Object mapValue(Object obj) {
        return mapValue((SObject) obj);
    }

    global Object mapValue(SObject obj) {
        obj.put(this.setField, this.getValueFunction.mapValue(obj));
        return obj;
    }
}
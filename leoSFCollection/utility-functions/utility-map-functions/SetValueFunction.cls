@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing virtual class SetValueFunction implements MapFunction {

    protected sobjectField setField;
    protected Object value;

    global SetValueFunction(sobjectField setField, Object value) {
        this.setField = setField;
        this.value = value;
    }

    global virtual Object mapValue(Object obj) {
        return mapValue((SObject) obj);
    }

    global Object mapValue(SObject obj) {
        obj.put(this.setField, this.value);
        return obj;
    }
}
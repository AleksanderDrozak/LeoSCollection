@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing virtual class SetMultipleValuesFunction implements MapFunction {

    private Map<SObjectField, Object> mappings;

    global SetMultipleValuesFunction(Map<SObjectField, Object> mappings) {
        this.mappings = mappings;
    }

    global Object mapValue(Object obj) {
        return mapValue((SObject) obj);
    }

    global Object mapValue(SObject obj) {

        for(SObjectField field : this.mappings.keySet()) {
            obj.put(field, this.mappings.get(field));
        }

        return obj;
    }
}
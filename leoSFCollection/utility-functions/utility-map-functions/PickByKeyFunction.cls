@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class PickByKeyFunction implements MapFunction {

    private final String key;

    /**
     * Reads one value out of a Map by key, so a pipeline can work over data that is already keyed rather
     * than over records.
     *
     * The two sources that make this worth having: SObject.getPopulatedFieldsAsMap() turns a record - or an
     * AggregateResult - into a Map<String, Object>, and JSON.deserializeUntyped() turns an inbound payload
     * into one. Both then read the same way:
     *
     *     Collection.of(rows).transform(new PickByKeyFunction('total'))
     */
    global PickByKeyFunction(String key) {
        this.key = key;
    }

    global Object mapValue(Object current) {
        return ((Map<String, Object>) current).get(this.key);
    }
}

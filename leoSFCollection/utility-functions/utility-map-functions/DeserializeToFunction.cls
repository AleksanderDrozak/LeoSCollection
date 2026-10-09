@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class DeserializeToFunction implements MapFunction {

    private final Type targetType;

    /**
     * Turns a row into a typed DTO by round-tripping it through JSON.
     *
     * Written for aggregate results, where the alternative is a cast per column:
     *
     *     (Integer) row.get('total')      // and one more cast for every other alias
     *
     * The DTO's field names must match the SOQL aliases - that is the point: the query already names its
     * columns, so the mapping is declared there instead of here.
     *
     *     SELECT BillingCountry, COUNT(Id) total FROM Account GROUP BY BillingCountry
     *     // DTO: global String billingCountry; global Integer total;
     *
     * It is not aggregate-specific: any SObject row serialises to a JSON object keyed by field name, so the
     * same step maps a plain query result onto a payload class. An AggregateResult serialises with an extra
     * "attributes" key, which JSON.deserialize ignores.
     */
    global DeserializeToFunction(Type targetType) {
        this.targetType = targetType;
    }

    global Object mapValue(Object current) {
        return JSON.deserialize(JSON.serialize(current), this.targetType);
    }
}

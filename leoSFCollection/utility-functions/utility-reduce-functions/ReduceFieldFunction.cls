@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class ReduceFieldFunction implements ReduceFunction {

    global class ReduceFieldFunctionException extends LeoSCollectionException {}

    global enum Aggregation {
        SUM,
        MIN,
        MAX,
        AVERAGE
    }

    private String fieldName;
    private Aggregation aggregation;
    private Integer processedCount = 0;

    global ReduceFieldFunction(SObjectField field, Aggregation aggregation) {
        this(field.toString(), aggregation);
    }

    private ReduceFieldFunction(String fieldName, Aggregation aggregation) {
        this.fieldName = fieldName;
        this.aggregation = aggregation;
    }

    global static ReduceFieldFunction sum(SObjectField field) {
        return new ReduceFieldFunction(field, Aggregation.SUM);
    }

    global static ReduceFieldFunction min(SObjectField field) {
        return new ReduceFieldFunction(field, Aggregation.MIN);
    }

    global static ReduceFieldFunction max(SObjectField field) {
        return new ReduceFieldFunction(field, Aggregation.MAX);
    }

    global static ReduceFieldFunction average(SObjectField field) {
        return new ReduceFieldFunction(field, Aggregation.AVERAGE);
    }

    /** by API name, so an AggregateResult alias can be reduced the same way a record field is */
    global static ReduceFieldFunction sum(String fieldName) {
        return new ReduceFieldFunction(fieldName, Aggregation.SUM);
    }

    global static ReduceFieldFunction min(String fieldName) {
        return new ReduceFieldFunction(fieldName, Aggregation.MIN);
    }

    global static ReduceFieldFunction max(String fieldName) {
        return new ReduceFieldFunction(fieldName, Aggregation.MAX);
    }

    global static ReduceFieldFunction average(String fieldName) {
        return new ReduceFieldFunction(fieldName, Aggregation.AVERAGE);
    }

    global Object getInitialValue() {

        /** called once per reduce run: a template applied twice must not carry the first run's count into the second */
        this.processedCount = 0;

        if(isBoundaryAggregation()) {
            return null;
        }
        return 0;
    }

    global Object reduceValue(Object previous, Object current) {
        return this.reduceValue((Decimal) previous, (SObject) current);
    }

    global Decimal reduceValue(Decimal previous, SObject record) {

        Decimal value = this.getValue(record);
        this.processedCount++;

        switch on this.aggregation {
            /** a missing value contributes nothing to a sum */
            when SUM {
                return (previous == null ? 0 : previous) + (value == null ? 0 : value);
            }
            /** a missing value is not a boundary, so it is skipped instead of being read as zero */
            when MIN {
                if(value == null) {
                    return previous;
                }
                return previous == null || previous > value ? value : previous;
            }
            when MAX {
                if(value == null) {
                    return previous;
                }
                return previous == null || previous < value ? value : previous;
            }
            when AVERAGE {
                return (previous == null ? 0 : previous) * (this.processedCount - 1) / this.processedCount
                       + (value == null ? 0 : value) / this.processedCount;
            }
            when else {
                throw new ReduceFieldFunctionException('Unhandled aggregation ' + String.valueOf(this.aggregation));
            }
        }
    }

    private Decimal getValue(SObject record) {
        return (Decimal) record.get(this.fieldName);
    }

    private Boolean isBoundaryAggregation() {
        return this.aggregation == Aggregation.MIN || this.aggregation == Aggregation.MAX;
    }
}

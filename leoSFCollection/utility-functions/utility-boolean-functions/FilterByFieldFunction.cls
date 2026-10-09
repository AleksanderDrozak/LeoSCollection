@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class FilterByFieldFunction implements BooleanFunction {

    global class FilterByFieldFunctionException extends LeoSCollectionException {}

    global List<FilterByCondition> conditions = new List<FilterByCondition>();

    private BooleanFunction combined;

    global FilterByFieldFunction addFilterBy(FilterByCondition condition) {
        this.conditions.add(condition);
        this.combined = null;
        return this;
    }

    global FilterByFieldFunction addFilterBy(SObjectField field, ComparationUtil.Comparators comparator, Object compareTo) {
        this.conditions.add(new FilterByCondition(field, comparator, compareTo));
        this.combined = null;
        return this;
    }

    /** by API name, so an AggregateResult alias can be filtered the same way a record field is */
    global FilterByFieldFunction addFilterBy(String fieldName, ComparationUtil.Comparators comparator, Object compareTo) {
        this.conditions.add(new FilterByCondition(fieldName, comparator, compareTo));
        this.combined = null;
        return this;
    }

    /** Conditions are combined with AND. For OR / NOT compose AndFunction, OrFunction and NotFunction directly. */
    global BooleanFunction evaluate() {

        if(this.conditions.isEmpty()) {
            throw new FilterByFieldFunctionException('Cannot evaluate a filter without any condition added');
        }

        BooleanFunction returnVal = null;

        for(FilterByCondition condition : this.conditions) {
            if(returnVal == null) {
                returnVal = condition;
            } else {
                returnVal = new AndFunction(returnVal, condition);
            }
        }

        return returnVal;
    }

    /** so the class can be passed to filter() directly instead of requiring .evaluate() first; the chain is built once and cached */
    global Boolean isTrueFor(Object obj) {

        if(this.combined == null) {
            this.combined = this.evaluate();
        }

        return this.combined.isTrueFor(obj);
    }
}

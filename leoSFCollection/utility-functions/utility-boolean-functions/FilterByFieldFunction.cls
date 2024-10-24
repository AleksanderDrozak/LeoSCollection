@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class FilterByFieldFunction {

    global List<FilterByCondition> condtions = new List<FilterByCondition>();
    
    global String expression;

    private static final FilterUtil.FilterExpressionTransformer EXPRESSION_TRANSFORMER = new FilterUtil.FilterExpressionTransformer(
        new Map<FilterUtil.FilterJoinOperators, Type> {
            FilterUtil.FilterJoinOperators.AND_OPERATOR => AndFunction.class,
            FilterUtil.FilterJoinOperators.OR_OPERATOR => OrFunction.class,
            FilterUtil.FilterJoinOperators.NOT_OPERATOR => NotFunction.class
        }
    );
    
    global FilterByFieldFunction addFilterBy(FilterByCondition condition) {
        this.condtions.add(condition);
        return this;
    }

    global FilterByFieldFunction addFilterBy(SObjectField field, ComparationUtil.Comparators comparator, Object compareTo) {
        this.condtions.add(new FilterByCondition(field, comparator, compareTo));
        return this;
    }

    global FilterByFieldFunction setExpression(String expression) {
        this.expression = expression;
        return this;
    }

    global BooleanFunction evaluate() {
        /** treat as all ANDs */
        if(this.expression == null) {
            this.setAndExpression();
        }

        return EXPRESSION_TRANSFORMER.evaluate(this.expression, this.condtions);
    }

    private void setAndExpression() {
 
        List<Integer> condtionsNumber = new List<Integer>();

        for(Integer value = 1; value <= this.condtions.size(); value++){
            condtionsNumber.add(value);
        }

        this.expression = String.join(condtionsNumber, ' AND ');
    }
}

@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class GroupByFieldFunction implements GroupByFunction {

    private String groupByFieldName;

    global GroupByFieldFunction(SObjectField groupByField){
        this.groupByFieldName = groupByField.toString();
    }

    /** by API name, so an AggregateResult alias can be grouped the same way a record field is */
    global GroupByFieldFunction(String groupByFieldName){
        this.groupByFieldName = groupByFieldName;
    }

    global String getGroupKey(Object obj){
        return String.valueOf(this.getGroupKey((SObject) obj));
    }

    global Object getGroupKey(SObject obj){
        return obj.get(this.groupByFieldName);
    }
}
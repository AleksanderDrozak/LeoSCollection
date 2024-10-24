@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class GroupByFieldFunction implements GroupByFunction {

    private SObjectField groupByField;
    
    global GroupByFieldFunction(SObjectField groupByField){
        this.groupByField = groupByField;
    }

    global String getGroupKey(Object obj){
        return String.valueOf(this.getGroupKey((SObject) obj));
    }

    global Object getGroupKey(SObject obj){
        return obj.get(groupByField);
    }
}
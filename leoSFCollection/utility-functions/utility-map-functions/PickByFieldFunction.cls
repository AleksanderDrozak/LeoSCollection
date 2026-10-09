@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class PickByFieldFunction implements MapFunction {
    
    private String pickFieldName;

    global PickByFieldFunction(sobjectField pickField){
        this.pickFieldName = pickField.toString();
    }

    /** by API name instead of a token - the only way to read a SOQL alias, which has no SObjectField */
    global PickByFieldFunction(String pickFieldName){
        this.pickFieldName = pickFieldName;
    }

    global Object mapValue(Object obj){
        return mapValue((SObject) obj);
    }

    global Object mapValue(SObject obj){
        return obj.get(this.pickFieldName);
    }
}
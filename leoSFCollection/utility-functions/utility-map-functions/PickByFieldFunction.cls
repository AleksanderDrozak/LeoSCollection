@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class PickByFieldFunction implements MapFunction {
    
    sobjectField pickField;

    global PickByFieldFunction(sobjectField pickField){
        this.pickField = pickField;
    }

    global Object mapValue(Object obj){
        return mapValue((SObject) obj);
    }

    global Object mapValue(SObject obj){
        return obj.get(this.pickField);
    }
}
@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class MaxFieldFunction implements ReduceFunction {
   
    SObjectField fieldToFindMax;

    global MaxFieldFunction(SObjectField fieldToFindMax) {
        this.fieldToFindMax = fieldToFindMax;
    }

    global Object getInitialValue() {
        return null;
    }

    global Object reduceValue(Object currentMax, Object obj){
        return reduceValue((Decimal) currentMax, (SObject) obj);
    }

    global Decimal reduceValue(Decimal currentMax, SObject obj){
        Decimal currentValue = (Decimal) obj.get(this.fieldToFindMax);
        
        if(currentMax == null) {
            return currentValue;
        }

        return currentMax < currentValue ? currentValue : currentMax;
    }
}


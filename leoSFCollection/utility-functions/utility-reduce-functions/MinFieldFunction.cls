@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class MinFieldFunction implements ReduceFunction {

    SObjectField fieldToFindMin;

    global MinFieldFunction(SObjectField fieldToFindMin) {
        this.fieldToFindMin = fieldToFindMin;
    }

    global Object getInitialValue() {
        return null;
    }

    global Object reduceValue(Object currentMin, Object obj){
        return reduceValue((Decimal) currentMin, (SObject) obj);
    }

    global Decimal reduceValue(Decimal currentMin, SObject obj){
        Decimal currentValue = (Decimal) obj.get(this.fieldToFindMin);

        if(currentMin == null) {
            return currentValue;
        }

        return currentMin > currentValue ? currentValue : currentMin;
    }
}

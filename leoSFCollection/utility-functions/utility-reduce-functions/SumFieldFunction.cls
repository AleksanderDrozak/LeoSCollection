@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class SumFieldFunction implements ReduceFunction {

    SObjectField fieldToSum;

    global SumFieldFunction(SObjectField fieldToSum) {
        this.fieldToSum = fieldToSum;
    }

    global Object getInitialValue() {
        return 0;
    }

    global Object reduceValue(Object currentSum, Object obj){
        return reduceValue((Decimal) currentSum, (SObject) obj);
    }

    Decimal getValue(SObject obj){
        Decimal value = (Decimal) obj.get(this.fieldToSum);
        return value != null ? value : (Decimal) this.getInitialValue();
    }

    global Decimal reduceValue(Decimal currentSum, SObject obj){
        return currentSum + this.getValue(obj);
    }
}
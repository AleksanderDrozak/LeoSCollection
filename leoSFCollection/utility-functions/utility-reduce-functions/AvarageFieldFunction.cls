@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class AvarageFieldFunction implements ReduceFunction {

    SObjectField fieldToAvarage;
    Integer index;

    global AvarageFieldFunction(SObjectField fieldToAvarage) {
        this.fieldToAvarage = fieldToAvarage;
        this.index = 0;
    }

    global Object getInitialValue() {
        return 0;
    }

    global Object reduceValue(Object currentSum, Object obj){
        return reduceValue((Decimal) currentSum, (SObject) obj);
    }

    Decimal getValue(SObject obj){
        Decimal value = (Decimal) obj.get(this.fieldToAvarage);
        return value != null ? value : (Decimal) this.getInitialValue();
    }

    global Decimal reduceValue(Decimal currentAvarage, SObject obj){
        this.index++;
        /** dynamic avarage caluclation for growing sets of numbers */
        return currentAvarage * (this.index-1)/this.index + this.getValue(obj)/this.index;
    }
}

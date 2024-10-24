@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class FilterByCondition implements BooleanFunction {

    global SObjectField field;
    global SoapType fieldType;
    global ComparationUtil.Comparators comparator;
    global Object compareTo;

    global FilterByCondition(
        SObjectField field,
        ComparationUtil.Comparators comparator,
        Object compareTo
    ){
        this.field = field;
        this.fieldType = field.getDescribe().getSoapType();
        this.comparator = comparator;
        this.compareTo = compareTo;
    }

    global Boolean isTrueFor(Object obj) {
        return isTrueFor((SObject) obj);
    }

    global Boolean isTrueFor(SObject obj) {
        return this.validate(obj);
    }
    
    public Boolean validate(SObject obj) {
        
        Object compareFrom = obj.get(this.field);

        return ComparationUtil.compare(compareFrom, this.comparator, this.compareTo);
    }
}
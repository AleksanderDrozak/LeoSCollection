@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class FilterByCondition implements BooleanFunction {

    global String fieldName;
    global SoapType fieldType;
    global ComparationUtil.Comparators comparator;
    global Object compareTo;

    global FilterByCondition(
        SObjectField field,
        ComparationUtil.Comparators comparator,
        Object compareTo
    ){
        this.fieldName = field.toString();
        this.fieldType = field.getDescribe().getSoapType();
        this.comparator = comparator;
        this.compareTo = compareTo;
    }

    /**
     * By API name instead of a token - the way to compare a SOQL alias, which has no SObjectField. No
     * describe() is needed: the comparison uses the value's runtime type, not the field's declared type.
     */
    global FilterByCondition(
        String fieldName,
        ComparationUtil.Comparators comparator,
        Object compareTo
    ){
        this.fieldName = fieldName;
        this.comparator = comparator;
        this.compareTo = compareTo;
    }

    global static FilterByCondition equalsTo(SObjectField field, Object compareTo) {
        return new FilterByCondition(field, ComparationUtil.Comparators.EQUALS, compareTo);
    }

    global static FilterByCondition notEquals(SObjectField field, Object compareTo) {
        return new FilterByCondition(field, ComparationUtil.Comparators.NOT_EQUALS, compareTo);
    }

    global static FilterByCondition greaterThan(SObjectField field, Object compareTo) {
        return new FilterByCondition(field, ComparationUtil.Comparators.GREATER_THAN, compareTo);
    }

    global static FilterByCondition lessThan(SObjectField field, Object compareTo) {
        return new FilterByCondition(field, ComparationUtil.Comparators.LESS_THAN, compareTo);
    }

    /** substring test, not equality: reads as "the field includes this text" */
    global static FilterByCondition includes(SObjectField field, Object compareTo) {
        return new FilterByCondition(field, ComparationUtil.Comparators.INCLUDES, compareTo);
    }

    global Boolean isTrueFor(Object obj) {
        return isTrueFor((SObject) obj);
    }

    global Boolean isTrueFor(SObject obj) {
        return this.validate(obj);
    }
    
    public Boolean validate(SObject obj) {
        
        Object compareFrom = obj.get(this.fieldName);

        return ComparationUtil.compare(compareFrom, this.comparator, this.compareTo);
    }
}
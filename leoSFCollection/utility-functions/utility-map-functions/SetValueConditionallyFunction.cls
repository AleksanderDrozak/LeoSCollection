@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class SetValueConditionallyFunction extends SetValueFunction {

    protected BooleanFunction condition;

    global SetValueConditionallyFunction(sobjectField setField, BooleanFunction condition, Object value) {
        super(setField, value);
        this.condition = condition;
    }

    global override Object mapValue(Object obj) {

        if(condition.isTrueFor(obj)) {
            return super.mapValue(obj);
        }

        return obj;
    }
}
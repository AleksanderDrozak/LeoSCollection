@SuppressWarnings('PMD.AvoidGlobalModifier')
global interface ReduceFunction {
    Object getInitialValue();
    Object reduceValue(Object previous, Object current);
}
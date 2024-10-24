@SuppressWarnings('PMD.AvoidGlobalModifier')
global interface GroupByFunction {
    String getGroupKey(Object current);
}
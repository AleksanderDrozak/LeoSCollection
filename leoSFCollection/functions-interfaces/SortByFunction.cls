@SuppressWarnings('PMD.AvoidGlobalModifier')
global interface SortByFunction {
    
    SortByFunction setOrder(SortUtil.SORTING_ORDER order);

    /** @describe used in pair with Comparable interface which requries */
    Integer compare(Object compareFrom, Object compareTo);
}
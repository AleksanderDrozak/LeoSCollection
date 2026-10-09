@SuppressWarnings('PMD.AvoidGlobalModifier')
global interface SortByFunction {
    
    SortByFunction setOrder(SortUtil.SORTING_ORDER order);

    /** declared here so the direction can be set through the interface, which is the type pipe() and sortBy() hand you */
    SortByFunction setAscending();

    SortByFunction setDescending();

    /** @describe used in pair with Comparable interface which requries */
    Integer compare(Object compareFrom, Object compareTo);
}
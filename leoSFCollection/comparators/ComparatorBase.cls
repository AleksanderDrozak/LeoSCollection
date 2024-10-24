@SuppressWarnings('PMD.AvoidGlobalModifier')
global abstract class ComparatorBase implements SortByFunction {

    protected SortUtil.SORTING_ORDER sortingOrder = SortUtil.SORTING_ORDER.ASCENDING;
    
    private Integer compareTrueValue = SortUtil.SORTING_ORDER_TRUE_VALUE_MAP.get(SortUtil.SORTING_ORDER.ASCENDING);

    private Boolean isAsc = true;

    global abstract Integer compare(Object compareFrom, Object compareTo);
    
    global Integer compare(Boolean isBigger) {
        return isBigger ? this.compareTrueValue : -this.compareTrueValue;
    }

    global Integer compare(Integer comparationDistance) {
        return this.isAsc ? comparationDistance : -comparationDistance;
    }

    global virtual SortByFunction setDescending() {
        return this.setOrder(SortUtil.SORTING_ORDER.DESCENDING);
    }

    global virtual SortByFunction setAscending() {
        return this.setOrder(SortUtil.SORTING_ORDER.ASCENDING);
    }

    global virtual SortByFunction setOrder(SortUtil.SORTING_ORDER sortingOrder) {
        this.sortingOrder = sortingOrder;
        this.compareTrueValue = SortUtil.SORTING_ORDER_TRUE_VALUE_MAP.get(this.sortingOrder);
        this.isAsc = sortingOrder === SortUtil.SORTING_ORDER.ASCENDING;
        return (SortByFunction) this;
    }
}

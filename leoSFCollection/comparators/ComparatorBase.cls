@SuppressWarnings('PMD.AvoidGlobalModifier')
global abstract class ComparatorBase implements SortByFunction {

    protected SortUtil.SORTING_ORDER sortingOrder = SortUtil.SORTING_ORDER.ASCENDING;

    global abstract Integer compare(Object compareFrom, Object compareTo);

    /** Orderless distance in, ordered result out - the one place direction is applied. */
    global Integer compare(Integer comparationDistance) {
        return this.sortingOrder == SortUtil.SORTING_ORDER.ASCENDING ? comparationDistance : -comparationDistance;
    }

    global virtual SortByFunction setDescending() {
        return this.setOrder(SortUtil.SORTING_ORDER.DESCENDING);
    }

    global virtual SortByFunction setAscending() {
        return this.setOrder(SortUtil.SORTING_ORDER.ASCENDING);
    }

    global virtual SortByFunction setOrder(SortUtil.SORTING_ORDER sortingOrder) {
        this.sortingOrder = sortingOrder;
        return (SortByFunction) this;
    }
}
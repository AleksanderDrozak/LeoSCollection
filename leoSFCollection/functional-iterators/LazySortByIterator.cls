@SuppressWarnings('PMD.AvoidGlobalModifier')
global class LazySortByIterator extends LazyIterator {

    private List<SortingWrapper> sortedWrappers;
    private Integer position = 0;

    /**
     * The sort runs here, when sortBy() is called, rather than on the first read. A sort cannot emit anything
     * before it has seen every element, so deferring the work bought nothing - it only moved the cost into
     * hasNext(), where it turned up as a stall on an unrelated call. Sorting at the call makes the barrier the
     * caller's decision instead of a surprise, and the stream that comes out is an ordinary one.
     */
    public LazySortByIterator(Iterator<Object> iterator, SortByFunction sortingFunction) {
        super(iterator);

        List<SortingWrapper> wrapped = new List<SortingWrapper>();

        while(iterator.hasNext()) {
            wrapped.add(new SortingWrapper(iterator.next(), sortingFunction));
        }

        wrapped.sort();
        this.sortedWrappers = wrapped;
    }

    global override Boolean hasNext() {
        return this.position < this.sortedWrappers.size();
    }

    global override Object next() {
        Object value = this.sortedWrappers[this.position].value();
        this.position++;
        return value;
    }

    global inherited sharing class SortingWrapper implements Comparable {

        private Object compareFrom;
        private SortByFunction sortingFunction;

        public SortingWrapper(Object compareFrom, SortByFunction sortingFunction) {
            this.compareFrom = compareFrom;
            this.sortingFunction = sortingFunction;
        }

        global Integer compareTo(Object compareTo) {
            return this.compareTo((SortingWrapper) compareTo);
        }

        global Integer compareTo(SortingWrapper compareTo) {
            return this.sortingFunction.compare(this.compareFrom, compareTo.value());
        }

        Object value() {
            return this.compareFrom;
        }
    }
}

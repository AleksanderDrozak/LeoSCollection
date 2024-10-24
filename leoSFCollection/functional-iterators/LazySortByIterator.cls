@SuppressWarnings('PMD.AvoidGlobalModifier')
global class LazySortByIterator extends LazyIterator {

    private SortByFunction sortingFunction;

    public LazySortByIterator(Iterator<Object> iterator, SortByFunction sortingFunction) {
        super(iterator);
        this.sortingFunction = sortingFunction;
    }

    global override LazyIterator instance() {
        return this.instanceWithSortedData();
    }

    private LazyIterator instanceWithSortedData() {
        final List<SortingWrapper> dataToSort = (List<SortingWrapper>) this.wrap(new SortingWrapper(this.sortingFunction)).toList(SortingWrapper.class);
        dataToSort.sort();
        return new LazySortWrapperIterator(dataToSort);
    }

    /** class to unpack value wrapped for sorting logic */
    global class LazySortWrapperIterator extends LazyIterator {

        public LazySortWrapperIterator(List<SortingWrapper> sortingWrappersList) {
            super(sortingWrappersList);
        }

        global override Object next() {
            SortingWrapper wrapper = (SortingWrapper) super.next();
            return wrapper.value();
        }
    }

    global inherited sharing class SortingWrapper implements Comparable, WrapperFunction {

        private Object compareFrom;
        private SortByFunction sortingFunction;

        public SortingWrapper(Object compareFrom, SortByFunction sortingFunction) {
            this.compareFrom = compareFrom;
            this.sortingFunction = sortingFunction;
        }

        public SortingWrapper(SortByFunction sortingFunction) {
            this.sortingFunction = sortingFunction;
        }

        global Integer compareTo(Object compareTo) {
            return this.compareTo((SortingWrapper) compareTo);
        }

        global Integer compareTo(SortingWrapper compareTo) {
            return this.sortingFunction.compare(this.compareFrom, compareTo.value());
        }

        global Object wrap(Object data) {
            return new SortingWrapper(data, this.sortingFunction);
        }

        Object value() {
            return this.compareFrom;
        }
    }
}

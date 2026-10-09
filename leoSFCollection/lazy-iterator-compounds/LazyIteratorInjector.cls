public without sharing class LazyIteratorInjector {

    private LazyIterator injectFunction(LazyIterator iterator, Object function, Integer index) {

        if(function instanceof BooleanFunction) {
            return new LazyFilterIterator(iterator, (BooleanFunction) function);
        }

        if(function instanceof IndexedMapFunction) {
            return new LazyMapWithIndexIterator(iterator, (IndexedMapFunction) function);
        }

        if(function instanceof MapFunction) {
            return new LazyMapIterator(iterator, (MapFunction) function);
        }

        if(function instanceof ReduceFunction) {
            return new LazyReduceIterator(iterator, (ReduceFunction) function);
        }

        if(function instanceof SortByFunction) {
            return new LazySortByIterator(iterator, (SortByFunction) function);
        }

        if(function instanceof GroupByFunction) {
            return new LazyGroupByIterator(iterator, (GroupByFunction) function);
        }

        if(function instanceof FlatFunction) {
            return new LazyFlatIterator(iterator);
        }

        if(function instanceof WrapperFunction) {
            return new LazyWrapIterator(iterator, (WrapperFunction) function);
        }

        if(function instanceof Function) {
            return new LazyTapIterator(iterator, (Function) function);
        }

        if(function instanceof LimitFunction) {
            return new LazyLimitIterator(iterator, (LimitFunction) function);
        }

        /** Apex cannot type-check a List<Object> at compile time and has no reflection for a class name,
            so the index is the part that actually locates the mistake in the caller's list literal. */
        throw new LeoSCollectionException(
            'Element ' + index + ' of the pipe is not a recognised pipeline step: ' + String.valueOf(function)
            + '. Expected one of MapFunction, IndexedMapFunction, BooleanFunction, ReduceFunction, SortByFunction, '
            + 'GroupByFunction, FlatFunction, WrapperFunction, Function, LimitFunction.'
        );
    }

    public LazyIterator injectFunctions(LazyIterator iterator, List<Object> functions) {

        Integer index = 0;

        for(Object function : functions) {
            iterator = this.injectFunction(iterator, function, index);
            index++;
        }

        return iterator;
    }
}

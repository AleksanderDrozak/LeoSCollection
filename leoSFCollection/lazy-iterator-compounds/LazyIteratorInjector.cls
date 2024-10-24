public without sharing class LazyIteratorInjector {

    class LazyIteratorInjectorException extends Exception {}

    private LazyIterator injectFunction(LazyIterator iterator, Object function) {

        if(function instanceof BooleanFunction) {
            return new LazyFilterIterator(iterator, (BooleanFunction) function);
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

        throw new LazyIteratorInjectorException('Not implemented function type!' + String.valueOf(function));
    }

    public LazyIterator injectFunctions(LazyIterator iterator, List<Object> functions) {

        for(Object function : functions) {
            iterator = this.injectFunction(iterator, function);
        }

        return iterator;
    }

    /**
     * @descrition inject data to current instance of iterator, so any operation can be done on that set of data, so already setup Lazy Iterator can be reused.
     * @explanation General purpose of this method is to find first lazy iterator and replace its iterator field with current data iterator, so when one of method that evealuates lazy iterator will run, be executed on data passed as argument to apply instead of initialy applied data durring creation of first Lazy Iterator. Is not recommended to use on any Lazy Iterator that had initially passed data to iterate, because it might affect that.
     */
    public LazyIterator injectData(LazyIterator iterator, Object data) {
        Object currentLazyIterator = iterator;
        Object currentLazyIteratorIterator = ((LazyIterator) currentLazyIterator).iterator;

        while(currentLazyIteratorIterator instanceof LazyIterator) {
            currentLazyIterator = currentLazyIteratorIterator;
            currentLazyIteratorIterator = ((LazyIterator) currentLazyIteratorIterator).iterator;
        }

        ((LazyIterator) currentLazyIterator).iterator = ((Iterable<Object>) data).iterator();

        return iterator.clone();
    }
}
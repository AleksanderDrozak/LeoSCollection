@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class Collection {

    global static LazyIterator nil() {
        return new LazyIterator();
    }

    global static LazyIterator empty() {
        return new LazyIterator(new List<Object>());
    }

    global static LazyIterator of(Object anyInstance) {
        return new LazyIterator(anyInstance);
    }

    global static LazyIterator filter(Object anyInstance, BooleanFunction matchingFunction) {
        return of(anyInstance).filter(matchingFunction);
    }

    global static LazyIterator transform(Object anyInstance, MapFunction mappingFunction) {
        return of(anyInstance).transform(mappingFunction);
    }

    global static LazyIterator wrap(Object anyInstance, WrapperFunction wrapFunction) {
        return of(anyInstance).wrap(wrapFunction);
    }

    global static LazyIterator reduce(Object anyInstance, ReduceFunction reducingFunction) {
        return of(anyInstance).reduce(reducingFunction);
    }

    global static LazyIterator groupBy(Object anyInstance, GroupByFunction grouppingFunction) {
        return of(anyInstance).groupBy(grouppingFunction);
    }

    global static LazyIterator flat(Object anyInstance) {
        return of(anyInstance).flat();
    }

    global static LazyIterator flatMap(Object anyInstance, MapFunction mappingFunction) {
        return of(anyInstance).flatMap(mappingFunction);
    }
    
    global static LazyIterator sortBy(Object anyInstance, SortByFunction sortingFunction) {
        return of(anyInstance).sortBy(sortingFunction);
    }

    global static LazyIterator sortBy(Object anyInstance) {
        return of(anyInstance).sortBy();
    }

    global static LazyIterator sortBy(Object anyInstance, SortUtil.SORTING_ORDER order) {
        return of(anyInstance).sortBy(order);
    }

    global static LazyIterator pipe(Object anyInstance, List<Object> functions) {
        return of(anyInstance).pipe(functions);
    }

    global static LazyIterator query(QueryableFunction function) {
        return empty().query(function);
    }
    
    global static Boolean every(Object anyInstance, BooleanFunction matchingFunction) {
        return of(anyInstance).every(matchingFunction);
    }

    global static Boolean some(Object anyInstance, BooleanFunction matchingFunction) {
        return of(anyInstance).some(matchingFunction);
    }

    global static Object find(Object anyInstance, BooleanFunction matchingFunction) {
        return of(anyInstance).find(matchingFunction);
    }

    global static void forEach(Object anyInstance, Function callingFunction) {
        of(anyInstance).forEach(callingFunction);
    }

    global static Object firstOrDefault(Object anyInstance, Object defaultValue) {
        return of(anyInstance).firstOrDefault(defaultValue);
    }
}
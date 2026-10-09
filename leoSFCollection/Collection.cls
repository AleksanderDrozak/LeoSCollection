@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class Collection {

    /**
     * A pipeline with no source yet. Building one is a deliberate act, and it stays inert until apply()
     * hands it data - a template is a step list, not a stream, so nothing runs against it until then.
     */
    global static TemplateIterator template() {
        return new TemplateIterator();
    }

    global static TemplateIterator template(List<Object> steps) {
        return new TemplateIterator(steps);
    }

    /**
     * The source, whatever it is: a list, a set, an existing Iterator. A Map is accepted, but a map iterates
     * over its keys - so of(someMap) hands you the keys and drops the values. When the map is already grouped
     * and the values are the point, that is ofMap().
     */
    global static LazyIterator of(Object anyInstance) {

        if(anyInstance == null) {
            throw new LeoSCollectionException('Collection.of(null) has no source to iterate; pass a list (an empty one is fine) or an Iterator.');
        }

        return new LazyIterator(anyInstance);
    }

    /**
     * A map that is already grouped: each entry is a key and its members. Nothing is bucketed here - the
     * grouping exists already, so this is the way in when the map came from somewhere other than groupBy(),
     * a payload, another pipeline's toListMap(), or a query result shaped by hand.
     */
    global static LazyGroupByIterator ofMap(Map<String, List<Object>> grouped) {
        return new LazyGroupByIterator(grouped);
    }

    global static LazyIterator filter(Object anyInstance, BooleanFunction matchingFunction) {
        return of(anyInstance).filter(matchingFunction);
    }

    global static LazyIterator transform(Object anyInstance, MapFunction mappingFunction) {
        return of(anyInstance).transform(mappingFunction);
    }

    global static LazyIterator transformWithIndex(Object anyInstance, IndexedMapFunction mappingFunction) {
        return of(anyInstance).transformWithIndex(mappingFunction);
    }

    global static LazyIterator wrap(Object anyInstance, WrapperFunction wrapFunction) {
        return of(anyInstance).wrap(wrapFunction);
    }

    global static LazyIterator reduce(Object anyInstance, ReduceFunction reducingFunction) {
        return of(anyInstance).reduce(reducingFunction);
    }

    global static LazyGroupByIterator groupBy(Object anyInstance, GroupByFunction groupingFunction) {
        return of(anyInstance).groupBy(groupingFunction);
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

    /** the query is the source, not a step over one: with no upstream rows to feed it, the function runs on nothing and its result becomes the pipeline */
    global static LazyIterator query(QueryableFunction function) {
        return new LazyIterator(function.queryData(new List<Object>()));
    }

    global static LazyIterator query(String soql) {
        return query(new SoqlQueryFunction(soql));
    }

    global static LazyIterator take(Object anyInstance, Integer limitRecords) {
        return of(anyInstance).take(limitRecords);
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
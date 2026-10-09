@SuppressWarnings('PMD.AvoidGlobalModifier,PMD.CyclomaticComplexity')
global virtual class LazyIterator implements Iterator<Object>, Iterable<Object> {

    public Iterator<Object> iterator;

    public Iterator<Object> iterator() {
        return this.iterator;
    }

    private ContainerCreator containerCreator = new ContainerCreator();
    private LazyIteratorInjector injector = new LazyIteratorInjector();

    /** empty source rather than a null iterator: a pipeline over no rows is still a pipeline, and toList() must hand back an empty list rather than a null pointer */
    global LazyIterator() {
        this.iterator = new List<Object>().iterator();
    }

    global LazyIterator(Iterable<SObject> iterableInstance) {
        this.iterator = (Iterator<Object>) iterableInstance.iterator();
    }

    global LazyIterator(Object anyInstance) {
        Iterable<Object> iterableInstance = (Iterable<Object>) anyInstance;
        this.iterator = iterableInstance.iterator();
    }

    global LazyIterator(Iterator<Object> iterator) {
        this.iterator = iterator;
    }

    global virtual Boolean hasNext() {
        return this.iterator.hasNext();
    }

    global virtual Object next() {
        return this.iterator.next();
    }

    /**
     * A key per element, for the map terminals below. The base stream has none - only a grouped stream, or a
     * custom iterator that overrides this, does. Answering with a placeholder is what made a flat toMap() or
     * toListMap() quietly collapse the whole stream into a single 'key' entry, so it refuses instead.
     */
    global virtual String nextKey() {
        throw new LeoSCollectionException(
            'This stream carries no key per element: toMap(), toListMap() and toDistinctList() need a grouped '
            + 'stream - call groupBy() before them.'
        );
    }

    global virtual List<Object> toList(Type dataType) {

        List<Object> returnVal = this.containerCreator.getList(dataType);

        while(this.hasNext()) {
            returnVal.add(this.next());
        }

        return returnVal;
    }

    global virtual Set<Object> toSet(Type dataType) {

        Set<Object> returnVal = this.containerCreator.getSet(dataType);

        while(this.hasNext()) {
            returnVal.add(this.next());
        }

        return returnVal;
    }

    global virtual Set<Object> toNonNullSet(Type dataType) {

        Set<Object> returnVal = this.toSet(dataType);
        returnVal.remove(null);
        return returnVal;
    }

    global virtual Map<String, Object> toMap(Type dataType) {
        return this.toMap(String.class, dataType);
    }

    global virtual Map<String, Object> toMap(Type keyType, Type dataType) {

        Map<String, Object> returnVal = this.containerCreator.getMap(keyType, dataType);

        while(this.hasNext()) {
            returnVal.put(this.nextKey(), this.next());
        }

        return returnVal;
    }

    global virtual Map<String, List<Object>> toListMap(Type dataType) {
        return this.toListMap(String.class, dataType);
    }

    private virtual Map<String, List<Object>> toListMap(Type keyType, Type dataType) {

        Map<String, List<Object>> returnVal = this.containerCreator.getMapOfLists(keyType, dataType);

        while(this.hasNext()) {
            String key = this.nextKey();
            if(!returnVal.containsKey(key)) {
                returnVal.put(key, this.containerCreator.getList(dataType));
            }

            List<Object> current = (List<Object>) returnVal.get(key);
            current.add(this.next());
        }

        return returnVal;
    }

    /** used with group by to return distinct list of fields using group by function as distinct condition */
    global virtual List<Object> toDistinctList(Type dataType) {
        return this.toMap(dataType).values();
    }

    global virtual Object toValue() {
        Object returnVal;

        while(this.hasNext()) {
            returnVal = this.next();
        }

        return returnVal;
    }

    global virtual Object first() {
        return this.firstOrDefault(null);
    }

    global virtual Object firstOrDefault(Object defaultValue) {

        if(this.hasNext()) {
            return this.next();
        }

        return defaultValue;
    }

    global virtual Integer count() {
        return this.toList(Object.class).size();
    }

    global virtual Boolean every(BooleanFunction matchingFunction) {

        while(this.hasNext()) {
            if(!matchingFunction.isTrueFor(this.next())) {
                return false;
            }
        }

        return true;
    }

    global virtual Boolean some(BooleanFunction matchingFunction) {

        while(this.hasNext()) {
            if(matchingFunction.isTrueFor(this.next())) {
                return true;
            }
        }

        return false;
    }

    global virtual Object find(BooleanFunction matchingFunction) {

        while(this.hasNext()) {
            Object value = this.next();
            if(matchingFunction.isTrueFor(value)) {
                return value;
            }
        }

        return null;
    }

    global virtual void forEach(Function callableFunction) {
        this.tap(callableFunction).execute();
    }

    /** @description method run all lazy iterators, but without returning value, so operation setup in advance must modyfi collection */
    global virtual void execute() {
        while(this.hasNext()) {
            this.next();
        }
    }


    /**
     * @description execute Function on every element adn retrun that element. Function shoudn't modify element that was iterated. Purpose for this function to add possibility to add side effects durring mapping process, like logging.
     */
    global LazyIterator tap(Function callableFunction) {
        return new LazyTapIterator(this, callableFunction);
    }

    global LazyIterator filter(BooleanFunction matchingFunction) {
        return new LazyFilterIterator(this, matchingFunction);
    }

    /** transform every element of iterable into wrapper using wrap factory */
    global LazyIterator wrap(WrapperFunction wrapFunction) {
        return new LazyWrapIterator(this, wrapFunction);
    }

    global LazyIterator transform(MapFunction mappingFunction) {
        return new LazyMapIterator(this, mappingFunction);
    }

    /** @description transform every element using its position in the stream, counted from 0 */
    global LazyIterator transformWithIndex(IndexedMapFunction mappingFunction) {
        return new LazyMapWithIndexIterator(this, mappingFunction);
    }

    global LazyIterator reduce(ReduceFunction reducingFunction) {
        return new LazyReduceIterator(this, reducingFunction);
    }

    /** @description convert List of List to just List */
    global virtual LazyIterator flat() {
        return new LazyFlatIterator(this);
    }

    /**
     * @description transform iterable collection into nested collection using mapping function then flats that nested collection
     * List\<Parent\> => List\<List\<Child\>\> => List\<Child\>
     * @example List\<Account\> => List\<List\<Contact\>\> => List\<Contact\>
     */
    global virtual LazyIterator flatMap(MapFunction mappingFunction) {
        return this.transform(mappingFunction).flat();
    }

    /**
     * @description split the stream into keyed groups. Returns the grouped type rather than LazyIterator,
     * because after this step the stream carries groups, so a following filter filters groups.
     */
    global LazyGroupByIterator groupBy(GroupByFunction groupingFunction) {
        return new LazyGroupByIterator(this, groupingFunction);
    }

    global LazyIterator sortBy(SortByFunction sortingFunction) {
        return new LazySortByIterator(this, sortingFunction);
    }

    /**
     * @description using AnyComparator with declared order
     * (handle any type of object that implements Comparable or can be used in String.valueOf to compare lexically)
     **/
    global LazyIterator sortBy(SortUtil.SORTING_ORDER order) {

        AnyComparator sortFunction = new AnyComparator();

        if(order.equals(SortUtil.SORTING_ORDER.DESCENDING)) {
            sortFunction.setDescending();
        }

        return this.sortBy(sortFunction);
    }

    /**
     * @description using AnyComparator with ascending order
     * (handle any type of object that implements Comparable or can be used in String.valueOf to compare lexically)
     */
    global LazyIterator sortBy() {
        return this.sortBy(SortUtil.SORTING_ORDER.ASCENDING);
    }

    global LazyIterator pipe(List<Object> functions) {
        return this.injector.injectFunctions(this, functions);
    }

    global LazyIterator take(Integer limitRecords) {
        return new LazyLimitIterator(this, new LimitToFunction(limitRecords));
    }

    /** @description Method executes query to retrive somet data, where data from previous processing steps are evaluated and pass as param to be queried. As a return it will be Lazy Iterator of queried data, for further processing.
     */
    global LazyIterator query(QueryableFunction function) {
        return new LazyIterator(function.queryData(this.toList(Object.class)));
    }

    /** @description The string form of query(QueryableFunction), for a one-off query where a class would be ceremony. It wraps the SOQL in a SoqlQueryFunction, so it runs through the same path as a named one.
     */
    global LazyIterator query(String soql) {
        return this.query(new SoqlQueryFunction(soql));
    }

    /** @description Method executes update dml that will interact with database. As a param it will get evaluated data from previous processing steps. As a return should provide data that were updated.
     */
    global Object dmlUpdate(DmlUpdateFunction function) {
        return function.dmlUpdate((List<SObject>)this.toList(SObject.class));
    }
}
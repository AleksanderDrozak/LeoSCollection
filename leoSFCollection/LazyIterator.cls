@SuppressWarnings('PMD.AvoidGlobalModifier,PMD.CyclomaticComplexity')
global virtual class LazyIterator implements Iterator<Object> {

    public Iterator<Object> iterator;

    private ContainerCreator containerCreator = new ContainerCreator();
    private LazyIteratorInjector injector = new LazyIteratorInjector();

    private LazyIterator currentInstance {
        get {

            if(this.currentInstance == null) {
                this.currentInstance = instance();
            }

            return this.currentInstance;
        }
        private set;
    }

    global LazyIterator() {
        this.iterator = null;
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

    protected virtual LazyIterator instance() {
        return this;
    }

    global virtual Boolean hasNext() {
        return this.iterator.hasNext();
    }

    global virtual Object next() {
        return this.iterator.next();
    }

    global virtual String nextKey() {
        return 'key';
    }

    global virtual List<Object> toList(Type dataType) {

        List<Object> returnVal = this.containerCreator.getList(dataType);

        while(this.currentInstance.hasNext()) {
            returnVal.add(this.currentInstance.next());
        }

        return returnVal;
    }

    global virtual Set<Object> toSet(Type dataType) {

        Set<Object> returnVal = this.containerCreator.getSet(dataType);

        while(this.currentInstance.hasNext()) {
            returnVal.add(this.currentInstance.next());
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

        while(this.currentInstance.hasNext()) {
            returnVal.put(this.currentInstance.nextKey(), this.currentInstance.next());
        }

        return returnVal;
    }

    global virtual Map<String, List<Object>> toListMap(Type dataType) {
        return this.toListMap(String.class, dataType);
    }

    private virtual Map<String, List<Object>> toListMap(Type keyType, Type dataType) {

        Map<String, List<Object>> returnVal = this.containerCreator.getMapOfLists(keyType, dataType);

        while(this.currentInstance.hasNext()) {
            String key = this.currentInstance.nextKey();
            if(!returnVal.containsKey(key)) {
                returnVal.put(key, this.containerCreator.getList(dataType));
            }

            List<Object> current = (List<Object>) returnVal.get(key);
            current.add(this.currentInstance.next());
        }

        return returnVal;
    }

    /** used with group by to return distinct list of fields using group by function as distinct condition */
    global virtual List<Object> toDistinctList(Type dataType) {
        return this.toMap(dataType).values();
    }

    global virtual Object toValue() {
        Object returnVal;

        while(this.currentInstance.hasNext()) {
            returnVal = this.currentInstance.next();
        }

        return returnVal;
    }

    global virtual Object first() {
        return this.toValue();
    }

    global virtual Object firstOrDefault(Object defaultValue) {

        if(this.currentInstance.hasNext()) {
            return this.currentInstance.next();
        }

        return defaultValue;
    }

    global virtual Integer count() {
        return this.currentInstance.toList(Object.class).size();
    }

    global virtual Boolean every(BooleanFunction matchingFunction) {

        while(this.currentInstance.hasNext()) {
            if(!matchingFunction.isTrueFor(this.currentInstance.next())) {
                return false;
            }
        }

        return true;
    }

    global virtual Boolean some(BooleanFunction matchingFunction) {

        while(this.currentInstance.hasNext()) {
            if(matchingFunction.isTrueFor(this.currentInstance.next())) {
                return true;
            }
        }

        return false;
    }

    global virtual Object find(BooleanFunction matchingFunction) {

        while(this.currentInstance.hasNext()) {
            Object value = this.currentInstance.next();
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
        while(this.currentInstance.hasNext()) {
            this.currentInstance.next();
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

    global LazyIterator groupBy(GroupByFunction grouppingFunction) {
        return new LazyGroupByIterator(this, grouppingFunction);
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

    /**
     * @descrition Apply data to current instance of iterator, so any operation can be done on that set of data, so already setup Lazy Iterator can be reused.
     * @explanation General purpose of this method is to find first lazy iterator and replace its iterator field with current data iterator, so when one of method that evealuates lazy iterator will run, be executed on data passed as argument to apply instead of initialy applied data durring creation of first Lazy Iterator. Is not recommended to use on any Lazy Iterator that had initially passed data to iterate, because it might affect that.
     */
    global LazyIterator apply(Object data) {
        return this.injector.injectData(instance(), data);
    }

    global LazyIterator pipe(List<Object> functions) {
        return this.injector.injectFunctions(instance(), functions);
    }

    global LazyIterator take(Integer limitRecords) {
        return new LazyLimitIterator(this, new LimitToFunction(limitRecords));
    }

    /** @description Method executes query to retrive somet data, where data from previous processing steps are evaluated and pass as param to be queried. As a return it will be Lazy Iterator of queried data, for further processing.
     */
    global LazyIterator query(QueryableFunction function) {
        return new LazyIterator(function.queryData(this.toList(Object.class)));
    }

    /** @description Method executes update dml that will interact with database. As a param it will get evaluated data from previous processing steps. As a return should provide data that were updated.
     */
    global Object dmlUpdate(DmlUpdateFunction function) {
        return function.dmlUpdate((List<SObject>)this.toList(SObject.class));
    }
}
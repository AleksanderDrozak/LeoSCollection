@SuppressWarnings('PMD.AvoidGlobalModifier')
global class LazyMapIterator extends LazyIterator {

    private MapFunction mappingFunction;

    public LazyMapIterator(Iterator<Object> iterator, MapFunction mappingFunction) {
        super(iterator);
        this.mappingFunction = mappingFunction;
    }

    public override Object next() {
        return mappingFunction.mapValue(iterator.next());
    }
}

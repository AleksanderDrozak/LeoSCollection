@SuppressWarnings('PMD.AvoidGlobalModifier')
global class LazyMapWithIndexIterator extends LazyIterator {

    private IndexedMapFunction mappingFunction;
    private Integer index = 0;

    public LazyMapWithIndexIterator(Iterator<Object> iterator, IndexedMapFunction mappingFunction) {
        super(iterator);
        this.mappingFunction = mappingFunction;
    }

    /** the counter lives here, not in the mapping function, so the function itself stays stateless */
    public override Object next() {
        Object current = this.iterator.next();
        Object mapped = this.mappingFunction.mapValue(current, this.index);
        this.index++;
        return mapped;
    }
}

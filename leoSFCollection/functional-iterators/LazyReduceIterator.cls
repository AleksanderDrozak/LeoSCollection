@SuppressWarnings('PMD.AvoidGlobalModifier')
global class LazyReduceIterator extends LazyIterator {

    private ReduceFunction reducingFunction;
    private Object previousValue;

    public LazyReduceIterator(Iterator<Object> iterator, ReduceFunction reducingFunction) {
        super(iterator);
        this.previousValue = reducingFunction.getInitialValue();
        this.reducingFunction = reducingFunction;
    }

    public override Object next() {
        this.previousValue = (Object) this.reducingFunction.reduceValue(this.previousValue, this.iterator.next());
        return this.previousValue;
    }
}

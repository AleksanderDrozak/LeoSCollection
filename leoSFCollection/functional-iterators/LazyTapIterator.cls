@SuppressWarnings('PMD.AvoidGlobalModifier')
global class LazyTapIterator extends LazyIterator {

    private Function callableFunction;

    public LazyTapIterator(Iterator<Object> iterator, Function callableFunction) {
        super(iterator);
        this.callableFunction = callableFunction;
    }

    global override Object next() {
        Object data = this.iterator.next();
        this.callableFunction.call(data);
        return data;
    }
}
@SuppressWarnings('PMD.AvoidGlobalModifier')
global class LazyFilterIterator extends LazyIterator {

    private BooleanFunction matchingFunction;
    private Object peek;

    public LazyFilterIterator(Iterator<Object> iterator, BooleanFunction matchingFunction) {
        super(iterator);
        this.matchingFunction = matchingFunction;
    }

    public override Boolean hasNext() {

        if(!this.iterator.hasNext()) {
            return false;
        }

        this.peek = this.iterator.next();

        if(this.matchingFunction.isTrueFor(this.peek)){
            return true;
        }

        return this.hasNext();
    }

    public override Object next() {
        return this.peek;
    }
}
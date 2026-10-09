@SuppressWarnings('PMD.AvoidGlobalModifier')
global class LazyFilterIterator extends LazyIterator {

    private BooleanFunction matchingFunction;
    private Object peek;
    private Boolean hasPeek = false;
    private Boolean peekMatches = false;

    public LazyFilterIterator(Iterator<Object> iterator, BooleanFunction matchingFunction) {
        super(iterator);
        this.matchingFunction = matchingFunction;
    }

    /** Idempotent: repeated calls without next() neither consume nor lose elements. */
    global override Boolean hasNext() {

        if(!this.hasPeek) {
            this.peekMatches = this.advanceToNextMatch();
            this.hasPeek = true;
        }

        return this.peekMatches;
    }

    private Boolean advanceToNextMatch() {

        while(this.iterator.hasNext()) {
            Object candidate = this.iterator.next();

            if(this.matchingFunction.isTrueFor(candidate)) {
                this.peek = candidate;
                return true;
            }
        }

        return false;
    }

    global override Object next() {

        if(!this.hasPeek) {
            this.hasNext();
        }

        this.hasPeek = false;

        return this.peek;
    }
}

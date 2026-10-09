@SuppressWarnings('PMD.AvoidGlobalModifier')
global class LazyFlatIterator extends LazyIterator {

    private Iterator<Object> innerIterator;
    private Object innerPeek;
    private Boolean hasInnerPeek = false;

    public LazyFlatIterator(Iterator<Object> iterator) {
        super(iterator);
    }

    /** Idempotent: repeated calls without next() neither consume nor lose elements. */
    global override Boolean hasNext() {

        if(this.hasInnerPeek) {
            return true;
        }

        while(true) {

            if(this.innerIterator != null && this.innerIterator.hasNext()) {
                this.innerPeek = this.innerIterator.next();
                this.hasInnerPeek = true;
                return true;
            }

            if(!this.iterator.hasNext()) {
                return false;
            }

            Object iterable = this.iterator.next();
            this.innerIterator = iterable != null ? ((Iterable<Object>) iterable).iterator() : null;
        }
    }

    global override Object next() {

        if(!this.hasInnerPeek) {
            this.hasNext();
        }

        this.hasInnerPeek = false;

        return this.innerPeek;
    }
}

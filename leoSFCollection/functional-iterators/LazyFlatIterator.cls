@SuppressWarnings('PMD.AvoidGlobalModifier')
global class LazyFlatIterator extends LazyIterator {

    private Iterator<Object> innerIterator;

    public LazyFlatIterator(Iterator<Object> iterator) {
        super(iterator);
    }

    global override Boolean hasNext() {

        if(this.innerIterator == null && this.iterator.hasNext()) {
            Object iterable = this.iterator.next();
            this.innerIterator = iterable != null ? ((Iterable<Object>) iterable).iterator() : null;
        }

        if(this.innerIterator == null) {
            return false;
        }

        if(this.innerIterator.hasNext()) {
            return true;
        }

        this.innerIterator = null;

        return this.hasNext();
    }

    global override Object next() {
        return this.innerIterator.next();
    }
}
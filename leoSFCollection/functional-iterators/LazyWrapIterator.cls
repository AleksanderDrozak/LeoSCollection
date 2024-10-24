@SuppressWarnings('PMD.AvoidGlobalModifier')
global class LazyWrapIterator extends LazyIterator {

    private WrapperFunction wrapper;

    public LazyWrapIterator(Iterator<Object> iterator, WrapperFunction wrapper) {
        super(iterator);
        this.wrapper = wrapper;
    }

    global override Object next() {
        return this.wrapper.wrap(this.iterator.next());
    }
}
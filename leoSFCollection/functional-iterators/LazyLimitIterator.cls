public class LazyLimitIterator extends LazyIterator {

    private LimitFunction limitFunction;
    private Integer currentIndex;

    public LazyLimitIterator(Iterator<Object> iterator, LimitFunction limitFunction) {
        super(iterator);
        this.limitFunction = limitFunction;
        this.currentIndex = 0;
    }

    /** Idempotent: the counter advances in next(), never in hasNext(). */
    public override Boolean hasNext() {

        if(this.limitFunction.shouldStop(this.currentIndex)) {
            return false;
        }

        return super.hasNext();
    }

    public override Object next() {
        this.currentIndex++;
        return super.next();
    }
}

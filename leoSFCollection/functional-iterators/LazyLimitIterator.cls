public class LazyLimitIterator extends LazyIterator {

    private LimitFunction limitFunction;
    private Integer currentIndex;

    public LazyLimitIterator(Iterator<Object> iterator, LimitFunction limitFunction) {
        super(iterator);
        this.limitFunction = limitFunction;
        this.currentIndex = 0;
    }

    public override Boolean hasNext() {
        if(this.limitFunction.shouldStop(this.currentIndex++)) {
            return false;
        }

        return super.hasNext();
    }
}
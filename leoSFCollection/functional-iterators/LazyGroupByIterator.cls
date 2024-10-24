public class LazyGroupByIterator extends LazyIterator {

    private GroupByFunction grouppingFunction;
    private Object current;

    public LazyGroupByIterator(Iterator<Object> iterator, GroupByFunction grouppingFunction) {
        super(iterator);
        this.grouppingFunction = grouppingFunction;
    }

    public override String nextKey() {
        this.current = super.next();
        return this.grouppingFunction.getGroupKey(this.current);
    }

    public override Object next() {
        return this.current;
    }
}

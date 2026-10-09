@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class IteratorToReduceFunction extends IteratorToFunction {

    private ReduceFunction reducingFunction;

    /** rolls a child list into a single value, so ReduceFieldFunction becomes reachable from PickListApplyFunction */
    global IteratorToReduceFunction(ReduceFunction reducingFunction) {
        this.reducingFunction = reducingFunction;
    }

    global override Object mapValue(LazyIterator iterator) {
        return iterator.reduce(this.reducingFunction).toValue();
    }
}

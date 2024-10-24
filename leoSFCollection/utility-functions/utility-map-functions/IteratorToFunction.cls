@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing abstract class IteratorToFunction implements MapFunction {

    global Object mapValue(Object obj) {
        return this.mapValue((LazyIterator) obj);
    }

    global abstract Object mapValue(LazyIterator obj);
}
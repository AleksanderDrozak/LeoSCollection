@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class IteratorToCountFunction extends IteratorToFunction {

    global override Object mapValue(LazyIterator iterator) {
        return iterator.count();
    }
}

@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class IteratorToValueFunction extends IteratorToFunction {

    global override Object mapValue(LazyIterator iterator) {
        return iterator.toValue();
    }
}
@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class IteratorToIsEmpty extends IteratorToFunction {

    global override Object mapValue(LazyIterator iterator) {
        return !iterator.hasNext();
    }
}

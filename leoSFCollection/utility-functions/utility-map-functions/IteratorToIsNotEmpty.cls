@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class IteratorToIsNotEmpty extends IteratorToFunction {

    global override Object mapValue(LazyIterator iterator) {
        return iterator.hasNext();
    }
}

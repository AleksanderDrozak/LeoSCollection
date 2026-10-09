@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class AnyComparator extends ComparatorBase {

    /**
     * The comparison strategy is picked per pair, not cached from the first record:
     * caching broke on mixed types and on a leading null value.
     */
    global override Integer compare(Object compareFrom, Object compareTo) {
        return this.compare(ComparationUtil.compare(compareFrom, compareTo));
    }
}

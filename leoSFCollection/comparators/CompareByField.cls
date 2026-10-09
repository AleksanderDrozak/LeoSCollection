@SuppressWarnings('PMD.AvoidGlobalModifier')
global virtual inherited sharing class CompareByField extends ComparatorBase {

    private String sortByFieldName;

    /**
     * The comparison strategy on its own - SObjects by one field - with no claim to being a pipeline
     * step. SortByFieldFunction extends this and adds nothing but that name: a caller reaching for a
     * comparator should find one, and a caller wiring a pipeline should find a step, without either name
     * having to cover both. Virtual so that second name can exist at all.
     *
     * No field type is taken: the value read off the record is compared through ComparationUtil, which
     * uses the platform's natural order when the value is Comparable and only falls back to stringifying
     * when it is not. Declaring the type bought a slightly faster comparison path at the cost of a class
     * per type, a cast that could disagree with the runtime type, and a comparison that never reported
     * equality - not worth it, for a step that is one small part of the sort.
     */
    global CompareByField(SObjectField sortByField) {
        this.sortByFieldName = sortByField.toString();
    }

    /** by API name, so the same comparison sorts an AggregateResult alias as well as a record field */
    global CompareByField(String sortByFieldName) {
        this.sortByFieldName = sortByFieldName;
    }

    global override Integer compare(Object compareFrom, Object compareTo) {
        SObject left = (SObject) compareFrom;
        SObject right = (SObject) compareTo;
        return this.compare(ComparationUtil.compare(left.get(this.sortByFieldName), right.get(this.sortByFieldName)));
    }
}
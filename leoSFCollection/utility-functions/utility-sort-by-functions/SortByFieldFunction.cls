@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class SortByFieldFunction extends CompareByField {

    /**
     * The pipeline step, and nothing more: the comparison is entirely CompareByField's. Two names for one
     * behaviour on purpose, so a pipeline reads as a pipeline and a comparator reads as a comparator -
     * named after the field it reads, like FilterByFieldFunction and GroupByFieldFunction beside it.
     */
    global SortByFieldFunction(SObjectField sortByField) {
        super(sortByField);
    }

    /** by API name, so an AggregateResult alias can be sorted the same way a record field is */
    global SortByFieldFunction(String sortByFieldName) {
        super(sortByFieldName);
    }
}
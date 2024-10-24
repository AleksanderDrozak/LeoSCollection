@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class SobjectByFieldComparator extends ComparatorBase {

    private SObjectField sortByField;
    private SortByFunction compareFunction;
    
    global SobjectByFieldComparator(SObjectField sortByField, Type fieldType) {
        this.sortByField = sortByField;
        Boolean hasComparator = ComparatorsConstants.COMPARABLE_TYPE_MAPPING.containsKey(fieldType);
        /** if quick comparator not exists for field type use AnyComparator which is slower about 20% in avarage */
        this.compareFunction = hasComparator ? ComparatorsConstants.COMPARABLE_TYPE_MAPPING.get(fieldType) : new AnyComparator();
    }

    global override Integer compare(Object compareFrom, Object compareTo) {
        return this.compare((SObject) compareFrom, (SObject) compareTo);
    }
    
    global override SortByFunction setOrder(SortUtil.SORTING_ORDER sortingOrder) { 
        super.setOrder(sortingOrder);
        this.compareFunction.setOrder(sortingOrder);
        return this;
    }

    global Integer compare(SObject compareFrom, SObject compareTo) {
        return this.compareFunction.compare(compareFrom.get(this.sortByField), compareTo.get(this.sortByField));
    }
}
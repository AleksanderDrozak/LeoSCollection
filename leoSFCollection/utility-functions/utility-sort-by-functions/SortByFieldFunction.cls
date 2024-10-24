@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class SortByFieldFunction extends ComparatorBase {

    private SobjectByFieldComparator compareFunction;
    
    global SortByFieldFunction(SObjectField sortByField, Type compareType) {
        this.compareFunction = new SobjectByFieldComparator(sortByField, compareType);
    }

    global SortByFieldFunction(SObjectField sortByField) {
        Type compareType = Type.forName(String.valueOf(sortByField.getDescribe().getSoapType()));
        this.compareFunction = new SobjectByFieldComparator(sortByField, compareType);
    }

    global SortByFieldFunction(SobjectByFieldComparator compareFunction) {
        this.compareFunction = compareFunction;
    }

    global override SortByFunction setOrder(SortUtil.SORTING_ORDER sortingOrder) { 
        super.setOrder(sortingOrder);
        this.compareFunction.setOrder(sortingOrder);
        return this;
    }

    global override Integer compare(Object compareFrom, Object compareTo) {
        // TODO implement when equal and more robust sort by two conditions
        return this.compareFunction.compare(compareFrom, compareTo);
    }
}
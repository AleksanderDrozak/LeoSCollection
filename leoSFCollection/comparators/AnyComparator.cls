@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class AnyComparator extends ComparatorBase {

    ComparatorBase comparator;
    
    private void setComparator(Object compareFrom){
        Boolean isByInstance = ComparationUtil.BY_INSTANCE_COMPARATOR.isCompareByInstance(compareFrom);
        this.comparator = isByInstance ? (ComparatorBase) ComparationUtil.BY_INSTANCE_COMPARATOR :  (ComparatorBase) ComparationUtil.BY_STRINGIFY_COMPARATOR;
        this.comparator.setOrder(this.sortingOrder);
    }

    global override Integer compare(Object compareFrom, Object compareTo) {
        
        if(this.comparator == null) {
            this.setComparator(compareFrom);
        }

        /** base class handle order, so to handle it correctly it requires wrap compare */
        return this.comparator.compare(this.comparator.compare(compareFrom, compareTo));
    }
}
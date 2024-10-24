@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class DateComparator extends ComparatorBase {

    global override Integer compare(Object compareFrom, Object compareTo) {
        return this.compare((DateTime) compareFrom, (DateTime) compareTo);
    }

    global Integer compare(DateTime compareFrom, DateTime compareTo) {
        return this.compare(compareFrom > compareTo);
    }
}

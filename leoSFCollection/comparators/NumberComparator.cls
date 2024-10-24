@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class NumberComparator extends ComparatorBase {

    global override Integer compare(Object compareFrom, Object compareTo) {
        return this.compare((Double) compareFrom, (Double) compareTo);
    }

    global Integer compare(Double compareFrom, Double compareTo) {
        return this.compare(compareFrom > compareTo);
    }
}

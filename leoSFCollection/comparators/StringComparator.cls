@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class StringComparator extends ComparatorBase {

    global override Integer compare(Object compareFrom, Object compareTo) {
        return this.compare((String) compareFrom, (String) compareTo);
    }

    global Integer compare(String compareFrom, String compareTo) {
        return this.compare(compareFrom > compareTo);
    }
}

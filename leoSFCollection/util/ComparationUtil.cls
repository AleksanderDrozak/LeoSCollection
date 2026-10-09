@SuppressWarnings('PMD.AvoidGlobalModifier')
global abstract class ComparationUtil {
    
    global static final CompareByInstance BY_INSTANCE_COMPARATOR = new CompareByInstance();
    global static final CompareByStringify BY_STRINGIFY_COMPARATOR = new CompareByStringify();

    global enum Comparators {
        EQUALS,
        NOT_EQUALS,
        GREATER_THAN,
        GREATER_OR_EQUALS,
        LESS_THAN,
        LESS_OR_EQUALS,
        INCLUDES,
        NOT_INCLUDES
    }

    global class ComparationException extends LeoSCollectionException {}

    global class CompareByInstance extends ComparatorBase {
        
        public Boolean isCompareByInstance(Object compareFrom) {
            return compareFrom instanceof Comparable;
        }

        /** Orderless natural distance: compareFrom against compareTo. Ordering is applied by the caller. */
        public override Integer compare(Object compareFrom, Object compareTo) {
            return ((Comparable) compareFrom).compareTo(compareTo);
        }
     }
    
     global class CompareByStringify extends ComparatorBase {
        
        global override Integer compare(Object compareFrom, Object compareTo) {
            return String.valueOf(compareFrom).compareTo(String.valueOf(compareTo));
        }
     }

    /** Natural order, so a positive result means compareFrom is greater than compareTo. Nulls sort first. */
    global static Integer compare(Object compareFrom, Object compareTo) {

        if(compareFrom == null && compareTo == null) {
            return 0;
        }

        if(compareFrom == null) {
            return -1;
        }

        if(compareTo == null) {
            return 1;
        }

        if(BY_INSTANCE_COMPARATOR.isCompareByInstance(compareFrom)) {
            return BY_INSTANCE_COMPARATOR.compare(compareFrom, compareTo);
        }

        return BY_STRINGIFY_COMPARATOR.compare(compareFrom, compareTo);
    }

    global static Boolean compare(Object compareFrom, Comparators comparator, Object compareTo) {

        if(comparator.equals(Comparators.INCLUDES)){
            return includes(compareFrom, compareTo);
        }

        if(comparator.equals(Comparators.NOT_INCLUDES)){
            return !includes(compareFrom, compareTo);
        }

        return isValidCompare(compare(compareFrom, compareTo), comparator);
    }

    private static Boolean includes(Object compareFrom, Object compareTo){
        return String.valueOf(compareFrom).contains(String.valueOf(compareTo));
    }

    global static Boolean isValidCompare(Integer comparationDistance, Comparators comparator) {
        
        switch on comparator {
            when EQUALS {
				return comparationDistance == 0;
			}
			when NOT_EQUALS {
				return comparationDistance != 0;
			}
			when LESS_THAN {
				return comparationDistance < 0;
			}
			when LESS_OR_EQUALS {
				return comparationDistance <= 0;
			}
			when GREATER_THAN {
				return comparationDistance > 0;
			}
			when GREATER_OR_EQUALS {
				return comparationDistance >= 0;
			}
            when else {
                throw new ComparationException('Unhandled comparator ' + String.valueOf(comparator));
            }
        }
    }
}

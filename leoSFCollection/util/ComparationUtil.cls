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

    global class ComparationException extends Exception {}

    global class CompareByInstance extends ComparatorBase {
        
        public Boolean isCompareByInstance(Object compareFrom) {
            return compareFrom instanceof Comparable;
        }

        public override Integer compare(Object compareFrom, Object compareTo) {
            /** wrap compareTo in compare base function to  */
            return this.compare(((Comparable) compareTo).compareTo(compareFrom));
        }
     }
    
     global class CompareByStringify extends ComparatorBase {
        
        global override Integer compare(Object compareFrom, Object compareTo) {
            return String.valueOf(compareFrom).compareTo(String.valueOf(compareTo));
        }
     }

    global static Integer compare(Object compareFrom, Object compareTo) {
        
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

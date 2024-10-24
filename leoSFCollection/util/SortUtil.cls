@SuppressWarnings('PMD.AvoidGlobalModifier')
global abstract class SortUtil {
    
    global enum SORTING_ORDER {
        ASCENDING,
        DESCENDING
    }

    global static final Integer ASCENDING_RETURN_TRUE_VALUE = 1;
    global static final Integer DESCENDING_RETURN_TRUE_VALUE = -1;

    global static final Map<SORTING_ORDER, Integer> SORTING_ORDER_TRUE_VALUE_MAP = new Map<SORTING_ORDER, Integer> {
        SORTING_ORDER.ASCENDING => ASCENDING_RETURN_TRUE_VALUE,
        SORTING_ORDER.DESCENDING => DESCENDING_RETURN_TRUE_VALUE
    };
}

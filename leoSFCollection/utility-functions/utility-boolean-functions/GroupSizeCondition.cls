@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class GroupSizeCondition implements BooleanFunction {

    private ComparationUtil.Comparators comparator;
    private Object compareTo;

    /**
     * The group's size goes through the same comparator enum FilterByCondition uses, so a rule is stated
     * rather than a class written per threshold - "bigger than one" is one of these calls, not its own
     * concept. It reads the group groupBy hands to filterGroup(), and says so by taking the group.
     */
    global GroupSizeCondition(ComparationUtil.Comparators comparator, Object compareTo) {
        this.comparator = comparator;
        this.compareTo = compareTo;
    }

    global Boolean isTrueFor(Object keyedGroup) {
        return ComparationUtil.compare(((LazyGroupByIterator.KeyedGroup) keyedGroup).size(), this.comparator, this.compareTo);
    }
}
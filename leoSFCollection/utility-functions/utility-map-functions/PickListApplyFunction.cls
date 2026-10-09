@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing virtual class PickListApplyFunction extends PickListByFieldFunction {

    List<Object> functions;
    IteratorToFunction transformToValueFunction;

    public PickListApplyFunction(SObjectField pickListObject, List<Object> functions, IteratorToFunction transformToValueFunction) {
        super(pickListObject);
        this.functions = functions;
        this.transformToValueFunction = transformToValueFunction;
    }

    public PickListApplyFunction(SObjectField pickListObject, List<Object> functions) {
        this(pickListObject, functions, new IteratorToValueFunction());
    }

    public PickListApplyFunction(SObjectField pickListObject, IteratorToFunction transformToValueFunction) {
        this(pickListObject, new List<Object>(), transformToValueFunction);
    }

    global override Object mapValue(SObject obj) {

        /** an unpopulated relationship returns null, which must behave like an empty child list */
        List<SObject> childRecords = (List<SObject>) super.mapValue(obj) ?? new List<SObject>();

        return this.transformToValueFunction.mapValue(
            new LazyIterator(childRecords).pipe(this.functions)
        );
    }
}
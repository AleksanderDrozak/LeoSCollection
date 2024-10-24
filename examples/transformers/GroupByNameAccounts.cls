@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class GroupByNameAccounts {

    public static LazyIterator getInstance(Iterable<SObject> iterableInstance) {
        return new LazyIterator(iterableInstance).groupBy(new GroupByNameFunction());
    }

    global inherited sharing class GroupByNameFunction implements GroupByFunction {
        global String getGroupKey(Object acc){
            return getGroupKey((Account) acc);
        }
    
        global String getGroupKey(Account acc){
            return acc.Name;
        }
    }
    
}

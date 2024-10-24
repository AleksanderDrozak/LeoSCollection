@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class SumNumberOnAccounts {
    
    public static LazyIterator getInstance(Iterable<SObject> iterableInstance){
        return new LazyIterator(iterableInstance).reduce(new SumNumberOfEmployees()) ; 
    }

    global inherited sharing class SumNumberOfEmployees implements ReduceFunction {

        global Object getInitialValue() {
            return 0;
        }

        global Object reduceValue(Object currentSum, Object acc){
            return reduceValue((Integer) currentSum, (Account) acc);
        }
    
        global Integer reduceValue(Integer currentSum, Account acc){
            return currentSum + acc.NumberOfEmployees;
        }
    }
    
}
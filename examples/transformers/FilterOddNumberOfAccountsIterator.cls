@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class FilterOddNumberOfAccountsIterator {
    
    public static LazyIterator getInstance(Iterable<SObject> iterableInstance){
        return new LazyIterator(iterableInstance).filter(new NumberOfEmployeesIsOdd()) ; 
    }

    global inherited sharing class NumberOfEmployeesIsOdd implements BooleanFunction  {
        global Boolean isTrueFor(Object acc){
            return isTrueFor((Account) acc);
        }
    
        global Boolean isTrueFor(Account acc){
            return math.mod(acc.NumberOfEmployees,2) > 0;
        }
    }
    
}

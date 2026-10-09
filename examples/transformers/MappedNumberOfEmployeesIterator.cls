@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class MappedNumberOfEmployeesIterator {

    public static LazyIterator getInstance(Iterable<SObject> iterableInstance) {
        return new LazyIterator(iterableInstance).transform(new NumberOfEmployeesValue());
    }

    global inherited sharing class NumberOfEmployeesValue implements MapFunction {
        global Object mapValue(Object acc){
            return mapValue((Account) acc);
        }
    
        global Integer mapValue(Account acc){
            return acc.NumberOfEmployees;
        }
    }
    
}

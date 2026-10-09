@isTest
private class BooleanFunctionTest {

    private static List<Account> accounts() {
        return new List<Account> {
            new Account(Name = 'Alpha', NumberOfEmployees = 1),
            new Account(Name = 'Beta', NumberOfEmployees = 2),
            new Account(Name = 'Gamma', NumberOfEmployees = 3),
            new Account(Name = 'Delta', NumberOfEmployees = 4)
        };
    }

    private class EmployeesAreOdd implements BooleanFunction {
        public Boolean isTrueFor(Object record) {
            return Math.mod((Integer) ((SObject) record).get(Account.NumberOfEmployees), 2) == 1;
        }
    }

    @isTest
    static void filterByConditionSupportsComparators() {
        List<Account> records = accounts();

        System.assertEquals(1, Collection.filter(records, new FilterByCondition(Account.NumberOfEmployees, ComparationUtil.Comparators.EQUALS, 3)).toList(Account.class).size());
        System.assertEquals(3, Collection.filter(records, new FilterByCondition(Account.NumberOfEmployees, ComparationUtil.Comparators.NOT_EQUALS, 3)).toList(Account.class).size());
        System.assertEquals(2, Collection.filter(records, new FilterByCondition(Account.NumberOfEmployees, ComparationUtil.Comparators.GREATER_THAN, 2)).toList(Account.class).size());
        System.assertEquals(2, Collection.filter(records, new FilterByCondition(Account.NumberOfEmployees, ComparationUtil.Comparators.LESS_THAN, 3)).toList(Account.class).size());
    }

    @isTest
    static void filterByConditionHandlesNullFieldValues() {
        List<Account> records = new List<Account> {
            new Account(Name = 'NoEmployees'),
            new Account(Name = 'WithEmployees', NumberOfEmployees = 5)
        };

        System.assertEquals(1, Collection.filter(records, new FilterByCondition(Account.NumberOfEmployees, ComparationUtil.Comparators.NOT_EQUALS, 5)).toList(Account.class).size());
    }

    @isTest
    static void andOrNotCompose() {
        List<Account> records = accounts();

        BooleanFunction isOdd = new EmployeesAreOdd();
        BooleanFunction isThree = new FilterByCondition(Account.NumberOfEmployees, ComparationUtil.Comparators.EQUALS, 3);
        BooleanFunction isNotOne = new FilterByCondition(Account.NumberOfEmployees, ComparationUtil.Comparators.NOT_EQUALS, 1);

        System.assertEquals(1, Collection.filter(records, new AndFunction(isOdd, new NotFunction(isThree))).toList(Account.class).size());
        System.assertEquals(4, Collection.filter(records, new OrFunction(isOdd, isNotOne)).toList(Account.class).size());
        System.assertEquals(3, Collection.filter(records, new NotFunction(isOdd)).toList(Account.class).size());
    }

    @isTest
    static void filterByFieldFunctionCombinesWithAnd() {
        BooleanFunction filter = new FilterByFieldFunction()
            .addFilterBy(Account.NumberOfEmployees, ComparationUtil.Comparators.NOT_EQUALS, 1)
            .addFilterBy(Account.NumberOfEmployees, ComparationUtil.Comparators.LESS_THAN, 4)
            .evaluate();

        System.assertEquals(2, Collection.filter(accounts(), filter).toList(Account.class).size());
    }

    @isTest
    static void filterByFieldFunctionAcceptsPrebuiltConditions() {
        BooleanFunction filter = new FilterByFieldFunction()
            .addFilterBy(new FilterByCondition(Account.Name, ComparationUtil.Comparators.EQUALS, 'Alpha'))
            .evaluate();

        System.assertEquals(1, Collection.filter(accounts(), filter).toList(Account.class).size());
    }

    @isTest
    static void filterByFieldFunctionRejectsEmptyConditionList() {
        try {
            new FilterByFieldFunction().evaluate();
            System.assert(false, 'Expected FilterByFieldFunctionException');
        } catch(FilterByFieldFunction.FilterByFieldFunctionException expected) {
            System.assert(true);
        }
    }
}

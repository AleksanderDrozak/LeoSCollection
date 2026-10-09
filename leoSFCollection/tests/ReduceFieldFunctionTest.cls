@isTest
private class ReduceFieldFunctionTest {

    private static List<Account> accounts() {
        return new List<Account> {
            new Account(Name = 'A', NumberOfEmployees = 1),
            new Account(Name = 'B', NumberOfEmployees = 2),
            new Account(Name = 'C', NumberOfEmployees = 3),
            new Account(Name = 'D', NumberOfEmployees = 4)
        };
    }

    private static Decimal reduceWith(List<Account> records, ReduceFieldFunction reducingFunction) {
        return (Decimal) Collection.of(records).reduce(reducingFunction).toValue();
    }

    @isTest
    static void everyAggregationOverFullSet() {
        List<Account> records = accounts();

        System.assertEquals(10, reduceWith(records, ReduceFieldFunction.sum(Account.NumberOfEmployees)).intValue());
        System.assertEquals(1, reduceWith(records, ReduceFieldFunction.min(Account.NumberOfEmployees)).intValue());
        System.assertEquals(4, reduceWith(records, ReduceFieldFunction.max(Account.NumberOfEmployees)).intValue());
        System.assertEquals(0, reduceWith(records, ReduceFieldFunction.average(Account.NumberOfEmployees)).compareTo(Decimal.valueOf('2.5')));
    }

    @isTest
    static void nullFieldValuesCountAsZeroForSum() {
        List<Account> records = new List<Account> {
            new Account(Name = 'A', NumberOfEmployees = 2),
            new Account(Name = 'B')
        };

        System.assertEquals(2, reduceWith(records, ReduceFieldFunction.sum(Account.NumberOfEmployees)).intValue());
    }

    @isTest
    static void nullFieldValuesAreSkippedForMinAndMax() {
        List<Account> records = new List<Account> {
            new Account(Name = 'A', NumberOfEmployees = 7),
            new Account(Name = 'B'),
            new Account(Name = 'C', NumberOfEmployees = 3)
        };

        System.assertEquals(3, reduceWith(records, ReduceFieldFunction.min(Account.NumberOfEmployees)).intValue());
        System.assertEquals(7, reduceWith(records, ReduceFieldFunction.max(Account.NumberOfEmployees)).intValue());
    }

    @isTest
    static void allNullFieldValuesYieldNoBoundary() {
        List<Account> records = new List<Account> {
            new Account(Name = 'A'),
            new Account(Name = 'B')
        };

        Object minimum = Collection.of(records).reduce(ReduceFieldFunction.min(Account.NumberOfEmployees)).toValue();
        System.assertEquals(true, minimum == null);
    }

    @isTest
    static void emptyStreamYieldsNoReducedValue() {
        /** reduce yields a running value per record, so an empty stream produces nothing to return */
        Object reduced = Collection.of(new List<Account>()).reduce(ReduceFieldFunction.sum(Account.NumberOfEmployees)).toValue();
        System.assertEquals(true, reduced == null);
    }

    @isTest
    static void reusedPipelineRecalculatesAverage() {
        TemplateIterator pipeline = Collection.template(new List<Object> {
            ReduceFieldFunction.average(Account.NumberOfEmployees)
        });

        System.assertEquals(0, ((Decimal) pipeline.apply(accounts()).toValue()).compareTo(Decimal.valueOf('2.5')));

        List<Account> longerSet = accounts();
        longerSet.add(new Account(Name = 'E', NumberOfEmployees = 5));

        System.assertEquals(0, ((Decimal) pipeline.apply(longerSet).toValue()).compareTo(Decimal.valueOf('3')));
        System.assertEquals(0, ((Decimal) pipeline.apply(accounts()).toValue()).compareTo(Decimal.valueOf('2.5')));
    }

    @isTest
    static void aggregationWorksInsidePipe() {
        List<Account> records = accounts();

        Object total = Collection.pipe(records, new List<Object> {
            new FilterByCondition(Account.NumberOfEmployees, ComparationUtil.Comparators.GREATER_THAN, 2),
            ReduceFieldFunction.sum(Account.NumberOfEmployees)
        }).toValue();

        System.assertEquals(7, ((Decimal) total).intValue());
    }
}

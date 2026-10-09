@isTest
private class ComparationUtilTest {

    @isTest
    static void compareReturnsNaturalOrder() {
        System.assertEquals(true, ComparationUtil.compare(5, 3) > 0);
        System.assertEquals(true, ComparationUtil.compare(3, 5) < 0);
        System.assertEquals(0, ComparationUtil.compare(5, 5));
    }

    @isTest
    static void compareTreatsNullAsSmallest() {
        System.assertEquals(0, ComparationUtil.compare(null, null));
        System.assertEquals(true, ComparationUtil.compare(null, 5) < 0);
        System.assertEquals(true, ComparationUtil.compare(5, null) > 0);
    }

    @isTest
    static void compareAgainstEveryComparator() {
        System.assertEquals(true, ComparationUtil.compare(5, ComparationUtil.Comparators.EQUALS, 5));
        System.assertEquals(false, ComparationUtil.compare(5, ComparationUtil.Comparators.EQUALS, 3));
        System.assertEquals(true, ComparationUtil.compare(5, ComparationUtil.Comparators.NOT_EQUALS, 3));
        System.assertEquals(true, ComparationUtil.compare(5, ComparationUtil.Comparators.GREATER_THAN, 3));
        System.assertEquals(false, ComparationUtil.compare(3, ComparationUtil.Comparators.GREATER_THAN, 5));
        System.assertEquals(true, ComparationUtil.compare(3, ComparationUtil.Comparators.LESS_THAN, 5));
        System.assertEquals(true, ComparationUtil.compare(5, ComparationUtil.Comparators.GREATER_OR_EQUALS, 5));
        System.assertEquals(true, ComparationUtil.compare(5, ComparationUtil.Comparators.LESS_OR_EQUALS, 5));
        System.assertEquals(true, ComparationUtil.compare('abcdef', ComparationUtil.Comparators.INCLUDES, 'cde'));
        System.assertEquals(true, ComparationUtil.compare('abcdef', ComparationUtil.Comparators.NOT_INCLUDES, 'xyz'));
    }

    @isTest
    static void anyComparatorHandlesMixedAndNullValues() {
        System.assertEquals(true, new AnyComparator().compare(5, 3) > 0);
        System.assertEquals(true, new AnyComparator().compare(3, 5) < 0);
        System.assertEquals(true, new AnyComparator().compare(null, 3) < 0);
        System.assertEquals(true, new AnyComparator().setDescending().compare(3, 5) > 0);
    }

    @isTest
    static void anyComparatorOrdersEveryValueType() {
        System.assertEquals(true, new AnyComparator().compare(5, 3) > 0);
        System.assertEquals(true, new AnyComparator().setDescending().compare(5, 3) < 0);
        System.assertEquals(true, new AnyComparator().compare('b', 'a') > 0);
        System.assertEquals(true, new AnyComparator().compare(System.now().addDays(1), System.now()) > 0);
    }

    @isTest
    static void sortByFieldSortsRecords() {
        List<Account> records = new List<Account> {
            new Account(Name = 'Gamma', NumberOfEmployees = 3),
            new Account(Name = 'Alpha', NumberOfEmployees = 1),
            new Account(Name = 'Beta', NumberOfEmployees = 2)
        };

        List<Object> ascending = Collection.of(records)
            .sortBy(new SortByFieldFunction(Account.NumberOfEmployees))
            .toList(Account.class);

        List<Object> descending = Collection.of(records)
            .sortBy(new SortByFieldFunction(Account.NumberOfEmployees).setDescending())
            .toList(Account.class);

        System.assertEquals(1, ((Account) ascending[0]).NumberOfEmployees);
        System.assertEquals(3, ((Account) ascending[2]).NumberOfEmployees);
        System.assertEquals(3, ((Account) descending[0]).NumberOfEmployees);
        System.assertEquals(1, ((Account) descending[2]).NumberOfEmployees);
    }

    @isTest
    static void sortByFieldHandlesDateFields() {
        /** a Date field used to reach a comparator that cast the value to DateTime, which a Date is not */
        List<Contact> records = new List<Contact> {
            new Contact(LastName = 'Later', Birthdate = Date.newInstance(2020, 1, 1)),
            new Contact(LastName = 'Earlier', Birthdate = Date.newInstance(2010, 1, 1))
        };

        List<Object> ascending = Collection.of(records)
            .sortBy(new SortByFieldFunction(Contact.Birthdate))
            .toList(Contact.class);

        System.assertEquals('Earlier', ((Contact) ascending[0]).LastName);
        System.assertEquals('Later', ((Contact) ascending[1]).LastName);
    }

    @isTest
    static void compareByFieldComparesSobjectsByOneField() {
        List<Account> records = new List<Account> {
            new Account(Name = 'Gamma', NumberOfEmployees = 3),
            new Account(Name = 'Beta', NumberOfEmployees = 2)
        };

        System.assertEquals(true, new CompareByField(Account.NumberOfEmployees).compare(records[0], records[1]) > 0);
        System.assertEquals(true, new CompareByField(Account.NumberOfEmployees).setDescending().compare(records[0], records[1]) < 0);
    }
}

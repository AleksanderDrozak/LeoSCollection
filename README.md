# Leo SF Collection

For working on iterable Apex object (e.g. Lists) with lazy-evaluated functions.

For example:

```java
List<Account> accounts = new List<Account> {
    new Account(Name ='NOT ACME', NumberOfEmployees = 1),
    new Account(Name ='NOT ACME', NumberOfEmployees = 2),
    new Account(Name ='ACME', NumberOfEmployees = 3),
    new Account(Name ='ACME', NumberOfEmployees = 4),
    new Account(Name ='ACME', NumberOfEmployees = 5)
};

List<Account> accounts2 = new List<Account> {
    new Account(Name ='NOT ACME', NumberOfEmployees = 1),
    new Account(Name ='NOT ACME', NumberOfEmployees = 2),
    new Account(Name ='ACME', NumberOfEmployees = 3)
};

List<List<Account>> nestedAccounts = new List<List<Account>> {
    accounts,
    accounts,
    accounts
};

List<List<Account>> nestedAccounts2 = new List<List<Account>> {
    accounts,
    accounts
};

List<Account> accountsWithContacts = (List<Account>) JSON.deserialize('[{"Name":"Test Account","Contacts":{"totalSize":5,"done":true,"records":[{"FirstName":"Andreas","LastName":"Vikerup"},{"FirstName":"Thomas","LastName":"Peterson"},{"FirstName":"Dominik","LastName":"Stronk"},{"FirstName":"Peter","LastName":"Bat"},{"FirstName":"Randome","LastName":"User"}]}}]', List<Account>.class);

List<Account> accountsWithOpportunities =  (List<Account>) JSON.deserialize('[{"Name":"Test Account","Opportunities":{"totalSize":3,"done":true,"records":[{"attributes":{"type":"Opportunity"},"StageName":"Closed Lost","CloseDate":"2023-03-08","Amount":1000},{"attributes":{"type":"Opportunity"},"StageName":"Closed Won","CloseDate":"2023-03-08","Amount":2000},{"attributes":{"type":"Opportunity"},"StageName":"Closed Won","CloseDate":"2022-03-08","Amount":3000},{"attributes":{"type":"Opportunity"},"StageName":"Closed Won","CloseDate":"2023-03-08","Amount":4000}]}}]', List<Account>.class);

List<Account> accountsToAddPhone = new List<Account> {
    new Account(Name ='NOT ACME', NumberOfEmployees = 5, AnnualRevenue = 1.2),
    new Account(Name ='NOT ACME', NumberOfEmployees = 4, AnnualRevenue = 1.3),
    new Account(Name ='ACME', NumberOfEmployees = 3, AnnualRevenue = 1.5),
    new Account(Name ='ACME', NumberOfEmployees = 2, AnnualRevenue = 1.1),
    new Account(Name ='ACME', NumberOfEmployees = 1, AnnualRevenue = 1)
};

LazyIterator Iterator1 = new LazyIterator(accounts);
LazyIterator Iterator2 = FilterOddNumberOfAccountsIterator.getInstance(accounts);
LazyIterator Iterator3 = MappedNumberOfEmployeesIterator.getInstance(accounts);
LazyIterator Iterator4 = SumNumberOnAccounts.getInstance(accounts);
LazyIterator Iterator5 = SumNumberOnAccounts.getInstance(accounts);
LazyIterator Iterator6 = GroupByNameAccounts.getInstance(accounts);
LazyIterator Iterator7 = new LazyIterator(accounts);
LazyIterator Iterator8 = new LazyIterator(accounts);
LazyIterator Iterator9 = new LazyIterator(nestedAccounts);
LazyIterator Iterator10 = new LazyIterator(nestedAccounts);
LazyIterator Iterator11 = new LazyIterator(nestedAccounts);
LazyIterator Iterator12 = new LazyIterator(accounts);
LazyIterator Iterator13 = new LazyIterator(accounts);
LazyIterator Iterator14 = new LazyIterator(accounts);
LazyIterator Iterator15 = new LazyIterator(accounts);
LazyIterator Iterator16 = new LazyIterator(accounts);
LazyIterator Iterator17 = new LazyIterator(accounts);
LazyIterator Iterator18 = new LazyIterator(accounts);
LazyIterator Iterator19 = new LazyIterator(accounts);
LazyIterator Iterator20 = new LazyIterator(accounts);
LazyIterator Iterator21 = new LazyIterator(accounts);
LazyIterator Iterator22 = new LazyIterator(accounts);
LazyIterator Iterator23 = new LazyIterator(accounts);
LazyIterator Iterator24 = new LazyIterator(accounts);

System.debug(JSON.serializePretty(Iterator1.toListMap(Account.class)));
System.debug(JSON.serializePretty(Iterator2.toList(Account.class)));
System.debug(JSON.serializePretty(Iterator3.toMap(Integer.class)));
System.debug(JSON.serializePretty(Iterator4.toMap(Integer.class)));
System.debug(Iterator5.toValue());
System.debug(JSON.serializePretty(Iterator6.toListMap(Account.class)));
System.debug(Iterator7.some(new FilterOddNumberOfAccountsIterator.NumberOfEmployeesIsOdd()));
System.debug(Iterator8.every(new FilterOddNumberOfAccountsIterator.NumberOfEmployeesIsOdd()));
System.debug(Iterator9.flat().toList(Account.class).size());
System.debug(
    Iterator10.flat()
    .groupBy(new GroupByNameAccounts.GroupByNameFunction())
    .toListMap(Account.class)
);
System.debug(
    Iterator11.flat()
    .filter(new FilterOddNumberOfAccountsIterator.NumberOfEmployeesIsOdd())
    .reduce(new SumNumberOnAccounts.SumNumberOfEmployees())
    .toValue()
);

System.debug(Iterator12.filter(
                 new FilterByFieldFunction()
                 .addFilterBy(Account.NumberOfEmployees, ComparationUtil.Comparators.EQUALS, 5)
                 .addFilterBy(Account.NumberOfEmployees, ComparationUtil.Comparators.NOT_EQUALS, 2)
                 .addFilterBy(Account.NumberOfEmployees, ComparationUtil.Comparators.NOT_EQUALS, 3)
                 .addFilterBy(Account.NumberOfEmployees, ComparationUtil.Comparators.NOT_EQUALS, 4)
                 .setExpression('(1 AND 2) OR (3 AND 4)')
                 .evaluate()
)
             .toList(Account.class)
);

System.debug(Iterator13
             .transform(new PickByFieldFunction(Account.NumberOfEmployees))
             .toList(Integer.class)
);

System.debug(Iterator14
             .find(
                 new FilterByFieldFunction()
                 .addFilterBy(Account.NumberOfEmployees, ComparationUtil.Comparators.EQUALS, 5)
                 .evaluate()
             )
);

System.debug(Iterator15
             .find(
                 new FilterOddNumberOfAccountsIterator.NumberOfEmployeesIsOdd()
             )
);

System.debug(
    Iterator16
    .groupBy(new GroupByFieldFunction(Account.NumberOfEmployees))
    .toMap(Account.class)
);

System.debug(
    Iterator17
    .reduce(new SumFieldFunction(Account.NumberOfEmployees))
    .toValue()
);

System.debug(
    Iterator18
    .reduce(new AvarageFieldFunction(Account.NumberOfEmployees))
    .toValue()
);

System.debug(
    Iterator19
    .filter(new FilterOddNumberOfAccountsIterator.NumberOfEmployeesIsOdd())
    .count()
);

System.debug(
    Iterator20
    .reduce(new MinFieldFunction(Account.NumberOfEmployees))
    .toValue()
);

System.debug(
    Iterator21
    .reduce(new MaxFieldFunction(Account.NumberOfEmployees))
    .toValue()
);

/** same implementation as for iterator 12 - its about 30% faster */
System.debug(Iterator22.filter(
                 new AndFunction(
                     new AndFunction(
                         new FilterByCondition(Account.NumberOfEmployees, ComparationUtil.Comparators.EQUALS, 5),
                         new FilterByCondition(Account.NumberOfEmployees, ComparationUtil.Comparators.NOT_EQUALS, 2)
                     ),
                     new AndFunction(
                         new FilterByCondition(Account.NumberOfEmployees, ComparationUtil.Comparators.NOT_EQUALS, 3),
                         new FilterByCondition(Account.NumberOfEmployees, ComparationUtil.Comparators.NOT_EQUALS, 4)
                     )
                 )
)
             .toList(Account.class)
);

System.debug(Iterator23.filter(
                 new NotFunction(
                     new FilterByCondition(Account.NumberOfEmployees, ComparationUtil.Comparators.EQUALS, 5)
                 )
)
             .toList(Account.class)
);

System.debug(Iterator24.filter(
                 new OrFunction(
                     new FilterByCondition(Account.NumberOfEmployees, ComparationUtil.Comparators.EQUALS, 5),
                     new FilterByCondition(Account.NumberOfEmployees, ComparationUtil.Comparators.EQUALS, 3)
                 )
)
             .toList(Account.class)
);

/** Every operation from LazyIterator can be done using Collection class eg */
System.debug(Collection.of(accounts).find(
                 new FilterByCondition(Account.NumberOfEmployees, ComparationUtil.Comparators.EQUALS, 5)
)
);

/** even shorter */
System.debug(Collection.find(accounts, new FilterByCondition(Account.NumberOfEmployees, ComparationUtil.Comparators.EQUALS, 5)));

/** with other methods */
System.debug(Collection.some(accounts, new FilterByCondition(Account.NumberOfEmployees, ComparationUtil.Comparators.EQUALS, 5)));

/** also returning lazy iterator */
System.debug(Collection.filter(
                 accounts, new FilterByCondition(Account.NumberOfEmployees, ComparationUtil.Comparators.NOT_EQUALS, 5)
).toList(Account.class)
);

/** sorting logic from Lazy iterator sort by call using AnyComparator with ascending order which are defaults */
System.debug(Collection.of(new List<Integer> { 4, 3, 6, 1, 2, 5, 7 }).sortBy().toList(Integer.class));

/** same here using AnyComparator which is default with set descending order */
System.debug(Collection.of(new List<Integer> { 4, 3, 6, 1, 2, 5, 7 }).sortBy(SortUtil.SORTING_ORDER.DESCENDING).toList(Integer.class));

/** same here shorter without of function, using AnyComparator with descending order set by param */
System.debug(Collection.sortBy(new List<Integer> { 4, 3, 6, 1, 2, 5, 7 }, new AnyComparator().setDescending()).toList(Integer.class));

/** sorting logic for Lazy iterator (works from collection static also) with declared sorting function (faster then AnyComparator by 20%) with default descending order */
System.debug(Collection.sortBy(new List<Integer> { 4, 3, 6, 1, 2, 5, 7 }, new NumberComparator().setDescending()).toList(Integer.class));

System.debug(
    Collection.of(new List<Account> {
    new Account(Name ='NOT ACME', NumberOfEmployees = 4),
    new Account(Name ='NOT ACME', NumberOfEmployees = 3),
    new Account(Name ='ACME', NumberOfEmployees = 2),
    new Account(Name ='ACME', NumberOfEmployees = 5),
    new Account(Name ='ACME', NumberOfEmployees = 1)
})
    .sortBy(new SortByFieldFunction(Account.NumberOfEmployees, Decimal.class))
    .toList(Account.class)
);

System.debug(
    Collection.sortBy(new List<Account> {
    new Account(Name ='NOT ACME', NumberOfEmployees = 4, AnnualRevenue = 1.2),
    new Account(Name ='NOT ACME', NumberOfEmployees = 4, AnnualRevenue = 1.3),
    new Account(Name ='ACME', NumberOfEmployees = 2, AnnualRevenue = 1.5),
    new Account(Name ='ACME', NumberOfEmployees = 2, AnnualRevenue = 1.1),
    new Account(Name ='ACME', NumberOfEmployees = 1, AnnualRevenue = 1)
}, new SortByFieldFunction(Account.AnnualRevenue).setDescending())
    .toList(Account.class)
);

System.debug(
    Collection.wrap(new List<Account> {
    new Account(Name ='NOT ACME', NumberOfEmployees = 4, AnnualRevenue = 1.2),
    new Account(Name ='NOT ACME', NumberOfEmployees = 4, AnnualRevenue = 1.3),
    new Account(Name ='ACME', NumberOfEmployees = 2, AnnualRevenue = 1.5),
    new Account(Name ='ACME', NumberOfEmployees = 2, AnnualRevenue = 1.1),
    new Account(Name ='ACME', NumberOfEmployees = 1, AnnualRevenue = 1)
}, new AccountWrapper())
    .toList(AccountWrapper.class)
);

System.debug(Collection.transform(new List<Account> {
    new Account(Name ='NOT ACME', NumberOfEmployees = 4, AnnualRevenue = 1.2),
    new Account(Name ='NOT ACME', NumberOfEmployees = 4, AnnualRevenue = 1.3),
    new Account(Name ='ACME', NumberOfEmployees = 2, AnnualRevenue = 1.5),
    new Account(Name ='ACME', NumberOfEmployees = 2, AnnualRevenue = 1.1),
    new Account(Name ='ACME', NumberOfEmployees = 1, AnnualRevenue = 1)
}, new ConvertFunction(Contact.class, new Map<SObjectField, SObjectField> {
    Contact.Name => Account.Name,
    Contact.Salutation => Account.NumberOfEmployees
}))
             .toList(Contact.class)
);

System.debug(
    Collection.flatMap(
        accountsWithContacts, new PickListByFieldFunction(Contact.AccountId)
    ).toList(Contact.class)
);

LazyIterator reusableIterator = Collection.nil()
                                .flat()
                                .filter(new FilterOddNumberOfAccountsIterator.NumberOfEmployeesIsOdd())
                                .reduce(new SumNumberOnAccounts.SumNumberOfEmployees());

System.debug(reusableIterator.apply(nestedAccounts).toValue());
System.debug(reusableIterator.apply(nestedAccounts2).toValue());

List<Account> accountsToAddPhone1 = accountsToAddPhone.deepClone();

Collection.transform(
    accountsToAddPhone1, new SetValueFunction(Account.Phone, '+12 123-123-123')
).execute();

System.debug(accountsToAddPhone1);

List<List<Account>> nestedAccountsToAddPhone = new List<List<Account>> {
    accountsToAddPhone.deepClone(),
                    accountsToAddPhone.deepClone()
};

/** works also with Collection.of(nestedAccountsToAddPhone).pipe(... */
Collection.pipe(nestedAccountsToAddPhone, new List<Object> {
    /** function do nothing, only placed to inform pipe function that we want to apply flattening */
    new FlattenFunction(),
    new FilterOddNumberOfAccountsIterator.NumberOfEmployeesIsOdd(),
    new SetValueFunction(Account.Phone, '+12 123-123-123')
})
.execute();

System.debug(JSON.serializePretty(nestedAccountsToAddPhone));

System.debug(
    Collection.pipe(accounts, new List<Object> {
    new ConvertFunction(Contact.class, new Map<SObjectField, SObjectField> {
        Contact.Name => Account.Name,
        Contact.Salutation => Account.NumberOfEmployees
    }),
    new GroupByFieldFunction(Contact.Name)
}
    )
    .toDistinctList(Contact.class)
);

System.debug(
    Collection.of(accounts)
    .transform(
        new SetValueConditionallyFunction(
            Account.Phone,
            new FilterOddNumberOfAccountsIterator.NumberOfEmployeesIsOdd(),
            '+12 123-123-123'
        )
    )
    .toList(Account.class)
);

System.debug(
    Collection.of(accounts)
    .transform(new SetMultipleValuesFunction
               (
                   new Map<SObjectField, Object>
                   { Account.Phone => '+12 123-123-123',
                     Account.Website => 'some.website.com' }
               )
    )
    .toList(Account.class)
);

System.debug(
    Collection.pipe(accountsWithContacts, new List<Object> {
    new PickListByFieldFunction(Contact.AccountId),
    /** function do nothing, only placed to inform pipe function that we want to apply flattening */
    new FlattenFunction(),
    new SetValueFunction(Contact.Phone, '+12 123-123-123')
})
    .toList(Contact.class)
);

System.debug(
    Collection.pipe(accountsWithContacts, new List<Object> {
    new LoggerFunction(),
    new PickListByFieldFunction(Contact.AccountId),
    new LoggerFunction(),
    /** function do nothing, only placed to inform pipe function that we want to apply flattening */
    new FlattenFunction(),
    new LoggerFunction(),
    new SetValueFunction(Contact.Phone, '+12 123-123-123'),
    new LoggerFunction()
})
    .toList(Contact.class)
);

System.debug(
    Collection.pipe(
        accounts,
        new List<Object> { new LimitToFunction(3) }
    )
    .count()
);

System.debug(
    Collection.of(accounts)
    .take(2)
    .count()
);

System.debug(
    Collection.empty()
    .firstOrDefault(accounts.get(0))
);

Collection.of(accounts).forEach(new LoggerFunction());

System.debug(
    Collection.query(new QueryFirstAccount())
    .transform(new SetValueFunction(Account.Name, 'Acme Test'))
    .dmlUpdate(new DefaultDmlUpdateFunction())
);


System.debug(
    Collection.of(accounts)
    .pipe(new List<Object> {
    new SetValueFunction(
        Account.Phone,
        '+12 234 567 890'
    ),
    new SetValueFunction(
        Account.BillingStreet,
        'Test Street'
    ),
    new SetValueFunction(
        Account.BillingCity,
        'Test City'
    ),
    new SetValueFromFunction(
        Account.Fax,
        new PickByFieldFunction(Account.Phone)
    ),
    new SetValueFromFunction(
        Account.Name,
        new ConcatFunction(
            new PickByFieldFunction(Account.BillingStreet),
            new ConstantMapFunction(' '),
            new PickByFieldFunction(Account.BillingCity)
        )
    ),
    new SetValueFromFunction(
        Account.Phone,
        new ReduceMapFunction(
            new PickByFieldFunction(Account.Phone),
            new RegexReplaceFunction(' ', '-')
        )
    )
}).toList(Account.class)
);

Datetime beginingOfTheYear = Datetime.now().addDays(-Datetime.now().dayOfYear());
System.debug(
    Collection.of(accountsWithOpportunities).transform(
        new SetValueFromFunction(
            Account.AnnualRevenue,
            new PickListApplyFunction(
                Opportunity.AccountId,
                new List<Object>
                { new FilterByCondition(
                      Opportunity.CloseDate,
                      ComparationUtil.Comparators.GREATER_OR_EQUALS,
                      beginingOfTheYear
                  ),
                  new FilterByCondition(
                      Opportunity.CloseDate,
                      ComparationUtil.Comparators.LESS_OR_EQUALS,
                      Datetime.now()
                  ),
                  new FilterByCondition(
                      Opportunity.StageName,
                      ComparationUtil.Comparators.EQUALS,
                      'Closed Won'
                  ),
                  new SumFieldFunction(Opportunity.Amount) }
            )
        )
    )
    .toList(Account.class)
);

System.debug(
    Collection.of(accountsWithOpportunities).transform(
        new SetValueFromFunction(
            Account.Name,
            new ConcatFunction(
                new ConstantMapFunction('Has Closed Won Opportunites: '),
                new PickListApplyFunction(
                    Opportunity.AccountId,
                    new List<Object> { new FilterByCondition(
                                           Opportunity.StageName,
                                           ComparationUtil.Comparators.EQUALS,
                                           'Closed Won'
                                       ) },
                    new IteratorToIsNotEmpty()
                )
            )
        )
    )
    .toList(Account.class)
);

System.debug(
    Collection.of(accountsWithOpportunities).transform(
        new SetValueFromFunction(
            Account.Name,
            new ConcatFunction(
                new ConstantMapFunction('Has Closed Won Opportunites: '),
                new PickListIsNotEmptyFunction(
                    Opportunity.AccountId,
                    new List<Object> { new FilterByCondition(
                                           Opportunity.StageName,
                                           ComparationUtil.Comparators.EQUALS,
                                           'Closed Won'
                                       ) }
                )
            )
        )
    )
    .toList(Account.class)
);

System.debug(
    Collection.of(accountsWithOpportunities).transform(
        new SetValueFromFunction(
            Account.Name,
            new ConcatFunction(
                new ConstantMapFunction('Has No Opportunites: '),
                new PickListApplyFunction(
                    Opportunity.AccountId,
                    new IteratorToIsEmpty()
                )
            )
        )
    )
    .toList(Account.class)
);

System.debug(
    Collection.of(accountsWithOpportunities).transform(
        new SetValueFromFunction(
            Account.Name,
            new ConcatFunction(
                new ConstantMapFunction('Has No Opportunites: '),
                new PickListIsEmptyFunction(
                    Opportunity.AccountId
                )
            )
        )
    )
    .toList(Account.class)
);
```

Fork and inspiration from :
- https://nebulaconsulting.co.uk/insights/using-lazy-evaluation-to-write-salesforce-apex-code-without-for-loops
  Ideas for functions:
- https://ramdajs.com/docs/#promap
- https://laravel.com/docs/9.x/collections

### Open Ideas
- [implement ideas](./ideas)

### TODO's:
- REVERT toMap / toListMap to have String as a key, because apex not works with casting...
- Refactor LazySortIterator, list of issues and proposals:
  - [Issue] equal value in sorting algorithm to fix issues with two field sorting (debug two functions sorting) - (SortByFieldFunction), sorting not working properly when we have to sorting methods applied to single  
  - [Proposal]- implement logic to allow pass list of sorting functions instead of single
  - [Proposal] - remove LazySortIterator and replace its functionality with just method that sorts data and results with new LazyIterator that contains sorted data, it will be more predictable (as well can be implemented option to pass multiple sorting functions)
- universal Map iterable wrapper to allow transformation on maps
- append/prepend method to allow extending number of iterable elements (multiple iterable elements without losing performance),
- remove compare functions for every type, because improved AnyCompare works in almost same speed as them
- remove requirement for passing type to conversion method

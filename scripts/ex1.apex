List<Account> accounts = new List<Account> {
    new Account(Name ='NOT ACME', NumberOfEmployees = 1),
    new Account(Name ='NOT ACME', NumberOfEmployees = 2),
    new Account(Name ='ACME', NumberOfEmployees = 3),
    new Account(Name ='ACME', NumberOfEmployees = 4),
    new Account(Name ='ACME', NumberOfEmployees = 5)
};

LazyIterator Iterator1 = new LazyIterator(accounts);
LazyIterator Iterator2 = new LazyIterator(accounts);

// returns first matching element
System.debug(Iterator1.find(new FilterOddNumberOfAccountsIterator.NumberOfEmployeesIsOdd())
);

// returns null as we already iterated over it
System.debug(Iterator1.find(new FilterOddNumberOfAccountsIterator.NumberOfEmployeesIsOdd())
);

// returns map with keys 1,3,5 as we filtered out accounts with even employees
System.debug(JSON.serializePretty(
    Iterator2
    .filter(new FilterOddNumberOfAccountsIterator.NumberOfEmployeesIsOdd())
    .groupBy(new GroupByFieldFunction(Account.NumberOfEmployees))
    .toMap(Account.class))
);
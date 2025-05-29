List<Account> accounts = new List<Account> {
    new Account(Name ='NOT ACME', NumberOfEmployees = 1),
    new Account(Name ='NOT ACME', NumberOfEmployees = 2),
    new Account(Name ='ACME', NumberOfEmployees = 3),
    new Account(Name ='ACME', NumberOfEmployees = 4),
    new Account(Name ='ACME', NumberOfEmployees = 5)
};

LazyIterator Iterator1 = new LazyIterator(accounts);
LazyIterator Iterator2 = new LazyIterator(accounts);

System.debug(Iterator1.find(new FilterOddNumberOfAccountsIterator.NumberOfEmployeesIsOdd())
);

System.debug(Iterator1.find(new FilterOddNumberOfAccountsIterator.NumberOfEmployeesIsOdd())
);

System.debug(JSON.serializePretty(
    Iterator2
    .filter(new FilterOddNumberOfAccountsIterator.NumberOfEmployeesIsOdd())
    .groupBy(new GroupByFieldFunction(Account.NumberOfEmployees))
    .toMap(Account.class))
);
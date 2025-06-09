List<Account> accountsWithOpportunities =  (List<Account>) JSON.deserialize('[{"Name":"Test Account","Opportunities":{"totalSize":3,"done":true,"records":[{"attributes":{"type":"Opportunity"},"StageName":"Closed Lost","CloseDate":"2023-03-08","Amount":1000},{"attributes":{"type":"Opportunity"},"StageName":"Closed Won","CloseDate":"2023-03-08","Amount":2000},{"attributes":{"type":"Opportunity"},"StageName":"Closed Won","CloseDate":"2022-03-08","Amount":3000},{"attributes":{"type":"Opportunity"},"StageName":"Closed Won","CloseDate":"2023-03-08","Amount":4000}]}}]', List<Account>.class);
Iterable<Object> iterator = (Iterable<Object>) Collection.of(accountsWithOpportunities)
    .pipe(
        new List<Object> {
            new SetValueFromFunction(
                Account.Name,
                new ConcatFunction(
                    new ConstantMapFunction('Has No Opportunites: '),
                    new PickListIsEmptyFunction(
                        Opportunity.AccountId,
                        new List<Object> {
                            new FilterByCondition(Opportunity.Amount, ComparationUtil.Comparators.GREATER_OR_EQUALS, 1000),
                            new LimitToFunction(1)
                        }
                    )
                )
            )
        }
    );

for (Object record : iterator) {
    System.debug(record);
}
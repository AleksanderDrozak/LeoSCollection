/**
 * General idea is to call Add error with custom message on sobject record, which is usefull in triggers
 */
Collection.of(accounts)
.pipe(new List<Object> {
    new FilterByCondition(Account.Rating,ComparationUtil.Comparators.LESS_THAN, 3),
    new AddError('Your Rating shouldn`t be less then 3')
});
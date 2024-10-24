/**- transform with constant or default mapping
   - transform with conditional mapping */

Collection
    .transform(
        accounts,
        new ConvertFunction(
            Contact.class,
            new Map<SObjectField, MapFunction> { 
                Contact.Name => new ConcatFunction(
                    new ConstantMapFunction('Contact '),
                    new PickByFieldFunction(Account.Name)
                ),
                Contact.Salutation => new ConditionalMapFunction(
                    new FilterByCondition(Account.NumberOfEmployees, ComparationUtil.Comparators.NOT_EQUALS, null),
                    new PickByFieldFunction(Account.NumberOfEmployees),
                    new ConstantMapFunction(0),
                ),
                Contact.Salutation => new DefaultMapFunction(
                    new PickByFieldFunction(Account.NumberOfEmployees),
                    new ConstantMapFunction(0),
                )
            }
        )
)
.toList(Contact.class);
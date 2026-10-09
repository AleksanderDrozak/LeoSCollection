@isTest
private class MapFunctionTest {

    @isTest
    static void convertCopiesFieldsFieldByFieldByDefault() {
        List<Account> source = new List<Account> { new Account(Name = 'Acme', Phone = '111') };

        List<Object> result = Collection.transform(source, new ConvertFunction(Contact.class, new Map<SObjectField, SObjectField> {
            Contact.LastName => Account.Name,
            Contact.Phone => Account.Phone
        })).toList(Contact.class);

        System.assertEquals(1, result.size());
        System.assertEquals('Acme', ((Contact) result[0]).LastName);
        System.assertEquals('111', ((Contact) result[0]).Phone);
    }

    @isTest
    static void convertToleratesNullSourceField() {
        List<Account> source = new List<Account> { new Account(Name = 'Acme') };

        List<Object> result = Collection.transform(source, new ConvertFunction(Contact.class, new Map<SObjectField, SObjectField> {
            Contact.LastName => Account.Name,
            Contact.Phone => Account.Phone
        })).toList(Contact.class);

        System.assertEquals('Acme', ((Contact) result[0]).LastName);
        System.assertEquals(null, ((Contact) result[0]).Phone);
    }

    @isTest
    static void convertWithJsonCopyAlsoWorks() {
        List<Account> source = new List<Account> { new Account(Name = 'Acme') };

        List<Object> result = Collection.transform(source, new ConvertFunction(Contact.class, new Map<SObjectField, SObjectField> {
            Contact.LastName => Account.Name
        }, true)).toList(Contact.class);

        System.assertEquals('Acme', ((Contact) result[0]).LastName);
    }

    @isTest
    static void convertAcceptsMapFunctions() {
        List<Account> source = new List<Account> { new Account(Name = 'Acme', Phone = '11 22') };

        List<Object> result = Collection.transform(source, new ConvertFunction(Contact.class, new Map<SObjectField, MapFunction> {
            Contact.LastName => new PickByFieldFunction(Account.Name),
            Contact.Phone => new ComposeMapFunction(new PickByFieldFunction(Account.Phone), new RegexReplaceFunction(' ', '-'))
        })).toList(Contact.class);

        System.assertEquals('Acme', ((Contact) result[0]).LastName);
        System.assertEquals('11-22', ((Contact) result[0]).Phone);
    }

    @isTest
    static void setValueConditionallyOnlyTouchesMatchingRecords() {
        List<Account> source = new List<Account> { new Account(Name = 'Acme'), new Account(Name = 'Other') };

        List<Object> result = Collection.of(source)
            .transform(new SetValueConditionallyFunction(
                Account.Phone,
                new FilterByCondition(Account.Name, ComparationUtil.Comparators.EQUALS, 'Acme'),
                '111'
            ))
            .toList(Account.class);

        System.assertEquals('111', ((Account) result[0]).Phone);
        System.assertEquals(null, ((Account) result[1]).Phone);
    }

    @isTest
    static void setMultipleValuesAppliesWholeMap() {
        List<Account> source = new List<Account> { new Account(Name = 'Acme') };

        List<Object> result = Collection.of(source)
            .transform(new SetMultipleValuesFunction(new Map<SObjectField, Object> {
                Account.Phone => '+12 123-123-123',
                Account.Website => 'some.website.com'
            }))
            .toList(Account.class);

        System.assertEquals('+12 123-123-123', ((Account) result[0]).Phone);
        System.assertEquals('some.website.com', ((Account) result[0]).Website);
    }

    @isTest
    static void pickListApplyAggregatesChildrenOntoParent() {
        List<Account> source = (List<Account>) JSON.deserialize(
            '[{"Name":"Acme","Opportunities":{"totalSize":2,"done":true,"records":['
            + '{"attributes":{"type":"Opportunity"},"StageName":"Closed Won","Amount":1000},'
            + '{"attributes":{"type":"Opportunity"},"StageName":"Closed Lost","Amount":500}]}}]',
            List<Account>.class
        );

        List<Object> result = Collection.of(source).transform(
            new SetValueFromFunction(Account.AnnualRevenue, new PickListApplyFunction(
                Opportunity.AccountId,
                new List<Object> {
                    new FilterByCondition(Opportunity.StageName, ComparationUtil.Comparators.EQUALS, 'Closed Won'),
                    ReduceFieldFunction.sum(Opportunity.Amount)
                }
            ))
        ).toList(Account.class);

        System.assertEquals(0, ((Account) result[0]).AnnualRevenue.compareTo(Decimal.valueOf(1000)));
    }

    @isTest
    static void pickListIsEmptyTreatsMissingRelationshipAsEmpty() {
        List<Account> source = (List<Account>) JSON.deserialize(
            '[{"Name":"WithContacts","Contacts":{"totalSize":1,"done":true,"records":[{"attributes":{"type":"Contact"},"LastName":"One"}]}},'
            + '{"Name":"WithoutContacts","Contacts":{"totalSize":0,"done":true,"records":[]}},'
            + '{"Name":"RelationshipNotQueried"}]',
            List<Account>.class
        );

        List<Object> result = Collection.of(source).transform(
            new SetValueFromFunction(Account.Fax, new ConcatFunction(
                new ConstantMapFunction('contacts:'),
                new PickListIsNotEmptyFunction(Contact.AccountId)
            ))
        ).toList(Account.class);

        System.assertEquals('contacts:true', ((Account) result[0]).Fax);
        System.assertEquals('contacts:false', ((Account) result[1]).Fax);
        System.assertEquals('contacts:false', ((Account) result[2]).Fax);
    }

    /** the same class works as a predicate, so "keep the parents whose children match" needs no hand-written function */
    @isTest
    static void pickListIsNotEmptyWorksAsAFilter() {
        List<Account> source = (List<Account>) JSON.deserialize(
            '[{"Name":"WithContacts","Contacts":{"totalSize":1,"done":true,"records":[{"attributes":{"type":"Contact"},"LastName":"One"}]}},'
            + '{"Name":"WithoutContacts","Contacts":{"totalSize":0,"done":true,"records":[]}}]',
            List<Account>.class
        );

        List<Object> result = Collection.of(source)
            .filter(new PickListIsNotEmptyFunction(Contact.AccountId))
            .toList(Account.class);

        System.assertEquals(1, result.size());
        System.assertEquals('WithContacts', ((Account) result[0]).Name);
    }

    @isTest
    static void pickListIsEmptyIsTheInverseOfIsNotEmpty() {
        List<Account> source = (List<Account>) JSON.deserialize(
            '[{"Name":"WithContacts","Contacts":{"totalSize":1,"done":true,"records":[{"attributes":{"type":"Contact"},"LastName":"One"}]}}]',
            List<Account>.class
        );

        List<Object> result = Collection.of(source).transform(
            new SetValueFromFunction(Account.Fax, new ConcatFunction(
                new ConstantMapFunction('empty:'),
                new PickListIsEmptyFunction(Contact.AccountId)
            ))
        ).toList(Account.class);

        System.assertEquals('empty:false', ((Account) result[0]).Fax);
    }

    @isTest
    static void pickListApplySupportsIsNotEmptyWithoutExtraFilters() {
        List<Account> source = (List<Account>) JSON.deserialize(
            '[{"Name":"WithContacts","Contacts":{"totalSize":2,"done":true,"records":[{"attributes":{"type":"Contact"},"LastName":"One"},{"attributes":{"type":"Contact"},"LastName":"Two"}]}}]',
            List<Account>.class
        );

        List<Object> result = Collection.of(source).transform(
            new SetValueFromFunction(Account.Fax, new ConcatFunction(
                new ConstantMapFunction('any:'),
                new PickListApplyFunction(Contact.AccountId, new IteratorToIsNotEmpty())
            ))
        ).toList(Account.class);

        System.assertEquals('any:true', ((Account) result[0]).Fax);
    }
}

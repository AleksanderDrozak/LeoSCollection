@isTest
private class LazyIteratorTest {

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

    private class SumEmployees implements ReduceFunction {
        public Object getInitialValue() {
            return 0;
        }
        public Object reduceValue(Object previous, Object current) {
            return (Integer) previous + (Integer) ((SObject) current).get(Account.NumberOfEmployees);
        }
    }

    private class GroupByName implements GroupByFunction {
        public String getGroupKey(Object record) {
            return (String) ((SObject) record).get(Account.Name);
        }
    }

    /** two groups hold a repeated name, so the group-level predicates have something to drop */
    private static List<Account> duplicatedNames() {
        return new List<Account> {
            new Account(Name = 'Same', NumberOfEmployees = 1),
            new Account(Name = 'Same', NumberOfEmployees = 2),
            new Account(Name = 'Other', NumberOfEmployees = 3)
        };
    }

    private class KeyStartsWith implements BooleanFunction {
        private String prefix;
        public KeyStartsWith(String prefix) {
            this.prefix = prefix;
        }
        public Boolean isTrueFor(Object keyedGroup) {
            return ((LazyGroupByIterator.KeyedGroup) keyedGroup).key().startsWith(this.prefix);
        }
    }

    /** counts how many groups the filter was asked about, which is how laziness becomes visible from a test */
    private class CountingPredicate implements BooleanFunction {
        public Integer calls = 0;
        public Boolean isTrueFor(Object keyedGroup) {
            this.calls++;
            return true;
        }
    }

    private class FirstAccountQuery implements QueryableFunction {
        public Object queryData(List<Object> data) {
            return [SELECT Id, Name FROM Account LIMIT 1];
        }
    }

    @isTest
    static void filterDoesNotConsumeOnRepeatedHasNext() {
        LazyIterator filtered = Collection.filter(accounts(), new EmployeesAreOdd());

        System.assertEquals(true, filtered.hasNext());
        System.assertEquals(true, filtered.hasNext());
        System.assertEquals(true, filtered.hasNext());
        System.assertEquals(1, ((Account) filtered.next()).NumberOfEmployees);

        System.assertEquals(true, filtered.hasNext());
        System.assertEquals(3, ((Account) filtered.next()).NumberOfEmployees);

        System.assertEquals(false, filtered.hasNext());
        System.assertEquals(false, filtered.hasNext());
    }

    @isTest
    static void nextWorksWithoutPrecedingHasNext() {
        LazyIterator filtered = Collection.filter(accounts(), new EmployeesAreOdd());

        System.assertEquals(1, ((Account) filtered.next()).NumberOfEmployees);
        System.assertEquals(3, ((Account) filtered.next()).NumberOfEmployees);
    }

    @isTest
    static void takeDoesNotLoseLimitOnRepeatedHasNext() {
        LazyIterator limited = Collection.of(accounts()).take(2);

        System.assertEquals(true, limited.hasNext());
        System.assertEquals(true, limited.hasNext());
        System.assertEquals(true, limited.hasNext());

        System.assertEquals(2, limited.toList(Account.class).size());
    }

    @isTest
    static void takeReturnsFirstRecords() {
        List<Object> result = Collection.of(accounts()).take(2).toList(Account.class);

        System.assertEquals(2, result.size());
        System.assertEquals(1, ((Account) result[0]).NumberOfEmployees);
        System.assertEquals(2, ((Account) result[1]).NumberOfEmployees);
    }

    @isTest
    static void flatSkipsNullAndEmptyBatches() {
        List<Object> batches = new List<Object> { accounts(), null, new List<Account>(), accounts() };

        System.assertEquals(8, Collection.flat(batches).toList(Account.class).size());
    }

    @isTest
    static void flatHasNextIsIdempotent() {
        List<Object> batches = new List<Object> { accounts(), null, new List<Account>(), accounts() };
        LazyIterator flattened = Collection.flat(batches);

        System.assertEquals(true, flattened.hasNext());
        System.assertEquals(true, flattened.hasNext());
        System.assertEquals(1, ((Account) flattened.next()).NumberOfEmployees);
    }

    @isTest
    static void firstReturnsFirstElement() {
        System.assertEquals(1, ((Account) Collection.of(accounts()).first()).NumberOfEmployees);
        System.assertEquals(1, ((Account) Collection.of(accounts()).take(2).first()).NumberOfEmployees);
        System.assertEquals(true, TestUtils.empty().first() == null);
    }

    @isTest
    static void firstOrDefaultFallsBackOnEmpty() {
        Account fallback = new Account(Name = 'Fallback');

        System.assertEquals('Fallback', ((Account) TestUtils.empty().firstOrDefault(fallback)).Name);
        System.assertEquals(1, ((Account) Collection.of(accounts()).firstOrDefault(fallback)).NumberOfEmployees);
    }

    @isTest
    static void reduceAggregatesWholeStream() {
        System.assertEquals(10, Collection.of(accounts()).reduce(new SumEmployees()).toValue());
    }

    @isTest
    static void terminalOperations() {
        List<Account> records = accounts();

        System.assertEquals(2, Collection.filter(records, new EmployeesAreOdd()).count());
        System.assertEquals(true, Collection.some(records, new EmployeesAreOdd()));
        System.assertEquals(false, Collection.every(records, new EmployeesAreOdd()));
        System.assertEquals(1, ((Account) Collection.find(records, new EmployeesAreOdd())).NumberOfEmployees);
    }

    @isTest
    static void groupBySplitsByKey() {
        List<Account> records = new List<Account> {
            new Account(Name = 'Same', NumberOfEmployees = 1),
            new Account(Name = 'Same', NumberOfEmployees = 2),
            new Account(Name = 'Other', NumberOfEmployees = 3)
        };

        Map<String, List<Object>> grouped = Collection.of(records).groupBy(new GroupByName()).toListMap(Account.class);

        System.assertEquals(2, grouped.size());
        System.assertEquals(2, grouped.get('Same').size());
        System.assertEquals(1, grouped.get('Other').size());
    }

    @isTest
    static void groupByProducesKeyedMap() {
        Map<String, Object> keyed = Collection.of(accounts()).groupBy(new GroupByName()).toMap(Account.class);

        System.assertEquals(4, keyed.size());
    }

    @isTest
    static void distinctListCollapsesGroupKeys() {
        List<Account> records = new List<Account> {
            new Account(Name = 'Same'),
            new Account(Name = 'Same'),
            new Account(Name = 'Other')
        };

        System.assertEquals(2, Collection.of(records).groupBy(new GroupByName()).toDistinctList(Account.class).size());
    }

    /** grouping hands over groups, not records carrying a key on the side */
    @isTest
    static void groupByEmitsGroups() {
        LazyGroupByIterator.KeyedGroup grouped = (LazyGroupByIterator.KeyedGroup) Collection.of(duplicatedNames())
            .groupBy(new GroupByName())
            .first();

        System.assertEquals('Same', grouped.key());
        System.assertEquals(2, grouped.size());
        System.assertEquals(1, ((Account) grouped.members().get(0)).NumberOfEmployees);
    }

    /**
     * A step above groupBy used to lose the key, because the key was a method that only groupBy implemented
     * and every other node answered with a placeholder - so this asserted nothing before.
     */
    @isTest
    static void groupKeepsItsKeyThroughAStepAboveIt() {
        Map<String, List<Object>> kept = Collection.of(duplicatedNames())
            .groupBy(new GroupByName())
            .filterGroup(new GroupSizeCondition(ComparationUtil.Comparators.GREATER_THAN, 1))
            .toListMap(Account.class);

        System.assertEquals(1, kept.size());
        System.assertEquals(true, kept.containsKey('Same'));
        System.assertEquals(2, kept.get('Same').size());
    }

    /**
     * "Alpha" is the only group that satisfies both, which no single filter and no last-one-wins would give.
     * One method expresses both rules - the size rule reads the members, the prefix rule reads the key - because
     * filterGroup hands over the whole group rather than one half of it.
     */
    @isTest
    static void groupFiltersComposeInsteadOfReplacing() {
        List<Account> records = new List<Account> {
            new Account(Name = 'Alpha'), new Account(Name = 'Alpha'), new Account(Name = 'Alpha'),
            new Account(Name = 'Beta'), new Account(Name = 'Beta'),
            new Account(Name = 'Aurora')
        };

        Map<String, List<Object>> kept = Collection.of(records)
            .groupBy(new GroupByName())
            .filterGroup(new GroupSizeCondition(ComparationUtil.Comparators.GREATER_THAN, 1))
            .filterGroup(new KeyStartsWith('A'))
            .toListMap(Account.class);

        System.assertEquals(1, kept.size());
        System.assertEquals(true, kept.containsKey('Alpha'));
    }

    /** the keys to drop are known up front, so they are named directly instead of wrapped in a predicate */
    @isTest
    static void removeKeysDropsThoseGroupsAndKeepsTheRest() {
        Map<String, List<Object>> kept = Collection.of(duplicatedNames())
            .groupBy(new GroupByName())
            .removeKeys(new Set<String> { 'Other' })
            .toListMap(Account.class);

        System.assertEquals(1, kept.size());
        System.assertEquals(true, kept.containsKey('Same'));
        System.assertEquals(2, kept.get('Same').size());
    }

    /** it is a filter underneath, so it composes with the other group conditions rather than replacing them */
    @isTest
    static void removeKeysComposesWithFilterGroup() {
        Map<String, List<Object>> kept = Collection.of(duplicatedNames())
            .groupBy(new GroupByName())
            .filterGroup(new GroupSizeCondition(ComparationUtil.Comparators.GREATER_THAN, 1))
            .removeKeys(new Set<String> { 'Other' })
            .toListMap(Account.class);

        System.assertEquals(1, kept.size());
        System.assertEquals(true, kept.containsKey('Same'));
    }

    /**
     * The predicate is carried, not applied: take(1) above the filter asks about the group it needs and stops.
     * Building a filtered list at the call would have tested all four groups of accounts() instead.
     */
    @isTest
    static void filterGroupIsAppliedOnReadRatherThanAtTheCall() {
        CountingPredicate counted = new CountingPredicate();

        Collection.of(accounts())
            .groupBy(new GroupByName())
            .filterGroup(counted)
            .take(1)
            .toList(LazyGroupByIterator.KeyedGroup.class);

        System.assert(counted.calls < 4, 'filterGroup scanned the whole bucket instead of stopping at take(1)');
    }

    /**
     * A map that is already grouped is a way in: nothing is bucketed, the entries are the groups. This is the
     * door for a map that came from a payload or from another pipeline's toListMap(), not from groupBy().
     */
    @isTest
    static void ofMapEntersAnAlreadyGroupedMap() {
        Map<String, List<Object>> grouped = new Map<String, List<Object>> {
            'Same' => new List<Object> { new Account(Name = 'Same'), new Account(Name = 'Same') },
            'Other' => new List<Object> { new Account(Name = 'Other') }
        };

        Map<String, List<Object>> kept = Collection.ofMap(grouped)
            .filterGroup(new GroupSizeCondition(ComparationUtil.Comparators.GREATER_THAN, 1))
            .toListMap(Account.class);

        System.assertEquals(1, kept.size());
        System.assertEquals(true, kept.containsKey('Same'));
        System.assertEquals(2, kept.get('Same').size());
    }

    /** of() over a map iterates its keys - the values are ofMap()'s business, not of()'s */
    @isTest
    static void ofAMapIteratesItsKeys() {
        Map<String, List<Object>> grouped = new Map<String, List<Object>> {
            'Same' => new List<Object> { new Account(Name = 'Same') }
        };

        List<Object> keys = Collection.of(grouped).toList(String.class);

        System.assertEquals(1, keys.size());
        System.assertEquals('Same', keys[0]);
    }

    /** the collection form: keys as a Set, without building the map toMap() would have built */
    @isTest
    static void keySetReturnsTheKeysAsASet() {
        Set<String> keys = Collection.of(duplicatedNames()).groupBy(new GroupByName()).keySet();

        System.assertEquals(2, keys.size());
        System.assertEquals(true, keys.contains('Same'));
        System.assertEquals(true, keys.contains('Other'));
    }

    /** the collection form: one list per group, matching Map.values() */
    @isTest
    static void valuesReturnsTheMemberLists() {
        List<Object> values = Collection.of(duplicatedNames()).groupBy(new GroupByName()).values();

        System.assertEquals(2, values.size());
        System.assertEquals(2, ((List<Object>) values[0]).size());
        System.assertEquals(1, ((List<Object>) values[1]).size());
    }

    /** the pipeline form of keySet(), so the flat steps apply to the keys again */
    @isTest
    static void keySetLazyLeavesTheGroupedStream() {
        List<Object> keys = Collection.of(duplicatedNames())
            .groupBy(new GroupByName())
            .keySetLazy()
            .toList(String.class);

        System.assertEquals(2, keys.size());
        System.assertEquals(true, keys.contains('Same'));
        System.assertEquals(true, keys.contains('Other'));
    }

    /**
     * The whole point of leaving: filter the groups while they still carry their keys, then drop the grouping
     * and go back to records - valuesLazy() hands over the member lists, flat() turns them back into Accounts.
     */
    @isTest
    static void valuesLazyLeavesTheGroupedStreamAndFlattensBackToRecords() {
        List<Object> records = Collection.of(duplicatedNames())
            .groupBy(new GroupByName())
            .filterGroup(new GroupSizeCondition(ComparationUtil.Comparators.GREATER_THAN, 1))
            .valuesLazy()
            .flat()
            .toList(Account.class);

        System.assertEquals(2, records.size());
        System.assertEquals('Same', ((Account) records[0]).Name);
        System.assertEquals('Same', ((Account) records[1]).Name);
    }

    @isTest
    static void groupedMapTerminalsHandBackMembers() {
        Map<String, Object> keyed = Collection.of(duplicatedNames()).groupBy(new GroupByName()).toMap(Account.class);

        System.assertEquals(2, keyed.size());
        System.assertEquals(2, ((List<Object>) keyed.get('Same')).size());
    }

    @isTest
    static void groupedStreamSurvivesRepeatedHasNextAndReapplication() {
        LazyGroupByIterator grouped = Collection.of(duplicatedNames()).groupBy(new GroupByName());

        System.assertEquals(true, grouped.hasNext());
        System.assertEquals(true, grouped.hasNext());
        System.assertEquals(2, ((LazyGroupByIterator.KeyedGroup) grouped.next()).size());

        /** reapplication belongs to a template: it holds the steps, and apply() builds a fresh grouped pipeline on the new data */
        TemplateIterator reusable = Collection.template(new List<Object> { new GroupByName() });

        System.assertEquals(2, reusable.apply(duplicatedNames()).toListMap(Account.class).size());
    }

    /** a flat stream carries no key, so the grouping terminals refuse instead of collapsing to one entry */
    @isTest
    static void mapTerminalsRefuseAFlatStream() {
        Boolean refused = false;

        try {
            Collection.of(accounts()).toMap(Account.class);
        } catch (LeoSCollectionException e) {
            refused = true;
        }

        System.assert(refused, 'toMap() on a flat stream must name groupBy() rather than return a one-entry map');
    }

    @isTest
    static void toSetDeduplicatesAndToNonNullSetDropsNulls() {
        List<Object> values = new List<Object> { 1, 2, 2, 3, null };

        System.assertEquals(4, Collection.of(values).toSet(Integer.class).size());
        System.assertEquals(3, Collection.of(values).toNonNullSet(Integer.class).size());
    }

    @isTest
    static void pipelineCanBeReappliedToNewData() {
        TemplateIterator reusable = Collection.template(new List<Object> {
            new FlattenFunction(),
            new EmployeesAreOdd(),
            new SumEmployees()
        });

        List<Object> batch = new List<Object> { accounts(), null, new List<Account>() };
        List<Object> doubledBatch = new List<Object> { accounts(), accounts() };

        System.assertEquals(4, reusable.apply(batch).toValue());
        System.assertEquals(8, reusable.apply(doubledBatch).toValue());
        System.assertEquals(4, reusable.apply(batch).toValue());
    }

    @isTest
    static void filteringIsNotAffectedByPreviousApplications() {
        TemplateIterator reusable = Collection.template(new List<Object> { new EmployeesAreOdd() });

        List<Account> batch = accounts();

        System.assertEquals(2, reusable.apply(batch).toList(Account.class).size());
        System.assertEquals(2, reusable.apply(batch).toList(Account.class).size());
    }

    @isTest
    static void sortingOrdersAndDirections() {
        List<Integer> values = new List<Integer> { 4, 1, 3, 2 };

        System.assertEquals(new List<Integer> { 1, 2, 3, 4 }, Collection.of(values).sortBy().toList(Integer.class));
        System.assertEquals(new List<Integer> { 4, 3, 2, 1 }, Collection.of(values).sortBy(SortUtil.SORTING_ORDER.DESCENDING).toList(Integer.class));
        System.assertEquals(new List<Integer> { 1, 2, 3, 4 }, Collection.sortBy(values, new AnyComparator()).toList(Integer.class));
        System.assertEquals(new List<Integer> { 4, 3, 2, 1 }, Collection.sortBy(values, new AnyComparator().setDescending()).toList(Integer.class));
    }

    @isTest
    static void sortingPlacesNullsFirst() {
        List<Object> values = new List<Object> { null, 3, null, 1, 2 };

        System.assertEquals(new List<Object> { null, null, 1, 2, 3 }, Collection.of(values).sortBy().toList(Object.class));
    }

    @isTest
    static void sortByFieldSortsRecords() {
        List<Account> records = new List<Account> {
            new Account(Name = 'Gamma', NumberOfEmployees = 3),
            new Account(Name = 'Alpha', NumberOfEmployees = 1),
            new Account(Name = 'Beta', NumberOfEmployees = 2)
        };

        List<Object> ascending = Collection.of(records).sortBy(new SortByFieldFunction(Account.Name)).toList(Account.class);
        List<Object> descending = Collection.of(records).sortBy(new SortByFieldFunction(Account.Name).setDescending()).toList(Account.class);

        System.assertEquals('Alpha', ((Account) ascending[0]).Name);
        System.assertEquals('Gamma', ((Account) ascending[2]).Name);
        System.assertEquals('Gamma', ((Account) descending[0]).Name);
        System.assertEquals('Alpha', ((Account) descending[2]).Name);
    }

    @isTest
    static void pipeAppliesFunctionsInOrder() {
        List<Account> records = accounts();

        List<Object> result = Collection.pipe(records, new List<Object> {
            new FilterByCondition(Account.NumberOfEmployees, ComparationUtil.Comparators.NOT_EQUALS, 1),
            new SetValueFunction(Account.Name, 'Renamed'),
            new LimitToFunction(2)
        }).toList(Account.class);

        System.assertEquals(2, result.size());
        System.assertEquals('Renamed', ((Account) result[0]).Name);
        System.assertEquals('Renamed', ((Account) result[1]).Name);
    }

    @isTest
    static void transformAppliesMapFunction() {
        List<Object> result = Collection.of(accounts())
            .transform(new PickByFieldFunction(Account.NumberOfEmployees))
            .toList(Integer.class);

        System.assertEquals(new List<Integer> { 1, 2, 3, 4 }, result);
    }

    @isTest
    static void flatMapExpandsChildren() {
        List<Account> source = (List<Account>) JSON.deserialize(
            '[{"Name":"Acme","Contacts":{"totalSize":2,"done":true,"records":['
            + '{"attributes":{"type":"Contact"},"LastName":"One"},'
            + '{"attributes":{"type":"Contact"},"LastName":"Two"}]}}]',
            List<Account>.class
        );

        List<Object> contacts = Collection.flatMap(source, new PickListByFieldFunction(Contact.AccountId)).toList(Contact.class);

        System.assertEquals(2, contacts.size());
    }

    @isTest
    static void dmlUpdatePersistsTransformedRecords() {
        insert new List<Account> { new Account(Name = 'Before 1'), new Account(Name = 'Before 2') };

        List<Account> records = [SELECT Id, Name FROM Account];

        Collection.of(records)
            .transform(new SetValueFunction(Account.Name, 'After'))
            .dmlUpdate(new DefaultDmlUpdateFunction());

        for(Account updated : [SELECT Name FROM Account]) {
            System.assertEquals('After', updated.Name);
        }
    }

    @isTest
    static void queryFunctionReceivesUpstreamData() {
        insert new Account(Name = 'Queryable');

        List<Object> result = Collection.query(new FirstAccountQuery()).toList(Account.class);

        System.assertEquals(1, result.size());
        System.assertEquals('Queryable', ((Account) result[0]).Name);
    }

    @isTest
    static void forEachRunsSideEffectForEveryRecord() {
        List<Object> seen = new List<Object>();

        Collection.of(accounts()).forEach(new Collector(seen));

        System.assertEquals(4, seen.size());
    }

    private class Collector implements Function {
        private List<Object> collected;
        public Collector(List<Object> collected) {
            this.collected = collected;
        }
        public void call(Object record) {
            this.collected.add(record);
        }
    }

    private class NumberThem implements IndexedMapFunction {
        public Object mapValue(Object current, Integer index) {
            return index + ':' + ((Account) current).Name;
        }
    }

    /** Sorting used to happen only for terminal operations, so any step placed above it read the unsorted stream. */
    @isTest
    static void sortByIsHonouredByStepsAboveIt() {
        List<Integer> values = new List<Integer> { 4, 1, 3, 2 };

        System.assertEquals(new List<Object> { 1, 2, 3 }, Collection.of(values).sortBy().take(3).toList(Integer.class));
        System.assertEquals(new List<Object> { 4, 3 }, Collection.of(values).sortBy(SortUtil.SORTING_ORDER.DESCENDING).take(2).toList(Integer.class));
    }

    @isTest
    static void sortByIsHonouredByAFieldSortFollowedByTake() {
        List<Account> records = new List<Account> {
            new Account(Name = 'Gamma', NumberOfEmployees = 3),
            new Account(Name = 'Alpha', NumberOfEmployees = 1),
            new Account(Name = 'Beta', NumberOfEmployees = 2)
        };

        List<Object> firstTwo = Collection.of(records)
            .sortBy(new SortByFieldFunction(Account.Name))
            .take(2)
            .toList(Account.class);

        System.assertEquals('Alpha', ((Account) firstTwo[0]).Name);
        System.assertEquals('Beta', ((Account) firstTwo[1]).Name);
    }

    @isTest
    static void sortByHasNextIsIdempotentAndSurvivesReapplication() {
        LazyIterator sorted = Collection.of(new List<Integer> { 2, 1 }).sortBy();

        System.assertEquals(true, sorted.hasNext());
        System.assertEquals(true, sorted.hasNext());
        System.assertEquals(1, sorted.next());

        TemplateIterator reusable = Collection.template(new List<Object> { new AnyComparator() });
        System.assertEquals(new List<Object> { 1, 2 }, reusable.apply(new List<Integer> { 2, 1 }).toList(Integer.class));
        System.assertEquals(new List<Object> { 3, 4 }, reusable.apply(new List<Integer> { 4, 3 }).toList(Integer.class));
    }

    @isTest
    static void transformWithIndexSeesPosition() {
        List<Object> result = Collection.of(accounts()).transformWithIndex(new NumberThem()).toList(String.class);

        System.assertEquals(new List<Object> { '0:Alpha', '1:Beta', '2:Gamma', '3:Delta' }, result);
    }

    @isTest
    static void filterByFieldFunctionIsUsableWithoutEvaluate() {
        FilterByFieldFunction filter = new FilterByFieldFunction()
            .addFilterBy(Account.NumberOfEmployees, ComparationUtil.Comparators.GREATER_THAN, 2);

        List<Object> result = Collection.of(accounts()).filter(filter).toList(Account.class);

        System.assertEquals(2, result.size());
        System.assertEquals(3, ((Account) result[0]).NumberOfEmployees);
    }

    @isTest
    static void filterConditionFactoriesAgreeWithTheEnumForm() {
        List<Object> viaFactory = Collection.of(accounts())
            .filter(FilterByCondition.greaterThan(Account.NumberOfEmployees, 2))
            .toList(Account.class);

        List<Object> viaEnum = Collection.of(accounts())
            .filter(new FilterByCondition(Account.NumberOfEmployees, ComparationUtil.Comparators.GREATER_THAN, 2))
            .toList(Account.class);

        System.assertEquals(2, viaFactory.size());
        System.assertEquals(viaEnum.size(), viaFactory.size());
    }

    @isTest
    static void iteratorToCountFunctionCountsADelegatedIterator() {
        System.assertEquals(4, new IteratorToCountFunction().mapValue(Collection.of(accounts())));
    }

    @isTest
    static void emptyProducesAnEmptyResultInsteadOfANullPointer() {
        System.assertEquals(0, TestUtils.empty().toList(Account.class).size());
        System.assertEquals(0, TestUtils.empty().flat().toList(Account.class).size());
        System.assertEquals(true, TestUtils.empty().first() == null);
    }

    @isTest
    static void nullSourceNamesTheCallThatWasWrong() {
        Boolean ofThrown = false;

        try {
            Collection.of(null);
        } catch(LeoSCollectionException e) {
            ofThrown = true;
            System.assert(e.getMessage().contains('Collection.of(null)'));
        }

        Boolean applyThrown = false;

        try {
            Collection.template().apply(null);
        } catch(LeoSCollectionException e) {
            applyThrown = true;
        }

        System.assertEquals(true, ofThrown);
        System.assertEquals(true, applyThrown);
    }

    @isTest
    static void pipeNamesTheElementThatIsNotAPipelineStep() {
        Boolean thrown = false;

        try {
            Collection.of(accounts()).pipe(new List<Object> { new LimitToFunction(1), 'not a function' });
        } catch(LeoSCollectionException e) {
            thrown = true;
            System.assert(e.getMessage().contains('Element 1'));
        }

        System.assertEquals(true, thrown);
    }
}

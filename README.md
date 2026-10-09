# Leo SF Collection

For working on iterable Apex object (e.g. Lists) with lazy-evaluated functions.

[Realistic scenarios](./examples/scenarios) | [Configuration-driven pipelines](./examples/configurable) | [Ideas](./ideas) | [Full example script](./docs/examples.md)

## What it gives you

A lazy pipeline over any `Iterable` (lists, SOQL results, child relationships), with prebuilt
declarative building blocks so common SObject work does not need a hand-written function class:

| Purpose | Building blocks |
| --- | --- |
| Entry point | `Collection.of(...)`, `Collection.query(...)`, and `Collection.template(...)` for a pipeline that is applied to data later. `Collection.ofMap(...)` enters a map that is already grouped - `of(...)` over a map iterates its keys and drops the values |
| Filtering | `FilterByCondition`, `FilterByFieldFunction` |
| Combining conditions | `AndFunction`, `OrFunction`, `NotFunction` |
| Mapping | `PickByFieldFunction` (an SObject field, by token or by name) and `PickByKeyFunction` (a Map key), `SetValueFunction`, `SetValueFromFunction`, `SetMultipleValuesFunction`; `transformWithIndex` when the step depends on position |
| Relationship traversal | `PickListApplyFunction`, `PickListIsEmptyFunction` / `PickListIsNotEmptyFunction` (usable in `filter()` as well as `transform()`), `flatMap` |
| Aggregation | `ReduceFieldFunction.sum()` / `.min()` / `.max()` / `.average()`; `IteratorToReduceFunction` and `IteratorToCountFunction` roll a child list into a single value |
| Grouping and sorting | `GroupByFieldFunction`, `SortByFieldFunction` (the pipeline step) or `CompareByField` (the same comparison as a standalone strategy), `AnyComparator`; `groupBy` emits keyed groups, `filterGroup` (`GroupSizeCondition`) keeps only the groups that match — the predicate is carried and applied on read, so a `take()` above it stops early — and `keySet()` / `values()` read the keys or the member lists out as a collection while `keySetLazy()` / `valuesLazy()` leave the grouped stream for an ordinary pipeline |
| Terminal operations | `toList`, `toSet`, `toValue`, `count`, `first`, `find`, `some`, `every`; `toMap` / `toListMap` / `toDistinctList` key on a grouped stream |
| Effects | `forEach`, `execute`, `dmlUpdate`, `query` |
| Formula-driven steps | `FormulaFilterFunction` and `FormulaMapFunction` turn a `FormulaEval.FormulaInstance` into a filter or a mapper, so one class covers every rule whose logic is a formula instead of one class per rule. Built with Apex's own `Formula.builder()` - globals, template mode and the rest included, not re-implemented. Build the instance once and share it: `getReferencedFields()` names the inputs, so the same instance can shape a query's SELECT list and then process its rows - see [`FormulaForQueryAndProcessing`](./examples/scenarios/FormulaForQueryAndProcessing.cls) |
| Configuration-driven steps | `pipe()` applies a list of steps, and a step is a value - so a pipeline can be assembled from Custom Metadata instead of code. A new rule costs a metadata row rather than a class - see [`examples/configurable`](./examples/configurable) |
| Aggregate results | An aggregate is just a query: `Collection.query(...)` runs it and hands the rows back as a pipeline, so the aggregation stays in the query and only the shaping happens here. A row is a read-only SObject: a grouped field is read by token, an alias by name. `DeserializeToFunction` maps a row onto a DTO whose fields are named after the SOQL aliases, so the `(Integer) row.get('expr0')` casts disappear - see [`AggregateByCountry`](./examples/scenarios/AggregateByCountry.cls) |
| Errors | everything throws `LeoSCollectionException`, so a single `catch` covers the library |

Most steps returning a `LazyIterator` are lazy: no work happens until a terminal operation runs. The two that need every record before they can emit anything - `sortBy` and `groupBy` - do their work when they are called, not on the first read, so a pipeline carrying them pays that cost at the call site rather than as a stall inside an unrelated step.

```java
/** terminal operations return List<Object> - Apex erases generics on static methods, so cast once at the end */
List<Account> accounts = (List<Account>) Collection.of([SELECT Id, Name, NumberOfEmployees FROM Account])
    .filter(FilterByCondition.includes(Account.Name, 'Acme'))
    .transform(new SetValueFunction(Account.Phone, '+12 123-123-123'))
    .sortBy(new SortByFieldFunction(Account.Name))
    .toList(Account.class);
```

### Before you reach for this

The library pays off when a step is a **shape change** - flattening a relationship, grouping,
projecting one object onto another, rolling a child list into one value - over data already in hand.
It loses when a step is a per-record rule over plain data, because Apex has no lambdas and a
`BooleanFunction` then adds a class where an `if` was enough.

See [`NotEveryJobIsAPipeline.cls`](./examples/scenarios/NotEveryJobIsAPipeline.cls) for the job that
was deliberately written without the library, and [`docs/dx-review.md`](./docs/dx-review.md) for the
audit behind that rule.

#### When to use standard Salesforce instead

That rule is one case of a larger one: **if the platform can do it, let the platform do it.** Reach for
this library for the work that is left over after the query has done its part — never for work the
query could have done.

| The job | Do this instead |
| --- | --- |
| Filtering, ordering or limiting records that are in the database | `WHERE` / `ORDER BY` / `LIMIT` in the SOQL. The library cannot push a predicate down, so filtering after the query reads and discards rows the database could have skipped — and the row limit is spent before your filter runs. |
| Counting, summing, or aggregating across records | A SOQL aggregate query, `ROLLUP`, or a roll-up summary field. `ReduceFieldFunction` is for values already in memory, not a replacement for a roll-up the platform maintains for free. |
| A per-record rule over plain data (a number, a string, a boolean) | A plain `if`. A `BooleanFunction` adds a class where an `if` was enough — the cost this library cannot pay back. |
| Reshaping an inbound JSON or XML payload into typed objects | **DataWeave in Apex**, which exists for this: defaults, coercion and validation in one declarative script, rather than `JSON.deserialize` plus hand-written inner classes. Reasoning and caveats in [`docs/dx-review.md`](./docs/dx-review.md#dataweave-the-idea-that-changes-the-positioning). |
| Work over records the database cannot see yet | **This library.** `Trigger.new`, the rows of an import file, a payload just parsed — no SOQL reaches them, and that is where a lazy pipeline over data in hand earns its keep. |
| A named, reusable, data-driven shape change over records in hand | **This library.** Flattening a relationship, grouping by a field, projecting one object onto another, rolling a child list into one value — steps with a name, applicable to any number of data sets through a template's `apply()`. |

The honest summary: this library is for the gap the platform leaves, and that gap is smaller than a
collection API makes it look.

#### Limits found while writing the examples

Each of these was found by writing a realistic example and then trying to break it. They are the
reasons the examples above are the ones that exist.

| Limit | Consequence |
| --- | --- |
| The child-list steps (`PickListApplyFunction`, `flatMap(new PickByFieldFunction(rel))`) need a populated relationship, and `SObject.putSObjects()` does not exist - children can only be loaded by a query. | If the children are in the database, the aggregate the step computes is usually expressible as a SOQL aggregate too, and SOQL wins. What is left is the case where the query cannot express the rule, or the records are not in the database at all. |
| `ReduceFieldFunction` reads SObject fields (`reduceValue(Decimal, SObject)`). | There is no prebuilt reducer for plain or payload data, so `reduce` over a payload class needs a hand-written `ReduceFunction`. |
| `SetValueFromFunction(field, mapper)` hands the mapper the whole record, not the field value. | Pairing it with `RegexReplaceFunction` needs a `ComposeMapFunction` extractor in front, and there is no prebuilt step that applies a mapper conditionally on a null guard. |
| `toMap`, `toListMap` and `toDistinctList` need a key per element, which only a grouped stream - or a custom iterator overriding `nextKey()` - has. | They are terminals of the grouping family, not general-purpose conversions: on a flat stream they throw rather than quietly return a single-entry map. |
| `filterGroup` / `keySet()` / `values()` / `keySetLazy()` / `valuesLazy()` exist on `LazyGroupByIterator` only. | They are reachable after `groupBy()`, not on an arbitrary `LazyIterator`. `filterGroup` drops whole groups — it does not thin the members inside one. `keySet()` / `values()` hand back a collection (`toMap(...).keySet()` / `.values()` give the same set and list, but only after the map is built). `keySetLazy()` / `valuesLazy()` hand back a plain `LazyIterator`, so the grouped stream ends there — they are the form to chain on (`.valuesLazy().flat()`). |
| `ComparationUtil`'s `INCLUDES` / `NOT_INCLUDES` are dispatched before the null handling, so the value is stringified. | `includes(null, '@')` is false by luck; `includes(null, 'u')` is true. Prefer an explicit `NOT_EQUALS null`. |

Fork and inspiration from :

- https://nebulaconsulting.co.uk/insights/using-lazy-evaluation-to-write-salesforce-apex-code-without-for-loops
  Ideas for functions:
- https://ramdajs.com/docs/#promap
- https://laravel.com/docs/9.x/collections

### Open Ideas

- [implement ideas](./ideas)

### Iteration contract

Every `LazyIterator` honours the standard `Iterator` contract: `hasNext()` is idempotent and never
consumes an element, and the counter behind `take(n)` advances in `next()`, not in `hasNext()`.
Calling `hasNext()` any number of times before `next()` is safe. `next()` also works without a
preceding `hasNext()`.

A **template** is a pipeline with no source: it holds the steps and nothing else, so building one is a
deliberate act and it stays inert until `apply(data)` hands it a source. `apply()` rebuilds the pipeline
on the new data instead of mutating anything, so a template can be applied to any number of data sets,
in any order, and each application starts from a clean state:

```java
TemplateIterator reusable = Collection.template(new List<Object> {
    new FlattenFunction(),
    new FilterOddNumberOfAccountsIterator.NumberOfEmployeesIsOdd(),
    ReduceFieldFunction.sum(Account.NumberOfEmployees)
});

System.debug(reusable.apply(nestedAccounts).toValue());
System.debug(reusable.apply(nestedAccounts2).toValue());
/** still correct, because applying a template does not consume or corrupt it */
System.debug(reusable.apply(nestedAccounts).toValue());
```

A template's only step entry is `pipe(steps)` - every step is a value, and a list of values covers the
rest - so the step-by-step methods stay on the `LazyIterator` that actually runs.

### Tests

Apex tests live in `leoSFCollection/tests`. Run them against an org to verify the iteration
contract, comparator ordering and the SObject helpers:

```
sf apex run test --test-level RunLocalTests --wait 10 --result-format human --code-coverage
```

### TODO's:

- [DX review](./docs/dx-review.md) - audit of the API surface, with the fixes worth making (missing
  rollup functions, missing position access, and why the sort comparators were reduced to one)

- DataWeave in Apex: looked at as a way to get real lambdas, and rejected as an engine - the
  reasoning is in [the DX review](./docs/dx-review.md#dataweave-the-idea-that-changes-the-positioning).
  Worth revisiting only for payload shaping at the edge, and only after checking whether a trigger
  can call it.

- Fixes worth making, in the order they cost the reader something:
  - A `ReduceFunction` over plain values. `ReduceFieldFunction` reads SObject fields, so a payload
    class cannot be reduced at all.
  - `SetValueFromFunction` hands the mapper the record, not the field value, and nothing applies a
    mapper conditionally on a null guard. A `SetValueFromFunction(field, extractor, mapper)` shape, or
    an explicit note, would save the next reader the `ComposeMapFunction` detour.
  - A `sortBy(MapFunction keyExtractor)` overload. Sorting by a key would then cover
    `SortByFieldFunction` and `CompareByField` in one class, and a *computed* sort key - including one
    from a formula - would become possible at all.
- Namespace: `sfdx-project.json` has `"namespace": ""`, so the `public` constructors on `global` classes
  (`PickListApplyFunction`, `PickListIsEmptyFunction`, `PickListIsNotEmptyFunction`, `ConcatFunction`,
  `ConstantMapFunction`, `RegexReplaceFunction`) are reachable today. Adding a namespace before packaging
  makes every one of them unreachable from consumer code. `ContainerCreator` and `LazyIteratorInjector`
  are not `global` either.
- REVERT toMap / toListMap to have String as a key, because apex not works with casting...
- Refactor LazySortIterator, list of issues and proposals:
  - [Issue] equal value in sorting algorithm to fix issues with two field sorting (debug two functions sorting) - (SortByFieldFunction), sorting not working properly when we have to sorting methods applied to single
  - [Proposal]- implement logic to allow pass list of sorting functions instead of single
  - [Proposal] - remove LazySortIterator and replace its functionality with just method that sorts data and results with new LazyIterator that contains sorted data, it will be more predictable (as well can be implemented option to pass multiple sorting functions)
- universal Map iterable wrapper to allow transformation on maps
- append/prepend method to allow extending number of iterable elements (multiple iterable elements without losing performance),
- remove requirement for passing type to conversion method
- `dmlUpdate` and `query` make a pipeline impure; consider separating terminal effects from pure transformations

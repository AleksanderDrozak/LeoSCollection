# DX review

An audit of what makes this library pleasant or unpleasant to use, and what would make it genuinely
more useful. Written by attacking each proposal rather than by listing wishes — every idea below is
followed by the strongest objection to it and a verdict that sometimes rejects it.

## How this was produced

The method, applied to every proposal and to every example:

1. **Write the alternative for real.** Not "imperative equivalent: two loops" — the actual code. An
   asserted comparison is unfalsifiable, so it will always flatter. Written out, an example that
   duplicates what SOQL already does gives itself away in its first line.
2. **Then attack it.** Read as the skeptic whose goal is to reject it: "why not a `WHERE` clause,
   an `ORDER BY`, a formula field, a Flow?" A reading done from the persuasive side only confirms
   itself.
3. **Take the verdict.** Keep, fix, or delete. Including the deletions.

## The finding that matters most

Applying step 1 to the examples produced a consistent answer, and it is not flattering:

> **The library pays off when a step is a SHAPE CHANGE** — flattening a relationship, grouping,
> projecting one object onto another, rolling a child list into a single value. Apex has no lambdas,
> so every one of those needs a class either way, and the library's prebuilt classes are then free.
>
> **It loses when a step is a per-record rule over plain data.** `if(email != null)` needs no class
> in plain Apex, so wrapping it in a `BooleanFunction` adds an object and removes nothing.

Consequence for positioning: an example built on per-record rules makes the library look like
ceremony. An example built on shape changes makes the case by itself. The example set was rewritten
on that basis — four of five scenarios were deleted, and the replacement for them is
[`examples/scenarios/NotEveryJobIsAPipeline.cls`](../examples/scenarios/NotEveryJobIsAPipeline.cls).

## Correctness

### 1. `sortBy()` silently does nothing unless it is the last step

**Claim.** `LazySortByIterator` does its sorting inside `instance()`, which is only reached through
the `currentInstance` getter used by terminal operations. Chained operations wrap `this` and go
through the base `hasNext()`, which reads `this.iterator` — the unsorted upstream.

**Consequence.** `.sortBy(f).filter(...).toList(...)` filters the unsorted stream.
`.sortBy(f).take(2)` returns the first two unsorted records. No exception, no warning — a wrong
answer in the right shape.

**Attack.** Is it really reached? `LazySortByIterator` overrides `instance()` but not `hasNext()`, so
any wrapper placed on top of it consumes the unsorted stream. Verified by reading; the README TODO
already suspected it ("remove LazySortIterator … it will be more predictable").

**Verdict — fix, and it simplifies the code.** Implement what the TODO proposes: make `sortBy()`
materialise and return a plain `LazyIterator` holding the sorted list. That deletes the bug, and
with it `instance()`, `currentInstance`, `LazySortWrapperIterator` and the `SortingWrapper`-as-
`WrapperFunction` trick. A silent wrong-answer bug whose removal *shrinks* the class is the best
kind of fix available here.

### 1b. The typed comparators are gone — `AnyComparator` is the only comparator

**Claim.** `NumberComparator` and `StringComparator` routed through
`ComparatorBase.compare(Boolean isBigger)`, which returned `compareTrueValue` or its negation — `1` or
`-1`, never `0`. Equal values therefore compared as *less than*, breaking the antisymmetry a
`compareTo` contract requires. `DateComparator` additionally cast its arguments to `DateTime`, while
the type map bound `Date.class` to it — so sorting by a `Date` field threw at runtime.
`AnyComparator` was already correct: it goes through `ComparationUtil.compare`, which returns a
genuine `0` and orders nulls.

**Why the extra comparators never paid off.** They were reachable from exactly one place —
`SobjectByFieldComparator(field, fieldType)`, which looked the type up in
`ComparatorsConstants.COMPARABLE_TYPE_MAPPING` and fell back to `AnyComparator` when it was not in the
map (the comment said "slower about 20% in average"). So reaching the faster path required the caller
to *know* the field type, and when they did not, the library quietly used the other one — the correct
one. The mechanism shaved a constant factor off the comparison step, one small part of a sort, in
exchange for a class per type, a cast that could disagree with the runtime type, and a comparison that
never reported equality. That is the wrong trade in either direction: it is not worth a class to save
a constant factor, and it is certainly not worth *correctness*.

**Verdict — deleted, not documented.** `NumberComparator`, `StringComparator`, `DateComparator` and
`ComparatorsConstants` are gone. The field read and comparison that `SobjectByFieldComparator`
performed now live in `CompareByField`, and `SortByFieldFunction` holds no comparison of its own — it
extends `CompareByField` and adds nothing but the name. Two names for one behaviour, on purpose: the
step reads as a step and the comparator reads as a comparator, and `CompareByField` is `virtual` so
that second name can exist at all. The split is the point: `CompareByField` is the strategy,
named for what it does, and `SortByFieldFunction` is the step, named for where it is used, in the same
family as `FilterByFieldFunction` and `GroupByFieldFunction`. Both take just the field, so
`SortByFieldFunction(Account.Name, String.class)` became `SortByFieldFunction(Account.Name)` — and
`SobjectByFieldComparator` with it.
`ComparatorBase` lost `compare(Boolean)` and the duplicate field behind it — direction is applied in
one place now — and `SortUtil` lost the true-value map that fed only that helper. Four classes fewer
overall, and no path left where the caller has to name a type the library can see for itself.

The materialising `LazySortByIterator` was never the problem: a sort cannot emit anything before it
has seen every element, so buffering is correct by necessity, and its output type is honest (the same
records, in a new order) — unlike `groupBy` in #10. Both buffers now fill in the constructor, at the
`sortBy()` / `groupBy()` call, rather than on the first read: the barrier is the same, but the caller
pays for it where they asked for it instead of inside an unrelated `hasNext()`.

Multi-key sorting still wants a composite comparator over an ordered list of `SortByFunction` that
returns the first non-zero — what the README TODO asks for. That work is unchanged; what changed is
that a plain chained sort is now *valid* rather than merely lucky, because ties are reported as ties.

### 2. `apply()` shares the caller's function instances, so stateful functions leak between runs

**Claim.** Rebuilding a pipeline on new data reuses the same function objects. A user function that
counts (`ReduceFieldFunction.processedCount`) carries its state into the next run.

**Attack.** The library cannot clone arbitrary user objects, so it cannot prevent this. True — but
it can stop *requiring* it. The count in `ReduceFieldFunction` exists only because `reduceValue` is
never told how far along the stream it is.

**Verdict — the concept moved; the cause is still #9.** Reuse used to live on `LazyIterator` itself:
every node carried a `withSource()`, and the base `apply()` called it, so any pipeline could be
reapplied and any stateful function could leak. Reuse is now its own type — `Collection.template(steps)`
returns a `TemplateIterator` that holds the steps and no data, and `apply()` rebuilds from the source
each time — so a pipeline that runs now cannot be silently reapplied, and a function is only ever
shared when the caller deliberately built a template. Templates still share the instances, so the rule
"write stateless functions" stands for them. The real fix is #9 below: pass the position, and the
stateful function disappears for the common cases. `ReduceFieldFunction` was patched to reset its
counter in `getInitialValue()`, a per-class workaround for a library-wide rule.

## API surface

### 3. `FilterByFieldFunction` is not a `BooleanFunction`

**Claim.** The class name says filter, but `.filter(new FilterByFieldFunction()…)` does not compile:
you must call `.evaluate()`. Every reader hits this once.

**Attack.** `.evaluate()` makes composition explicit, and hiding a build step inside `isTrueFor`
means accidentally rebuilding the `And` chain per record if it is not cached.

**Verdict — fix, with the cache.** `implements BooleanFunction`, building the chain lazily into a
private field on first `isTrueFor`, with `evaluate()` kept for callers who want it explicit. About
eight lines, and it removes a compile error that has no useful message.

### 4. `FilterByCondition` is verbose at every call site

**Claim.** `new FilterByCondition(Account.Name, ComparationUtil.Comparators.INCLUDES, 'Acme')` — the
fully qualified enum is 36 characters, and it appears in every filter.

**Attack.** Static factories duplicate the constructor; two ways to do one thing.

**Verdict — fix.** The duplication is trivial and the readability is not: `.includes(Account.Name,
'Acme')` reads as the sentence it is. Add `equalsTo`, `notEquals`, `greaterThan`,
`lessThan`, `includes` as static factories, purely additive, nothing removed.

### 5. One catchable exception type

**Claim.** The library throws `FilterByFieldFunctionException`, `ReduceFieldFunctionException`,
`ComparationException`, `LazyIteratorInjectorException` — and the last one is declared with no
modifier, so it is private and a consumer cannot name it in a `catch` at all, even though it comes
out of `pipe()`, which is public API.

**Attack.** Granular types let callers handle cases differently.

**Verdict — fix.** Nobody catches these separately; they catch "the library failed". Add
`global class LeoSCollectionException extends Exception` and make every existing type extend it, so
one `catch` covers the surface, while the specific types stay available. Also correct
`LazyIteratorInjectorException`'s visibility — a private class escaping through a public method is
a plain mistake.

### 6. `pipe()` reports a bad element without saying which one

**Claim.** A wrong type in the function list fails at runtime with a message that never says which
element was wrong: `'Not implemented function type!' + String.valueOf(function)`. It also leans on
`String.valueOf`, which may print something unhelpful for a function object.

**Attack.** Apex cannot type-check a heterogeneous `List<Object>`, so a runtime failure is
unavoidable.

**Verdict — fix the message.** Unavoidable failure is not the same as an unhelpful failure. Include
the index and the actual type name: `'Element 3 of the pipe is a FilterByCondition, which is not a
map function (expected MapFunction, BooleanFunction, …)'`. Three lines; converts a puzzle into an
instruction.

### 7. Every terminal operation needs a cast

**Claim.** `toList(Type)` returns `List<Object>`, so call sites read
`(List<Contact>) ….toList(Contact.class)`. The README's own example omits the cast.

**Attack.** Apex erases generics on static methods; a typed return is not expressible. Correct — the
library cannot fix this.

**Verdict — document, do not code.** Fix the README's example to show the cast, and say once why it
is needed. A documented limitation costs nothing; an undocumented one is a compile error every new
user hits.

## Capability gaps

### 8. You cannot roll up a child list with the prebuilt classes

**Claim.** `PickListApplyFunction` needs an `IteratorToFunction`, and the family is
`IteratorToValueFunction`, `IteratorToIsEmpty`, `IteratorToIsNotEmpty`. There is no
`IteratorToReduceFunction` and no `IteratorToCountFunction`. So the headline shape change — roll a
child list into one number — requires the user to write their own `IteratorToFunction` subclass.
`ReduceFieldFunction` is unreachable from `PickListApplyFunction` as shipped.

**Attack.** Rollups are usually pushdownable to a SOQL aggregate, so the gap is narrower than it
looks.

**Verdict — fix anyway.** It is the library's own idiom, it is about eight lines per class, and the
README currently advertises "Aggregation" in the feature table with `ReduceFieldFunction` — which
only works on a flat numeric stream, not on the relationship case people actually reach for. Two
small classes make the advertised feature true.

### 9. No position in `map` or `filter`, so position-dependent steps force stateful functions

**Claim.** Round-robin assignment, numbering, "every other element" — all need the index, and the
library offers none. The workaround is a `MapFunction` holding a counter, which is exactly the
stateful function that leaks across `apply()` (see #2).

**Attack.** New interfaces grow the surface, and the case is not that common.

**Verdict — fix.** It is one narrow interface (`IndexedMapFunction { Object mapValue(Object o,
Integer index); }`) plus one method, and it removes the entire class of stateful-function
landmines rather than documenting them. The leak in #2 is a symptom of this gap, so fixing it here
is cheaper than the documentation it replaces.

### 10. No step that filters groups

**Claim.** `groupBy(...).toListMap(...)` hands back every group, and there is no way to keep only
the groups that matter. Both a hand-written loop and a documented gap appear in
[`DuplicateContactsInBatch`](../examples/scenarios/DuplicateContactsInBatch.cls).

**Attack.** A general "operations on groups" API is a real design project and would dwarf the rest
of the library.

**Verdict — reverted on the author's objection. The narrow fix was in the wrong place.**

The first verdict here was to add `toListMap(Type dataType, BooleanFunction groupFilter)`, and it was
implemented. The author then rejected it, and the objection is the correct one: the overload mixes the
two concepts the library is built on — a **step** (a function) and an **executor** (a terminal
operation). Everything else in the API obeys the split: functions are pipeline steps that return a
`LazyIterator`, and terminal operations only materialise. `every`/`some`/`find` take a
`BooleanFunction`, but they are *queries* that answer a question — they are not materialisers being
handed a filtering step. `toListMap` is a materialiser, so taking a predicate made one method do two
jobs, and the capability was bought at the cost of the rule.

The deeper diagnosis, which the version above only papered over: **the missing capability is not a
missing method.** A group filter is not expressible as the ordinary `filter` step because `groupBy`
does not emit groups — it emits a flat stream of records annotated with `nextKey()`. `filter` after
`groupBy` therefore filters individual records, not groups. So the obstacle is what `groupBy` produces,
and the only fix that respects the step/executor split is a **step** that materialises the keyed stream
into groups, keeps the ones that match, and re-emits keyed records — the same materialise-at-the-call
shape now used by `sortBy`:

```
Collection.of(incoming)
    .filter(FilterByCondition.includes(Contact.Email, '@'))
    .groupBy(new GroupByFieldFunction(Contact.Email))
    .filterGroup(new GroupSizeCondition(ComparationUtil.Comparators.GREATER_THAN, 1))   // a step, not a terminal argument
    .toListMap(Contact.class);
```

That is the shape the fix took: **implemented**, on the author's instruction to make `groupBy` return
something that says what it really is. Two findings came out of doing it that the diagnosis above only
half saw.

**Finding one: the key did not survive any step placed above `groupBy`.** `nextKey()` lives on the
iterator, not on the element, and only `LazyGroupByIterator` implemented it — every other node fell
through to the base, which returned the literal `'key'` (it now throws, naming `groupBy` as the step
that was left out, so the same mistake is loud instead of a one-entry map). So
`.groupBy(…).filter(…).toListMap(…)`, and
equally `.take(…)` or `.sortBy(…)`, quietly put every record into a single bucket named `'key'`. Wrong
answer, no exception — the same family as the `sortBy` bug in #1.

Propagating the key through the wrappers instead is not possible: `LazyFilterIterator` peeks by
consuming its upstream, so by the time a terminal asks for a key the upstream has already advanced past
the element that terminal is about to receive. A key that has to survive arbitrary composition must be
part of the element. That is what `groupBy` now emits — a `KeyedGroup` holding the key and its members,
which no step can lose.

**Finding two: `filter` is the wrong name for the group step, even though it is the right idea.** The
step is not a `filter` override. A predicate meaning "per record" at one position and "per group" at
another would make the step's meaning depend on where it sits in the chain, which is precisely the
positional magic this exercise exists to remove. A named step says what it does, so its meaning cannot
drift — and it keeps the change off `LazyIterator`, since overriding `filter` would have needed a
covariant return type that cannot be verified without an org.

The predicate receives the group, not one half of it. An earlier pass split the step in two — `filterKey`
over the key, `filterValue` over the members — and that was wrong twice over. `filterValue` read as "thin
the values inside each group" but did no such thing: it dropped whole groups, so from the result's side
it was choosing which keys survived, and its name described the predicate's input rather than the step's
effect. And with the group in hand the split bought nothing: `filterGroup(g -> g.key().startsWith('A'))`
is the key rule, `new GroupSizeCondition(...)` is the member rule, same call. One method, no reader
having to work out which half they are looking at.

It is also lazy, and unlike `groupBy` that is a choice rather than a necessity: the predicate is carried
and applied in `hasNext()`/`next()`/`nextKey()`, sharing the parent's bucket instead of building a
filtered copy of it. So a `take()` or `first()` above the filter stops as soon as it has what it asked
for. Two calls compose into one `AndFunction` rather than a chain of iterators. The terminals
(`toListMap`, `toMap`, `keySet`, `values`) cannot defer — they hand back a collection — so they apply
the predicate to the bucket without consuming the iterator or moving its position.

The boundary, stated rather than left to be discovered: after `groupBy` the stream carries groups, and
the steps that keep that shape are `filterGroup` and the map terminals (`toListMap`, `toMap`,
`toDistinctList` — `toDistinctList` is `toMap(...).values()`, so it follows for free). A record-shaped
step above `groupBy` — `transform`, `take`, `sortBy` — leaves grouped land and yields a plain
`LazyIterator` over groups, where the typed container in `ContainerCreator` turns the mistake into a
`TypeException` rather than a wrong answer. Loud beats silent, but `take` is the obvious next candidate
for staying grouped if the author wants it.

Leaving grouped land is also a deliberate step rather than a side effect, and it comes in two forms
rather than one. `keySet()` and `values()` are the collection form, mirroring `Map.keySet()` /
`Map.values()`: the keys as a `Set<String>`, the member lists as a `List<Object>`. They read the groups
straight through, where `toMap(...).keySet()` would build the whole map first.

`keySetLazy()` and `valuesLazy()` are the same two things as a plain `LazyIterator` — over the keys, or
over each group's members as one element — so `.valuesLazy().flat()` turns the groups back into the
records they were made of, and the flat steps (`filter`, `toList`) apply again. The suffix is a wart:
nothing else in the library names a method after its laziness, because everything else is lazy already.
It is here because these two sit next to the collection forms and the return type is the only thing
telling them apart.

[`DuplicateContactsInBatch`](../examples/scenarios/DuplicateContactsInBatch.cls) is now the four-step
chain above, with no hand-written loop and no gap to apologise for.

Worth keeping in mind generally: this is the second time in this audit that a "small additive fix"
turned out to be load-bearing on a design rule. Adding a parameter to an existing method is cheap to
write and expensive to live with — and in both cases the honest fix turned out to change what the step
*produces*, not what it accepts.

### 11. `toListMap(keyType, dataType)` is private, so keys are always `String`

**Claim.** The public overloads hardcode `String.class`. The README TODO already records that
grouping by a non-String key misbehaves — calling `toListMap(Case.class)` silently gives you
`Map<String, …>` whose keys are stringified.

**Attack.** Apex cannot produce a `Map<Case, List<Object>>` from a generic method anyway.

**Verdict — retracted while implementing: document, do not publish the overload.** The first verdict
here said to make the two-type overload public. Re-running the attack against the implementation
killed it: `ContainerCreator.getMapOfLists(keyType, dataType)` really does build
`Map<keyType, List<dataType>>`, so for a non-String key a `Map<Case, List<Object>>` is created and
the declared `Map<String, …>` return can only fail on the cast. Publishing it would ship a method
whose sole documented behaviour is throwing on the input it exists to accept. The typing cannot be
fixed in Apex, so the honest change is documentation — which the README TODO already carries.

### 12. Rejected: a general-purpose string/value function suite

**Proposal.** Add lowercase, trim, substring, pad-left `MapFunction`s so expressions like the
case-sensitive email grouping in `DuplicateContactsInBatch` have a built-in answer.

**Attack.** The set is unbounded. Every one of these is a two-line class over an existing `String`
method, and the library already ships `RegexReplaceFunction` as the worked example of how to write
one.

**Verdict — reject.** Writing a small `MapFunction` is the intended extension path, and it is
already cheap. A partial string utility suite would be a promise the library cannot keep, and it
would obscure the interfaces it is actually about.

## Project

### 13. The examples are debug scripts, so they rot silently

**Claim.** `docs/examples.md` is ~530 lines of `System.debug`, mirrored a second time in
`scripts/examples-to-run-after-deploy.apex`. Nothing fails when the API changes; the snippets just
quietly stop being true. The two copies were already synced by hand once during this work.

**Attack.** Converting them to assertions means owning expected values.

**Verdict — adopt, highest leverage change here.** Collapse the two copies into one class of
`@isTest` methods that assert. It becomes executable documentation, it catches drift, and it counts
toward the 75% coverage an unlocked package version needs. Apex already forces the test harness to
exist; the examples may as well live inside it.

**Deferred, with the reason.** Half of this shipped: the behaviour the examples were demonstrating —
sorting order under chaining, group filtering, position access, the null-source guards — is now
asserted in `leoSFCollection/tests/LazyIteratorTest.cls`, so those particular snippets can no longer
rot silently. The full conversion did not ship, and should not be attempted blind: it is a
five-hundred-line rewrite of `System.debug` into assertions with expected values I cannot verify,
against a harness that is currently *working* for its actual purpose (`examples-to-run-after-deploy`
is pasted into anonymous Apex and read from the debug log). Trading a working tool for an
uncompilable one to satisfy a documentation item is the wrong trade. Convert it in the org, where
each assertion can be run as it is written; the tests added here are the model to follow.

## Positioning

### 14. The README does not say when not to use the library

**Claim.** Every example shows the library winning. A reader who has been burned by over-abstraction
reads that as a sales pitch, and they are right to — the losing cases are real and common (see the
finding at the top).

**Attack.** Admitting limits loses adopters.

**Verdict — adopt.** The limits are discoverable in ten minutes of real use, so hiding them buys
nothing and costs credibility. Add a "when this pays off / when it does not" section to the README,
anchored on `NotEveryJobIsAPipeline`, plus the two-line rule from the top of this document. This is
most likely to increase the library's real-world usefulness, because the expensive failure is not
"nobody adopts it" — it is "somebody adopts it for the wrong job and blames the library".

**Implemented**, and taken further than the verdict asked. The author's instruction was to state when
to use DataWeave — or anything else standard — instead of this library, on the principle *if the
platform can do it, let the platform do it*. The README now carries a `When to use standard Salesforce
instead` table: SOQL `WHERE`/`ORDER BY`/`LIMIT` for query-shaped filtering and ordering, SOQL aggregates
and roll-ups for aggregation, a plain `if` for per-record rules over plain data, DataWeave for inbound
payload shaping — and the two rows that are actually this library's job, both of them work over data
the database cannot see yet or a named shape change applied to many data sets. It closes on the line
that matters: the library is for the gap the platform leaves, and that gap is smaller than a collection
API makes it look.

## What the fixes did to the audit

Three things changed while implementing, and they are worth recording because they are the method
working rather than the method being right the first time.

- **#11 was wrong and is now retracted** (see above). An attack that only reads prose can still
  endorse a method that throws.
- **#1 shrank the surface instead of growing it.** Fixing `sortBy` deleted `instance()`,
  `currentInstance`, `LazySortWrapperIterator`, and `SortingWrapper`'s second role as a
  `WrapperFunction`. Removing `instance()` was only safe because a grep showed exactly one
  override — worth doing before deleting anything virtual.
- **Two more silent NPEs turned up in the same family.** The empty seed for a reusable pipeline (then
  `Collection.nil()`, since removed when reuse moved to `Collection.template()`) built a `LazyIterator`
  with a null iterator, so `toList(X)` on it threw a bare NPE; the no-arg `LazyIterator()` constructor
  had the same hole; and
  `Collection.of(null)` failed inside a cast with a message naming neither the method nor the
  argument. All three are the same mistake — treating "no data" as "no iterator" — so all three now
  seed an empty source or throw a `LeoSCollectionException` that says which call was wrong.
- **One visibility finding was wrong too.** `ComparatorsConstants`, `ComposeMapFunction` (then named
  `ReduceMapFunction`),
  `LazyGroupByIterator` and `LazyLimitIterator` are `public` rather than `global`, which in an
  unlocked package means unreachable from outside. Most of that list is not worth acting on:
  `ComparatorsConstants` was a candidate for *deletion* per the README, so promoting it would have
  been preparing a funeral — it has since been deleted outright (see #1b), and the two lazy iterators
  are only ever returned as `LazyIterator`. `ComposeMapFunction` was the real one — it appears in
  `docs/examples.md` as consumer-facing API — and is now `global`.

## DataWeave: the idea that changes the positioning

**Proposal.** Write the per-record logic as MuleSoft DataWeave scripts (`.dwl`), ship them with the
package, and drive them from Apex — so the library finally gets the one thing Apex cannot give it:
real lambdas. `filter $.numberOfEmployees > 10` in a script, instead of a `BooleanFunction` class.

The premise is correct, which is why it deserves a real answer rather than a dismissal. The weakness
this library keeps running into is that Apex has no lambdas, so every predicate and every mapper
costs a class. DataWeave is a language whose entire purpose is lambdas over collections — `filter`,
`map`, `groupBy`, `orderBy`, `distinctBy`, `pluck`. It is the missing piece, stated plainly.

**Attack.**

- **It lifts no Apex limit.** DataWeave scripts run in Salesforce application servers and are subject
  to the same heap and CPU limits as Apex. If the goal was "where Apex limited me", this is not it:
  it is the same transaction, behind another runtime.
- **It is a competitor, not an extension.** If a whole pipeline fits in one `.dwl` script, then
  `filter` / `map` / `groupBy` / `sortBy` — the library's entire answer to "no lambdas" — are the
  parts DataWeave replaces, with better syntax and no classes. Adopting it would not grow this
  library; it would hollow out the region of it that exists to work around a limitation DataWeave
  does not have. That is the honest reading, and it argues against building this.
- **It cannot be lazy.** `execute()` takes a payload and returns a value. Laziness is the library's
  identity. A DataWeave step can therefore sit only at the ends of a pipeline, never inside one.
  This is structural, not an implementation detail.
- **Custom modules cannot be imported**, so scripts cannot be composed into a reusable library of
  small named steps — each script must be a whole transform. "Generic scripts, dynamically reused"
  therefore means *selecting* a script by name and *parameterising* its inputs, not composing logic.
- **It moves failures away from compile time.** `createScript('name')` binds by string at runtime, so
  renaming a script becomes a runtime error instead of a deploy failure, and a bad script surfaces as
  `System.DataWeaveScriptException` — a Mule error, with no Apex stack trace. A library sold on
  predictability should be reluctant to trade compile-time safety for nicer syntax.
- **SObjects do not survive the trip cleanly.** Scripts operate on generic maps and lists, so records
  are serialised in and out, losing typed field access and paying conversion on both sides — awkward
  exactly in the SObject case this library exists for.
- **Version skew is silent.** The DataWeave language version follows the script's API version
  (2.5 at API 61.0, 2.8 at 62.0, 2.9 at 63.0+), and this package is on 60.0. A feature from a current
  blog post will not resolve, with nothing on the Apex side to say why.

**Verdict — do not adopt it as an engine; keep it as a documented boundary.** A DataWeave-backed
pipeline would replace this library's core with a worse-typed, non-lazy, harder-to-debug version of
the same idea. What survives the attack is narrow and real: DataWeave is genuinely excellent at the
*edge* problem — reshaping an inbound JSON payload into typed objects, with defaults, coercion and
validation in one declarative script. That is exactly the job `WebhookOrderIntake` currently does
with `JSON.deserialize` and hand-written inner classes. The right move is therefore to name the seam
in the README — pipeline and iteration on this side, payload shaping on the other — and, if an
adapter is ever added, to add exactly one terminal step (`run this named script over the whole
payload`), never a pipeline operator.

**Follow-up: could DataWeave be an inject — a few templates plus dynamic variables?** Partly, and the
part that works is not the part that would have helped.

- **Deployed templates with dynamic inputs are real.** `DataWeave.Script.createScript('name')` resolves
  a `.dwl` that exists as metadata, and `execute(Map<String, Object>)` takes named inputs. Several
  scripts — a pivot, a group-by-field, a payload normaliser — each parameterised by field names, a
  threshold or an options map, is a working design.
- **Runtime-authored logic is impossible.** `createScript` takes a *name*, not source. There is no way
  to compile DataWeave from a string at runtime, so "dynamic scripts" can only ever mean *selecting*
  among deployed scripts, never generating logic. The `DataWeaveScriptResource` inner class generated
  per script confirms the bind-by-name shape.
- **Composition is the casualty.** Custom modules cannot be imported, so templates cannot call each
  other. A library of small reusable named steps — the thing that would make this feel like *this*
  library — cannot be built in DataWeave at all.
- **A DataWeave node is structurally possible but does not earn its place.** It would materialise the
  upstream, `execute(...)` the whole payload, then iterate the result — the same
  materialise-on-first-read shape `sortBy` and `groupBy` use. That part is implementable. But it cannot
  be a per-element `MapFunction` (one Mule invocation per record), so it could only ever sit at an end,
  and it buys worse typing and worse debugging for syntax the caller cannot author at runtime anyway.

So: parameterised deployed templates are real, runtime-authored dynamic scripts are not, and the path
leads back to the verdict above — name the seam in the README, do not build an engine.

**Not verified.** The Salesforce documentation site returns HTTP 403 to this environment, so the API
shape, the limitation list and the version table above come from search results and a Salesforce
Stack Exchange answer rather than from the primary source, and none of it has been compiled or run.
In particular, whether DataWeave can be invoked from a trigger is *not* settled by anything I read —
if it cannot, this idea is dead for the library's flagship scenario, which is the trigger case. That
question has to be answered first-hand before a line of this is built.

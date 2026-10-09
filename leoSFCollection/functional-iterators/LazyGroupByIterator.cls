@SuppressWarnings('PMD.AvoidGlobalModifier')
global class LazyGroupByIterator extends LazyIterator {

    /**
     * A key together with its members. groupBy hands one of these over per group, because a group has no
     * honest record shape: the key cannot live on the side of the stream without being lost by every step
     * that buffers or peeks, and it is not a field of the record either.
     */
    global class KeyedGroup {

        private String key;
        private List<Object> members;

        global KeyedGroup(String key, List<Object> members) {
            this.key = key;
            this.members = members;
        }

        global String key() {
            return this.key;
        }

        global List<Object> members() {
            return this.members;
        }

        global Integer size() {
            return this.members.size();
        }
    }

    private List<KeyedGroup> groups;
    private BooleanFunction groupPredicate;
    private Integer position = 0;

    /**
     * The bucketing runs here, when groupBy() is called, rather than on the first read. A group cannot be
     * emitted before its last member has been seen, so deferring the work bought nothing - it only moved the
     * cost into hasNext(), where it turned up as a stall on an unrelated call. Bucketing at the call makes
     * the barrier the caller's decision instead of a surprise.
     */
    public LazyGroupByIterator(Iterator<Object> iterator, GroupByFunction groupingFunction) {
        super(iterator);
        this.groups = this.bucket(iterator, groupingFunction);
    }

    /**
     * Built from a map that is already grouped, so there is nothing to bucket: each entry is a key and its
     * members. The keys are read once, in the map's own iteration order, so the groups come out in the same
     * order every time this iterator is walked.
     */
    public LazyGroupByIterator(Map<String, List<Object>> grouped) {

        super(new List<Object>());

        List<KeyedGroup> built = new List<KeyedGroup>();

        for(String key : grouped.keySet()) {
            built.add(new KeyedGroup(key, grouped.get(key)));
        }

        this.groups = built;
    }

    /**
     * Shares the parent's already-bucketed groups and carries a predicate instead of a filtered copy of them:
     * nothing is tested until a read asks for it, so take() or first() above the filter stops as soon as it
     * has what it asked for. The predicate is null when there is nothing to filter, which is the common case.
     */
    private LazyGroupByIterator(List<KeyedGroup> groups, BooleanFunction groupPredicate) {
        super(new List<Object>());
        this.groups = groups;
        this.groupPredicate = groupPredicate;
    }

    private List<KeyedGroup> bucket(Iterator<Object> iterator, GroupByFunction groupingFunction) {

        Map<String, List<Object>> buckets = new Map<String, List<Object>>();
        List<String> keys = new List<String>();

        while(iterator.hasNext()) {
            Object record = iterator.next();
            String key = groupingFunction.getGroupKey(record);

            if(!buckets.containsKey(key)) {
                buckets.put(key, new List<Object>());
                keys.add(key);
            }

            buckets.get(key).add(record);
        }

        List<KeyedGroup> built = new List<KeyedGroup>();

        for(String key : keys) {
            built.add(new KeyedGroup(key, buckets.get(key)));
        }

        return built;
    }

    global override Boolean hasNext() {
        this.advanceToMatch();
        return this.position < this.groups.size();
    }

    global override Object next() {
        this.advanceToMatch();
        KeyedGroup current = this.groups[this.position];
        this.position++;
        return current;
    }

    /** a grouped stream does carry a key per element, so the map terminals answer with the group key */
    global override String nextKey() {
        this.advanceToMatch();
        return this.groups[this.position].key();
    }

    /**
     * Steps over the groups the predicate rejected. Idempotent - it stops on the first match, so a repeated
     * hasNext() does not move past it - and that is what keeps nextKey() honest: a terminal reading the key
     * always reads it off a group this iterator would actually emit.
     */
    private void advanceToMatch() {

        while(this.groupPredicate != null
              && this.position < this.groups.size()
              && !this.groupPredicate.isTrueFor(this.groups[this.position])) {
            this.position++;
        }
    }

    /**
     * The groups this iterator will emit, in order - the predicate applied, without consuming the iterator or
     * moving its position. The terminals answer from this rather than from the raw bucket, so what they return
     * is what the pipeline promised.
     */
    private List<KeyedGroup> matchingGroups() {

        if(this.groupPredicate == null) {
            return this.groups;
        }

        List<KeyedGroup> matched = new List<KeyedGroup>();

        for(KeyedGroup keyedGroup : this.groups) {
            if(this.groupPredicate.isTrueFor(keyedGroup)) {
                matched.add(keyedGroup);
            }
        }

        return matched;
    }

    /**
     * Keeps only the groups that satisfy the predicate, and stays grouped so the key keeps travelling with
     * them. The predicate receives the group itself - key and members together - rather than one or the other:
     * a rule that reads the key and a rule that reads the members are the same call, and neither needs the
     * reader to work out which one they are looking at. Conditions compose - each call narrows what the
     * previous one left. It drops whole groups; it does not thin the members inside one.
     *
     * Nothing is filtered here. The predicate is carried and applied on read, so a take() or first() above it
     * stops as soon as it has what it asked for, and two calls compose into one predicate rather than a chain
     * of iterators.
     */
    global LazyGroupByIterator filterGroup(BooleanFunction groupPredicate) {

        BooleanFunction combined = this.groupPredicate == null
            ? groupPredicate
            : new AndFunction(this.groupPredicate, groupPredicate);

        return new LazyGroupByIterator(this.groups, combined);
    }

    /**
     * The keys as a collection, mirroring Map.keySet(). toMap(...).keySet() gives the same set, but only after
     * building the map; this one reads the groups straight through.
     */
    global Set<String> keySet() {

        Set<String> keys = new Set<String>();

        for(KeyedGroup keyedGroup : this.matchingGroups()) {
            keys.add(keyedGroup.key());
        }

        return keys;
    }

    /** each group's members as one element, mirroring Map.values() - the grouped stream's values are the groups themselves */
    global List<Object> values() {

        List<Object> values = new List<Object>();

        for(KeyedGroup keyedGroup : this.matchingGroups()) {
            values.add(keyedGroup.members());
        }

        return values;
    }

    /** the complement of filterGroup for the case where the keys to drop are already known as a set */
    private class KeyNotInSet implements BooleanFunction {

        private Set<String> removed;

        public KeyNotInSet(Set<String> removed) {
            this.removed = removed;
        }

        public Boolean isTrueFor(Object keyedGroup) {
            return !this.removed.contains(((KeyedGroup) keyedGroup).key());
        }
    }

    /**
     * Drops the groups whose key is in the set, and stays grouped so the rest keep their keys. It is a filter
     * underneath - the set is tested once per group on read, so it costs the same scan as filterGroup rather
     * than the O(1)-per-key removal a map would give. What it buys is the spelling: the caller who already holds
     * the keys says so directly instead of writing a predicate around them.
     */
    global LazyGroupByIterator removeKeys(Set<String> keys) {
        return this.filterGroup(new KeyNotInSet(keys));
    }

    /** reads the key off a group, so keySetLazy() maps on read instead of building the set first */
    private class KeyOfGroup implements MapFunction {
        public Object mapValue(Object keyedGroup) {
            return ((KeyedGroup) keyedGroup).key();
        }
    }

    /** the same for the members, which is what valuesLazy() hands over */
    private class MembersOfGroup implements MapFunction {
        public Object mapValue(Object keyedGroup) {
            return ((KeyedGroup) keyedGroup).members();
        }
    }

    /**
     * The keys as an ordinary pipeline, so a step can follow. Nothing is read here - the mapping happens on
     * read, so a take() above it stops early - and the grouped stream ends at this point: a key is just a value
     * again and the flat steps apply. Like every lazy pipeline, reading it consumes this iterator.
     */
    global LazyIterator keySetLazy() {
        return this.transform(new KeyOfGroup());
    }

    /**
     * The members as an ordinary pipeline, one list per group - so a following flat() turns the groups back into
     * the records they were made of, and filter()/toList() are the flat steps again.
     */
    global LazyIterator valuesLazy() {
        return this.transform(new MembersOfGroup());
    }

    /**
     * The map terminals key on the group key and hand back members, so they answer the question they answered
     * before grouping became honest. The dataType argument is kept for signature compatibility and is not used:
     * the members are the upstream records, already of the right type.
     */
    global override Map<String, List<Object>> toListMap(Type dataType) {

        Map<String, List<Object>> grouped = new Map<String, List<Object>>();

        for(KeyedGroup current : this.matchingGroups()) {
            grouped.put(current.key(), current.members());
        }

        return grouped;
    }

    global override Map<String, Object> toMap(Type dataType) {

        Map<String, Object> grouped = new Map<String, Object>();

        for(KeyedGroup current : this.matchingGroups()) {
            grouped.put(current.key(), current.members());
        }

        return grouped;
    }
}

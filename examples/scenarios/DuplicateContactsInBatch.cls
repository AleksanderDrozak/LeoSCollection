@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class DuplicateContactsInBatch {

    /**
     * Emails shared by more than one contact in the same incoming batch.
     *
     * There is no query to push this into, and that is the point. Trigger.new, and the rows of an
     * import file, are not in the database yet - no SOQL can see them, so the work has to happen over
     * the records in hand. This is the situation the library is actually for.
     *
     * Three steps, and two of them change the shape of the data: the filter drops rows, the grouping
     * turns the remaining records into keyed groups, and the group filter drops whole groups. None of
     * the three can be pushed into a query, and none of them needs a hand-written walk.
     *
     * The grouping key is lowercased by GroupByLowercasedEmail rather than taken straight off the field.
     * That is not decoration: keys are compared as strings, so "J.Kowalski@acme.example" and
     * "j.kowalski@acme.example" are two different groups to GroupByFieldFunction - and a duplicate
     * detector that reports one of a pair is a bug, not a nuance.
     */
    global static Map<String, List<Object>> sharedEmails(List<Contact> incoming) {

        return Collection.of(incoming)
            /**
             * "has an email" written as a comparison rather than as includes(Contact.Email, '@').
             * includes() reaches ComparationUtil with the value stringified, so a null email is compared
             * as the text 'null' - which does not contain '@', but does contain 'u'. The comparison below
             * has no such reading.
             */
            .filter(new FilterByCondition(Contact.Email, ComparationUtil.Comparators.NOT_EQUALS, null))
            .groupBy(new GroupByLowercasedEmail())
            .filterGroup(new GroupSizeCondition(ComparationUtil.Comparators.GREATER_THAN, 1))
            .toListMap(Contact.class);
    }

    global static void demo() {

        /**
         * Stands in for the batch - not a query result. The first two rows are the same address written
         * two ways, which is the case the lowercased key exists for; the fourth row has no address at all.
         */
        List<Contact> incoming = (List<Contact>) JSON.deserialize(
            '[{"LastName":"Kowalski","Email":"j.kowalski@acme.example"},' +
            ' {"LastName":"Jan Kowalski","Email":"J.Kowalski@Acme.example"},' +
            ' {"LastName":"Nowak","Email":"a.nowak@acme.example"},' +
            ' {"LastName":"Bez adresu","Email":null}]',
            List<Contact>.class
        );

        Map<String, List<Object>> shared = sharedEmails(incoming);

        for(String email : shared.keySet()) {
            System.debug(email + ' used ' + shared.get(email).size() + ' times in this batch');
        }
        /** one entry: the two spellings of the same address, reported under the lowercased key */
    }
}
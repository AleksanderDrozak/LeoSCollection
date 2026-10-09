@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class NotEveryJobIsAPipeline {

    /**
     * The nightly contact hygiene job - deliberately written WITHOUT the collection library.
     *
     * This example exists because the obvious version of it uses the library, and that version is worse.
     * The pipeline form is written out below, so the claim can be checked rather than believed.
     *
     * What it costs, concretely:
     *
     *   The phone rule has no prebuilt pipeline form at all. SetValueFromFunction hands the MAPPER the
     *   whole record, not the field value, so pairing it with RegexReplaceFunction means composing an
     *   extractor in front of the regex (ComposeMapFunction) - and even then the regex runs on records
     *   whose Phone is null and throws, because nothing in the library applies a mapper conditionally on
     *   a null guard. Doing it in the pipeline needs a class of its own, which is the ceremony the
     *   library was supposed to remove.
     *
     *   The DoNotCall rule does have a prebuilt form, and it is four nested constructor calls to say
     *   what the loop says in one `if`.
     *
     * The rule for choosing, learned by writing both versions:
     *
     *   A step is worth putting in a pipeline when it is a SHAPE CHANGE - flattening a relationship,
     *   grouping, projecting one object into another, rolling a child list into a single value. Those
     *   steps cannot be written in a loop without inventing a container and a lookup, and the library's
     *   prebuilt classes are free.
     *
     *   A per-record rule over plain data needs no container and no lookup. Turning it into a function
     *   object adds a wrapper and removes nothing, so the library only gets in the way.
     *
     * So: reach for the library to change the shape of data. Do not reach for it to hold two
     * if-statements.
     */
    global static List<Contact> normalise(List<Contact> contacts) {

        for(Contact current : contacts) {

            if(current.Phone != null) {
                current.Phone = current.Phone.replaceAll('[^0-9+]', '');
            }

            if(current.MailingCountry != 'PL' || current.HasOptedOutOfEmail == true) {
                current.DoNotCall = true;
            }
        }

        update contacts;
        return contacts;
    }

    /**
     * The same job as a pipeline. Four constructor calls for the second rule, and the first rule missing
     * entirely - see the note at the top for why it has no prebuilt form.
     */
    global static List<Contact> normaliseAsPipeline(List<Contact> contacts) {

        return (List<Contact>) Collection.of(contacts)
            .transform(new SetValueConditionallyFunction(
                Contact.DoNotCall,
                new OrFunction(
                    new FilterByCondition(Contact.MailingCountry, ComparationUtil.Comparators.NOT_EQUALS, 'PL'),
                    new FilterByCondition(Contact.HasOptedOutOfEmail, ComparationUtil.Comparators.EQUALS, true)
                ),
                true
            ))
            .toList(Contact.class);
    }

    global static void demo() {

        List<Contact> contacts = [
            SELECT Id, Phone, MailingCountry, HasOptedOutOfEmail, DoNotCall
            FROM Contact
            WHERE Phone != null
            LIMIT 50
        ];

        /** this job updates real records, so the demo puts them back */
        Savepoint beforeDemo = Database.setSavepoint();

        for(Contact normalised : normalise(contacts)) {
            System.debug(normalised.Phone + ' / DoNotCall=' + normalised.DoNotCall);
        }

        Database.rollback(beforeDemo);
    }
}
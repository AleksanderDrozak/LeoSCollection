@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class GroupByLowercasedEmail implements GroupByFunction {

    /**
     * Grouping keys are compared as they are, so the built-in GroupByFieldFunction would put
     * "J.Kowalski@acme.example" and "j.kowalski@acme.example" in different groups - and a duplicate
     * detector that misses half the duplicates is worse than no detector.
     *
     * One small function is the whole extension point: the library asks for a String and does not care
     * how it was produced. Normalising inside the key rather than in a step before it also keeps the
     * normalised value out of the data, which matters when the same records are about to be inserted.
     */
    global String getGroupKey(Object current) {

        String email = ((Contact) current).Email;
        return email == null ? null : email.toLowerCase();
    }
}
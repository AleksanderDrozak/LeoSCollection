@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class SoqlQueryFunction implements QueryableFunction {

    private final String soql;

    /**
     * A QueryableFunction whose query is written inline, so a one-off query does not need a class of its own.
     *
     * It exists so the string shorthand still goes through the same path as a named QueryableFunction - the
     * string is sugar, not a second mechanism. Because the query stays a value, a test can hand the pipeline
     * its own QueryableFunction in its place and never touch the database.
     */
    global SoqlQueryFunction(String soql) {
        this.soql = soql;
    }

    /** The data parameter is unused on purpose: it is part of the QueryableFunction contract, and this query does not depend on what came before it. A QueryableFunction that does use it is how a query is parameterised by earlier steps. */
    global Object queryData(List<Object> data) {
        return Database.query(this.soql);
    }
}

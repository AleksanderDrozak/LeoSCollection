@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class AggregateByCountry {

    /**
     * Reporting roll-ups that the database computes.
     *
     * The aggregation happens in SOQL - COUNT, SUM, GROUP BY - because that is where it is cheap and where
     * the row limit is not spent on rows you then throw away. Apex only shapes the result.
     *
     * What made this painful before is that an AggregateResult is a read-only SObject with no typed fields:
     * every column comes back as Object, so every read is a cast, and an aliased expression has no
     * SObjectField token at all.
     *
     *     for (AggregateResult row : [SELECT BillingCountry, COUNT(Id) total FROM Account GROUP BY BillingCountry]) {
     *         String country = (String) row.get('BillingCountry');
     *         Integer total  = (Integer) row.get('total');
     *         ...
     *     }
     *
     * Nothing aggregate-specific is needed to fix that: an aggregate is just a query, so it enters the
     * pipeline through Collection.query() like any other - the SOQL lives in a QueryableFunction, so it is a
     * value that can be named, reused and applied, not a string argument. A row is still an AggregateResult,
     * so the ordinary steps apply to it - an alias is read by name - and DeserializeToFunction fills a DTO
     * from the aliases, so the query declares the shape and the casts disappear.
     */
    global class CountryTotal {
        global String billingCountry;
        global Integer total;
        global Decimal employees;
    }

    /** The query is the value here: it names itself, so a call site reads as "accounts by country", not as a string. */
    global class AccountsByCountry implements QueryableFunction {
        global Object queryData(List<Object> data) {
            return Database.query(
                'SELECT BillingCountry billingCountry, COUNT(Id) total, SUM(NumberOfEmployees) employees ' +
                'FROM Account WHERE BillingCountry != null GROUP BY BillingCountry'
            );
        }
    }

    /**
     * Sort and cap before mapping: the rows are still AggregateResults, so 'total' is read by name the same
     * way a record field is read by token. Sorting an Integer alias is exactly what the sort step does.
     */
    global static List<CountryTotal> topCountries(Integer limitRecords) {

        return (List<CountryTotal>) Collection.query(new AccountsByCountry())
            .sortBy(new SortByFieldFunction('total').setDescending())
            .take(limitRecords)
            .transform(new DeserializeToFunction(CountryTotal.class))
            .toList(CountryTotal.class);
    }

    /** A filter on an alias: keep the countries with enough accounts, before anything is deserialised. */
    global static List<CountryTotal> significantCountries(Integer minimumAccounts) {

        return (List<CountryTotal>) Collection.query(new AccountsByCountry())
            .filter(new FilterByCondition('total', ComparationUtil.Comparators.GREATER_OR_EQUALS, minimumAccounts))
            .transform(new DeserializeToFunction(CountryTotal.class))
            .toList(CountryTotal.class);
    }

    /** When nothing runs on the rows first, the mapping is the whole job - so it is the whole call. */
    global static List<CountryTotal> allCountries() {

        return (List<CountryTotal>) Collection.query(new AccountsByCountry())
            .transform(new DeserializeToFunction(CountryTotal.class))
            .toList(CountryTotal.class);
    }

    /** The counts are already per country; the grand total is one more fold, over an alias read by name. */
    global static Decimal totalAccounts() {

        return (Decimal) Collection.query(new AccountsByCountry())
            .reduce(ReduceFieldFunction.sum('total'))
            .toValue();
    }

    global static void demo() {

        for (CountryTotal country : topCountries(5)) {
            System.debug(country.billingCountry + ': ' + country.total + ' accounts, ' + country.employees + ' employees');
        }

        for (CountryTotal country : significantCountries(2)) {
            System.debug(country.billingCountry + ': ' + country.total + ' accounts (2 or more)');
        }

        System.debug('accounts in total: ' + totalAccounts());
    }
}

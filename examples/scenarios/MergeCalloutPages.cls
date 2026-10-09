@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class MergeCalloutPages {

    /**
     * A paged callout answered with several pages, each one a list of records. Merge the pages into one
     * stream, keep the rows worth keeping, and group them by country for the follow-up.
     *
     * SOQL is not an option here, and not because it would be slower: these records arrived over HTTP and
     * the database has never seen them. There is no query to push any of this into, which is exactly the
     * situation the library is for.
     *
     * Compare with the merge and the grouping this replaces:
     *
     *     Map<String, List<Account>> byCountry = new Map<String, List<Account>>();
     *     for (List<Account> page : pages) {
     *         for (Account account : page) {
     *             if (account.Phone == null || account.BillingCountry == null) { continue; }
     *             if (!byCountry.containsKey(account.BillingCountry)) {
     *                 byCountry.put(account.BillingCountry, new List<Account>());
     *             }
     *             byCountry.get(account.BillingCountry).add(account);
     *         }
     *     }
     *
     * Three levels of nesting, one of which exists only to fold the pages together, and the containsKey
     * dance in the middle. The library version has one level: flat() removes the page boundary, so the two
     * filters and the grouping do not know or care that the records ever arrived in pages.
     */
    global static Map<String, List<Object>> usableByCountry(List<List<Account>> pages) {

        return Collection.of(pages)
            .flat()
            .filter(new FilterByCondition(Account.Phone, ComparationUtil.Comparators.NOT_EQUALS, null))
            .filter(new FilterByCondition(Account.BillingCountry, ComparationUtil.Comparators.NOT_EQUALS, null))
            .groupBy(new GroupByFieldFunction(Account.BillingCountry))
            .toListMap(Account.class);
    }

    global static void demo() {

        /** what the callout answered, page by page */
        List<List<Account>> pages = new List<List<Account>> {
            new List<Account> {
                new Account(Name = 'Berlin One', BillingCountry = 'DE', Phone = '+49 30 1'),
                new Account(Name = 'No phone', BillingCountry = 'DE', Phone = null)
            },
            new List<Account> {
                new Account(Name = 'Paris One', BillingCountry = 'FR', Phone = '+33 1 1'),
                new Account(Name = 'Paris Two', BillingCountry = 'FR', Phone = '+33 1 2')
            },
            new List<Account> {
                new Account(Name = 'No country', BillingCountry = null, Phone = '+1 555 1'),
                new Account(Name = 'Berlin Two', BillingCountry = 'DE', Phone = '+49 30 2')
            }
        };

        Map<String, List<Object>> byCountry = usableByCountry(pages);

        for (String country : byCountry.keySet()) {
            System.debug(country + ' -> ' + byCountry.get(country).size() + ' usable records');
        }
        /** DE keeps two of three, FR keeps two, and the record with no country is dropped */
    }
}
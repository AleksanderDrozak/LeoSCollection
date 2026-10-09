@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class LeadsToAccountsInBatch {

    /**
     * One unsaved Account per Company, built from a batch of Leads that is not in the database yet.
     *
     * The batch is the file that was just uploaded, or the rows a Flow handed over: no SOQL reaches them,
     * so the grouping has to happen in memory. That is the whole reason the library is here.
     *
     * Compare with the grouping this replaces - the map dance, then a second pass over it:
     *
     *     Map<String, List<Lead>> byCompany = new Map<String, List<Lead>>();
     *     for (Lead lead : batch) {
     *         if (String.isBlank(lead.Company)) { continue; }
     *         if (!byCompany.containsKey(lead.Company)) { byCompany.put(lead.Company, new List<Lead>()); }
     *         byCompany.get(lead.Company).add(lead);
     *     }
     *     List<Account> accounts = new List<Account>();
     *     for (String company : byCompany.keySet()) {
     *         if (byCompany.get(company).size() <= 1) { continue; }
     *         Decimal employees = 0;
     *         for (Lead lead : byCompany.get(company)) {
     *             employees += lead.NumberOfEmployees == null ? 0 : lead.NumberOfEmployees;   // and the null guard
     *         }
     *         accounts.add(new Account(Name = company, NumberOfEmployees = employees));
     *     }
     *
     * The library version separates the three concerns the loop above mixes: which rows are usable, which
     * companies are worth an Account, and what that Account's numbers are. Each is one step, and the null
     * guard lives in ReduceFieldFunction rather than in this method.
     */
    global static List<Account> accountsFor(List<Lead> batch) {

        Map<String, List<Object>> leadsByCompany = Collection.of(batch)
            .filter(new FilterByCondition(Lead.Company, ComparationUtil.Comparators.NOT_EQUALS, null))
            .groupBy(new GroupByFieldFunction(Lead.Company))
            .filterGroup(new GroupSizeCondition(ComparationUtil.Comparators.GREATER_THAN, 1))
            .toListMap(Lead.class);

        List<Account> accounts = new List<Account>();

        /**
         * The tail is plain Apex on purpose: the library has no operation that maps a group to a value, so
         * one record per group is built by hand. Three lines, and no pretence that the pipeline covers it.
         */
        for (String company : leadsByCompany.keySet()) {
            accounts.add(new Account(
                Name = company,
                NumberOfEmployees = (Decimal) Collection.of(leadsByCompany.get(company))
                    .reduce(ReduceFieldFunction.sum(Lead.NumberOfEmployees))
                    .toValue()
            ));
        }

        return accounts;
    }

    global static void demo() {

        /** an upload in progress - the Leads have no Ids, and the database has never seen them */
        List<Lead> batch = new List<Lead> {
            new Lead(LastName = 'Kowalski', Company = 'Acme', NumberOfEmployees = 120),
            new Lead(LastName = 'Nowak', Company = 'Acme', NumberOfEmployees = 80),
            new Lead(LastName = 'Bez firmy', Company = null, NumberOfEmployees = 5),
            new Lead(LastName = 'Solo', Company = 'One Man Shop', NumberOfEmployees = 1),
            new Lead(LastName = 'Zielinski', Company = 'Acme', NumberOfEmployees = null)
        };

        for (Account account : accountsFor(batch)) {
            System.debug(account.Name + ' -> ' + account.NumberOfEmployees + ' employees across the batch');
        }
        /** Acme only: the blank Company is skipped, and One Man Shop has a single Lead */
    }
}
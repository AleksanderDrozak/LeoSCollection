@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class ReusablePipeline {

    /**
     * One pipeline, several data sets, one transaction - and the same answer every time.
     *
     * A file arrives in pages, and each page has to be summarised on its own. The pipeline below is
     * composed once and then applied to each page. apply() rebuilds the pipeline on a new source instead
     * of consuming the one it holds, so the second page does not inherit anything from the first.
     *
     * That guarantee is worth more than it sounds, because the step that would break it is an accumulator.
     * ReduceFieldFunction.average keeps a running count as it goes; a hand-rolled accumulator reused across
     * pages carries the previous page's count into the next page's average, and the bug shows up as a
     * slightly wrong number rather than an exception. The reset lives in the step's getInitialValue(), which
     * each run calls once - the vanilla equivalent is a class that remembers to reset itself:
     *
     *     class Averager {
     *         Decimal total = 0;
     *         Integer count = 0;
     *         Decimal add(Decimal value) { total += value; count++; return total / count; }
     *         // and the caller has to remember: average = new Averager(); before every page
     *     }
     *
     * The third apply() in the demo is the point: it re-runs the first page and must produce the same
     * number, which it does because the pipeline was never consumed and never accumulated.
     */
    global static TemplateIterator averageEmployees() {

        return Collection.template(new List<Object> {
            new FlattenFunction(),
            new FilterByCondition(Account.NumberOfEmployees, ComparationUtil.Comparators.NOT_EQUALS, null),
            ReduceFieldFunction.average(Account.NumberOfEmployees)
        });
    }

    global static void demo() {

        List<List<Account>> pages = new List<List<Account>> {
            new List<Account> {
                new Account(Name = 'Small', NumberOfEmployees = 10),
                new Account(Name = 'Medium', NumberOfEmployees = 20)
            },
            new List<Account> {
                new Account(Name = 'Large', NumberOfEmployees = 100),
                new Account(Name = 'Huge', NumberOfEmployees = 300)
            }
        };

        TemplateIterator pipeline = averageEmployees();

        for (List<Account> page : pages) {
            System.debug('page average: ' + pipeline.apply(page).toValue());
        }

        /** the first page again: the same number, not a blend of both pages */
        System.debug('page average, re-run: ' + pipeline.apply(pages[0]).toValue());
    }
}
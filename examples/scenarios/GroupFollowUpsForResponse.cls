@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class GroupFollowUpsForResponse {

    /**
     * An inbound payload carries follow-up tasks; the response has to hand them back grouped by priority,
     * with the priorities that only got one task left out - an external system asking for "everything we
     * should chase" has no use for a category of one.
     *
     * The payload is not in the database and never will be: these are tasks the caller is proposing, and
     * the response is the answer. No query reaches them, so the grouping happens in memory.
     *
     * Compare with the grouping this replaces:
     *
     *     Map<String, List<Task>> byPriority = new Map<String, List<Task>>();
     *     for (Task task : payload.tasks) {
     *         if (task.Priority == null) { continue; }
     *         if (!byPriority.containsKey(task.Priority)) { byPriority.put(task.Priority, new List<Task>()); }
     *         byPriority.get(task.Priority).add(task);
     *     }
     *     Map<String, List<Task>> worthAnswering = new Map<String, List<Task>>();
     *     for (String priority : byPriority.keySet()) {
     *         if (byPriority.get(priority).size() > 1) { worthAnswering.put(priority, byPriority.get(priority)); }
     *     }
     *
     * Two passes and two maps, the second one existing only to drop the small groups. The library version
     * filters the groups before they ever become a map, and toListMap() returns exactly the shape the
     * response body needs, so it serialises without a further pass.
     */
    global static Map<String, List<Object>> byPriority(List<Task> tasks) {

        return Collection.of(tasks)
            .filter(new FilterByCondition(Task.Priority, ComparationUtil.Comparators.NOT_EQUALS, null))
            .groupBy(new GroupByFieldFunction(Task.Priority))
            .filterGroup(new GroupSizeCondition(ComparationUtil.Comparators.GREATER_THAN, 1))
            .toListMap(Task.class);
    }

    global static void demo() {

        /** the tasks block of a request body, not query results */
        List<Task> tasks = new List<Task> {
            new Task(Subject = 'Call back', Priority = 'High'),
            new Task(Subject = 'Send quote', Priority = 'High'),
            new Task(Subject = 'Send brochure', Priority = 'Normal'),
            new Task(Subject = 'Archive', Priority = 'Low'),
            new Task(Subject = 'No priority', Priority = null)
        };

        String responseBody = JSON.serialize(byPriority(tasks));
        System.debug(responseBody);
        /** only High survives: Normal and Low each got a single task, and the unprioritised one is dropped */
    }
}
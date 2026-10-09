@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class TemplateIterator {

    private List<Object> steps;

    /**
     * A template is a step list and nothing else. It holds no data, so it cannot be run on its own: the
     * only way to get a result out of it is apply(), which hands it a source. That is deliberate - building
     * a pipeline to be reused is a decision, and it should not be something you slip into by starting from
     * an empty source.
     */
    global TemplateIterator() {
        this.steps = new List<Object>();
    }

    global TemplateIterator(List<Object> steps) {
        this.steps = new List<Object>(steps);
    }

    /**
     * The one step entry a template has. pipe() is the most powerful of them - every step is a value, and a
     * list of values covers the rest - so the step-by-step methods stay where they belong, on the pipeline
     * that actually runs.
     */
    global TemplateIterator pipe(List<Object> steps) {
        this.steps.addAll(steps);
        return this;
    }

    /**
     * Runs the recorded steps over the passed data and hands back a fresh pipeline. The pipeline is built
     * on the new source rather than reusing a consumed one, so a template can be applied to any number of
     * data sets, in any order, and each application starts clean.
     */
    global LazyIterator apply(Object data) {
        return Collection.of(data).pipe(this.steps);
    }
}

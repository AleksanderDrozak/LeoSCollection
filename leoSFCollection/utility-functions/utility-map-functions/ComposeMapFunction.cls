@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class ComposeMapFunction implements MapFunction {

    private MapFunction previousMapFunction;
    private MapFunction currentMapFunction;

    /**
     * Two mappers as one: previous runs first, current runs on its result. Named for what it does - a
     * composition of mappers - rather than for a reduce, which it never performs.
     */
    global ComposeMapFunction(MapFunction previousMapFunction, MapFunction currentMapFunction) {
        this.previousMapFunction = previousMapFunction;
        this.currentMapFunction = currentMapFunction;
    }

    global Object mapValue(Object obj) {
        return this.currentMapFunction.mapValue(this.previousMapFunction.mapValue(obj));
    }

}

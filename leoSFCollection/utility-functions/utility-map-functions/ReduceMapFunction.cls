@SuppressWarnings('PMD.AvoidGlobalModifier')
public inherited sharing class ReduceMapFunction implements MapFunction {

    private MapFunction previousMapFunction;
    private MapFunction currentMapFunction;

    public ReduceMapFunction(MapFunction previousMapFunction, MapFunction currentMapFunction) {
        this.previousMapFunction = previousMapFunction;
        this.currentMapFunction = currentMapFunction;
    }

    public Object mapValue(Object obj) {
        return this.currentMapFunction.mapValue(this.previousMapFunction.mapValue(obj));
    }

}
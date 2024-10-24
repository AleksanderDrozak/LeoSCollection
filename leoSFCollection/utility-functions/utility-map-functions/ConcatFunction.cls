@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class ConcatFunction implements MapFunction {

    private MapFunction previousMapFunction;
    private MapFunction currentMapFunction;

    public ConcatFunction(MapFunction firstFunction, MapFunction secondFunction) {
        this.previousMapFunction = firstFunction;
        this.currentMapFunction = secondFunction;
    }

    public ConcatFunction(MapFunction firstFunction, MapFunction secondFunction, MapFunction thirdFunction) {
        this.previousMapFunction = new ConcatFunction(firstFunction, secondFunction);
        this.currentMapFunction = thirdFunction;
    }

    public Object mapValue(Object obj) {
        String previousString = String.valueOf(this.previousMapFunction.mapValue(obj));
        String currentString = String.valueOf(this.currentMapFunction.mapValue(obj));
        return previousString + currentString;
    }
}
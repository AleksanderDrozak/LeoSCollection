@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class ConstantMapFunction  implements MapFunction {

    private Object constant;

    public ConstantMapFunction(Object constant) {
        this.constant = constant;
    }

    public Object mapValue(Object obj) {
        return this.constant;
    }
}
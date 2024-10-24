@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class LimitToFunction implements LimitFunction {

    public Integer maxValue {
        get;
        private set;
    }

    global LimitToFunction(Integer maxValue) {
        this.maxValue = maxValue;
    }

    global Boolean shouldStop(Object data) {
        return this.shouldStop((Integer) data);
    }

    global Boolean shouldStop(Integer currentIndex) {
        return currentIndex >= this.maxValue;
    }
}
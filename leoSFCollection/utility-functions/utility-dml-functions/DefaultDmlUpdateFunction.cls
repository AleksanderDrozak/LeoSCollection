@SuppressWarnings('PMD.AvoidGlobalModifier')
global inherited sharing class DefaultDmlUpdateFunction implements DmlUpdateFunction {
    global Object dmlUpdate(List<SObject> data) {
        update data;
        return data;
    }
}
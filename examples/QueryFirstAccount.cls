@SuppressWarnings('PMD.AvoidGlobalModifier')
global without sharing class QueryFirstAccount implements QueryableFunction {

    global Object queryData(List<Object> data) {
        return [
            SELECT Id, Name FROM Account LIMIT 1
        ];
    }
}
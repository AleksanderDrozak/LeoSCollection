private without sharing class Example1 {

    without sharing class FindDeliveryTasksForWorkOrders implements GroupByFunction, QueryableFunction {

        String getGroupKey(Object record) {
            return ((DeliveryTask__c) record).DeliveryTask_WorkOrder__r.WorkOrder__c;
        }

        Object queryData(List<Object> junctionIds) {
            return [
                SELECT DeliveryTask_WorkOrder__r.WorkOrder__c
                FROM DeliveryTask__c
                WHERE Delivery_WorkOrder__c IN : junctionIds
                ORDER BY Id
            ];
        }

        public Map<Id, List<DeliveryTask__c>> process(Set<Id> junctionIdSet) {
            return Collection.of(junctionIdSet)
                   .query(this)
                   .groupBy(this)
                   .toListMap(Id.class, DeliveryTask__c.class);
        }
    }

    private static Map<Id, List<DeliveryTask__c>> refactoredLogic(Set<Id> junctionIdSet) {
        return new FindDeliveryTasksForWorkOrders().process(junctionIdSet);
    }

    private static Map<Id, List<DeliveryTask__c>> oldLogic(Set<Id> junctionIdSet) {
        Map<Id, List<DeliveryTask__c>> output = new Map<Id, List<DeliveryTask__c>>();

        for(DeliveryTask__c deliveryTask : [
                SELECT DeliveryTask_WorkOrder__r.WorkOrder__c
                FROM DeliveryTask__c
                WHERE DeliveryTask_WorkOrder__c IN : junctionIds
                ORDER BY Id
            ]) {

            if(!output.containsKey(deliveryTask.DeliveryTask_WorkOrder__r.WorkOrder__c)) {
                output.put(deliveryTask.DeliveryTask_WorkOrder__r.WorkOrder__c, new List<DeliveryTask__c>());
            }

            output.get(deliveryTask.DeliveryTask_WorkOrder__r.WorkOrder__c).add(deliveryTask);
        }

        return output;
    }
}
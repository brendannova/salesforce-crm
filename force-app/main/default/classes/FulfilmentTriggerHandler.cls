public class FulfilmentTriggerHandler extends TriggerHandler{

    //recast trigger variables from SObjects
    private Map<Id, Fulfilment__c> oldFulfilmentMap = (Map<Id, Fulfilment__c>) Trigger.oldMap;
    private Map<Id, Fulfilment__c> newFulfilmentMap = (Map<Id, Fulfilment__c>) Trigger.newMap;

    public override void afterUpdate(){
        FulfilmentTriggerHelper helper = new FulfilmentTriggerHelper();
        helper.processSubmittedFulfilments(oldFulfilmentMap, newFulfilmentMap);
    }
}
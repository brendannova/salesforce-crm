public class FufilmentTriggerHandler extends TriggerHandler{

    //recast trigger variables from SObjects
    private Map<Id, Fulfilment__c> oldFufilmentMap = (Map<Id, Fulfilment__c>) Trigger.oldMap;
    private Map<Id, Fulfilment__c> newFufilmentMap = (Map<Id, Fulfilment__c>) Trigger.newMap;

    public override void afterUpdate(){
        FulfilmentTriggerHelper helper = new FulfilmentTriggerHelper();
        helper.processSubmittedFulfilments(oldFufilmentMap, newFufilmentMap);
    }
}
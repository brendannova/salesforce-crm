trigger FulfilmentTrigger on Fulfilment__c (after update) {
    new FulfilmentTriggerHandler().run();
}
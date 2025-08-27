trigger FulfilmentTrigger on Fulfilment__c (before insert, before update, after insert, after update) {
    new FufilmentTriggerHandler().run();
}
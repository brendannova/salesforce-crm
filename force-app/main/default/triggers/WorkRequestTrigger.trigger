trigger WorkRequestTrigger on WorkRequest__c (before insert, before update, after insert, after update) {
    new WorkRequestTriggerHandler().run();
}
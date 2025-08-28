trigger TaskRequestTrigger on OW_Task_Request__c (before insert, before update, after insert, after update) {
    new TaskRequestTriggerHandler().run();
}
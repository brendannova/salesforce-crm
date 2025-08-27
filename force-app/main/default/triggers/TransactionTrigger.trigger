trigger TransactionTrigger on Transaction__c (before insert, before update, after insert, after update) {
    new TransactionTriggerHandler().run();
}
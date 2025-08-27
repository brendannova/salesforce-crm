trigger ExpectationTrigger on Expectation__c (before insert, before update, after insert, after update) {
    new ExpectationTriggerHandler().run();
}
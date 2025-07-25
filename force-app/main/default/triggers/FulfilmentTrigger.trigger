trigger FulfilmentTrigger on Fulfilment__c (after update) {
    System.debug('New trigger');
    for(Fulfilment__c flfl : Trigger.new) {
        System.debug('Triggered fulfilment: ' + flfl);
    }
    new FulfilmentTriggerHandler().run();
}
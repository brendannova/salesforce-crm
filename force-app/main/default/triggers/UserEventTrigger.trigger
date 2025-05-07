trigger UserEventTrigger on UserEvent__e (after insert) {
    System.debug('fired');
    new UserEventTriggerHandler().run();
}
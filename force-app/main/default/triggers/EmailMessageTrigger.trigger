trigger EmailMessageTrigger on EmailMessage (after insert, after update) {
    new EmailMesssageTriggerHandler().run();
}
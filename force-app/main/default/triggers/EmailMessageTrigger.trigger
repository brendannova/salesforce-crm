trigger EmailMessageTrigger on EmailMessage (before insert, after insert, after update) {
    new EmailMesssageTriggerHandler().run();
}
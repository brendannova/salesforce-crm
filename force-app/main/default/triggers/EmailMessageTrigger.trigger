trigger EmailMessageTrigger on EmailMessage (before insert, after insert, before update, after update) {
    if(Trigger.isAfter){
        EmailMessageHelper emh = new EmailMessageHelper(Trigger.newMap);
        emh.validateConditions();
    }
}
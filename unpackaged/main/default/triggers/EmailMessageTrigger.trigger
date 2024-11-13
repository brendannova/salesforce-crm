trigger EmailMessageTrigger on EmailMessage (before insert, after insert) {
    if(Trigger.isAfter){
        EmailMessageHelper emh = new EmailMessageHelper(Trigger.newMap);
        emh.validateConditions();
    }
}
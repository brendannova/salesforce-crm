trigger EmailMessageTrigger on EmailMessage (after insert, after update) {
    if(Trigger.isAfter){
        EmailMessageHelper emh = new EmailMessageHelper(Trigger.newMap);
        emh.validateConditions();
    }
}
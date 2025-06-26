public class EmailMesssageTriggerHandler extends TriggerHandler {
    
    //must recast from SObjects
    private Map<Id, EmailMessage> newEmailMessageMap = (Map<Id, EmailMessage>) Trigger.newMap;

    public override void beforeInsert() {
        EmailMessageHelper emh = new EmailMessageHelper();
        emh.setValidationType(this.newEmailMessageMap);
    }

    public override void afterInsert() {
        EmailMessageHelper emh = new EmailMessageHelper(this.newEmailMessageMap);
        emh.validateConditions();
    }

    public override void afterUpdate() {
        EmailMessageHelper emh = new EmailMessageHelper(this.newEmailMessageMap);
        emh.validateConditions();
    }
}
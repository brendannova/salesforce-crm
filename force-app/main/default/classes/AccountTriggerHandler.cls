public with sharing class AccountTriggerHandler extends TriggerHandler {

    private List<Account> newAccountList = (List<Account>) Trigger.new;

    public override void beforeInsert() {
        AccountTriggerHelper ath = new AccountTriggerHelper();
        ath.mapContactFields(this.newAccountList);
    }

    public override void beforeUpdate() {
        AccountTriggerHelper ath = new AccountTriggerHelper();
        ath.mapContactFields(this.newAccountList);
    }
}
public with sharing class AccountTriggerHelper {

    public void mapContactFields(List<Account> newAccounts){
        for (Account newAccount : newAccounts) {
            if (newAccount.IsPersonAccount) {
                newAccount.StatusWealth__pc = newAccount.FinServ__Status__c;
            }
        }
    }
}
public with sharing class LwcHelperAccountStatusFlags {
    
    public static Set<Id> getHouseholdAccountIds(Id householdId){
        Set<Id> accountIds = new Set<Id>();
        for(AccountContactRelation relation : [SELECT Id, ContactId, Contact.AccountId FROM AccountContactRelation WHERE AccountId = :householdId AND IsActive = True]){
            accountIds.add(relation.Contact.AccountId);
        }
        return accountIds;
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> getAccountsByHouseholdId(Id householdId) {
        Set<Id> accountIds = getHouseholdAccountIds(householdId);
        List<Account> accounts = [
            SELECT Id, FinServ__Status__c, OW_terms_of_Business_Status__c, OW_aml_check_account__c, OW_rtq_status__c, Vulnerable_Client__c
            FROM Account
            WHERE Id 
            IN :accountIds
        ];

        return accounts;

    }
}
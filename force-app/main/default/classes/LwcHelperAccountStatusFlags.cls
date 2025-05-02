public with sharing class LwcHelperAccountStatusFlags {

    public static final String ROLE_CLIENT = 'Client';
    
    public static Set<Id> getHouseholdAccountIds(Id householdId){
        Set<Id> accountIds = new Set<Id>();
        for(AccountContactRelation relation : [SELECT Id, ContactId, Contact.AccountId FROM AccountContactRelation WHERE AccountId = :householdId AND IsActive = True AND Roles = :ROLE_CLIENT]){
            accountIds.add(relation.Contact.AccountId);
        }
        return accountIds;
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> getAccountsByHouseholdId(Id householdId) {
        Set<Id> accountIds = getHouseholdAccountIds(householdId);
        List<Account> accounts = [
            SELECT Id, FinServ__Status__c, OW_terms_of_Business_Status__c, OW_aml_check_account__c, OW_rtq_status__c, Vulnerable_Client__c, TempBankDetailIssues__c
            FROM Account
            WHERE Id 
            IN :accountIds
        ];

        return accounts;

    }

    @AuraEnabled(cacheable=true)
    public static flagWrapper getWrapperFromRecord(Id recordId, String objectName) {
        flagWrapper flags = new flagWrapper();
        if(objectName == 'Advice__c'){
            Advice__c advice = [SELECT Id, Advice_Household__c FROM Advice__c WHERE Id = :recordId];
            flags.householdId = advice.Advice_Household__c;
        }
        return flags;
    }

    public class flagWrapper {
        @AuraEnabled public String householdId;
        @AuraEnabled public Boolean exampleFlagValue;
    }
}
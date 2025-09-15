@IsTest
public without sharing class AccountTriggerTest {

    @TestSetup
    static void setup() {

        final String ACCOUNT_OBJECT_API_NAME = 'Account';
        final String STATUS_FIELD_API_NAME = 'FinServ__Status__c';
        List<Schema.PicklistEntry> statusValues = Schema.getGlobalDescribe().get(ACCOUNT_OBJECT_API_NAME).getDescribe().fields.getMap().get(STATUS_FIELD_API_NAME).getDescribe().getPicklistValues();
        
        List<Account> testAccounts = new List<Account>();
        String RecordTypeDevNamePerson = 'PersonAccount';
        Id RecordTypeIdPerson = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(RecordTypeDevNamePerson).getRecordTypeId();

        for (Schema.PicklistEntry statusValue : statusValues){
            Account testAccount = new Account(
                FirstName = 'Test',
                LastName = 'Test ' + statusValue.getValue(),
                RecordTypeId = RecordTypeIdPerson,
                FinServ__Status__c = statusValue.getValue()
            );
            testAccounts.add(testAccount);
        }
        insert testAccounts;
    }

    @IsTest
    static void contactFieldsSynced_success() {

        List<Account> testAccounts = [SELECT Id, FinServ__Status__c, StatusWealth__pc FROM Account];
        for(Account testAccount : testAccounts) {
            System.assertEquals(testAccount.FinServ__Status__c, testAccount.StatusWealth__pc, 'Status field not synced');
            testAccount.FinServ__Status__c = 'Onboarding';
        }
        update testAccounts;
        testAccounts = [SELECT Id, FinServ__Status__c, StatusWealth__pc FROM Account];
        for(Account testAccount : testAccounts) {
            System.assertEquals('Onboarding', testAccount.StatusWealth__pc, 'Status field not synced');
        }
    }
}
public with sharing class UserEventTriggerHelper {

    @TestVisible private static final String COLLEAGUE_ACCOUNT_RECORD_TYPE_DEVELOPER_NAME = 'Colleague';
    @TestVisible private static final String COLLEAGUE_ACCOUNT_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Colleague').getRecordTypeId();
    @TestVisible private static final String NOVA_USER_TYPE_COLLEAGUE = 'COLLEAGUE';

    // The purpose of this method is to process user events and run any logic required for the given users.
    public void processUserEvents(List<UserEvent__e> userEvents){
        System.debug('uysdfasdfadsas');

        // Build a list of the user IDs from the events
        Set<Id> userIds = new Set<Id>();
        for(UserEvent__e userEvent : userEvents){
            userIds.add(userEvent.UserId__c);
        }

        // Given the user IDs from the events, retrieve all users that should have colleague accounts. 
        Map<Id, User> userMap = new Map<Id, User>([SELECT Id, FirstName, LastName, Username, ColleagueAccountId__c FROM User WHERE Id IN :userIds AND UserType__c = :NOVA_USER_TYPE_COLLEAGUE AND IsActive = True]);
        /*
        TBC if any of this is needed. This is if we want to run checks on existing accounts 1st. 
        List<Account> colleagueAccountsExisting = [SELECT Id, FirstName, LastName FROM Account WHERE RecordTypeId = :COLLEAGUE_ACCOUNT_RECORD_TYPE_ID AND Colleague__c IN :userIds];
        Map<Id, Account> userColleagueAccountMap = new Map<Id, Account>();
        for(Account colleagueAccount : colleagueAccountsExisting){
            userColleagueAccountMap.put(colleagueAccount.Colleague__c, colleagueAccount);
        }
        */

        // Loop the users and build a list of colleague accounts to upsert
        List<Account> colleagueAccounts = new List<Account>();
        for(User user : userMap.values()){
            // Define a colleague account variable for the current user. This will be used either to create or update/sync the account if existing. 
            Account colleagueAccount = new Account(
                RecordTypeId = COLLEAGUE_ACCOUNT_RECORD_TYPE_ID,
                OwnerId = user.Id,
                Colleague__c = user.Id,
                Type = NOVA_USER_TYPE_COLLEAGUE,
                FirstName = user.FirstName,
                LastName = user.LastName,
                PersonEmail = user.Username,
                ServiceContactPreferences__pc = '',
                Fact_Find_Type__c = '',
                BankDetailsStatus__c = '',
                OW_aml_check_account__c = '',
                OW_rtq_status__c = '',
                Wealth_Marketing_Opt_In__pc = '',
                MigrationGiving__c = '',
                MigrationSpendingSaving__c = '',
                OW_terms_of_Business_Status__c = '',
                FinServ__Status__c = '',
                Annual_Review_Schedule__c =''
            );

            // If we already have a colleague account, define the ID so we update that.
            if(!String.isBlank(user.ColleagueAccountId__c)){
                colleagueAccount.Id = user.ColleagueAccountId__c;
            }
            colleagueAccounts.add(colleagueAccount);
        }

        // If there are colleague accounts requiring upsert, do that. 
        if(!colleagueAccounts.isEmpty()){
            upsert colleagueAccounts;
        }

        // Identify any of the users that will need a ColleagueAccountId__c value and fire these off
        List<User> users = new List<User>();
        for(Account colleagueAccount : colleagueAccounts){
            if(String.isBlank(userMap.get(colleagueAccount.Colleague__c).ColleagueAccountId__c)){
                users.add(new User(Id = colleagueAccount.Colleague__c, ColleagueAccountId__c = colleagueAccount.Id));
            }
        }
        if(!users.isEmpty()){
            update users;
        }
    }
}
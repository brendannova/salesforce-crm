public class createTestData {
    
    public static String createHousehold (Integer numClients, Integer numChildren, String factFindType) {
        
        // Set variables used throughout the flow
        String HouseholdRecordTypeDevName = 'IndustriesHousehold';
        String PersonRecordTypeDevName = 'PersonAccount';   
        String HouseholdRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(HouseholdRecordTypeDevName).getRecordTypeId();
        String PersonRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(PersonRecordTypeDevName).getRecordTypeId();
        Id userId = System.UserInfo.getUserId();
        String runTime = String.valueOf(Datetime.now()).deleteWhiteSpace().remove('-').remove(':');
        String runIdentifier = userId + runTime;
        String personLastName = System.UserInfo.getLastName() + runTime;
        
        // Build the list of accounts that are to be inserted in this flow
        List<Account> accounts = new List<Account>();
        
        // Create household
        Account household = new Account(
            RecordTypeId = HouseholdRecordTypeId,
            Test_Record__c = true,
            Exclude_From_Reporting__c = true,
            AccountNumber = 'hh' + runIdentifier,
            OwnerId = userId,
            Name = 'Test ' + System.UserInfo.getLastName() + runTime, 
            AccountSource = 'Test data',
            FinServ__Status__c = 'Prospect',
            Fact_Find_Type__c = factFindType,
            Dashboard_Visibility__c = 'Off',
            Nominated_Bank_Details_Visible__c = true
        );
        accounts.add(household);
        
        // Create adult clients
        for( Integer i = 0; i < numClients; i++) {
            Account client = new Account(
                RecordTypeId = PersonRecordTypeId,
                Test_Record__c = true,
                Exclude_From_Reporting__c = true,
                AccountNumber = 'cl' + i + runIdentifier,
                OwnerId = userId,
                FirstName = System.UserInfo.getFirstName() + i,
                LastName = personLastName,
                FinServ__Status__c = 'Prospect',
                AccountSource = 'Test data',
                PersonEmail = 'owemailtest2108+' + String.valueOf(Integer.valueof((Math.random() * 1000))) + '@gmail.com'
            );
            accounts.add(client);
        }
        
        // Create children
        for( Integer i = 0; i < numChildren; i++) {
            Account child = new Account(
                RecordTypeId = PersonRecordTypeId,
                Test_Record__c = true,
                Exclude_From_Reporting__c = true,
                AccountNumber = 'ch' + i + runIdentifier,
                OwnerId = userId,
                FirstName = 'Child ' + i,
                LastName = personLastName,
                FinServ__Status__c = 'Prospect',
                AccountSource = 'Test data',
                PersonEmail = 'owemailtest2108+' + String.valueOf(Integer.valueof((Math.random() * 1000))) + '@gmail.com'          
            ); 
            accounts.add(child);
        }
        
        // Insert all accounts
        insert accounts;
        
        // Get the household ID and create a variable containing all the inserted person accounts
        String householdId;
        for (Account acc : accounts){
            if ( acc.RecordTypeId == HouseholdRecordTypeId ){
                householdId = acc.Id;
            }
        }
        
        // Get the details of the person accounts - query needed as we need the ID of the contact associated with the person account
        List<Account> personAccounts = [SELECT PersonContactId, AccountNumber FROM Account WHERE LastName =: personLastName];
        
        List<AccountContactRelation> relationships = new List<AccountContactRelation>();
        AccountContactRelation relationship = new AccountContactRelation( AccountId = householdId );
        for (Account personAccount : personAccounts){
            if ( personAccount.AccountNumber.left(2) == 'cl' ){
                relationship.ContactId = personAccount.PersonContactId;
                relationship.FinServ__PrimaryGroup__c = true;
                relationship.Roles = 'Client';
                relationships.add(relationship);
                relationship = new AccountContactRelation( AccountId = householdId );                
            } else if ( personAccount.AccountNumber.left(2) == 'ch' ) {
                relationship.ContactId = personAccount.PersonContactId;
                relationship.FinServ__PrimaryGroup__c = true;                
                relationship.Roles = 'Child';
                relationships.add(relationship);
                relationship = new AccountContactRelation( AccountId = householdId );
            }
        }
        insert relationships;
        
        return householdId;
    }
}
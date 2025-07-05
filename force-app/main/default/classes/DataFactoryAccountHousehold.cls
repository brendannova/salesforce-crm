public with sharing class DataFactoryAccountHousehold {
    public static Account createHousehold(String idenfitifer, Integer numClients, Integer numChildren, String status, String profileType){
        
        String RecordTypeDevNameHousehold = 'IndustriesHousehold';
        Id RecordTypeIdHousehold = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(RecordTypeDevNameHousehold).getRecordTypeId();
    
        String RecordTypeDevNamePerson = 'PersonAccount';
        Id RecordTypeIdPerson = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(RecordTypeDevNamePerson).getRecordTypeId();
    
        // Takes a number of clients, children, and status as inputs and generates the data   
        List<Account> accounts = new List<Account>(); // The list of accounts that will ultimately be inserted
        DataFactoryNameGenerator dfng = new DataFactoryNameGenerator();
        String familyName = dfng.generateName(false, true, false).lastName;
        String householdName = familyName;
        
        // Create the clients
        for( Integer i = 0; i < numClients; i++) {
            Account person = new Account(
                FirstName = dfng.generateName(true, false, false).firstName,
                LastName = familyName,  
                RecordTypeId = RecordTypeIdPerson,
                OW_role_in_primary_household__c = 'Client',
                FinServ__Status__c = status,
                PersonEmail = familyName + i + '@fakeemail.com',
                PersonBirthdate  = System.Today().addYears(-23),
                OW_admin_notes__c = idenfitifer + '-client-' + i
            );
            if(Math.mod(i, 2) != 0){
                person.FinServ__PreferredName__pc = dfng.generateName(false, false, true).preferredName;
            }
            accounts.add(person);
            
            // Add to the household name the initial of this client
            householdName += ', ' + person.FirstName.left(1);
        }
        
        // Create the children
        for( Integer i = 0; i < numChildren; i++) {
            Account person = new Account(
                FirstName = dfng.generateName(true, false, false).firstName,
                LastName = familyName,  
                RecordTypeId = RecordTypeIdPerson,
                OW_role_in_primary_household__c = 'Child',
                FinServ__Status__c = 'Junior',
                OW_admin_notes__c = idenfitifer + '-child-' + i
            );
            accounts.add(person);
        }
        
        // Create the household then insert all the accounts
        Account household = new Account(
            Name = householdName,
            RecordTypeId = RecordTypeIdHousehold,
            FinServ__Status__c = status,
            Fact_Find_Type__c = profileType,
            OW_admin_notes__c = idenfitifer
        );
        accounts.add(0, household);
        insert accounts;
        
        // Identify the household ID and the list of person account IDs now that they have been inserted
        household = accounts[0];
        List<Account> personAccounts = accounts;
        personAccounts.remove(0);
        Set<Id> personAccountIds = new Set<Id>();
        for (Account personAccount : personAccounts){
            personAccountIds.add(personAccount.Id);
        }
        
        // Return full details of the person accounts created earlier so the contact ID is known
        personAccounts = [SELECT Id, PersonContactId, OW_role_in_primary_household__c FROM Account WHERE Id IN :personAccountIds];
        
        // Create the account contact relationships between the household and the clients and children
        List<AccountContactRelation> relationships = new List<AccountContactRelation>();
        Boolean primaryClientSet = false;
        for (Account personAccount : personAccounts){
            AccountContactRelation relationship = new AccountContactRelation(
                AccountId = household.Id,
                ContactId = personAccount.PersonContactId,
                FinServ__PrimaryGroup__c = true,
                Roles = personAccount.OW_role_in_primary_household__c
            );
            if( primaryClientSet == false && relationship.Roles == 'Client'){
                relationship.FinServ__Primary__c = true;
                primaryClientSet = true;
            }
            relationships.add(relationship);
        }
        insert relationships;
        return household;
    }
}
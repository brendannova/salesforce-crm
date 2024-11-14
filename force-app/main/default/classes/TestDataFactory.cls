@isTest
public class TestDataFactory  {
    
    public static List<Account> createHousehold (Integer numClients, Integer numChildren, String identifier) {
        String HouseholdRecordTypeDevName = 'IndustriesHousehold';
        String PersonRecordTypeDevName = 'PersonAccount';
        String HouseholdSourceIdentifier = 'TestDataFactory';   
        List<Account> accounts = new List<Account>();
        Account household = new Account(Name = 'Test Household', AccountSource = HouseholdSourceIdentifier, AccountNumber = identifier, RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(HouseholdRecordTypeDevName).getRecordTypeId());
        accounts.add(household);
        
        for( Integer i = 0; i < numClients; i++) {
            Account a = new Account(FirstName = 'TestClient ' + i, LastName = 'Client', AccountNumber = identifier, RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(PersonRecordTypeDevName).getRecordTypeId());
            if ( Math.mod(i + 1, 2) == 0 ){
                a.FinServ__PreferredName__pc = 'TestytestyClient ' + i;
            }
            accounts.add(a);
        }
        
        for( Integer i = 0; i < numChildren; i++) {
            Account a = new Account(FirstName = 'TestChild ' + i, LastName = 'Child', AccountNumber = identifier, RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(PersonRecordTypeDevName).getRecordTypeId()); 
            accounts.add(a);
        }
        insert accounts;
        
        String householdId;
        for (Account acc : accounts){
            if ( householdId == null && acc.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(HouseholdRecordTypeDevName).getRecordTypeId() ){
                householdId = acc.Id;
            }
        }
        
        List<Account> personAccounts = [SELECT Id, PersonContactId, RecordTypeId, LastName FROM Account WHERE AccountNumber =: identifier];
        
        List<AccountContactRelation> relationships = new List<AccountContactRelation>();
        AccountContactRelation tempRelationship = new AccountContactRelation( AccountId = householdId );
        for (Account acc : personAccounts){
            if ( acc.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(PersonRecordTypeDevName).getRecordTypeId() && acc.LastName == 'Client' ){
                tempRelationship.ContactId = acc.PersonContactId;
                tempRelationship.FinServ__PrimaryGroup__c = true;
                tempRelationship.Roles = 'Client';
                relationships.add(tempRelationship);
                tempRelationship = new AccountContactRelation( AccountId = householdId );                
            } else if ( acc.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(PersonRecordTypeDevName).getRecordTypeId() && acc.LastName == 'Client' ) {
                tempRelationship.ContactId = acc.PersonContactId;
                tempRelationship.FinServ__PrimaryGroup__c = true;                
                tempRelationship.Roles = 'Child';
                relationships.add(tempRelationship);
                tempRelationship = new AccountContactRelation( AccountId = householdId );
            }
        }
        insert relationships;
        return accounts;
    }
    
    public static Advice__c createAdvice (Id HouseholdId, Integer numLOAs) {
        String HouseholdSourceIdentifier = 'TestDataFactory';
        householdId = [SELECT Id FROM Account WHERE AccountSource =: HouseholdSourceIdentifier LIMIT 1].Id;
        String adviceRecordTypeDevName = 'Advice_RT_General_Advice';
        Advice__c advice = new Advice__c(
            Advice_Household__c = householdId,
            RecordTypeId = Schema.SObjectType.Advice__c.getRecordTypeInfosByDeveloperName().get(adviceRecordTypeDevName).getRecordTypeId(),
            New_or_existing_client__c = 'New',
            Partner__c = [ SELECT Id FROM User WHERE Id = :UserInfo.getUserId() ].Id,
            Fact_find_requirements__c = 'Not required',
            Scope_of_advice_status__c = 'Not required',
            G_Drive_Advice_Folder__c = 'google.com',
            Update_valuations__c = 'No',
            New_LOAs_required__c = 'Yes',
            Advice_confirmed_with_client__c = 'Yes', 
            Ready_to_start_data_gathering__c = true,
            Advice_Status__c = 'Data Gathering',
            Subject__c = 'Test Advice',
            Name = 'Test Advice'
        );
        
        insert advice;
        
        if( numLOAs != 0){
            Public_Provider_Names__c publicProvider = new Public_Provider_Names__c (Name = 'Test provider');
            insert publicProvider;
            Provider_Database__c providerDB = new Provider_Database__c (Name = 'John Smith', Provider_Name__c = 'Test provider DB');
            insert providerDB;
            List<AccountContactRelation> customers = [SELECT Id, Contact.AccountId, Roles FROM AccountContactRelation WHERE AccountId =: householdId];
            String client1Id;
            String client2Id;
            for(AccountContactRelation customer : customers) {
                if(customer.Roles == 'Client' && client1Id == null){
                    client1Id = customer.Contact.AccountId;
                } else if (customer.Roles == 'Client' && client2Id == null){
                    client2Id = customer.Contact.AccountId;
                }
            }
            
            List<FinServ__FinancialAccount__c> productsCreate = new List<FinServ__FinancialAccount__c>();
            
            for(AccountContactRelation customer : customers) {
                Integer i;
                for( i = 0 ; i < numLOAs; i++) {
                    FinServ__FinancialAccount__c product = new FinServ__FinancialAccount__c(
                        Name = 'Test Product ' + i,
                        Subtype__c  = 'Stocks & Shares ISA',
                        FinServ__PrimaryOwner__c = customer.Contact.AccountId,
                        Household__c = householdId,
                        FinServ__Ownership__c = 'Individual',
                        FinServ__Status__c = 'Open',
                        Public_Provider_Name__c = publicProvider.Id,
                        Provider_Contact_Details__c = providerDB.Id,
                        RecordTypeId = Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName().get('FP_Stocks_Shares_ISA').getRecordTypeId()
                    );
                    productsCreate.add(product);
                }
            }
            
            FinServ__FinancialAccount__c product = new FinServ__FinancialAccount__c(
                Name = 'Test joint account',
                Subtype__c  = 'Current Account',
                FinServ__PrimaryOwner__c = client1Id,
                FinServ__JointOwner__c = client2Id,
                FinServ__Ownership__c = 'Joint',
                Household__c = householdId,
                FinServ__Status__c = 'Open',
                Public_Provider_Name__c = publicProvider.Id,
                Provider_Contact_Details__c = providerDB.Id,
                RecordTypeId = Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName().get('FP_Current_Account').getRecordTypeId()
            );
            productsCreate.add(product);
            
            insert productsCreate;
            
            List<LOA__c> loasCreate = new List<LOA__c>();
            for( FinServ__FinancialAccount__c prod : productsCreate){
                LOA__c loa = new LOA__c(
                    Name = 'Test LOA',
                    LOA_Financial_Account__c = prod.Id,
                    Household_Lookup__c = householdId,
                    MainLOAStatus__c = 'LOA Received Awaiting Information',
                    Date_LOA_sent_to_provider__c = Date.today(),
                    Date_LOA_accepted_by_provider__c = Date.today(),
                    Date_Last_Chased__c = Date.today(),
                    RecordTypeId = Schema.SObjectType.LOA__c.getRecordTypeInfosByDeveloperName().get('Pre_LOA').getRecordTypeId() 
                );
                loasCreate.add(loa);
            }
            insert loasCreate;
            
            List<LOA_to_Advice__c> ltas = new List<LOA_to_Advice__c>();
            for( LOA__c loaLoop : loasCreate){
                LOA_to_Advice__c lta = new LOA_to_Advice__c(
                    Advice__c = advice.Id,
                    LOA__c = loaLoop.Id
                );
                ltas.add(lta);
            }
            insert ltas;
        }
        return advice;
    }
}
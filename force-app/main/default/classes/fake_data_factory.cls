public class fake_data_factory {
    
    /**
* TITLE:	Create test household
* GOAL:		Generates household data for demo and test purposes.
* NOTES:	Stored in production so available in refreshed sandboxes but should not be used in production, though is initially for portal purposes. 
* 			Takes inputs of:
* 				- number of clients in the household
* 				- number of children in the household
* 				- status of the household
* 				- fact find type
* 				- identifier used to find this data after creation
**/    
    
    // Takes a number of clients, children, and status as inputs and generates the data   
    public Id create_household (String identifier, Integer num_clients, Integer num_children, String status, String profile_type) {
        
        // Define a few variables used throughout
        String HouseholdRecordTypeDevName = 'IndustriesHousehold';
        String PersonRecordTypeDevName = 'PersonAccount';
        List<Account> accounts = new List<Account>(); // The list of accounts that will ultimately be inserted
        
        // Create the family name
        random_name_generator rng = new random_name_generator();
        String family_name = rng.generate_name('last_name');
        String household_name = family_name;
        
        // Create the clients
        for( Integer i = 0; i < num_clients; i++) {
            Account person = new Account(
                FirstName = rng.generate_name('first_name'), 
                LastName = family_name,  
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(PersonRecordTypeDevName).getRecordTypeId(),
                OW_role_in_primary_household__c = 'Client',
                FinServ__Status__c = status,
                PersonEmail = family_name + i + '@fakeemail.com',
                utm_medium__c = identifier // Set an identifier specified by the requestor in a random unused text field so that these records can be identified by the requestor
            );
            accounts.add(person);
            
            // Add to the household name the initial of this client
            household_name = household_name + ', ' + person.FirstName.left(1);
        }
        
        // Create the children
        for( Integer i = 0; i < num_children; i++) {
            Account person = new Account(
                FirstName = rng.generate_name('first_name'), 
                LastName = family_name,  
                RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(PersonRecordTypeDevName).getRecordTypeId(),
                OW_role_in_primary_household__c = 'Child',
                FinServ__Status__c = status,
                utm_medium__c = identifier // Set an identifier specified by the requestor in a random unused text field so that these records can be identified by the requestor
            );
            accounts.add(person);
        }
        
        // Create the household then insert all the accounts
        Account household = new Account(
            Name = household_name,
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(HouseholdRecordTypeDevName).getRecordTypeId(),
            FinServ__Status__c = status,
            Fact_Find_Type__c = profile_type,
            utm_medium__c = identifier // Set an identifier specified by the requestor in a random unused text field so that these records can be identified by the requestor            
        );
        accounts.add(household);
        insert accounts;
        
        // Identify the household ID and the list of person account IDs now that they have been inserted
        String household_id;
        List<Id> person_ids = new List<Id>();
        for (Account acc : accounts){
            if( acc.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(HouseholdRecordTypeDevName).getRecordTypeId() ){
                household_id = acc.Id;
            } else {
                person_ids.add(acc.Id);
            }
        }
        
        // Return full details of the person accounts created earlier so the contact ID is known
        List<Account> person_accounts = [SELECT Id, PersonContactId, OW_role_in_primary_household__c FROM Account WHERE Id in: person_ids];
        
        // Create the account contact relationships between the household and the clients and children
        List<AccountContactRelation> acrs = new List<AccountContactRelation>();
        Boolean primary_client_set = false;
        for (Account acc : person_accounts){
            AccountContactRelation acr = new AccountContactRelation(
                AccountId = household_id,
                ContactId = acc.PersonContactId,
                FinServ__PrimaryGroup__c = true,
                Roles = acc.OW_role_in_primary_household__c,
                FinServ__SourceSystemId__c = identifier // Set an identifier specified by the requestor in a random unused text field so that these records can be identified by the requestor
            );
            if( primary_client_set == false && acr.Roles == 'Client'){
                acr.FinServ__Primary__c = true;
                primary_client_set = true;
            }
            acrs.add(acr);
        }
        insert acrs;
        return household_id;
    }
    
    // Takes a given household and creates a defined number of products per person with associated LOAs
    public Advice__c create_advice (String identifier, Integer num_products_pp, Id household_id){
        
        // Define constants used throughout
        String advice_record_type_dev_name = 'Advice_RT_General_Advice';
		String financial_product_record_type_dev_name = 'FP_Stocks_Shares_ISA';
        String financial_product_record_type_dev_name_joint = 'FP_General_Investment_Account_GIA';
        String public_provider_name = 'Big bank of biznizz';
        
        // Define and insert the advice record
        Advice__c advice = new Advice__c(
            Advice_Household__c = household_id,
            RecordTypeId = Schema.SObjectType.Advice__c.getRecordTypeInfosByDeveloperName().get(advice_record_type_dev_name).getRecordTypeId(),
            New_or_existing_client__c = 'Existing',
            Partner__c = [ SELECT Id FROM User WHERE Id = :UserInfo.getUserId() ].Id,
            Fact_find_requirements__c = 'Not required',
            G_Drive_Advice_Folder__c = 'google.com',
            Update_valuations__c = 'No',
            New_LOAs_required__c = 'No', 
            Advice_Status__c = 'Data Gathering',
            Subject__c = identifier,
            Name = identifier
        );
        insert advice;
        
        // Create the products
        if( num_products_pp != 0){
            
            // Identify an existing fake public provider or create a new one if none exists
            Public_Provider_Names__c public_provider = new Public_Provider_Names__c();
            Public_Provider_Names__c[] public_providers = [SELECT Id FROM Public_Provider_Names__c WHERE Name =: public_provider_name];
            if(public_providers.size() == 0){
                public_provider = new Public_Provider_Names__c (
                    Name = public_provider_name
                );
                insert public_provider;
            } else {
                public_provider = public_providers[0];
            }
            
            //Might not be needed as hoping this is not mandatory. 
            //Provider_Database__c providerDB = new Provider_Database__c (Name = 'John Smith', Provider_Name__c = 'Test provider DB');
            //insert providerDB;
            
            // Get the clients from the household
            AccountContactRelation[] acrs = [SELECT Id, Contact.AccountId FROM AccountContactRelation WHERE Roles = 'Client' AND AccountId =: household_id];
            
            // Start list of financial products to create
            List<FinServ__FinancialAccount__c> financial_products = new List<FinServ__FinancialAccount__c>();
            
            // Create financial products for each of the clients in the household
            for(AccountContactRelation acr : acrs) {
                Integer i;
                for( i = 0 ; i < num_products_pp; i++) {
                    FinServ__FinancialAccount__c financial_product = new FinServ__FinancialAccount__c(
                        Name = 'Test',
                        Subtype__c  = 'Stocks & Shares ISA',
                        FinServ__PrimaryOwner__c = acr.Contact.AccountId,
                        Household__c = household_id,
                        FinServ__Ownership__c = 'Individual',
                        FinServ__Status__c = 'Open',
                        Public_Provider_Name__c = public_provider.Id,
                        //Provider_Contact_Details__c = providerDB.Id,
                        RecordTypeId = Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName().get(financial_product_record_type_dev_name).getRecordTypeId()
                    );
                    financial_products.add(financial_product);
                }
            }
            
            // Create a joint account if there are 2 or more clients in the household
            if(acrs.size() >= 2){
                FinServ__FinancialAccount__c financial_product = new FinServ__FinancialAccount__c(
                    Name = 'Test',
                    Subtype__c  = 'General Investment Account',
                    FinServ__PrimaryOwner__c = acrs[0].Contact.AccountId,
                    FinServ__JointOwner__c = acrs[1].Contact.AccountId,
                    FinServ__Ownership__c = 'Joint',
                    Household__c = household_id,
                    FinServ__Status__c = 'Open',
                    Public_Provider_Name__c = public_provider.Id,
                    //Provider_Contact_Details__c = providerDB.Id,
                    RecordTypeId = Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName().get(financial_product_record_type_dev_name_joint).getRecordTypeId()
                );
                financial_products.add(financial_product);
            }
            insert financial_products;
            
            // Create LOAs for the financial products
            List<LOA__c> loas = new List<LOA__c>();
            for( FinServ__FinancialAccount__c financial_product : financial_products){
                LOA__c loa = new LOA__c(
                    Name = 'Test LOA',
                    LOA_Financial_Account__c = financial_product.Id,
                    Household_Lookup__c = household_id,
                    MainLOAStatus__c = 'LOA Received Awaiting Information',
                    Date_LOA_sent_to_provider__c = Date.today(),
                    Date_LOA_accepted_by_provider__c = Date.today(),
                    Date_Last_Chased__c = Date.today(),
                    RecordTypeId = Schema.SObjectType.LOA__c.getRecordTypeInfosByDeveloperName().get('Pre_LOA').getRecordTypeId() 
                );
                loas.add(loa);
            }
            insert loas;
            
            // Link the LOAs to the advice
            List<LOA_to_Advice__c> ltas = new List<LOA_to_Advice__c>();
            for(LOA__c loa : loas){
                LOA_to_Advice__c lta = new LOA_to_Advice__c(
                    Advice__c = advice.Id,
                    LOA__c = loa.Id
                );
                ltas.add(lta);
            }
            insert ltas;
        }
        return advice;
    }
}
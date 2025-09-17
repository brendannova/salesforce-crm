/*
* @Description: 
*
*
*/

public class FakeDataGenerata {
    
    public Id createHousehold(String identifier, Integer num_clients, Integer num_children, String status, String profile_type){
        // Define a few variables used throughout
        String HouseholdRecordTypeDevName = 'IndustriesHousehold';
        String PersonRecordTypeDevName = 'PersonAccount';
        List<Account> accounts = new List<Account>();
        List<FinServ__Employment__c> employments = new List< FinServ__Employment__c>();
        
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
                FinServ__Status__c = 'Onboarding',
                PersonEmail = family_name + i + '@fakeemail.com',
                PersonBirthdate  = System.Today().addYears(-23),
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
                FinServ__Status__c = 'Onboarding',
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

        for (Account acc : accounts) {
            if( acc.RecordTypeId == Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(HouseholdRecordTypeDevName).getRecordTypeId() ){
            } else {

            FinServ__Employment__c employment = new FinServ__Employment__c (
                    AmlStatus__c = 'Pending',
                    BankAccountStatus__c = 'Pending',
                    Name = 'Top Employer',
                    OW_status__c = 'Current',
                    Household__c = household_id,
                    Person_Account__c = acc.id
                );
                employments.add(employment);
            }
        }
        insert employments;

        return household_id;
    }
    
    public List<FinServ__FinancialAccount__c> createProducts(Id household_id, Map<String, String> product_types){
        // Identify an existing fake public provider or create a new one if none exists
        Public_Provider_Names__c public_provider = new Public_Provider_Names__c();
        Public_Provider_Names__c[] public_providers = [SELECT Id FROM Public_Provider_Names__c WHERE Name =: 'Big bank of bizznizz'];
        if(public_providers.size() == 0){
            public_provider = new Public_Provider_Names__c (
                Name = 'Big bank of bizznizz',
                ReferenceName__c = 'BBB'
            );
            insert public_provider;
        } else {
            public_provider = public_providers[0];
        }
        
        // Get the clients from the household
        AccountContactRelation[] acrs = [SELECT Id, Contact.AccountId FROM AccountContactRelation WHERE Roles = 'Client' AND AccountId =: household_id];
        
        // Start list of financial products to create
        List<FinServ__FinancialAccount__c> financial_products = new List<FinServ__FinancialAccount__c>();
        
        // Create financial products for each of the clients in the household
        for(AccountContactRelation acr : acrs) {
            for( String ptype : product_types.keySet() ) {
                FinServ__FinancialAccount__c financial_product = new FinServ__FinancialAccount__c(
                    Name = 'Test',
                    Subtype__c  = ptype,
                    FinServ__PrimaryOwner__c = acr.Contact.AccountId,
                    Household__c = household_id,
                    FinServ__Ownership__c = 'Individual',
                    FinServ__Status__c = 'Open',
                    Public_Provider_Name__c = public_provider.Id,
                    RecordTypeId = Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName().get(product_types.get(ptype)).getRecordTypeId()
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
                RecordTypeId = Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName().get('FP_General_Investment_Account_GIA').getRecordTypeId()
            );
            financial_products.add(financial_product);
        }
        insert financial_products;

      	return financial_products;  
    }
    
    public Id createAdvice(String identifier, String household_id, String status){ 
	// Define and insert the advice record
        Advice__c advice = new Advice__c(
            Advice_Household__c = household_id,
            RecordTypeId = Schema.SObjectType.Advice__c.getRecordTypeInfosByDeveloperName().get('Advice_RT_General_Advice').getRecordTypeId(),
            New_or_existing_client__c = 'Existing',
            Partner__c = [ SELECT Id FROM User WHERE Id = :UserInfo.getUserId() ].Id,
            Fact_find_requirements__c = 'Not required',
            G_Drive_Advice_Folder__c = 'google.com',
            Update_valuations__c = 'No',
            New_LOAs_required__c = 'No', 
            Advice_Status__c = status,
            Subject__c = identifier,
            Name = identifier,
            AdviceDeckCompleteDate__c = System.today()
        );
        insert advice;
        return advice.Id;
    }
    public List<Recommendation__c> createRecommendations(Map<String, String> rectypes, List<String> producttypes, String AdviceId, String household_id) {
        List<Recommendation__c> recommendations = new List<Recommendation__c>();
        List<AdviceRecipient__c> adviceRecipients = new List<AdviceRecipient__c>();
        AccountContactRelation[] acrs = [SELECT Id, Contact.AccountId FROM AccountContactRelation WHERE Roles = 'Client' AND AccountId =: household_id];
        for (AccountContactRelation account : acrs ) {
            for ( String type : producttypes ) {
                Recommendation__c newrec = new Recommendation__c(
                    Advice__c = adviceId,
                    DateOfDecision__c = System.Today(),
                    Household__c = household_id,
                    PrimaryOwner__c = account.Contact.AccountId,
                    Product__c = [ SELECT Id FROM Product__c WHERE ReferenceName__c =: type ].Id, 
                    RecommendationType__c = [ SELECT Id FROM RecommendationType__c WHERE ReferenceName__c = 'OPEN_PRODUCT' ].Id,
                    Status__c = 'Accepted'
                );
                recommendations.add(newrec);
            }
            FinServ__FinancialAccount__c destination = [ SELECT Id, Product__c FROM FinServ__FinancialAccount__c WHERE FinServ__PrimaryOwner__c =: account.Contact.AccountId LIMIT 1 ];
            FinServ__Employment__c employer = [ SELECT Id FROM FinServ__Employment__c WHERE Person_Account__c =: account.Contact.AccountId LIMIT 1 ];

            for ( String type : rectypes.keySet() ) {
                Recommendation__c newrec = new Recommendation__c(
                    Advice__c = adviceId,
                    DateOfDecision__c = System.Today(),
                    Household__c = household_id,
                    PrimaryOwner__c = account.Contact.AccountId,
                    DestinationLegacy__c = destination.Id,
                    Employment__c = employer.Id,
                    Product__c = destination.Product__c,
                    PaidBy__c = rectypes.get(type),
                    RecommendationType__c = [ SELECT Id FROM RecommendationType__c WHERE ReferenceName__c =: type ].Id,
                    Status__c = 'Accepted'
                );
                recommendations.add(newrec);
            }

            AdviceRecipient__c advrec = new AdviceRecipient__c (
                Person__c = account.Contact.AccountId,
                Advice__c = adviceId,
                AcceptedAdvice__c = 'SomeOrAllAdviceAccepted',
                Advised__c = 'Yes'
            );
            adviceRecipients.add(advrec);

        } 
        insert recommendations;
        insert adviceRecipients;
        return recommendations;       
    }

}
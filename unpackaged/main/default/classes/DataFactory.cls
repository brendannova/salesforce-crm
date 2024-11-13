/**
* TITLE:	Create test household
* GOAL:		Generates household data for demo and test purposes.
* NOTES:	Stored in production so available in refreshed sandboxes but should not be used in production, though is initially for portal purposes. 
* 			Takes inputs of:
* 				- number of clients in the household
* 				- number of children in the household
* 				- status of the household
* 				- fact find type
**/
public with sharing class DataFactory {
    
    String RecordTypeDevNameHousehold = 'IndustriesHousehold';
    Id RecordTypeIdHousehold = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(RecordTypeDevNameHousehold).getRecordTypeId();
    
    String RecordTypeDevNamePerson = 'PersonAccount';
    Id RecordTypeIdPerson = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(RecordTypeDevNamePerson).getRecordTypeId();

    /*public void createConfigurationData(){
        List<sObject> ls = Test.loadData(Public_Provider_Names__c.sObjectType, 'ProvidersRef');
        List<sObject> ls3 = Test.loadData(RecommendationType__c.sObjectType, 'RecRef');
        List<sObject> ls4 = Test.loadData(ProductType__c.sObjectType, 'ProductTypeRef');
        List<sObject> ls2 = Test.loadData(Product__c.sObjectType, 'ProductRef');
    }
    */
    
    // Takes a number of clients, children, and status as inputs and generates the data   
    public Id createHousehold (String idenfitifer, Integer numClients, Integer numChildren, String status, String profileType) {
        
        List<Account> accounts = new List<Account>(); // The list of accounts that will ultimately be inserted
        // Create the family name
        String familyName = generateName(false, true, false).lastName;
        String householdName = familyName;
        
        // Create the clients
        for( Integer i = 0; i < numClients; i++) {
            Account person = new Account(
                FirstName = generateName(true, false, false).firstName,
                LastName = familyName,  
                RecordTypeId = this.RecordTypeIdPerson,
                OW_role_in_primary_household__c = 'Client',
                FinServ__Status__c = status,
                PersonEmail = familyName + i + '@fakeemail.com',
                PersonBirthdate  = System.Today().addYears(-23)
            );
            accounts.add(person);
            
            // Add to the household name the initial of this client
            householdName += ', ' + person.FirstName.left(1);
        }
        
        // Create the children
        for( Integer i = 0; i < numChildren; i++) {
            Account person = new Account(
                FirstName = generateName(true, false, false).firstName,
                LastName = familyName,  
                RecordTypeId = this.RecordTypeIdPerson,
                OW_role_in_primary_household__c = 'Child',
                FinServ__Status__c = 'Junior'
            );
            accounts.add(person);
        }
        
        // Create the household then insert all the accounts
        Account household = new Account(
            Name = householdName,
            RecordTypeId = this.RecordTypeIdHousehold,
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
        return household.Id;
    }
    
    // Takes a given household and creates a defined number of products per person with associated LOAs
    public Advice__c createAdvice (Integer num_products_pp, Id householdId){
        
        // Define constants used throughout
        String advice_record_type_dev_name = 'Advice_RT_General_Advice';
        String financial_product_record_type_dev_name = 'FP_Stocks_Shares_ISA';
        String financial_product_record_type_dev_name_joint = 'FP_General_Investment_Account_GIA';
        String public_provider_name = 'Big bank of biznizz';
        
        // Define and insert the advice record
        Advice__c advice = new Advice__c(
            Advice_Household__c = householdId,
            RecordTypeId = Schema.SObjectType.Advice__c.getRecordTypeInfosByDeveloperName().get(advice_record_type_dev_name).getRecordTypeId(),
            New_or_existing_client__c = 'Existing',
            Partner__c = [ SELECT Id FROM User WHERE Id = :UserInfo.getUserId() ].Id,
            Fact_find_requirements__c = 'Not required',
            G_Drive_Advice_Folder__c = 'google.com',
            Update_valuations__c = 'No',
            New_LOAs_required__c = 'No', 
            Advice_Status__c = 'Data Gathering',
            Subject__c = 'Test advice',
            Name = 'Test advice',
            FulfilmentUpdateStatus__c = 'Receiving updates'
        );
        insert advice;
        
        // Create the products
        if( num_products_pp != 0){
            
            // Identify an existing fake public provider or create a new one if none exists
            Public_Provider_Names__c public_provider = new Public_Provider_Names__c();
            Public_Provider_Names__c[] public_providers = [SELECT Id FROM Public_Provider_Names__c WHERE Name =: public_provider_name];
            if(public_providers.size() == 0){
                public_provider = new Public_Provider_Names__c (
                    Name = public_provider_name,
                    ReferenceName__c = public_provider_name
                );
                insert public_provider;
            } else {
                public_provider = public_providers[0];
            }
            
            //Might not be needed as hoping this is not mandatory. 
            //Provider_Database__c providerDB = new Provider_Database__c (Name = 'John Smith', Provider_Name__c = 'Test provider DB');
            //insert providerDB;
            
            // Get the clients from the household
            AccountContactRelation[] acrs = [SELECT Id, Contact.AccountId FROM AccountContactRelation WHERE Roles = 'Client' AND AccountId =: householdId];
            
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
                        Household__c = householdId,
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
                    Household__c = householdId,
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
                    Household_Lookup__c = householdId,
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
            
            List<FinServ__FinancialAccount__c> novaprods = new List<FinServ__FinancialAccount__c>();
            Id novaProviderId = [SELECT Id FROM Public_Provider_Names__c WHERE OW_own_company__c = true ].Id;
            for(AccountContactRelation acr : acrs) {
                FinServ__FinancialAccount__c novaprod = new FinServ__FinancialAccount__c(
                    Name = 'Test',
                    Subtype__c  = 'Stocks & Shares ISA',
                    FinServ__PrimaryOwner__c = acr.Contact.AccountId,
                    Household__c = householdId,
                    FinServ__Status__c = 'Open',
                    Public_Provider_Name__c = novaProviderId,
                    RecordTypeId = Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName().get('FP_Stocks_Shares_ISA').getRecordTypeId()
                );
                novaprods.add(novaprod);
            }
            insert(novaprods);
            
            List<Recommendation__c> recs = new List<Recommendation__c>();
            String ssisaId = [SELECT Id FROM Product__c WHERE ReferenceName__c = 'SSISA_HUBWISE' ].Id;
            Id recId = [SELECT Id FROM RecommendationType__c WHERE ReferenceName__c = 'OPEN_PRODUCT' ].Id;
            Id recTypeId = [SELECT Id FROM RecommendationType__c WHERE ReferenceName__c = 'LUMP_SUM' ].Id;
            // Create recommendations for each of the clients in the household
            for(FinServ__FinancialAccount__c novaprod : novaprods) {
                Recommendation__c newrec = new Recommendation__c(
                    Advice__c = advice.Id,
                    DateOfDecision__c = System.Today(),
                    Household__c = householdId,
                    InvestmentMandate__c = 'Passive Plus 80 (S)',
                    PrimaryOwner__c = novaprod.FinServ__PrimaryOwner__r.Id,
                    Product__c = ssisaId,
                    RecommendationType__c = recId,
                    Status__c = 'Accepted',
                    DestinationLegacy__c = novaprod.Id
                );
                recs.add(newrec);
                Recommendation__c newlumprec = new Recommendation__c(
                    Advice__c = advice.Id,
                    Amount__c  = 1000,
                    DateOfDecision__c = System.Today(),
                    Household__c = householdId,
                    InvestmentMandate__c = 'Passive Plus 80 (S)',
                    PrimaryOwner__c = novaprod.FinServ__PrimaryOwner__r.Id,
                    PaidBy__c = 'Client',
                    PhasingFrequency__c = 'Single',
                    RecommendationType__c = recTypeId,
                    Status__c = 'Accepted',
                    DestinationLegacy__c = novaprod.Id
                );
                recs.add(newlumprec);
            }
            insert(recs);
            
            // Create open product fulfilments
            List<Fulfilment__c> fulfils = new List<Fulfilment__c>();
            for( Recommendation__c rec : recs){
                Fulfilment__c fulfil = new Fulfilment__c(
                    Recommendation__c = rec.Id,
                    Household__c = householdId,
                    Status__c = 'Awaiting pre-requisites',
                    AdditionalBankDetailsStatus__c = 'Not required',
                    Advice__c = advice.Id,
                    ExpressionOfWishFormStatus__c = 'Not required',
                    FulfilmentType__c = [SELECT Id FROM FulfilmentType__c WHERE RecommendationType__c =: rec.RecommendationType__c AND DestinationProductType__c = '0121t0000001eNHAAY' ].Id,
                    SearchName__c = rec.PrimaryOwner__c + ' | ' + rec.recommendationType__r.Name + ' ISA ',
                    TransferFormsStatus__c = 'Not required'
                );
                fulfils.add(fulfil);
            }
            insert fulfils;
        }
        return advice;
    }

    // Generates random names for use in this data factory script
    private RandomName generateName(Boolean first, Boolean last, Boolean preferred){
        Integer nameIndex;
        RandomName name = new RandomName();
        if(first){
            List<String> firstNames = new List<String>{'Aaliyah', 'Abigail', 'Addison', 'Alexa', 'Alexandra', 'Alexis', 'Alice', 'Allison', 'Alyssa', 'Amelia', 'Anna', 'Annabelle', 'Aria', 'Ariana', 'Arianna', 'Ashley', 'Aubree', 'Aubrey', 'Audrey', 'Autumn', 'Ava', 'Avery', 'Bella', 'Brianna', 'Brooklyn', 'Camila', 'Caroline', 'Charlotte', 'Chloe', 'Claire', 'Eleanor', 'Elizabeth', 'Ella', 'Ellie', 'Emily', 'Emma', 'Eva', 'Evelyn', 'Faith', 'Gabriella', 'Genesis', 'Gianna', 'Grace', 'Hadley', 'Hailey', 'Hannah', 'Harper', 'Isabella', 'Isabelle', 'Jasmine', 'Julia', 'Katherine', 'Kaylee', 'Kennedy', 'Khloe', 'Kylie', 'Lauren', 'Layla', 'Leah', 'Lillian', 'Lily', 'London', 'Lucy', 'Lydia', 'Mackenzie', 'Madeline', 'Madelyn', 'Madison', 'Maya', 'Melanie', 'Mia', 'Mila', 'Naomi', 'Natalie', 'Nevaeh', 'Nora', 'Olivia', 'Paisley', 'Penelope', 'Peyton', 'Piper', 'Riley', 'Ruby', 'Sadie', 'Samantha', 'Sarah', 'Savannah', 'Scarlett', 'Serenity', 'Skylar', 'Sofia', 'Sophia', 'Sophie', 'Stella', 'Taylor', 'Victoria', 'Violet', 'Vivian', 'Zoe', 'Zoey', 'Aaron', 'Adam', 'Adrian', 'Aiden', 'Alexander', 'Andrew', 'Angel', 'Anthony', 'Asher', 'Austin', 'Ayden', 'Benjamin', 'Bentley', 'Blake', 'Brandon', 'Brayden', 'Brody', 'Caleb', 'Camden', 'Cameron', 'Carson', 'Carter', 'Charles', 'Chase', 'Christian', 'Christopher', 'Colton', 'Connor', 'Cooper', 'Daniel', 'David', 'Dominic', 'Dylan', 'Easton', 'Eli', 'Elijah', 'Ethan', 'Evan', 'Gabriel', 'Gavin', 'Grayson', 'Henry', 'Hudson', 'Hunter', 'Ian', 'Isaac', 'Isaiah', 'Jace', 'Jack', 'Jackson', 'Jacob', 'James', 'Jason', 'Jaxon', 'Jaxson', 'Jayden', 'Jeremiah', 'John', 'Jonathan', 'Jordan', 'Jose', 'Joseph', 'Joshua', 'Josiah', 'Juan', 'Julian', 'Justin', 'Kayden', 'Kevin', 'Landon', 'Leo', 'Levi', 'Liam', 'Lincoln', 'Logan', 'Lucas', 'Luis', 'Luke', 'Mason', 'Matthew', 'Michael', 'Nathan', 'Nathaniel', 'Nicholas', 'Noah', 'Nolan', 'Oliver', 'Owen', 'Parker', 'Robert', 'Ryan', 'Ryder', 'Samuel', 'Sebastian', 'Thomas', 'Tristan', 'Tyler', 'William', 'Wyatt', 'Xavier', 'Zachary'};			
            nameIndex = (Integer)(Math.random() * firstNames.size());
            name.firstName = firstNames[nameIndex];
        }
        if(last){
            List<String> lastNames = new List<String>{'Adams', 'Alexander', 'Allen', 'Alvarez', 'Anderson', 'Arnold', 'Bailey', 'Baker', 'Barnes', 'Bell', 'Bennett', 'Black', 'Boyd', 'Bradley', 'Brooks', 'Brown', 'Bryant', 'Burns', 'Butler', 'Campbell', 'Carter', 'Castillo', 'Castro', 'Chavez', 'Clark', 'Cole', 'Coleman', 'Collins', 'Cook', 'Cooper', 'Cox', 'Crawford', 'Cruz', 'Cunningham', 'Daniels', 'Davis', 'Diaz', 'Dixon', 'Dunn', 'Edwards', 'Elliott', 'Ellis', 'Evans', 'Ferguson', 'Fernandez', 'Fisher', 'Flores', 'Ford', 'Foster', 'Fox', 'Freeman', 'Garcia', 'Gardner', 'Gibson', 'Gomez', 'Gonzales', 'Gonzalez', 'Gordon', 'Graham', 'Grant', 'Gray', 'Green', 'Griffin', 'Gutierrez', 'Hall', 'Hamilton', 'Hansen', 'Harris', 'Harrison', 'Hart', 'Hawkins', 'Hayes', 'Henderson', 'Henry', 'Hernandez', 'Herrera', 'Hicks', 'Hill', 'Hoffman', 'Holmes', 'Howard', 'Hughes', 'Hunt', 'Hunter', 'Jackson', 'James', 'Jenkins', 'Jimenez', 'Johnson', 'Jones', 'Jordan', 'Kelley', 'Kelly', 'Kennedy', 'Kim', 'King', 'Knight', 'Lee', 'Lewis', 'Long', 'Lopez', 'Marshall', 'Martin', 'Martinez', 'Mason', 'Mcdonald', 'Medina', 'Mendoza', 'Meyer', 'Miller', 'Mills', 'Mitchell', 'Moore', 'Morales', 'Moreno', 'Morgan', 'Morris', 'Murphy', 'Murray', 'Myers', 'Nelson', 'Nguyen', 'Nichols', 'Olson', 'Ortiz', 'Owens', 'Palmer', 'Parker', 'Patel', 'Patterson', 'Payne', 'Perez', 'Perry', 'Peters', 'Peterson', 'Phillips', 'Pierce', 'Porter', 'Powell', 'Price', 'Ramirez', 'Ramos', 'Reed', 'Reyes', 'Reynolds', 'Rice', 'Richardson', 'Rivera', 'Roberts', 'Robertson', 'Robinson', 'Rodriguez', 'Rogers', 'Romero', 'Rose', 'Ross', 'Ruiz', 'Russell', 'Ryan', 'Sanchez', 'Sanders', 'Schmidt', 'Scott', 'Shaw', 'Simmons', 'Simpson', 'Smith', 'Snyder', 'Spencer', 'Stephens', 'Stevens', 'Stewart', 'Stone', 'Sullivan', 'Taylor', 'Thomas', 'Thompson', 'Torres', 'Tran', 'Tucker', 'Turner', 'Vasquez', 'Wagner', 'Walker', 'Wallace', 'Ward', 'Warren', 'Washington', 'Watson', 'Weaver', 'Webb', 'Wells', 'West', 'White', 'Williams', 'Wilson', 'Wood', 'Woods', 'Wright', 'Young'};
			nameIndex = (Integer)(Math.random() * lastNames.size());
            name.lastName = lastNames[nameIndex];
        }
        if(preferred){
            name.preferredName = 'Gareth';
        }
        return name;
    }

    // Random name class that will allow a collection of details to be returned together
    public class RandomName {
        public String firstName {get;set;}
        public String lastName {get;set;}
        public String preferredName {get;set;}
    }
}
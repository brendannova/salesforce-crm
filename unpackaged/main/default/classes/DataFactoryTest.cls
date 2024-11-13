@isTest
global class DataFactoryTest {

    @TestSetup
    static void testDataSetup() {
        // Set up reference data
        List<sObject> ls = Test.loadData(Public_Provider_Names__c.sObjectType, 'ProviderRef');
        List<sObject> ls3 = Test.loadData(RecommendationType__c.sObjectType, 'RecRef');
        List<sObject> ls4 = Test.loadData(ProductType__c.sObjectType, 'ProductTypeRef');
        List<sObject> ls2 = Test.loadData(Product__c.sObjectType, 'ProductRef');
        List<sObject> ls5 = Test.loadData(FulfilmentType__c.sObjectType, 'FTRef');
    }

    @istest
    static void testHouseholdCreation(){
        Integer numClients = 2;
        Integer numChildren = 3;
        String status = 'Active';
        String identifier = 'cth_test_run';
        String profileType = 'Full'; 
        DataFactory df = new DataFactory();
        String householdId = df.createHousehold(identifier, numClients, numChildren, status, profileType);
        
        //Account[] accounts = [SELECT Id FROM Account WHERE FinServ__Status__c =: status and Household_lookup__c =: householdId];
        AccountContactRelation[] acrs = [SELECT Id, Roles FROM AccountContactRelation WHERE AccountId =: householdId];
        
        // Check that there is a relationship for each client and child.
        Integer numChildRelationships = 0;
        Integer numClientRelationships = 0;      
        for(AccountContactRelation acr : acrs){
            if(acr.Roles == 'Client'){
                numClientRelationships++;
            } else if(acr.Roles == 'Child'){
                numChildRelationships++;
            }
        }
        System.assert(numChildRelationships == numChildren); 
        System.assert(numClientRelationships == numClients);
    }
    
    @istest
    static void testAdviceCreation(){
        Integer numClients = 2;
        Integer numProducts = 1;
        Integer numChildren = 0;
        String status = 'Active';
        String identifier = 'cth_test_run_advice';
        String profileType = 'Full'; 
        DataFactory df = new DataFactory();
        Id householdId = df.createHousehold(identifier, numClients, numChildren, status, profileType);
        Advice__c advice = df.createAdvice(numProducts, householdId);
        
        // Get the financial products and LOAs back
        FinServ__FinancialAccount__c[] financial_products = [SELECT Id FROM FinServ__FinancialAccount__c WHERE Household__c =: householdId];
        LOA__c[] loas = [SELECT Id FROM LOA__c WHERE Household_Lookup__c =: householdId];
        
        //System.assert(numClients * numProducts + 1 == financial_products.size()); // Check that there is a financial product for each client plus a joint product
        System.assert(numClients * numProducts + 1 == loas.size()); // Check that there is an LOA for each client plus a joint product
    }
}
@isTest
global class EmailFulfilmentUpdateTest{
    
    private static String getScenarioId(Integer scenarioNumber){
        String scenarioId;
        if(scenarioNumber == 1){
            scenarioId = 'SCENARIO_1';
        } else if (scenarioNumber == 2){
            scenarioId = 'SCENARIO_2';
        } else if (scenarioNumber == 3){
            scenarioId = 'SCENARIO_3';
        } 
        return scenarioId;
    }

    @TestSetup
    static void testDataSetup() {
        // Set up reference data
        List<sObject> ls = Test.loadData(Public_Provider_Names__c.sObjectType, 'ProviderRef');
        List<sObject> ls3 = Test.loadData(RecommendationType__c.sObjectType, 'RecRef');
        List<sObject> ls4 = Test.loadData(ProductType__c.sObjectType, 'ProductTypeRef');
        List<sObject> ls2 = Test.loadData(Product__c.sObjectType, 'ProductRef');
        List<sObject> ls5 = Test.loadData(FulfilmentType__c.sObjectType, 'FTRef');

        // Create scenario 1
        Integer numClients = 2;
        Integer numChildren = 2;
        String householdStatus = 'Active';
        String profileType = 'Full'; 
        DataFactory df = new DataFactory();
        Id householdId = df.createHousehold(getScenarioId(1), numClients, numChildren, householdStatus, profileType);
        Advice__c advice = df.createAdvice(2, householdId);

        // Create scenario 2
        numClients = 1;
        numChildren = 0;
        householdStatus = 'Active';
        profileType = 'Full'; 
        df = new DataFactory();
        householdId = df.createHousehold(getScenarioId(2), numClients, numChildren, householdStatus, profileType);
        advice = df.createAdvice(2, householdId);

        /*
        // Create scenario 3
        numClients = 3;
        numChildren = 0;
        householdStatus = 'Active';
        profileType = 'Full'; 
        df = new DataFactory();
        householdId = df.createHousehold(getScenarioId(3), numClients, numChildren, householdStatus, profileType);
        advice = df.createAdvice(2, householdId);*/
    }
    
    @istest
    static void testTableData(){
        Test.startTest();
        Id householdId = [SELECT Id FROM Account WHERE OW_admin_notes__c = :getScenarioId(1) LIMIT 1].Id;
        System.currentPageReference().getParameters().put('objectId', householdId); 
        EmailFulfilmentUpdate GetInfo = new EmailFulfilmentUpdate();
        GetInfo.getOwners();    
        System.assertEquals(GetInfo.objectId, householdId); 
        Test.stopTest();
    } 

    @istest
    static void testHiString(){
        Test.startTest();
        Id householdId = [SELECT Id FROM Account WHERE OW_admin_notes__c = :getScenarioId(1) LIMIT 1].Id;
        System.currentPageReference().getParameters().put('objectId', householdId); 
        EmailFulfilmentUpdate GetInfo = new EmailFulfilmentUpdate();
        GetInfo.getHiString();
        System.assertEquals(GetInfo.objectId, householdId);
        Test.stopTest(); 
    } 

    @istest
    static void testIntroCopyRegular(){
        Test.startTest();
        Id householdId = [SELECT Id FROM Account WHERE OW_admin_notes__c = :getScenarioId(1) LIMIT 1].Id;
        System.currentPageReference().getParameters().put('objectId', householdId); 
        EmailFulfilmentUpdate GetInfo = new EmailFulfilmentUpdate();
        GetInfo.getIntroCopyRegular();
        System.assertEquals(GetInfo.objectId, householdId); 
        Test.stopTest();
    } 

    @istest
    static void testIntroCopyFinal(){
        Test.startTest();
        Id householdId = [SELECT Id FROM Account WHERE OW_admin_notes__c = :getScenarioId(1) LIMIT 1].Id;
        System.currentPageReference().getParameters().put('objectId', householdId); 
        EmailFulfilmentUpdate GetInfo = new EmailFulfilmentUpdate();
        GetInfo.getIntroCopyFinal();
        System.assertEquals(GetInfo.objectId, householdId); 
        Test.stopTest();
    } 

    @istest
    static void testTableData1Client(){
        Test.startTest();
        Id householdId = [SELECT Id FROM Account WHERE OW_admin_notes__c = :getScenarioId(2) LIMIT 1].Id;
        System.currentPageReference().getParameters().put('objectId', householdId); 
        EmailFulfilmentUpdate GetInfo = new EmailFulfilmentUpdate();
        GetInfo.getOwners();    
        System.assertEquals(GetInfo.objectId, householdId); 
        Test.stopTest();
    } 

    /*
    @istest
    static void testTableData3Client(){
        Test.startTest();
        Id householdId = [SELECT Id FROM Account WHERE OW_admin_notes__c = :getScenarioId(3) LIMIT 1].Id;
        System.currentPageReference().getParameters().put('objectId', householdId); 
        FulfilmentUpdateEmail GetInfo = new FulfilmentUpdateEmail();
        GetInfo.getOwners();    
        System.assertEquals(GetInfo.objectId, householdId); 
        Test.stopTest();
    } 
    */
}
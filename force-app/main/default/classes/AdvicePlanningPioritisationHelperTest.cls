@isTest
public with sharing class AdvicePlanningPioritisationHelperTest {

    @isTest
    static void getAdvice_success() {
        List<sObject> ls = Test.loadData(Public_Provider_Names__c.sObjectType, 'ProviderRef');
        List<sObject> ls3 = Test.loadData(RecommendationType__c.sObjectType, 'RecRef');
        List<sObject> ls4 = Test.loadData(ProductType__c.sObjectType, 'ProductTypeRef');
        List<sObject> ls2 = Test.loadData(Product__c.sObjectType, 'ProductRef');
        List<sObject> ls5 = Test.loadData(FulfilmentType__c.sObjectType, 'FTRef');
        Integer numClients = 2;
        Integer numChildren = 2;
        String householdStatus = 'Active';
        String profileType = 'Full'; 
        DataFactory df = new DataFactory();
        Id householdId = df.createHousehold('Test', numClients, numChildren, householdStatus, profileType);
        Advice__c advice = df.createAdvice(2, householdId);
        List<Advice__c> records = AdvicePlanningPioritisationHelper.getAdvice();
        System.Assert.areEqual(records.size(), 1, 'Expected 1 advice record');
    }    
}
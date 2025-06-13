/* Test class to support LwcHelperCustomerFactsList 
 * Create a fact category, fact and customer fact linked to household and ensure it appears on the manage facts data table
 */
@isTest
public with sharing class LwcHelperCustomerFactsListTest {
    @isTest
    static void createList(){
        List<Account> testAccounts = TestDataFactory.createHousehold(2,0,'1239');
        Id hhRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesHousehold').getRecordTypeId();
        Id personRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account household = [SELECT Id, Name, AccountNumber FROM Account WHERE Id IN: testAccounts AND RecordTypeId =: hhRT LIMIT 1];
        Account person = [SELECT Id, Name, AccountNumber FROM Account WHERE Id IN: testAccounts AND RecordTypeId =: personRT LIMIT 1];
        
        FactCategory__c factCat = new FactCategory__c();
        factCat.Name = 'Objectives';
        factCat.Enum__c = 'OBJECTIVES';
        insert factCat;
        
        Fact__c fact = new Fact__c();
        fact.Name = 'General review';
        fact.Description__c = 'Add this fact if the client would like to see how their finances are performing and where we can improve things. E.g. asset performance, weighting of product types';
        fact.FactCategory__c = factCat.Id;
        insert fact;
        
        
        CustomerFact__c custFact = new CustomerFact__c();
        custFact.Fact__c = fact.Id;
        custFact.Name = fact.Name;
        custFact.Household__c = household.Id;
        custFact.Person__c = person.Id;
        custFact.Status__c = 'Active';
        custFact.Notes__c = 'General review';
        insert custFact;
        
        LwcHelperDynamicRecordList.configWrapper config = new LwcHelperDynamicRecordList.configWrapper();
        config.keyFieldName = 'factId';
        LwcHelperDynamicRecordList.DataWrapper data = LwcHelperCustomerFactsList.getCustomerFactData(household.Id);
        System.Assert.areEqual(1, data.rows.size(), 'Expected 1 row');
        
    }    
}
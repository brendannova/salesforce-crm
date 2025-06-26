/* Test class to support LwcHelperCustomerFactsList 
 * Create a fact category, fact and customer fact linked to household and ensure it appears on the manage facts data table
 */
@isTest
public with sharing class LwcHelperCustomerFactsListTest {
    
    @isTest
    static void createList(){
        List<Account> testAccounts = TestDataFactory.createHousehold(2,0,'1239');
        Id householdRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesHousehold').getRecordTypeId();
        Id personRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account household = [SELECT Id, Name, AccountNumber FROM Account WHERE Id IN: testAccounts AND RecordTypeId =: householdRecordTypeId LIMIT 1];
        Account person = [SELECT Id, Name, AccountNumber FROM Account WHERE Id IN: testAccounts AND RecordTypeId =: personRecordTypeId LIMIT 1];
        
        FactCategory__c factCategory = new FactCategory__c();
        factCategory.Name = 'Objectives';
        factCategory.Enum__c = 'OBJECTIVES';
        insert factCategory;
        
        Fact__c fact = new Fact__c();
        fact.Name = 'General review';
        fact.Description__c = 'Add this fact if the client would like to see how their finances are performing and where we can improve things. E.g. asset performance, weighting of product types';
        fact.FactCategory__c = factCategory.Id;
        insert fact;
        
        
        CustomerFact__c customerFact = new CustomerFact__c();
        customerFact.Fact__c = fact.Id;
        customerFact.Name = fact.Name;
        customerFact.Household__c = household.Id;
        customerFact.Person__c = person.Id;
        customerFact.Status__c = 'Active';
        customerFact.Notes__c = 'General review';
        insert customerFact;
        
        LwcHelperDynamicRecordList.configWrapper config = new LwcHelperDynamicRecordList.configWrapper();
        config.keyFieldName = 'factId';
        LwcHelperDynamicRecordList.DataWrapper data = LwcHelperCustomerFactsList.getCustomerFactData(household.Id);
        System.Assert.areEqual(1, data.rows.size(), 'Expected 1 row');
    }    
}
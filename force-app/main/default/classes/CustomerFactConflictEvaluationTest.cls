@isTest
public class CustomerFactConflictEvaluationTest {
    
    @testSetup
    static void testSetup(){
        List<Account> testAccounts = TestDataFactory.createHousehold(2,0,'1235');
        Id hhRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesHousehold').getRecordTypeId();
        Id personRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account household = [SELECT Id, Name, AccountNumber FROM Account WHERE Id IN: testAccounts AND RecordTypeId =: hhRT LIMIT 1];
        Account person = [SELECT Id, Name, AccountNumber FROM Account WHERE Id IN: testAccounts AND RecordTypeId =: personRT LIMIT 1];
    
        FactCategory__c coiFC = new FactCategory__c();
        coiFC.Name = 'Conflict of interest';
        coiFC.Enum__c = 'CONFLICT_OF_INTEREST';
        insert coiFC;
        
        Fact__c coiFact = new Fact__c();
        coiFact.Name = 'Friend';
        coiFact.Description__c = 'Add if this person is vulnerable as a result of someone close to them going through an illness we should be aware of';
        coiFact.FactCategory__c = coiFC.Id;
        insert coiFact;
        
        CustomerFact__c coiCF = new CustomerFact__c();
        coiCF.Fact__c = coiFact.Id;
        coiCF.Household__c = household.Id;
        coiCF.Notes__c = 'Mate of mine';
        coiCF.Status__c = 'Active';
        insert coiCF;
    }
    
    @isTest
    static void conflictTestMethod(){
        
        List<Account> testAccounts = new List<Account>();
        Id hhRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesHousehold').getRecordTypeId();
        Account household = [SELECT Id, Name, ConflictOfInterest__c, IsPersonAccount, DateConflictOfInterestAssessed__c FROM Account WHERE AccountNumber = '1235' LIMIT 1];
        testAccounts.add(household);
        
        CustomerFactConflictEvaluation.FlowInputs accs = new CustomerFactConflictEvaluation.FlowInputs();
        accs.accountList = testAccounts;
        List<CustomerFactConflictEvaluation.FlowInputs> accsList = new List<CustomerFactConflictEvaluation.FlowInputs>();
        accsList.add(accs);
        
        test.StartTest();
        CustomerFactConflictEvaluation.evaluateConflicts(accsList);
        Account hh = [SELECT Id, Name, ConflictOfInterest__c, DateConflictOfInterestAssessed__c FROM Account WHERE AccountNumber = '1235' LIMIT 1];
        test.StopTest();
        
        System.AssertEquals('Yes', hh.ConflictOfInterest__c);
    }
    
    @isTest
    static void noConflictTestMethod(){
        
        List<Account> testAccounts = new List<Account>();
        Id hhRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesHousehold').getRecordTypeId();
        Account household = [SELECT Id, Name, ConflictOfInterest__c, IsPersonAccount, DateConflictOfInterestAssessed__c FROM Account WHERE AccountNumber = '1235' LIMIT 1];
        testAccounts.add(household);
        
        CustomerFactConflictEvaluation.FlowInputs accs = new CustomerFactConflictEvaluation.FlowInputs();
        accs.accountList = testAccounts;
        List<CustomerFactConflictEvaluation.FlowInputs> accsList = new List<CustomerFactConflictEvaluation.FlowInputs>();
        accsList.add(accs);
        
        CustomerFact__c cf = [SELECT Id, Name FROM CustomerFact__c WHERE Name = 'Friend' AND Household__c =: household.Id LIMIT 1];
        cf.Status__c = 'Inactive';
        update cf;
        
        
        test.StartTest();
        CustomerFactConflictEvaluation.evaluateConflicts(accsList);
        Account hh = [SELECT Id, Name, ConflictOfInterest__c, DateConflictOfInterestAssessed__c FROM Account WHERE AccountNumber = '1235' LIMIT 1];
        test.StopTest();
        
        System.AssertEquals('No', hh.ConflictOfInterest__c);
    }
}
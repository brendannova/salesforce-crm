//Test class to assist the FlowHelperCaseEmailCreatedHousehold invocable class
@isTest
public class FlowHelperCaseEmailCreatedTest {
    
    @testSetup
    static void setup() {
        //Setup test data
        List<Account> testAccounts = TestDataFactory.createHousehold(2,0,'1236');
        Id personRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        List<Account> people = [SELECT Id, PersonEmail FROM Account WHERE AccountNumber = '1236' AND RecordTypeId =: personRT];
        System.debug(people);
        for(Integer i=0; i < people.size(); i++) {
            Account p = people.get(i);
            p.PersonEmail = 'owemailtest2108+' + i + '@gmail.com';
            System.debug(p);
        }
        update people;
    }
    
    @isTest
    static void sendEmail_FromExternal_HouseholdFound() {
        //Create new email from a known client and ensure a household is found and linked to related case
        Account h = [SELECT Id FROM Account WHERE AccountNumber = '1236' AND IsPersonAccount = false LIMIT 1];
        Case c = new Case();
        c.Subject = 'From external email';
        insert c;
        
        Account person = [SELECT Id, PersonEmail FROM Account WHERE AccountNumber = '1236' AND IsPersonAccount = true LIMIT 1];
        
        EmailMessage em = new EmailMessage();
        em.Subject = 'From external email';
        em.FromAddress = person.PersonEmail;
        em.ToAddress = 'test@novawm.com';
        em.ParentId = c.Id;
        em.Incoming = true;
        insert em;
        
        FlowHelperCaseEmailCreated.FlowInputs caseList = new FlowHelperCaseEmailCreated.FlowInputs();
        caseList.record = c;
        List<FlowHelperCaseEmailCreated.FlowInputs> caseFlowInputs = new List<FlowHelperCaseEmailCreated.FlowInputs>();
        caseFlowInputs.add(caseList);
        FlowHelperCaseEmailCreated.AssignHouseholdFromEmailMessage(caseFlowInputs);
        
        Case ca = [SELECT Id, AccountId FROM Case LIMIT 1];
        System.AssertEquals(h.Id, ca.AccountId);
    }
    
    @isTest
    static void sendEmail_FromInternal_HouseholdFound() {
        // Create new email from and internal @novawm.com email to a known client. Check corrent household is linked to related case
        Account h = [SELECT Id FROM Account WHERE AccountNumber = '1236' AND IsPersonAccount = false LIMIT 1];
        Account person = [SELECT Id, PersonEmail FROM Account WHERE AccountNumber = '1236' AND IsPersonAccount = true LIMIT 1];
        Case c = new Case();
        c.Subject = 'Test from internal email; household found';
        insert c;
        
        
        EmailMessage em = new EmailMessage();
        em.Subject = 'Test from internal email; household found';
        em.FromAddress = 'testcolleague@novawm.com';
        em.ToAddress = person.PersonEmail + '; test@novawm.com';
        em.ParentId = c.Id;
        em.Incoming = true;
        insert em;
        
        FlowHelperCaseEmailCreated.FlowInputs caseList = new FlowHelperCaseEmailCreated.FlowInputs();
        caseList.record = c;
        List<FlowHelperCaseEmailCreated.FlowInputs> caseFlowInputs = new List<FlowHelperCaseEmailCreated.FlowInputs>();
        caseFlowInputs.add(caseList);
        FlowHelperCaseEmailCreated.AssignHouseholdFromEmailMessage(caseFlowInputs);
        
        Case ca = [SELECT Id, AccountId FROM Case WHERE Subject = 'Test from internal email; household found' LIMIT 1];
        System.AssertEquals(h.Id, ca.AccountId);
    }

    @isTest
    static void sendEmail_FromInternal_NoHouseholdFound() {
        //Create email messsage from a @novawm.com email to a known client with unknown client copied in. No household should be linked.
        Account h = [SELECT Id FROM Account WHERE AccountNumber = '1236' AND IsPersonAccount = false LIMIT 1];
        Account person = [SELECT Id, PersonEmail FROM Account WHERE AccountNumber = '1236' AND IsPersonAccount = true LIMIT 1];
        Case c = new Case();
        c.Subject = 'Test from internal email; no household found';
        insert c;
        
        EmailMessage em = new EmailMessage();
        em.Subject = 'Test from internal email; no household found';
        em.FromAddress = 'testcolleague@novawm.com';
        em.ToAddress = person.PersonEmail + '; test@novawm.com';
        em.CcAddress = 'oifmemail@test.com';
        em.ParentId = c.Id;
        em.Incoming = true;
        insert em;
        
        FlowHelperCaseEmailCreated.FlowInputs caseList = new FlowHelperCaseEmailCreated.FlowInputs();
        caseList.record = c;
        List<FlowHelperCaseEmailCreated.FlowInputs> caseFlowInputs = new List<FlowHelperCaseEmailCreated.FlowInputs>();
        caseFlowInputs.add(caseList);
        FlowHelperCaseEmailCreated.AssignHouseholdFromEmailMessage(caseFlowInputs);
        
        Case ca = [SELECT Id, AccountId FROM Case WHERE Subject = 'Test from internal email; no household found' LIMIT 1];
        System.AssertEquals(null, ca.AccountId);
    }
    
    @isTest
    static void sendEmail_FromInternal_HouseholdFoundAssignDS() {
        //Create email message from an internal email to a know client. Add a DS to the household. Household should be found and linked to case. DS user should be the owner.
        Account h = [SELECT Id FROM Account WHERE AccountNumber = '1236' AND IsPersonAccount = false LIMIT 1];
        Account person = [SELECT Id, PersonEmail FROM Account WHERE AccountNumber = '1236' AND IsPersonAccount = true LIMIT 1];
        User u = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId()];
        h.OW_dedicated_specialist__c = u.Id;
        update h;
        
        Case c = new Case();
        c.Subject = 'Internal email, assign dedicated specialist';
        insert c;
        
        EmailMessage em = new EmailMessage();
        em.Subject = 'Internal email, assign dedicated specialist';
        em.FromAddress = 'testcolleague@novawm.com';
        em.ToAddress = person.PersonEmail + '; test@novawm.com';
        em.ParentId = c.Id;
        em.Incoming = true;
        insert em;
        
        FlowHelperCaseEmailCreated.FlowInputs caseList = new FlowHelperCaseEmailCreated.FlowInputs();
        caseList.record = c;
        List<FlowHelperCaseEmailCreated.FlowInputs> caseFlowInputs = new List<FlowHelperCaseEmailCreated.FlowInputs>();
        caseFlowInputs.add(caseList);
        FlowHelperCaseEmailCreated.AssignHouseholdFromEmailMessage(caseFlowInputs);
        
        Case ca = [SELECT Id, OwnerId, AccountId FROM Case WHERE Subject = 'Internal email, assign dedicated specialist' LIMIT 1];
        System.AssertEquals(u.Id, ca.OwnerId);
    }
    
    @isTest
    static void sendEmail_FromInternal_HouseholdFoundTwoPeopleCopied() {
        //Create new email message from an internal email with 2 clients on the household copied. Household found and linked to related case.
        Account h = [SELECT Id FROM Account WHERE AccountNumber = '1236' AND IsPersonAccount = false LIMIT 1];
        Account[] people = [SELECT Id, PersonEmail FROM Account WHERE AccountNumber = '1236' AND IsPersonAccount = true];
        Case c = new Case();
        c.Subject = 'From internal email, two person household';
        insert c;
        
        EmailMessage em = new EmailMessage();
        em.Subject = 'From internal email, two person household';
        em.FromAddress = 'testcolleague@novawm.com';
        em.ToAddress = people[0].PersonEmail + '; ' + people[1].PersonEmail;
        em.ParentId = c.Id;
        em.Incoming = true;
        insert em;
        
        FlowHelperCaseEmailCreated.FlowInputs caseList = new FlowHelperCaseEmailCreated.FlowInputs();
        caseList.record = c;
        List<FlowHelperCaseEmailCreated.FlowInputs> caseFlowInputs = new List<FlowHelperCaseEmailCreated.FlowInputs>();
        caseFlowInputs.add(caseList);
        FlowHelperCaseEmailCreated.AssignHouseholdFromEmailMessage(caseFlowInputs);

        Case ca = [SELECT Id, AccountId FROM Case WHERE Subject = 'From internal email, two person household' LIMIT 1];
        System.AssertEquals(h.Id, ca.AccountId);
    }
}
//Test class to assist the FlowHelperCaseEmailCreatedHousehold invocable class
@isTest
public class FlowHelperCaseEmailCreatedTest {
    
    @testSetup
    static void setup() {
        //Setup test data
        DataFactoryAccountHousehold household = new DataFactoryAccountHousehold();
        household.createHousehold('EmailAssignHousehold', 2, 0, 'Active', 'Full');
    }
    
    @isTest
    static void sendEmail_FromExternal_HouseholdFound() {
        //Create new email from a known client and ensure a household is found and linked to related case
        Account h = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailAssignHousehold' LIMIT 1];
        Case c = new Case();
        c.Subject = 'From external email';
        insert c;
        
        Account person = [SELECT Id, PersonEmail FROM Account WHERE Household_Lookup__c =: h.Id LIMIT 1];
        
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
        
        System.AssertEquals(h.Id, c.AccountId);
    }
    
    @isTest
    static void sendEmail_FromInternal_HouseholdFound() {
        // Create new email from and internal @novawm.com email to a known client. Check corrent household is linked to related case
        Account h = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailAssignHousehold' LIMIT 1];
        Account person = [SELECT Id, PersonEmail FROM Account WHERE Household_Lookup__c =: h.Id LIMIT 1];
        Case c = new Case();
        c.Subject = 'From internal email, person found';
        c.AccountId = person.Id;
        insert c;
        
        
        EmailMessage em = new EmailMessage();
        em.Subject = 'From external email';
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
        
        Case ca = [SELECT Id, AccountId FROM Case LIMIT 1];
        System.AssertEquals(h.Id, ca.AccountId);
    }

    @isTest
    static void sendEmail_FromInternal_NoHouseholdFound() {
        //Create email messsage from a @novawm.com email to a known client with unknown client copied in. No household should be linked.
        Account h = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailAssignHousehold' LIMIT 1];
        Case c = new Case();
        c.Subject = 'Internal email, no household';
        insert c;
        
        Account person = [SELECT Id, PersonEmail FROM Account WHERE Household_Lookup__c =: h.Id LIMIT 1];
        EmailMessage em = new EmailMessage();
        em.Subject = 'From external email';
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
        
        System.AssertEquals(null, c.AccountId);
    }
    
    @isTest
    static void sendEmail_FromInternal_HouseholdFoundAssignDS() {
        //Create email message from an internal email to a know client. Add a DS to the household. Household should be found and linked to case. DS user should be the owner.
        Account h = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailAssignHousehold' LIMIT 1];
        User u = [SELECT Id FROM User WHERE Id =: UserInfo.getUserId()];
        h.OW_dedicated_specialist__c = u.Id;
        update h;
        
        Case c = new Case();
        c.Subject = 'Internal email, assign dedicated specialist';
        insert c;
        
        Account person = [SELECT Id, PersonEmail FROM Account WHERE Household_Lookup__c =: h.Id LIMIT 1];
        EmailMessage em = new EmailMessage();
        em.Subject = 'From external email';
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
        
        System.AssertEquals(u.Id, c.OwnerId);
    }
    
    @isTest
    static void sendEmail_FromInternal_HouseholdFoundTwoPeopleCopied() {
        //Create new email message from an internal email with 2 clients on the household copied. Household found and linked to related case.
        Account h = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailAssignHousehold' LIMIT 1];
        
        Case c = new Case();
        c.Subject = 'From internal email, two person household';
        insert c;
        
        Account[] people = [SELECT Id, PersonEmail FROM Account WHERE Household_Lookup__c =: h.Id];
        EmailMessage em = new EmailMessage();
        em.Subject = 'From external email';
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

        System.AssertEquals(h.Id, c.AccountId);
    }
}
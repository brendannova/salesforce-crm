@isTest
public class sendTemplatedEmailTest {
    
    @testSetup
    static void setup() {

        // set up user and permissions
        User currentUser = [ SELECT Id FROM User WHERE Id = :UserInfo.getUserId() ];
        PermissionSet ps = new PermissionSet(
            Name = 'Test', 
            Label = 'Test'
        );
        System.runAs ( currentUser ) {
            insert ps;
        }
        CustomPermission cp = [SELECT Id, DeveloperName FROM CustomPermission WHERE IsLicensed = false AND IsProtected = false AND NamespacePrefix = null LIMIT 1];
        SetupEntityAccess sea = new SetupEntityAccess(
            ParentId = ps.Id, 
            SetupEntityId = cp.Id
        );
        System.runAs ( currentUser ) {
            insert sea;
        }
        
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = currentUser.Id,
            PermissionSetId = ps.Id
        );
        System.runAs ( currentUser ) {
            insert psa;
        }

        // Create email templates and email configuration records
        OrgWideEmailAddress fromEmail = [SELECT Id, Address FROM OrgWideEmailAddress ORDER BY Address ASC LIMIT 1];
        List<EmailTemplate> testEmailTemplates = new List<EmailTemplate>();
        List<EmailConfiguration__c> emailConfigRecords = new List<EmailConfiguration__c>();
        List<Account> accs = new List<Account>();
        testEmailTemplates.add(new EmailTemplate(
            isActive = true, 
            Name = 'STARTER_EMAIL', 
            DeveloperName = 'STARTER_EMAIL', 
            TemplateType = 'text', 
            FolderId = UserInfo.getUserId() // fix this line, not right
        )); 
        emailConfigRecords.add(new EmailConfiguration__c(
            Name = 'STARTER_EMAIL', 
            DeveloperName__c = 'STARTER_EMAIL',
            ClientsAddressed__c = 'All', 
            CustomPermission__c = cp.DeveloperName,
            Description__c = 'Test',
            From__c = fromEmail.Address,
            PartnerCopied__c = 'Always',
            Type__c = 'Service',
            Necessity__c = 'Required'
        ));
        String identifier = 'EmailMessageHelperTestHousehold';
        DataFactoryAccountHousehold dfah = new DataFactoryAccountHousehold();
        Account household = dfah.createHousehold(identifier, 1, 0, 'Active', 'Full');
        String ADVICE_RECORD_TYPE_DEVELOPER_NAME = 'Advice_RT_General_Advice';
        Advice__c advice = new Advice__c(
            Advice_Household__c = household.Id,
            RecordTypeId = Schema.SObjectType.Advice__c.getRecordTypeInfosByDeveloperName().get(ADVICE_RECORD_TYPE_DEVELOPER_NAME).getRecordTypeId(),
            New_or_existing_client__c = 'Existing',
            Partner__c = currentUser.Id,
            Fact_find_requirements__c = 'Not required',
            G_Drive_Advice_Folder__c = 'google.com',
            Update_valuations__c = 'No',
            New_LOAs_required__c = 'No', 
            Advice_Status__c = 'Data Gathering',
            Subject__c = identifier,
            Name = identifier
        );
            
        System.runAs ( currentUser ) {
			insert advice;
            insert testEmailTemplates;
            insert emailConfigRecords;
        }
    }
    
    @istest
    static void sendEmail_templateMissing_Blocked(){
        Account person = [SELECT Id, PersonEmail, PersonContactId FROM Account WHERE IsPersonAccount = true];
        Account acc = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailMessageHelperTestHousehold'];
        Advice__c adv = [SELECT Id FROM Advice__c WHERE Name = 'EmailMessageHelperTestHousehold'];
        OrgWideEmailAddress fromEmail = [SELECT Id, Address FROM OrgWideEmailAddress ORDER BY Address ASC LIMIT 1];
        List<String> toEmails = new List<String>{person.PersonEmail};
        List<String> ccEmails = new List<String>{UserInfo.getUserEmail()};
                
        Test.startTest();
        sendTemplatedEmail.sendTemplatedEmail(toEmails, ccEmails, 'NOT_REAL_TEMPLATE', person.PersonContactId, adv.Id, fromEmail.Id, true);    
        Integer emailsSent = Limits.getEmailInvocations();
        List<Task> task = [SELECT Id FROM Task WHERE WhatID =: adv.Id AND AccountId =: acc.Id AND WhoId =: person.PersonContactId];
        Test.stopTest();
        
        System.assertEquals(0, emailsSent);
        System.assertEquals(0, task.size());
    }
    
    @istest
    static void sendEmail_direct_allowed(){
        Account person = [SELECT Id, PersonEmail, PersonContactId FROM Account WHERE IsPersonAccount = true];
        Account acc = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailMessageHelperTestHousehold'];
        Advice__c adv = [SELECT Id FROM Advice__c WHERE Name = 'EmailMessageHelperTestHousehold'];
        OrgWideEmailAddress fromEmail = [SELECT Id, Address FROM OrgWideEmailAddress ORDER BY Address ASC LIMIT 1];
        List<String> toEmails = new List<String>{person.PersonEmail};
        List<String> ccEmails = new List<String>{UserInfo.getUserEmail()};
        
        Test.startTest();
        sendTemplatedEmail.sendTemplatedEmail(toEmails, ccEmails, 'STARTER_EMAIL', person.PersonContactId, adv.Id, fromEmail.Id, true);
        Integer emailsSent = Limits.getEmailInvocations();
        List<Task> task = [SELECT Id FROM Task WHERE WhatID =: adv.Id AND AccountId =: acc.Id AND WhoId =: person.PersonContactId];
        Test.stopTest();
        
        System.assertEquals(1, emailsSent, 'Expected 1 email but not true');
        System.assertEquals(1, task.size(), 'Exepcted 1 task but none/more found');
    }
    
    
    
    @isTest
    static void sendEmail_invocable_allowed() {
        Account person = [SELECT Id, PersonEmail, PersonContactId FROM Account WHERE IsPersonAccount = true];
		Account acc = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailMessageHelperTestHousehold'];
        Advice__c adv = [SELECT Id FROM Advice__c WHERE Name = 'EmailMessageHelperTestHousehold'];
        OrgWideEmailAddress fromEmail = [SELECT Id, Address FROM OrgWideEmailAddress ORDER BY Address ASC LIMIT 1];
        List<String> toEmails = new List<String>{person.PersonEmail};
        List<String> ccEmails = new List<String>{UserInfo.getUserEmail()};

        List<sendTemplatedEmail.FlowInputs> FlowInputs = new List<sendTemplatedEmail.FlowInputs>();
        sendTemplatedEmail.FlowInputs FlowInput = new sendTemplatedEmail.FlowInputs();
        FlowInput.toRecipients = toEmails;
        FlowInput.ccRecipients = ccEmails;
        FlowInput.emailTemplateDevName = 'STARTER_EMAIL';
        FlowInput.targetObjId = person.PersonContactId;
        FlowInput.whatId = adv.Id;
        FlowInput.orgWideEmailId = fromEmail.Id;
		FlowInput.saveAsActivity = true;        
        FlowInputs.add(FlowInput);
        
        Test.startTest();
		sendTemplatedEmail.invokeThisMethod(FlowInputs);
        Integer emailsSent = Limits.getEmailInvocations();
        List<Task> task = [SELECT Id FROM Task WHERE WhatId = :adv.Id AND AccountId = :acc.Id AND WhoId = :person.PersonContactId];
        Test.stopTest();
        System.assertEquals(1, emailsSent,  'Expected 1 email but not true');
        System.assertEquals(1, task.size(), 'Exepcted 1 task but none/more found');
    }
}
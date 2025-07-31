@IsTest
@SuppressWarnings('PMD.ApexUnitTestClassShouldHaveRunAs')
public class EmailSendTest { 
    @testSetup
    static void setup() {
        if( IS_EMAIL_DELIVERABILITY_ENABLED == true ) {
            DataFactory df = new DataFactory();
            Id household = df.createHousehold('EmailSendTestHousehold', 2, 2, 'Active', 'Full');
            Account acc = [SELECT Id FROM Account WHERE Id =: household];
            acc.OW_admin_notes__c = 'EmailSendTestHousehold';
            update acc;
            
            AccountHouseholdMembers.HouseholdMemberRequest request = new AccountHouseholdMembers.HouseholdMemberRequest();
        	request.householdId = household;
        	request.roles = new Set<String>{'Client','Child'};
        	AccountHouseholdMembers.HouseholdMemberResult result = AccountHouseholdMembers.getHouseholdMembers(request);
        	List<Account> clients = result.memberAccountsByRole.get('Client');
        	List<Account> children = result.memberAccountsByRole.get('Child');
            
            AccountContactRelation targetObject = [SELECT ContactId FROM AccountContactRelation WHERE AccountId =: household LIMIT 1][0];
            
            List<EmailConfiguration__c> emailConfigs = new List<EmailConfiguration__c>();
            EmailConfiguration__c emailConfig = new EmailConfiguration__c(
                SendingProcess__c='AUTOMATIC', 
                ClientsAddressed__c='One only', 
                DeveloperName__c='NovaWealthFulfilmentUpdateFinal',
                Necessity__c='Required',
                From__c='team@novawm.com',
                AwaitReply__c='No reply expected',
                PartnerCopied__c='Always',
                Type__c='Service'
            );
            emailConfigs.add(emailConfig);
            EmailConfiguration__c emailConfig2 = new EmailConfiguration__c(
                SendingProcess__c='AUTOMATIC', 
                ClientsAddressed__c='All', 
                DeveloperName__c='NotARealTemplate',
                Necessity__c='Required',
                From__c='team@novawm.com',
                AwaitReply__c='No reply expected',
                PartnerCopied__c='Always',
                Type__c='Service'
            );
            emailConfigs.add(emailConfig2);
            EmailConfiguration__c emailConfig3 = new EmailConfiguration__c(
                SendingProcess__c='AUTOMATIC', 
                ClientsAddressed__c='One only', 
                DeveloperName__c='NotGotAnOrgWideAddress',
                Necessity__c='Required',
                From__c='owemailtest2108+notanorgwideemailaddress@novawm.com',
                AwaitReply__c='No reply expected',
                PartnerCopied__c='Always',
                Type__c='Service'
            );
            emailConfigs.add(emailConfig3);
            insert emailConfigs;
        }
    }

    @isTest
    static void SendOneEmailSuccess() {
        Account acc = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailSendTestHousehold'];
        Id household = acc.Id;
        AccountContactRelation targetObject = [SELECT ContactId FROM AccountContactRelation WHERE AccountId =: household LIMIT 1][0];
            
        List<EmailSend.EmailSendRequestAutomatic> emailRequests = new List<EmailSend.EmailSendRequestAutomatic>();
        EmailSend.EmailSendRequestAutomatic emailRequest = new EmailSend.EmailSendRequestAutomatic();

        emailRequest.householdId = household;
        emailRequest.whatId = household;
        emailRequest.targetObjectId = targetObject.ContactId;
        emailRequest.saveAsActivity = true;
        emailRequest.subject = 'Test Email';
        emailRequest.parameters = new Map<String, String>{};
        emailRequest.emailTemplateDeveloperName = 'NovaWealthFulfilmentUpdateFinal';            
        emailRequests.add(emailRequest);
        
        Test.startTest();
        EmailSend emailSender = new EmailSend();
        emailSender.sendAutomaticTemplatedEmailCustomSubject(emailRequests);

        Integer emailsSent = Limits.getEmailInvocations();
        System.assertEquals(1, emailsSent, 'Expected 1 email but got ' + emailsSent);
        Test.stopTest();
    }
    
    @isTest
    static void SendMultipleEmailsSuccess() {
        Integer n = 2;    
        Account acc = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailSendTestHousehold'];   
        Id household = acc.Id;
        AccountContactRelation targetObject = [SELECT ContactId FROM AccountContactRelation WHERE AccountId =: household LIMIT 1][0];
        List<EmailSend.EmailSendRequestAutomatic> emailRequests = new List<EmailSend.EmailSendRequestAutomatic>();

        for(Integer i = 0; i < n; i++) {
            EmailSend.EmailSendRequestAutomatic emailRequest = new EmailSend.EmailSendRequestAutomatic();

            emailRequest.householdId = household;
            emailRequest.whatId = household;
            emailRequest.targetObjectId = targetObject.ContactId;
            emailRequest.saveAsActivity = true;
            emailRequest.subject = 'Test Email';
            emailRequest.parameters = new Map<String, String>{};
            emailRequest.emailTemplateDeveloperName = 'NovaWealthFulfilmentUpdateFinal';            
            emailRequests.add(emailRequest);
        }

        Test.startTest();
        EmailSend emailSender = new EmailSend();
        emailSender.sendAutomaticTemplatedEmailCustomSubject(emailRequests);

        Integer emailsSent = getSentEmailCount(household);
        System.assertEquals(n, emailsSent, 'Expected ' + n + ' emails but got ' + emailsSent);
        Test.stopTest();
    }

    @isTest
    static void NoEmailConfigs(){
        Account acc = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailSendTestHousehold'];
        Id household = acc.Id;
        AccountContactRelation targetObject = [SELECT ContactId FROM AccountContactRelation WHERE AccountId =: household LIMIT 1][0];
        List<EmailSend.EmailSendRequestAutomatic> emailRequests = new List<EmailSend.EmailSendRequestAutomatic>();
        EmailSend.EmailSendRequestAutomatic emailRequest = new EmailSend.EmailSendRequestAutomatic();

        emailRequest.householdId = household;
        emailRequest.whatId = household;
        emailRequest.targetObjectId = targetObject.ContactId;
        emailRequest.saveAsActivity = true;
        emailRequest.subject = 'Test Email';
        emailRequest.emailTemplateDeveloperName = 'DefinitelyNotARealConfigRecord';            
        emailRequest.parameters = new Map<String, String>{};
        emailRequests.add(emailRequest);

        Test.startTest();
        EmailSend emailSender = new EmailSend();
        try{
            emailSender.sendAutomaticTemplatedEmailCustomSubject(emailRequests);
        }  catch (EmailSend.EmailSendException e) {
            System.Assert.isTrue(e.getMessage().contains(EmailSend.ERROR_NO_EMAIL_CONFIGS), 'Allowed to send email without a config record');
        }
        Test.stopTest();
    }

    @isTest
    static void WrongNumberOfEmailConfigs() {
        Integer n = 2;    
        Account acc = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailSendTestHousehold'];   
        Id household = acc.Id;
        AccountContactRelation targetObject = [SELECT ContactId FROM AccountContactRelation WHERE AccountId =: household LIMIT 1][0];
        List<EmailSend.EmailSendRequestAutomatic> emailRequests = new List<EmailSend.EmailSendRequestAutomatic>();
      
        EmailSend.EmailSendRequestAutomatic emailRequest = new EmailSend.EmailSendRequestAutomatic();
        emailRequest.householdId = household;
        emailRequest.whatId = household;
        emailRequest.targetObjectId = targetObject.ContactId;
        emailRequest.saveAsActivity = true;
        emailRequest.subject = 'Test Email';
        emailRequest.parameters = new Map<String, String>{};
        emailRequest.emailTemplateDeveloperName = 'NovaWealthFulfilmentUpdateFinal';            
        emailRequests.add(emailRequest);

        EmailSend.EmailSendRequestAutomatic emailRequest2 = new EmailSend.EmailSendRequestAutomatic();
        emailRequest2.householdId = household;
        emailRequest2.whatId = household;
        emailRequest2.targetObjectId = targetObject.ContactId;
        emailRequest2.saveAsActivity = true;
        emailRequest2.subject = 'Test Email';
        emailRequest2.parameters = new Map<String, String>{};
        emailRequest2.emailTemplateDeveloperName = 'DefinitelyNotARealConfigRecord';            
        emailRequests.add(emailRequest2);

        Test.startTest();
        EmailSend emailSender = new EmailSend();
        try{
            emailSender.sendAutomaticTemplatedEmailCustomSubject(emailRequests);
        }  catch (EmailSend.EmailSendException e) {
            System.Assert.isTrue(e.getMessage().contains(EmailSend.ERROR_WRONG_SIZE_EMAIL_CONFIGS), 'Allowed to send emails without all config records');
        }
        Test.stopTest();
    }

    @isTest
    static void NoTargetObjectId(){
        Account acc = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailSendTestHousehold'];
        Id household = acc.Id;
        AccountContactRelation targetObject = [SELECT ContactId FROM AccountContactRelation WHERE AccountId =: household LIMIT 1][0];
        List<EmailSend.EmailSendRequestAutomatic> emailRequests = new List<EmailSend.EmailSendRequestAutomatic>();
        EmailSend.EmailSendRequestAutomatic emailRequest = new EmailSend.EmailSendRequestAutomatic();

        emailRequest.householdId = household;
        emailRequest.whatId = household;
        emailRequest.saveAsActivity = true;
        emailRequest.subject = 'Test Email';
        emailRequest.emailTemplateDeveloperName = 'NovaWealthFulfilmentUpdateFinal';       
        emailRequest.parameters = new Map<String, String>{};
        emailRequests.add(emailRequest);

        Test.startTest();
        EmailSend emailSender = new EmailSend();
        try{
            emailSender.sendAutomaticTemplatedEmailCustomSubject(emailRequests);
        }  catch (EmailSend.EmailSendException e) {
            System.Assert.isTrue(e.getMessage().contains(EmailSend.ERROR_TARGET_OBJECT_MISSING), 'Allowed to send email without a targetObject');
        }
        Test.stopTest();
    }

    @isTest
    static void NullTargetObjectId(){
        Account acc = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailSendTestHousehold'];
        Id household = acc.Id;
        AccountContactRelation targetObject = [SELECT ContactId FROM AccountContactRelation WHERE AccountId =: household LIMIT 1][0];
        List<EmailSend.EmailSendRequestAutomatic> emailRequests = new List<EmailSend.EmailSendRequestAutomatic>();
        EmailSend.EmailSendRequestAutomatic emailRequest = new EmailSend.EmailSendRequestAutomatic();

        emailRequest.householdId = household;
        emailRequest.whatId = household;
        emailRequest.targetObjectId = null;
        emailRequest.saveAsActivity = true;
        emailRequest.subject = 'Test Email';
        emailRequest.emailTemplateDeveloperName = 'NovaWealthFulfilmentUpdateFinal';       
        emailRequest.parameters = new Map<String, String>{};
        emailRequests.add(emailRequest);

        Test.startTest();
        EmailSend emailSender = new EmailSend();
        try{
            emailSender.sendAutomaticTemplatedEmailCustomSubject(emailRequests);
        }  catch (EmailSend.EmailSendException e) {
            System.Assert.isTrue(e.getMessage().contains(EmailSend.ERROR_TARGET_OBJECT_MISSING), 'Allowed to send email without a targetObject');
        }
        Test.stopTest();
    }

    @isTest
    static void NoHouseholdId(){
        Account acc = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailSendTestHousehold'];
        Id household = acc.Id;
        AccountContactRelation targetObject = [SELECT ContactId FROM AccountContactRelation WHERE AccountId =: household LIMIT 1][0];
        List<EmailSend.EmailSendRequestAutomatic> emailRequests = new List<EmailSend.EmailSendRequestAutomatic>();
        EmailSend.EmailSendRequestAutomatic emailRequest = new EmailSend.EmailSendRequestAutomatic();

        emailRequest.whatId = household;
        emailRequest.targetObjectId = targetObject.ContactId;
        emailRequest.saveAsActivity = true;
        emailRequest.subject = 'Test Email';
        emailRequest.emailTemplateDeveloperName = 'NovaWealthFulfilmentUpdateFinal';       
        emailRequest.parameters = new Map<String, String>{};
        emailRequests.add(emailRequest);

        Test.startTest();
        EmailSend emailSender = new EmailSend();
        try{
            emailSender.sendAutomaticTemplatedEmailCustomSubject(emailRequests);
        }  catch (EmailSend.EmailSendException e) {
            System.Assert.isTrue(e.getMessage().contains(EmailSend.ERROR_HOUSEHOLD_MISSING), 'Allowed to send email without a household');
        }
        Test.stopTest();
    }

    @isTest
    static void NullHouseholdId(){
        Account acc = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailSendTestHousehold'];
        Id household = acc.Id;
        AccountContactRelation targetObject = [SELECT ContactId FROM AccountContactRelation WHERE AccountId =: household LIMIT 1][0];
        List<EmailSend.EmailSendRequestAutomatic> emailRequests = new List<EmailSend.EmailSendRequestAutomatic>();
        EmailSend.EmailSendRequestAutomatic emailRequest = new EmailSend.EmailSendRequestAutomatic();

        emailRequest.householdId = null;
        emailRequest.whatId = household;
        emailRequest.targetObjectId = targetObject.ContactId;
        emailRequest.saveAsActivity = true;
        emailRequest.subject = 'Test Email';
        emailRequest.emailTemplateDeveloperName = 'NovaWealthFulfilmentUpdateFinal';       
        emailRequest.parameters = new Map<String, String>{};
        emailRequests.add(emailRequest);

        Test.startTest();
        EmailSend emailSender = new EmailSend();
        try{
            emailSender.sendAutomaticTemplatedEmailCustomSubject(emailRequests);
        }  catch (EmailSend.EmailSendException e) {
            System.Assert.isTrue(e.getMessage().contains(EmailSend.ERROR_HOUSEHOLD_MISSING), 'Allowed to send email without a household');
        }
        Test.stopTest();
    }

    @isTest
    static void NullWhatId(){
        Account acc = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailSendTestHousehold'];
        Id household = acc.Id;
        AccountContactRelation targetObject = [SELECT ContactId FROM AccountContactRelation WHERE AccountId =: household LIMIT 1][0];
        List<EmailSend.EmailSendRequestAutomatic> emailRequests = new List<EmailSend.EmailSendRequestAutomatic>();
        EmailSend.EmailSendRequestAutomatic emailRequest = new EmailSend.EmailSendRequestAutomatic();

        emailRequest.householdId = household;
        emailRequest.whatId = null;
        emailRequest.targetObjectId = targetObject.ContactId;
        emailRequest.saveAsActivity = true;
        emailRequest.subject = 'Test Email';
        emailRequest.emailTemplateDeveloperName = 'NovaWealthFulfilmentUpdateFinal';       
        emailRequest.parameters = new Map<String, String>{};
        emailRequests.add(emailRequest);

        Test.startTest();
        EmailSend emailSender = new EmailSend();
        try{
            emailSender.sendAutomaticTemplatedEmailCustomSubject(emailRequests);
        }  catch (EmailSend.EmailSendException e) {
            System.Assert.isTrue(e.getMessage().contains(EmailSend.ERROR_WHAT_ID_MISSING), 'Allowed to send email without a household');
        }
        Test.stopTest();
    }

    @isTest
    static void NoWhatId(){
        Account acc = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailSendTestHousehold'];
        Id household = acc.Id;
        AccountContactRelation targetObject = [SELECT ContactId FROM AccountContactRelation WHERE AccountId =: household LIMIT 1][0];
        List<EmailSend.EmailSendRequestAutomatic> emailRequests = new List<EmailSend.EmailSendRequestAutomatic>();
        EmailSend.EmailSendRequestAutomatic emailRequest = new EmailSend.EmailSendRequestAutomatic();

        emailRequest.householdId = household;
        emailRequest.targetObjectId = targetObject.ContactId;
        emailRequest.saveAsActivity = true;
        emailRequest.subject = 'Test Email';
        emailRequest.emailTemplateDeveloperName = 'NovaWealthFulfilmentUpdateFinal';       
        emailRequest.parameters = new Map<String, String>{};
        emailRequests.add(emailRequest);

        Test.startTest();
        EmailSend emailSender = new EmailSend();
        try{
            emailSender.sendAutomaticTemplatedEmailCustomSubject(emailRequests);
        }  catch (EmailSend.EmailSendException e) {
            System.Assert.isTrue(e.getMessage().contains(EmailSend.ERROR_WHAT_ID_MISSING), 'Allowed to send email without a household');
        }
        Test.stopTest();
    }

    @isTest
    static void NoEmailTemplates(){
        Account acc = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailSendTestHousehold'];
        Id household = acc.Id;
        AccountContactRelation targetObject = [SELECT ContactId FROM AccountContactRelation WHERE AccountId =: household LIMIT 1][0];
        List<EmailSend.EmailSendRequestAutomatic> emailRequests = new List<EmailSend.EmailSendRequestAutomatic>();
        EmailSend.EmailSendRequestAutomatic emailRequest = new EmailSend.EmailSendRequestAutomatic();
        
        emailRequest.householdId = household;
        emailRequest.whatId = household;
        emailRequest.targetObjectId = targetObject.ContactId;
        emailRequest.saveAsActivity = true;
        emailRequest.subject = 'Test Email';
        emailRequest.emailTemplateDeveloperName = 'NotARealTemplate';       
        emailRequest.parameters = new Map<String, String>{};
        emailRequests.add(emailRequest);

        Test.startTest();
        EmailSend emailSender = new EmailSend();
        try{
            emailSender.sendAutomaticTemplatedEmailCustomSubject(emailRequests);
        }  catch (EmailSend.EmailSendException e) {
            System.Assert.isTrue(e.getMessage().contains(EmailSend.ERROR_NO_EMAIL_TEMPLATES), 'Allowed to send email without a template');
        }
        Test.stopTest();
    }
    
    @isTest
    static void WrongNumberOfEmailTemplates() {
        Integer n = 2;    
        Account acc = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailSendTestHousehold'];   
        Id household = acc.Id;
        AccountContactRelation targetObject = [SELECT ContactId FROM AccountContactRelation WHERE AccountId =: household LIMIT 1][0];
        List<EmailSend.EmailSendRequestAutomatic> emailRequests = new List<EmailSend.EmailSendRequestAutomatic>();
      
        EmailSend.EmailSendRequestAutomatic emailRequest = new EmailSend.EmailSendRequestAutomatic();
        emailRequest.householdId = household;
        emailRequest.whatId = household;
        emailRequest.targetObjectId = targetObject.ContactId;
        emailRequest.saveAsActivity = true;
        emailRequest.subject = 'Test Email';
        emailRequest.parameters = new Map<String, String>{};
        emailRequest.emailTemplateDeveloperName = 'NovaWealthFulfilmentUpdateFinal';            
        emailRequests.add(emailRequest);

        EmailSend.EmailSendRequestAutomatic emailRequest2 = new EmailSend.EmailSendRequestAutomatic();
        emailRequest2.householdId = household;
        emailRequest2.whatId = household;
        emailRequest2.targetObjectId = targetObject.ContactId;
        emailRequest2.saveAsActivity = true;
        emailRequest2.subject = 'Test Email 2';
        emailRequest2.parameters = new Map<String, String>{};
        emailRequest2.emailTemplateDeveloperName = 'NotARealTemplate';            
        emailRequests.add(emailRequest2);

        Test.startTest();
        EmailSend emailSender = new EmailSend();
        try{
            emailSender.sendAutomaticTemplatedEmailCustomSubject(emailRequests);
        }  catch (EmailSend.EmailSendException e) {
            System.Assert.isTrue(e.getMessage().contains(EmailSend.ERROR_WRONG_SIZE_EMAIL_TEMPLATES), 'Allowed to send emails without all email templates');
        }
        Test.stopTest();
    }

    @isTest
    static void TagRemaining() {
        Account acc = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailSendTestHousehold'];
        Id household = acc.Id;
        AccountContactRelation targetObject = [SELECT ContactId FROM AccountContactRelation WHERE AccountId =: household LIMIT 1][0];
            
        List<EmailSend.EmailSendRequestAutomatic> emailRequests = new List<EmailSend.EmailSendRequestAutomatic>();
        EmailSend.EmailSendRequestAutomatic emailRequest = new EmailSend.EmailSendRequestAutomatic();

        emailRequest.householdId = household;
        emailRequest.whatId = household;
        emailRequest.targetObjectId = targetObject.ContactId;
        emailRequest.saveAsActivity = true;
        emailRequest.subject = '{{Test Email}}';
        emailRequest.parameters = new Map<String, String>{};
        emailRequest.emailTemplateDeveloperName = 'NovaWealthFulfilmentUpdateFinal';            
        emailRequests.add(emailRequest);
        
        Test.startTest();
        EmailSend emailSender = new EmailSend();
        try{
            emailSender.sendAutomaticTemplatedEmailCustomSubject(emailRequests);
        }  catch (EmailSend.EmailSendException e) {
            System.Assert.isTrue(e.getMessage().contains(EmailSend.ERROR_TAGS_NOT_REPLACED), 'Allowed to send emails with tags remaining');
        }
        Test.stopTest();
    }

    @isTest
    static void NoOrgWideEmaillAddress() {
        Account acc = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailSendTestHousehold'];
        Id household = acc.Id;
        AccountContactRelation targetObject = [SELECT ContactId FROM AccountContactRelation WHERE AccountId =: household LIMIT 1][0];
            
        List<EmailSend.EmailSendRequestAutomatic> emailRequests = new List<EmailSend.EmailSendRequestAutomatic>();
        EmailSend.EmailSendRequestAutomatic emailRequest = new EmailSend.EmailSendRequestAutomatic();

        emailRequest.householdId = household;
        emailRequest.whatId = household;
        emailRequest.targetObjectId = targetObject.ContactId;
        emailRequest.saveAsActivity = true;
        emailRequest.subject = 'Test Email';
        emailRequest.parameters = new Map<String, String>{};
        emailRequest.emailTemplateDeveloperName = 'NotGotAnOrgWideAddress';            
        emailRequests.add(emailRequest);
        
        Test.startTest();
        EmailSend emailSender = new EmailSend();
        try{
            emailSender.sendAutomaticTemplatedEmailCustomSubject(emailRequests);
        }  catch (EmailSend.EmailSendException e) {
            System.Assert.isTrue(e.getMessage().contains(EmailSend.ERROR_NO_ORGWIDE_ADDRESSES), 'Allowed to send emails with no org wide address');
        }
        Test.stopTest();
    }

    @isTest
    static void WrongNumberOfOrgWideAddresses() {
        Integer n = 2;    
        Account acc = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailSendTestHousehold'];   
        Id household = acc.Id;
        AccountContactRelation targetObject = [SELECT ContactId FROM AccountContactRelation WHERE AccountId =: household LIMIT 1][0];
        List<EmailSend.EmailSendRequestAutomatic> emailRequests = new List<EmailSend.EmailSendRequestAutomatic>();
      
        EmailSend.EmailSendRequestAutomatic emailRequest = new EmailSend.EmailSendRequestAutomatic();
        emailRequest.householdId = household;
        emailRequest.whatId = household;
        emailRequest.targetObjectId = targetObject.ContactId;
        emailRequest.saveAsActivity = true;
        emailRequest.subject = 'Test Email';
        emailRequest.parameters = new Map<String, String>{};
        emailRequest.emailTemplateDeveloperName = 'NovaWealthFulfilmentUpdateFinal';            
        emailRequests.add(emailRequest);

        EmailSend.EmailSendRequestAutomatic emailRequest2 = new EmailSend.EmailSendRequestAutomatic();
        emailRequest2.householdId = household;
        emailRequest2.whatId = household;
        emailRequest2.targetObjectId = targetObject.ContactId;
        emailRequest2.saveAsActivity = true;
        emailRequest2.subject = 'Test Email 2';
        emailRequest2.parameters = new Map<String, String>{};
        emailRequest2.emailTemplateDeveloperName = 'NotGotAnOrgWideAddress';            
        emailRequests.add(emailRequest2);

        Test.startTest();
        EmailSend emailSender = new EmailSend();
        try{
            emailSender.sendAutomaticTemplatedEmailCustomSubject(emailRequests);
        }  catch (EmailSend.EmailSendException e) {
            System.Assert.isTrue(e.getMessage().contains(EmailSend.ERROR_WRONG_SIZE_ORGWIDE_ADDRESSES), 'Allowed to send emails without all org wide email addresses');
        }
        Test.stopTest();
    }

    @isTest
    static void NoToAddresses() {
        Account acc = new Account(Name = 'Empty Household');
        insert acc;
        Id household = acc.Id;

        String RecordTypeDevNamePerson = 'PersonAccount';
        Id RecordTypeIdPerson = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(RecordTypeDevNamePerson).getRecordTypeId();

        Account person = new Account(FirstName = 'Empty', LastName = 'person', RecordTypeId = RecordTypeIdPerson);
        insert person;

        Account personAccount = [SELECT Id, PersonContactId, OW_role_in_primary_household__c FROM Account WHERE Id =: person.Id];
            
        List<EmailSend.EmailSendRequestAutomatic> emailRequests = new List<EmailSend.EmailSendRequestAutomatic>();
        EmailSend.EmailSendRequestAutomatic emailRequest = new EmailSend.EmailSendRequestAutomatic();

        emailRequest.householdId = household;
        emailRequest.whatId = household;
        emailRequest.targetObjectId = personAccount.PersonContactId;
        emailRequest.saveAsActivity = true;
        emailRequest.subject = 'Test Email';
        emailRequest.parameters = new Map<String, String>{};
        emailRequest.emailTemplateDeveloperName = 'NovaWealthFulfilmentUpdateFinal';            
        emailRequests.add(emailRequest);
        
        Test.startTest();
        EmailSend emailSender = new EmailSend();
        try{
            emailSender.sendAutomaticTemplatedEmailCustomSubject(emailRequests);
        }  catch (EmailSend.EmailSendException e) {
            System.Assert.isTrue(e.getMessage().contains(EmailSend.NO_TO_EMAILS), 'Allowed to send emails without a To address');
        }
        Test.stopTest();
    }

    @isTest
    static void SendOneEmailFail() {
        Account acc = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailSendTestHousehold'];
        Id household = acc.Id;
        AccountContactRelation targetObject = [SELECT ContactId FROM AccountContactRelation WHERE AccountId =: household LIMIT 1][0];
            
        List<EmailSend.EmailSendRequestAutomatic> emailRequests = new List<EmailSend.EmailSendRequestAutomatic>();
        EmailSend.EmailSendRequestAutomatic emailRequest = new EmailSend.EmailSendRequestAutomatic();

        emailRequest.householdId = household;
        emailRequest.whatId = household;
        emailRequest.targetObjectId = targetObject.ContactId;
        emailRequest.saveAsActivity = true;
        emailRequest.subject = 'Test Email';
        emailRequest.parameters = new Map<String, String>{};
        emailRequest.emailTemplateDeveloperName = 'NovaWealthFulfilmentUpdateFinal';            
        emailRequests.add(emailRequest);
        
        Test.startTest();
        EmailSend emailSender = new EmailSend();
        try{
            emailSender.sendAutomaticTemplatedEmailCustomSubject(emailRequests);
        }  catch(System.EmailException e ) {
            System.assert(false,'EmailSend error not handled' );
        }
        catch (EmailSend.EmailSendException e) {
            System.Assert.isTrue(e.getMessage().contains(EmailSend.ERROR_EMAIL_SEND_ERROR), 'EmailSend error not handled');
        }
        Test.stopTest();
    }
    

    @TestVisible
    private static final Boolean IS_EMAIL_DELIVERABILITY_ENABLED {
        get {
            if (IS_EMAIL_DELIVERABILITY_ENABLED == null) {
                try {
                    System.Messaging.reserveSingleEmailCapacity(1);
                    IS_EMAIL_DELIVERABILITY_ENABLED = true;
                } catch (System.NoAccessException e) {
                    IS_EMAIL_DELIVERABILITY_ENABLED = false;
                }
            }
            return IS_EMAIL_DELIVERABILITY_ENABLED;
        }
        set;
    } 

    public static Integer getSentEmailCount(Id recordId) {
        List<EmailMessage> sentEmails = [
            SELECT Id
            FROM EmailMessage
            WHERE RelatedToId = :recordId
        ];
        return sentEmails.size();
    }
}
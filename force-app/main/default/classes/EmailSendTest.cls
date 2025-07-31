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
            insert emailConfig;
        }
    }

    @isTest
    static void sendEmail_single_success() {
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
    static void sendEmail_multiple_success() {
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
    static void sendEmail_noConfig_blocked(){
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
            System.Assert.isTrue(e.getMessage().contains('No email configurations found'), 'Allowed to send email without a config record');
        }
        Test.stopTest();
    }

    @isTest
    static void sendEmails_wrongConfig_blocked() {
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
            System.Assert.isTrue(e.getMessage().contains('Email configuration records not found for all templates'), 'Allowed to send emails without all config records');
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
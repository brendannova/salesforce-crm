@IsTest
public class EmailSendTest { 
    @isTest
    static void runTest() {
        if( IS_EMAIL_DELIVERABILITY_ENABLED == true ) {
            DataFactory df = new DataFactory();
            Id household = df.createHousehold('OW001 Test',2,2,'Onboarding','Full');
            
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
    }
    
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
    
}
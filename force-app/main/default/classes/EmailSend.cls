/**
 * This class handles the sending of emails from Nova to customers, using a variety of methods to ensure consistency over who gets addressed, copied etc. 
 * It works in conjuction with email templates and Apex components and their controllers to produce content. 
 */
public without sharing class EmailSend{

    final private static String SENDING_PROCESS_AUTOMATIC = 'AUTOMATIC';
    final private static String ONE_REQUEST_ERROR = 'Only one request allowed. This method does not support bulk emails yet.';
    
    // A simple method responsible for sending emails
    private void sendEmails(List<Messaging.SingleEmailMessage> emails){
        List<Messaging.SendEmailResult> emailSendResults = Messaging.sendEmail(emails, true);
        // To-do: work through the results to determine if everything was successful
    }
    
    // The request wrapper that needs to be provided for the correct email to generate
    public class EmailSendRequestAutomatic {
        public String emailTemplateDeveloperName;               // The email template
        public Id targetObjectId;                               // The core recipient
        public Id householdId;                                  // The household the email relates to
        public Id whatId;                                       // The specific record the email relates to
        public Boolean saveAsActivity;                          // Set as activity    
    }
    
    // 
    public void sendAutomaticTemplatedEmailCustomSubject(List<EmailSendRequestAutomatic> requests) {
        if( requests.size() > 1 ) {
            throw new EmailSendException(ONE_REQUEST_ERROR); 
        }

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();              // The list of emails to be sent at the end
        String subject;
        EmailConfiguration__c emailConfig = new EmailConfiguration__c();
        
        for(EmailSendRequestAutomatic request : requests){
            validateInputs(request);
            
            emailConfig = getEmailConfig(request.emailTemplateDeveloperName); 
            
            String whatId = request.whatId;
            String whoId = request.targetObjectId;
            
            String emailTemplateId = getEmailTemplateId(request.emailTemplateDeveloperName);
            
            Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(emailTemplateId, whoId, whatId);
            
            subject = getSubject(emailConfig, request.whatId);
            email.setSubject(subject);

			email = setUpEmail(email, request.householdId, whoId, whatId, emailConfig);

            emails.add(email);  
        }
        sendEmails(emails);
    }
    
    public void sendAutomaticTemplatedEmail(List<EmailSendRequestAutomatic> requests){ 
        if( requests.size() > 1 ) {
            throw new EmailSendException(ONE_REQUEST_ERROR); 
        }
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();              // The list of emails to be sent at the end
        EmailConfiguration__c emailConfig = new EmailConfiguration__c();
        
        for(EmailSendRequestAutomatic request : requests){
            validateInputs(request);
            
            emailConfig = getEmailConfig(request.emailTemplateDeveloperName);
            
            String emailTemplateId = getEmailTemplateId(request.emailTemplateDeveloperName);
            
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            
            email.setTemplateId(emailTemplateId);
            
            email = setUpEmail(email, request.householdId, request.targetObjectId, request.whatId, emailConfig);
            
            emails.add(email); 
        }
        sendEmails(emails);
    }
    
    private String getSubject(EmailConfiguration__c emailConfig, Id targetObjectId) {
        Id objectId = Id.valueOf(targetObjectId);
        String objectApiName = objectId.getSObjectType().getDescribe().getName();
        String message = emailConfig.Subject__c;
        message = Utility.tagSubstituter(message, targetObjectId, objectApiName, emailConfig.DeveloperName__c);
        
        return message;
    }
    
    
    private List<String> getToAddresses(EmailConfiguration__c emailConfig, Id householdId, Id targetObjectId) {
        List<String> emailAddresses = new List<String>();
        if( emailConfig.ClientsAddressed__c == 'One only' ) {
            List<AccountContactRelation> acrs = [SELECT Contact.Email FROM AccountContactRelation WHERE Account.RecordType.DeveloperName = 'IndustriesHousehold' AND Roles = 'Client' AND AccountId =: householdId AND ContactId =: targetObjectId];
            for( AccountContactRelation acr : acrs ) {
                emailAddresses.add(acr.Contact.Email);
            }
        } else if( emailConfig.ClientsAddressed__c == 'All' ) {
            List<AccountContactRelation> acrs = [SELECT Contact.Email FROM AccountContactRelation WHERE Account.RecordType.DeveloperName = 'IndustriesHousehold' AND Roles = 'Client' AND AccountId =: householdId];
            for( AccountContactRelation acr : acrs ) {
                emailAddresses.add(acr.Contact.Email);
            }
        } 
        return emailAddresses;
    }
    
    private List<String> getCcAddresses(EmailConfiguration__c emailConfig, Id householdId, Id targetObjectId) {
        List<String> emailAddresses = new List<String>();
        if( emailConfig.ClientsAddressed__c == 'One only' && emailConfig.CopyOtherClients__c == 'ALWAYS' ) {
            List<AccountContactRelation> acrs = [SELECT Contact.Email FROM AccountContactRelation WHERE Account.RecordType.DeveloperName = 'IndustriesHousehold' AND Roles = 'Client' AND AccountId =: householdId AND ContactId !=: targetObjectId];
            for( AccountContactRelation acr : acrs ) {
                emailAddresses.add(acr.Contact.Email);
            }
        } 
        if( emailConfig.PartnerCopied__c == 'ALWAYS' ) {
            Account acct = [SELECT Id, Owner.Email FROM Account WHERE Id =: householdId];
            emailAddresses.add(acct.Owner.Email);
        }
        return emailAddresses;
    }
    
    private List<OrgWideEmailAddress> getOrgWideEmailAddress(String address) {
        List<OrgWideEmailAddress> orgWideEmailAddresses = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :address];
            if(orgWideEmailAddresses.isEmpty()){
                throw new EmailSendException('No org wide email address found for :' + address); 
            }
        return orgWideEmailAddresses;
    }
    
    private String getEmailTemplateId(String templateDevName) {
        String emailTemplateId;
        List<EmailTemplate> emailTemplates = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :templateDevName];
        if(emailTemplates.isEmpty()){
            throw new EmailSendException('No email template found with developer name :' + templateDevName); 
        } else {
            emailTemplateId = emailTemplates[0].Id;
        }
        return emailTemplateId;
    }
    
    private EmailConfiguration__c getEmailConfig(String emailTemplateDeveloperName) {
        EmailConfiguration__c emailConfig = new EmailConfiguration__c();
        List<EmailConfiguration__c> emailConfigs = [SELECT 
                                                    Id, 
                                                    DeveloperName__c, 
                                                    Subject__c, 
                                                    ClientsAddressed__c, 
                                                    CopyOtherClients__c, 
                                                    PartnerCopied__c, 
                                                    From__c, 
                                                    ReplyTo__c 
                                                    FROM EmailConfiguration__c 
                                                    WHERE DeveloperName__c = :emailTemplateDeveloperName 
                                                     AND SendingProcess__c = :SENDING_PROCESS_AUTOMATIC];
        if(emailConfigs.isEmpty()){
            throw new EmailSendException('No email configuration record found for the developer name :' + emailTemplateDeveloperName); 
        } else {
            emailConfig = emailConfigs[0];
        }
        return emailConfig;
    }
        
    private Messaging.SingleEmailMessage setUpEmail(Messaging.SingleEmailMessage email, Id householdId, Id targetObjId, Id whatId, EmailConfiguration__c emailConfig) {
		List<String> ccAddresses = new List<String>();                                                  // People to CC
        List<String> toAddresses = new List<String>();                                                  // People to address directly
        Id emailTemplateId;
        List<OrgWideEmailAddress> orgWideEmailAddresses = new List<OrgWideEmailAddress>();
                        
        orgWideEmailAddresses = getOrgWideEmailAddress(emailConfig.From__c);
        
        ccAddresses = getCcAddresses(emailConfig, householdId, targetObjId);
        
        toAddresses = getToAddresses(emailConfig, householdId, targetObjId);
        
        email.setTargetObjectId(targetObjId);
        if(!toAddresses.isEmpty()){
            email.setToAddresses(toAddresses);
        }
        if(!ccAddresses.isEmpty()){
            email.setCcAddresses(ccAddresses);
        }
        email.setorgWideEmailAddressId(orgWideEmailAddresses[0].Id);
        if(String.isNotBlank(emailConfig.ReplyTo__c)){
            email.setReplyTo(emailConfig.ReplyTo__c);
        }

        email.setWhatId(whatId);
        email.setUseSignature(false);
        email.setTreatTargetObjectAsRecipient(true);
        
        return email;
    }
    
    private void validateInputs(emailSendRequestAutomatic request) {
        // Make sure we have other required fields prior to proceeding
            if(request.targetObjectId == null){
                throw new EmailSendException('targetObjectId required'); 
            }
            if(request.householdId == null){
                throw new EmailSendException('householdId required'); 
            }
            if(request.whatId == null){
                throw new EmailSendException('whatId required'); 
            }
        	if(String.isBlank(request.emailTemplateDeveloperName)){
                throw new EmailSendException('Email template must be provided'); 
            }
    }
    
    // Placeholder to send email where the body, plain text and HTML, is defined as an input
    public static void sendCustomEmail(Id targetObjectId, List<String> toAddresses, List<String> ccAddresses, Id whatId, Boolean saveAsActivity, String subject, String htmlBody, String plainTextBody, String fromAddress){ 
        
    }

    public class EmailSendException extends Exception {}
}
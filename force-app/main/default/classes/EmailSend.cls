public without sharing class EmailSend{

    final private static String SENDING_PROCESS_AUTOMATIC = 'AUTOMATIC';
    final private static String ONE_REQUEST_ERROR = 'Only one request allowed. This method does not support bulk emails yet.';
    
    private void sendEmails(List<Messaging.SingleEmailMessage> emails){
        List<Messaging.SendEmailResult> emailSendResults = Messaging.sendEmail(emails, true);
    }
    
    public class EmailSendRequestAutomatic {
        public String emailTemplateDeveloperName;               // The email template
        public Id targetObjectId;                               // The core recipient
        public Id householdId;                                  // The household the email relates to
        public Id whatId;                                       // The specific record the email relates to
        public Boolean saveAsActivity;                          // Set as activity    
    }
    
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
            subject = getSubject(emailConfig, request.whatId);
            Messaging.SingleEmailMessage email = setUpEmail(request, emailConfig);
            email.setSubject(subject);
            
            emails.add(email);  
            System.debug('SUbject: ' + email.subject);
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
            Messaging.SingleEmailMessage email = setUpEmail(request, emailConfig);
            emails.add(email); 
            System.debug('SUbject ' + email.Subject);
        }
        sendEmails(emails);
    }
    
    private String getSubject(EmailConfiguration__c emailConfig, Id targetObjectId) {
        String message = emailConfig.Subject__c;
        Utility ut = new Utility();
        message = ut.tagSubstituter(message, targetObjectId, emailConfig.ObjectName__c, emailConfig.DeveloperName__c);
        
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
                                                    ObjectName__c, 
                                                    Subject__c, 
                                                    ClientsAddressed__c, 
                                                    CopyOtherClients__c, 
                                                    PartnerCopied__c, 
                                                    From__c, 
                                                    ReplyTo__c 
                                                    FROM EmailConfiguration__c 
                                                    WHERE DeveloperName__c = :emailTemplateDeveloperName 
                                                     AND SendingProcess__c = :SENDING_PROCESS_AUTOMATIC];
        System.debug(emailConfigs);
        if(emailConfigs.isEmpty()){
            throw new EmailSendException('No email configuration record found for the developer name :' + emailTemplateDeveloperName); 
        } else {
            emailConfig = emailConfigs[0];
        }
        return emailConfig;
    }
        
    private Messaging.SingleEmailMessage setUpEmail(emailSendRequestAutomatic request, EmailConfiguration__c emailConfig) {
		List<String> ccAddresses = new List<String>();                                                  // People to CC
        List<String> toAddresses = new List<String>();                                                  // People to address directly
        Id emailTemplateId;
        List<OrgWideEmailAddress> orgWideEmailAddresses = new List<OrgWideEmailAddress>();
        
        
        emailTemplateId = getEmailTemplateId(request.emailTemplateDeveloperName);
                
        orgWideEmailAddresses = getOrgWideEmailAddress(emailConfig.From__c);
        
        ccAddresses = getCcAddresses(emailConfig, request.householdId, request.targetObjectId);
        
        toAddresses = getToAddresses(emailConfig, request.householdId, request.targetObjectId);
        
        Messaging.SingleEmailMessage result = new Messaging.SingleEmailMessage();
        result.setTemplateId(emailTemplateId);
        result.setTargetObjectId(request.targetObjectId);
        if(!toAddresses.isEmpty()){
            result.setToAddresses(toAddresses);
        }
        if(!ccAddresses.isEmpty()){
            result.setCcAddresses(ccAddresses);
        }
        result.setorgWideEmailAddressId(orgWideEmailAddresses[0].Id);
        if(String.isNotBlank(emailConfig.ReplyTo__c)){
            result.setReplyTo(emailConfig.ReplyTo__c);
        }

        result.setWhatId(request.whatId);
        result.setSaveAsActivity(request.saveAsActivity);
        result.setUseSignature(false);
        result.setTreatTargetObjectAsRecipient(true);
        
        return result;
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
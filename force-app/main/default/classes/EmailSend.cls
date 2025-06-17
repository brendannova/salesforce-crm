public without sharing class EmailSend{

    final private static String SENDING_PROCESS_AUTOMATIC = 'AUTOMATIC';

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
    
    public void sendAutomaticTemplatedEmail(List<EmailSendRequestAutomatic> requests){ 
        System.debug('In the send automatic templated email function');
        // #### To-do #### Harriet - add validation to check we only have 1 emailSendRequest
        
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();           // The list of emails to be sent at the end

        for(EmailSendRequestAutomatic request : requests){
            List<String> ccAddresses = new List<String>();                                                  // People to CC
            List<String> toAddresses = new List<String>();                                                  // People to address directly
            EmailConfiguration__c emailConfig;                                                              // The email configuration record for the template. 
            Id emailTemplateId;
            
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
            
            /**
             * Make sure we have an email template developer name then check for the corresponding email template and email configuration record        
             * Throw errors if we can't find the appropriate information to proceed. 
             */
            if(String.isBlank(request.emailTemplateDeveloperName)){
                throw new EmailSendException('Email template must be provided'); 
            } else {
                List<EmailTemplate> emailTemplates = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :request.emailTemplateDeveloperName];
                if(emailTemplates.isEmpty()){
                    throw new EmailSendException('No email template found with developer name :' + request.emailTemplateDeveloperName); 
                } else {
                    emailTemplateId = emailTemplates[0].Id;
                }
                List<EmailConfiguration__c> emailConfigs = [SELECT Id, From__c, ReplyTo__c FROM EmailConfiguration__c WHERE DeveloperName__c = :request.emailTemplateDeveloperName AND SendingProcess__c = :SENDING_PROCESS_AUTOMATIC];
                System.debug(emailConfigs);
                if(emailConfigs.isEmpty()){
                    throw new EmailSendException('No email configuration record found for the developer name :' + request.emailTemplateDeveloperName); 
                } else {
                    emailConfig = emailConfigs[0];
                }
            }
            
            List<OrgWideEmailAddress> orgWideEmailAddresses = [SELECT Id FROM OrgWideEmailAddress WHERE Address = :emailConfig.From__c];
            if(orgWideEmailAddresses.isEmpty()){
                throw new EmailSendException('No org wide email address found for :' + emailConfig.From__c); 
            }

            // #### To-do #### Harriet - Construct the CC details from the household ID - adding the Nova partner and spouse/partner of the client if applicable. 
            
            // Start constructing the email 
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setTemplateId(emailTemplateId);
            email.setTargetObjectId(request.targetObjectId);
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
            email.setWhatId(request.whatId);
            email.setSaveAsActivity(request.saveAsActivity);
            email.setUseSignature(false);
            email.setTreatTargetObjectAsRecipient(true);
            emails.add(email);
        }
        sendEmails(emails);
    }
        
    // Placeholder to send email where the body, plain text and HTML, is defined as an input
    public static void sendCustomEmail(Id targetObjectId, List<String> toAddresses, List<String> ccAddresses, Id whatId, Boolean saveAsActivity, String subject, String htmlBody, String plainTextBody, String fromAddress){ 
        
    }

    public class EmailSendException extends Exception {}
}
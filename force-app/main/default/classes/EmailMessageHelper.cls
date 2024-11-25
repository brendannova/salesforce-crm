/*********************************************************
Apex Class Name    EmailMessageHelper
Created Date       2024-06-19
@description       This class is a helper for an email message trigger that ensures emails we send go the right people.
@author            Cian Morrissey
Modification Log:
Date         Author                               Modification
2024-09-17   Cian Morrissey                       Prevent emailing deceased and reported deceased customers plus update to code structure. 
2024-06-19   Cian Morrissey                       Initial Version
*********************************************************/
public with sharing class EmailMessageHelper {
    private List<EmailDetail> outboundMessages = new List<EmailDetail>();
    private Set<Id> emailTemplateIds = new Set<Id>();
    private Set<String> emailTemplateDeveloperNames = new Set<String>();
    private Map<String, Id> emailTemplateDevNameIdMap = new Map<String, Id>(); // Map of email template develo
    private Map<Id, EmailConfiguration__c> emailConfigMap = new Map<Id, EmailConfiguration__c>(); // Map of email template IDs to corresponding email configuration records
    private Set<Id> householdIds = new Set<Id>();
    private Set<Id> adviceIds = new Set<Id>();
    private Set<Id> caseIds = new Set<Id>();
    private Map<Id, Id> relatedIdHouseholdIdMap = new Map<Id, Id>();
    private Map<Id, Account> householdMap;
    private List<Account> households;
    private Map<Id, List<String>> householdEmailsMap = new Map<Id, List<String>>(); // Map of household ID to a list of the email addresses that can be safely sent to 
    private Map<Id, List<RecipientInformation>> householdRecipientMap = new Map<Id, List<RecipientInformation>>(); // Map of household ID to a list of the email addresses that can be safely sent to 

    /**********************************************************
    @Method Name    EmailMessageHelper
    @author         Cian Morrissey
    @description    Constructor class that collates the information needed in validation.
    @param          messagesMap - the map of email messages passed in from the Trigger
    *********************************************************/
    public EmailMessageHelper(Map<Id,EmailMessage> messagesMap){
        collateEmailInformation(messagesMap.values());      // Collate the key information needed
        collateEmailTemplateInformation();  // Get the email templates
        collateEmailConfigurationInfomration();             // Get the email configuration information
        getHouseholdInformation();                          // Get the information on households related to the emails
        collateEmailRecipientInformation();
    }
 
    /**********************************************************
    @Method Name    collateEmailInformation
    @author         Cian Morrissey
    @description    Construct a list of EmailDetail objects for each outbound EmailMessage
    @param          allEmails - a list of email messages that are to be sent
    *********************************************************/
    private void collateEmailInformation(List<EmailMessage> allEmails){
        for(EmailMessage email : allEmails){
            if(email.Incoming == false){
                EmailDetail emailDetail = new EmailDetail();
                emailDetail.emailMessage = email;
                emailDetail.relatedToId = email.RelatedToId;
                String relatedObjectApiName = email.RelatedToId.getSObjectType().getDescribe().getName();
                emailDetail.relatedObjectApiName = relatedObjectApiName;
                if (relatedObjectApiName == 'Account') { 
                    // To do: Need to add a check to manage whether household or person, assumes household for now
                    emailDetail.householdId = email.RelatedToId;
                    householdIds.add(email.RelatedToId);
                } else if (relatedObjectApiName == 'Advice__c') {
                    adviceIds.add(email.RelatedToId);
                } else if(relatedObjectApiName == 'Case'){
                    caseIds.add(email.RelatedToId);
                }
                outboundMessages.add(emailDetail);
            }
            
            // Create set of email template IDs 
            if(email.EmailTemplateId != null){
                emailTemplateIds.add(email.EmailTemplateId);
            }
        }
    }

    /**********************************************************
    @Method Name    collateEmailTemplateInformation
    @author         Cian Morrissey
    @description    Gets email template information so that associated email config records can be found from developer names
    *********************************************************/
    private void collateEmailTemplateInformation(){
        List<EmailTemplate> emailTemplates = [SELECT Id, DeveloperName FROM EmailTemplate WHERE Id IN :emailTemplateIds];
        for(EmailTemplate et : emailTemplates){
            emailTemplateDeveloperNames.add(et.DeveloperName);
            emailTemplateDevNameIdMap.put(et.DeveloperName, et.Id);
        }
    }

    /**********************************************************
    @Method Name    collateEmailConfigurationInfomration
    @author         Cian Morrissey
    @description    Gets email configruation record information for use in applying business rules
    *********************************************************/
    private void collateEmailConfigurationInfomration(){
        List<EmailConfiguration__c> emailConfigs = [SELECT Id, DeveloperName__c, PartnerCopied__c, Necessity__c, Type__c, From__c, CustomPermission__c FROM EmailConfiguration__c WHERE DeveloperName__c IN :emailTemplateDeveloperNames];
        for(EmailConfiguration__c config : emailConfigs){
            emailConfigMap.put(emailTemplateDevNameIdMap.get(config.DeveloperName__c), config);
        }
    }

    /**********************************************************
    @Method Name    getHouseholdInformation
    @author         Cian Morrissey
    @description    Gets information on households receiving emails
    *********************************************************/
    private void getHouseholdInformation(){
        // Get the household IDs for the advice we are sending messages for if there are advice IDs
        if(adviceIds.size() > 0){
            List<Advice__c> adviceList = [SELECT Id, Advice_household__c FROM Advice__c WHERE Id IN :adviceIds];
            for(Advice__c advice : adviceList){
                // *** Keep only one of these, TBC if the advice <=> household map is needed
                relatedIdHouseholdIdMap.put(advice.Id, advice.Advice_household__c);
            }
        }
        householdIds.addAll(relatedIdHouseholdIdMap.values());

        // Get the household IDs for the advice we are sending messages for if there are advice IDs
        if(caseIds.size() > 0){
            List<Case> caseList = [SELECT Id, AccountId FROM Case WHERE Id IN :caseIds];
            for(Case c : caseList){
                // *** Keep only one of these, TBC if the advice <=> household map is needed
                relatedIdHouseholdIdMap.put(c.Id, c.AccountId);
            }
        }
        householdIds.addAll(relatedIdHouseholdIdMap.values());

        //Get account details
        households = [SELECT Id, OwnerId, Owner.Email, EmailRecipientValidationBypass__c FROM Account WHERE Id IN: householdIds];
        householdMap = new Map<Id, Account>(households);
    }

    /**********************************************************
    @Method Name    collateEmailRecipientInformation
    @author         Cian Morrissey
    @description    Gets information on people in the household that might need to receive the email
    *********************************************************/
    private void collateEmailRecipientInformation(){
        // Create the map of household IDs to accepted email addresses
        for(Id householdId : householdIds){
            householdEmailsMap.put(householdId, new List<String>());
            householdRecipientMap.put(householdId, new List<RecipientInformation>());
        }

        // Get the list of emailable clients in each household and add it to the appropriate map
        List<AccountContactRelation> acrs = [SELECT Id, AccountId, ContactId, Contact.AddressedName__c, Contact.Email, Contact.ServiceContactPreferences__c, Roles, Contact.Account.FinServ__Status__c FROM AccountContactRelation WHERE Account.RecordType.DeveloperName = 'IndustriesHousehold' AND Roles = 'Client' AND AccountId IN :householdIds ORDER BY AccountId ASC, Contact.Email ASC];
        for(AccountContactRelation acr : acrs){
            householdEmailsMap.get(acr.AccountId).add(acr.Contact.Email);
            //Add a check based on email config to only send if they should be emailable for this type of email
            RecipientInformation recipient = new RecipientInformation();
            recipient.name = acr.Contact.AddressedName__c;
            recipient.email = acr.Contact.Email;
            if(acr.Contact.Account.FinServ__Status__c != 'Reported Deceased' && acr.Contact.Account.FinServ__Status__c != 'Deceased'){
                recipient.doNotEmail = false;
            } else {
                recipient.doNotEmail = true;
                recipient.doNotEmailReason = 'Do not email ' + recipient.name + '. They are ' + acr.Contact.Account.FinServ__Status__c;
            }
            recipient.serviceContactPreferences = acr.Contact.ServiceContactPreferences__c;
            householdRecipientMap.get(acr.AccountId).add(recipient);
        }      
    }

    /**********************************************************
    @Method Name    validateConditions
    @author         Cian Morrissey
    @description    Runs through the collated information to determine if the email message meets the business rules that apply
    *********************************************************/
    public void validateConditions(){
        List<Account> householdsBypassRevert = new List<Account>();
        // Loop the known outbound emails to validate the conditions are met
        for(EmailDetail outboundMessage : outboundMessages){
            List<String> errors = new List<String>();

            // Check whether an email template ID has been specified - one must be
            if (outboundMessage.emailMessage.EmailTemplateId == null) {
                errors.add(System.Label.EmailTriggerNoTemplate);
            } else {
                // Check for an email config file and through an error if there is not one
                EmailConfiguration__c emailConfig = emailConfigMap.get(outboundMessage.emailMessage.EmailTemplateId);
                if (emailConfig == null) {
                    errors.add(System.Label.EmailTriggerNoConfig);
                } else {
                    // Check that the user has the permission to send the associated email template and throw an error if not
                    if(!FeatureManagement.checkPermission(emailConfig.CustomPermission__c)){
                        errors.add(System.Label.EmailTriggerNoPermission);
                    } else {
                        // Validate that the conditions of the email are in line with what the email configuration file requires
                        Id householdId;
                        if(outboundMessage.relatedObjectApiName == 'Account'){
                            householdId = outboundMessage.householdId;
                        } else {
                            householdId = relatedIdHouseholdIdMap.get(outboundMessage.emailMessage.relatedToId);
                        }
                        Boolean bypassValidation = householdMap.get(householdId).EmailRecipientValidationBypass__c;
                        errors.addAll(checkFrom(outboundMessage, emailConfig));
                        //errors.addAll(checkBcc(outboundMessage, bypassValidation));
                        errors.addAll(checkCc(outboundMessage, emailConfig, householdId, bypassValidation));
                        errors.addAll(checkTo(outboundMessage, emailConfig, householdId, bypassValidation));
                        if(bypassValidation && outboundMessage.EmailMessage.Status == '3'){
                            householdsBypassRevert.add(new Account(Id = householdId, EmailRecipientValidationBypass__c = false));
                        }
                    } 
                }
            }
            if(errors.size() > 0){
                outboundMessage.emailMessage.addError('Error: ' + String.join(errors, '; '));
            }
        }  
        if(householdsBypassRevert.size() > 0){
            update householdsBypassRevert;
        }
    }

    /**********************************************************
    @Method Name    checkFrom
    @author         Cian Morrissey
    @description    Ensures the correct from address has been applied
    @param          ed - the EmailDetail object that contains the email message and additional information
    @param          ec - the email configuration that contains business rules
    @return         errors - a list of errors that should be displayed at the end of validation
    *********************************************************/
    private List<String> checkFrom(EmailDetail ed, EmailConfiguration__c ec){
        List<String> errors = new List<String>();
        String requiredFromAddress = ec.From__c;
        if(requiredFromAddress != ed.emailMessage.FromAddress){
            errors.add(String.join(new List<String> {System.Label.EmailTriggerFrom, requiredFromAddress}, ' '));
        }
        return errors;
    }

    /**********************************************************
    @Method Name    checkBcc
    @author         Cian Morrissey
    @description    Ensures nobody is included in BCC
    @param          ed - the EmailDetail object that contains the email message and additional information
    @param          bypassValidation - indicates if validation bypass applies
    @return         errors - a list of errors that should be displayed at the end of validation
    *********************************************************/
 /*   private List<String> checkBcc(EmailDetail ed, Boolean bypassValidation){
        List<String> errors = new List<String>();
        if (!bypassValidation) {
            if(!String.isBlank(ed.emailMessage.BccAddress)){
                errors.add(System.Label.EmailTriggerNoBcc);
            }
        }
        return errors;
    } */

    /**********************************************************
    @Method Name    checkCc
    @author         Cian Morrissey
    @description    Ensures the CC field requirements have been met
    @param          ed - the EmailDetail object that contains the email message and additional information
    @param          ec - the email configuration that contains business rules
    @param          householdId - the ID of the household the email is going to 
    @param          bypassValidation - indicates if validation bypass applies
    @return         errors - a list of errors that should be displayed at the end of validation
    *********************************************************/
    private List<String> checkCc(EmailDetail ed, EmailConfiguration__c ec, Id householdId, Boolean bypassValidation){
        List<String> errors = new List<String>();
        if (!bypassValidation) {
            String partnerEmail = householdMap.get(householdId).Owner.Email;
            Boolean ccPopulated = String.isNotBlank(ed.emailMessage.CcAddress);
            Boolean ccPartnerOnly;
            Boolean ccPartnerIncluded = false;
            if(ccPopulated){
                ccPartnerIncluded = ed.emailMessage.CcAddress.contains(partnerEmail);
                if(partnerEmail.equals(ed.emailMessage.CcAddress)){
                    ccPartnerOnly = true;
                } else {
                    ccPartnerOnly = false;
                }
            }
            if(ec.PartnerCopied__c == 'Always'){
                if (!ccPopulated) {
                    errors.add(System.Label.EmailTriggerCcPartner);
                } else {
                    if(!ccPartnerOnly){
                        errors.add(System.Label.EmailTriggerCcPartnerOnly);
                        if(!ccPartnerIncluded){
                            errors.add(System.Label.EmailTriggerCcPartner);
                        }
                    }
                }
            } else if(ec.PartnerCopied__c == 'Never'){
                if(ccPopulated){
                    errors.add(System.Label.EmailTriggerCcMustBeBlank);
                }
            } else if(ec.PartnerCopied__c == 'Optional'){
                if (ccPopulated){
                    if(!ccPartnerOnly){
                        errors.add(System.Label.EmailTriggerCcPartnerOnly);
                    }
                }
            }
        }
        return errors;
    }

    /**********************************************************
    @Method Name    checkTo
    @author         Cian Morrissey
    @description    Ensures the main recipients meet the business rules
    @param          ed - the EmailDetail object that contains the email message and additional information
    @param          ec - the email configuration that contains business rules
    @param          householdId - the ID of the household the email is going to 
    @param          bypassValidation - indicates if validation bypass applies
    @return         errors - a list of errors that should be displayed at the end of validation
    *********************************************************/
    private List<String> checkTo(EmailDetail ed, EmailConfiguration__c ec, Id householdId, Boolean bypassValidation){
        List<String> errors = new List<String>();
        if (!bypassValidation) {
            List<String> recipientsOutsideHousehold = new List<String>();
            List<String> missingRequiredRecipients = new List<String>();
            List<RecipientInformation> blockedRecipients = new List<RecipientInformation>();
            List<RecipientInformation> validRecipients = new List<RecipientInformation>();
            List<String> toAddresses = ed.emailMessage.ToAddress.deleteWhiteSpace().split(';');
            List<String> acceptedEmails = householdEmailsMap.get(householdId);
            List<String> householdEmails = householdEmailsMap.get(householdId);
            
            // Check if there is anyone addressed outside the clients in the household
            for(String toAddress : toAddresses){
                if(!householdEmails.contains(toAddress)){
                    recipientsOutsideHousehold.add(toAddress);
                }
            }
            if(recipientsOutsideHousehold.size() > 0){
                errors.add(System.Label.EmailTriggerRecipients + String.join(recipientsOutsideHousehold, ', '));
            }

            // Check the household emails to figure out who should be blocked from being emailed and who is required
            List<RecipientInformation> ris = householdRecipientMap.get(householdId);
            for (RecipientInformation ri : ris) {
                if(ri.doNotEmail){
                    if(toAddresses.contains(ri.email)){
                        errors.add(ri.doNotEmailReason);
                    }
                    blockedRecipients.add(ri);
                } else {
                    validRecipients.add(ri);
                }
            }

            // Check that all clients have been emailed if it's a required email
            if(ec.Necessity__c == 'Required'){
                for (RecipientInformation ri : validRecipients) {
                    if(!toAddresses.contains(ri.email)){
                        missingRequiredRecipients.add(ri.email);
                    }
                }
                if(!missingRequiredRecipients.isEmpty()){
                    errors.add(System.Label.EmailTriggerRecipientsMissing + String.join(missingRequiredRecipients, ', '));
                }
            }

            // For an optional email, check that clients who do not want serivce emails have been excluded
            if(ec.Necessity__c == 'Optional'){
                for (RecipientInformation ri : validRecipients) {
                    if(ri.serviceContactPreferences == 'Essential only'){
                        if(toAddresses.contains(ri.Email)){
                            errors.add('This person doesn\'t want to get optional emails: ' + ri.Email);
                        }
                    } else if (ri.serviceContactPreferences == 'All emails'){
                        if(!toAddresses.contains(ri.Email)){
                            errors.add('This person should be included on the email: ' + ri.Email);
                        }
                    }
                }
            }
        }
        return errors;
    }

    // A class that holds the email message and related key details like household ID that'll be calculated as they are not stored on the EmailMessage
    private class EmailDetail {
        public Id householdId;
        public Id relatedToId;
        public String relatedObjectApiName;
        public EmailMessage emailMessage;
    }

    // A class that holds the information on a recipient
    private class RecipientInformation {
        public String name;
        public String email;
        public Boolean doNotEmail;
        public String doNotEmailReason;
        public String serviceContactPreferences;
    }
}
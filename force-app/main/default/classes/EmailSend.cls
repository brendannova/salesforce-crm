/**
 * This class handles the sending of emails from Nova to customers, using a variety of methods to ensure consistency over who gets addressed, copied etc.
 * It works in conjuction with email templates and Apex components and their controllers to produce content.
 */
@SuppressWarnings('PMD.CognitiveComplexity, PMD.CyclomaticComplexity')
public without sharing class EmailSend{

    final private static String SENDING_PROCESS_AUTOMATIC = 'AUTOMATIC';
    final private static String EMAIL_INCLUDE_TO = 'EMAIL_INCLUDE_TO';
    final private static String EMAIL_INCLUDE_CC = 'EMAIL_INCLUDE_CC';
    final private static String HI_LINE ='{{hiLine}}';
    final private static String CLIENT ='Client';
    final private static String ONE_ONLY ='One only';
    final private static String ALL ='All';
    final private static String ONE_REQUEST_ERROR = 'Only one request allowed. This method does not support bulk emails yet.';
    Set<String> fromEmailAddresses = new Set<String>();
    Map<Id, AccountHouseholdMembers.HouseholdMemberResult> householdMembersMap = new Map<Id, AccountHouseholdMembers.HouseholdMemberResult>();
    Map<String, OrgWideEmailAddress> orgWideEmailAddressMap;

    // The request wrapper that needs to be provided for the correct email to generate
    public class EmailSendRequestAutomatic {
        public String emailTemplateDeveloperName;               // The email template
        public Id targetObjectId;                               // The core recipient
        public Id householdId;                                  // The household the email relates to
        public Id whatId;                                       // The specific record the email relates to
        public Boolean saveAsActivity;                          // Set as activity
        public String subject;                                  // An option custom subject
        public Map<String, String> parameters;                  // An optional map of parameters that will be replaced in the email with the values in the map
    }

    // Takes email requests and processes them to construct then send the emails
    public void sendAutomaticTemplatedEmailCustomSubject(List<EmailSendRequestAutomatic> requests) {
        // Validate requests and build a list of the email template developer names
        Set<String> emailTemplateDeveloperNames = new Set<String>();
        Set<Id> householdIds = new Set<Id>();
        for(EmailSendRequestAutomatic request : requests){
            validateRequest(request);
            emailTemplateDeveloperNames.add(request.emailTemplateDeveloperName);
            householdIds.add(request.householdId);
        }
        Map<String, EmailConfiguration__c> emailConfigurationsMap = getEmailConfigurations(emailTemplateDeveloperNames);
        orgWideEmailAddressMap = getOrgWideEmailAddresses(fromEmailAddresses);
        getHouseholdMembers(householdIds);
        Map<String, EmailTemplate> emailTemplatesMap = getEmailTemplates(emailTemplateDeveloperNames);
        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();

        // Loop the requests and construct the emails
        for(EmailSendRequestAutomatic request : requests){
            // Build the email using the template to render the HTML content
            Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(emailTemplatesMap.get(request.emailTemplateDeveloperName).Id, request.targetObjectId, request.whatId);
             // If there are parameters to swap out, do so
            if(!request.parameters.isEmpty()){
                email.htmlBody = emailTagSubstituter(request.parameters, email.htmlBody);
            }
            // If there is a custom subject, set it
            if(String.isNotBlank(request.subject)){
                email.setSubject(request.subject);
            }
            EmailConfiguration__c emailConfiguration = emailConfigurationsMap.get(request.emailTemplateDeveloperName);
			email = setUpEmail(request, email, emailConfiguration);
            System.debug(email.htmlBody);
            if( email.htmlBody.contains('{{') ) {
                throw new EmailSendException('Tags have not been replaced');
            }
            emails.add(email);
        }
        sendEmails(emails);
    }

    // Make sure we have required details for each request
    private void validateRequest(emailSendRequestAutomatic request) {
        if(request.targetObjectId == null)                          {throw new EmailSendException('targetObjectId required');}
        if(request.householdId == null)                             {throw new EmailSendException('householdId required');}
        if(request.whatId == null)                                  {throw new EmailSendException('whatId required');}
        if(String.isBlank(request.emailTemplateDeveloperName))      {throw new EmailSendException('Email template must be provided');}
    }

    // Get all email configuration records for the emails being sent
    private Map<String, EmailConfiguration__c> getEmailConfigurations(Set<String> emailTemplateDeveloperNames) {
        List<EmailConfiguration__c> emailConfigurations = [SELECT Id, DeveloperName__c, Subject__c, ClientsAddressed__c, CopyOtherClients__c, PartnerCopied__c, From__c, ReplyTo__c FROM EmailConfiguration__c WHERE DeveloperName__c IN :emailTemplateDeveloperNames AND SendingProcess__c = :SENDING_PROCESS_AUTOMATIC];
        if(emailConfigurations.isEmpty()){
            throw new EmailSendException('No email configurations found');
        } else if(emailConfigurations.size() != emailTemplateDeveloperNames.size()){
            throw new EmailSendException('Email configuration records not found for all templates');
        }
        Map<String, EmailConfiguration__c> emailConfigurationsMap = new Map<String, EmailConfiguration__c>();
        for(EmailConfiguration__c emailConfiguration : emailConfigurations){
            emailConfigurationsMap.put(emailConfiguration.DeveloperName__c, emailConfiguration);
            fromEmailAddresses.add(emailConfiguration.From__c);
        }
        return emailConfigurationsMap;
    }

    // Get all email templates for the emails being sent
    private Map<String, EmailTemplate> getEmailTemplates(Set<String> emailTemplateDeveloperNames) {
        List<EmailTemplate> emailTemplates = [SELECT Id, DeveloperName FROM EmailTemplate WHERE DeveloperName IN :emailTemplateDeveloperNames];
        if(emailTemplates.isEmpty()){
            throw new EmailSendException('No email templates found');
        } else if(emailTemplates.size() != emailTemplateDeveloperNames.size()){
            throw new EmailSendException('Email templates not all found');
        }
        Map<String, EmailTemplate> emailTemplatesMap = new Map<String, EmailTemplate>();
        for(EmailTemplate emailTemplate : emailTemplates){
            emailTemplatesMap.put(emailTemplate.DeveloperName, emailTemplate);
        }
        return emailTemplatesMap;
    }

    // Get all organization wide email addresses for the emails being sent
    private Map<String, OrgWideEmailAddress> getOrgWideEmailAddresses(Set<String> fromEmailAddresses) {
        List<OrgWideEmailAddress> orgWideEmailAddresses = [SELECT Id, Address FROM OrgWideEmailAddress WHERE Address IN :fromEmailAddresses];
        if(orgWideEmailAddresses.isEmpty()){
            throw new EmailSendException('No org wide email addresses found');
        } else if(orgWideEmailAddresses.size() != fromEmailAddresses.size()){
            throw new EmailSendException('Org wide email addresses not all found');
        }
        Map<String, OrgWideEmailAddress> orgWideEmailAddressMap = new Map<String, OrgWideEmailAddress>();
        for(OrgWideEmailAddress OrgWideEmailAddress : OrgWideEmailAddresses){
            orgWideEmailAddressMap.put(OrgWideEmailAddress.Address, OrgWideEmailAddress);
        }
        return orgWideEmailAddressMap;
    }

    // Set up common values for the email based on the request
    private Messaging.SingleEmailMessage setUpEmail(EmailSendRequestAutomatic request, Messaging.SingleEmailMessage email, EmailConfiguration__c emailConfig) {
        email.setorgWideEmailAddressId(orgWideEmailAddressMap.get(emailConfig.From__c).Id);
        email.setWhatId(request.whatId);
        email.setTargetObjectId(request.targetObjectId);
        email.setTreatTargetObjectAsRecipient(true);
        if(String.isNotBlank(emailConfig.ReplyTo__c)){
            email.setReplyTo(emailConfig.ReplyTo__c);
        }
        email.setUseSignature(false);

        AccountHouseholdMembers.HouseholdMemberResult result = householdMembersMap.get(request.householdId);
        System.debug(result);

        List<Account> toAccounts = getToAccounts(request, result, emailConfig);
        email.htmlBody = email.htmlBody.replace(HI_LINE, getHiString(toAccounts));
        List<String> toAddresses = getToAddresses(toAccounts);
        List<String> ccAddresses = getCcAddresses(result, emailConfig);
        if(!toAddresses.isEmpty()){
            email.setToAddresses(toAddresses);
        }
        if(!ccAddresses.isEmpty()){
            email.setCcAddresses(ccAddresses);
        }
        return email;
    }

    // Get the people who should directly receive the email, in to.
    private List<Account> getToAccounts(EmailSendRequestAutomatic request, AccountHouseholdMembers.HouseholdMemberResult result, EmailConfiguration__c emailConfig){
        Set<Account> toAccounts = new Set<Account>();
        if( emailConfig.ClientsAddressed__c == ONE_ONLY ) {
            for(Account member : result.memberAccountsByRole.get(CLIENT)){
                if(member.PersonContactId == request.targetObjectId){
                    toAccounts.add(member);
                }
            }
        } else if( emailConfig.ClientsAddressed__c == 'ALL' ) {
            for(Account member : result.memberAccountsByRole.get(CLIENT)){
                if(member.PersonContactId != request.targetObjectId){
                    toAccounts.add(member);
                }
            }
        }
        if( result.memberAccountsByRole.containsKey(EMAIL_INCLUDE_TO) ) {
            for( Account member : result.memberAccountsByRole.get(EMAIL_INCLUDE_TO) ) {
                    toAccounts.add(member);
            }
        }
        return new List<Account>(toAccounts);
    }

    // Take the people who are directly address, in to, on an email and construct their email addresses
    private List<String> getToAddresses(List<Account> accounts) {
        List<String> toEmails = new List<String>();
        for(Account account : accounts ) {
            toEmails.add(account.PersonEmail);
        }
        return toEmails;
    }

    // Get the people who should receive the email as CC.
    private List<String> getCcAddresses(AccountHouseholdMembers.HouseholdMemberResult result, EmailConfiguration__c emailConfig){
        Set<String> ccAddresses = new Set<String>();
        if( emailConfig.PartnerCopied__c == 'ALWAYS' ) {
            ccAddresses.add(result.household.Owner.Email);
        }
        if( result.memberAccountsByRole.containsKey(EMAIL_INCLUDE_CC) ) {
            for( Account member : result.memberAccountsByRole.get(EMAIL_INCLUDE_CC) ) {
                    ccAddresses.add(member.PersonEmail);
            }
        }
        return new List<String>(ccAddresses);
    }

    // Call the AccountHouseholdMembers class to get the members of the households who could be possible recipients.
    private void getHouseholdMembers(Set<Id> householdIds){
        List<AccountHouseholdMembers.HouseholdMemberRequest> requests = new List<AccountHouseholdMembers.HouseholdMemberRequest>();
        for(Id householdId : householdIds){
            AccountHouseholdMembers.HouseholdMemberRequest request = new AccountHouseholdMembers.HouseholdMemberRequest();
            request.householdId = householdId;
            request.roles = new Set<String>{CLIENT,EMAIL_INCLUDE_CC,EMAIL_INCLUDE_TO};
            requests.add(request);
        }
        householdMembersMap = AccountHouseholdMembers.getHouseholdMembers(requests);
    }

    // Takes a list of email recipients and constructs the opening line of the email, saying Hi.
    private String getHiString(List<Account> recipients) {
        Integer n = recipients.size();
        Integer i = 0;
        String hiString = 'Hi ';
        if ( n == 1 ) {
            hiString = hiString + recipients[0].AddressedName__pc + ',';
        } else {
            i = 0;
            for(Account recipient : recipients){
                if ( i < n - 2 ) {
                    hiString = hiString + recipients[i].AddressedName__pc + ', ';
                } else if ( i == n - 2 ) {
                    hiString = hiString + recipients[i].AddressedName__pc + ' & ';
                } else {
                    hiString = hiString + recipients[i].AddressedName__pc + ',';
                }
                i = i + 1;
            }
        }
        return hiString;
    }

    // Take a string and replaces all instances of a tag within that string with a given value. Used to replace merge fields with values.
    public static String emailTagSubstituter(Map<String, String> parameterMap, String text){
        for(String parameter : parameterMap.keySet()){
            text = text.replace(parameter, parameterMap.get(parameter));
        }
        return text;
    }

    // A simple method responsible for sending emails
    private void sendEmails(List<Messaging.SingleEmailMessage> emails){
        List<Messaging.SendEmailResult> emailSendResults = Messaging.sendEmail(emails, true);
        // To-do: work through the results to determine if everything was successful
    }
    
    // Exception class used to handle custom errors within this class
    public class EmailSendException extends Exception {}
}
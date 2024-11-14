public class sendTemplatedEmail{
    
    public static Boolean sendTemplatedEmail(String[] toRecipients, String[] ccRecipients, String emailTemplateDevName, ID targetObjId, Id whatId, ID orgWideEmailId, Boolean saveAsActivity ) {
        //  templateId  must be ID of an Email template
        //  targetObjId must be a Contact Id -- also used in merge fields of template recipient.xxxx
        //  whatId      must be an SObject that is used in the merge fields of the template relatedTo.xxxx
        //  fromId      if non null, use current user, otherwise, use this ID (most likely an org wide no reply id)
        
        Boolean successful_send;
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        Id templateId;  
        try {
            templateId = [SELECT Id, Name FROM EmailTemplate WHERE DeveloperName =: emailTemplateDevName].id;
        }catch (Exception e) {
            System.debug('Unable to locate email template using: ' + emailTemplateDevName + ' - please talk to an admin');
        }
        
        email.setToAddresses(toRecipients);
        email.setCcAddresses(ccRecipients);
        email.setTargetObjectId(targetObjId);
        email.setWhatId(whatId);
        email.setorgWideEmailAddressId(orgWideEmailId);
        email.setTemplateId(templateId);
        email.setSaveAsActivity(saveAsActivity);            // save email as activity on the targetObjId (i.e. Contact)
        try {
            Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
            successful_send = true;
        }
        catch (EmailException e) {
            successful_send = false;
            OW_system_log__c systemLog = new OW_system_log__c(OW_log_type__c = 'Send templated email', OW_log_source__c = 'sendTemplatedEmail', OW_source_type__c = 'Apex Class', OW_description__c = e.getMessage(), OW_error__c = true);
            insert systemLog;
        }
        return successful_send;
    }
    
        //The method is invocable to ensure this can be called from a flow, allowing us to use this within declarative automation. 
    @InvocableMethod(label = 'Send templated email' description = 'Sends an email using a specified template.' category = 'Email')
    public static List<FlowOutputs> invokeThisMethod(List<FlowInputs> requests){
        List<FlowOutputs> results = new List<FlowOutputs>();
        for (FlowInputs request : requests) {
            results.add(invokeLocalMethod(request));
        }
        return results;
    }
    
    public static FlowOutputs invokeLocalMethod(FlowInputs request){        
        FlowOutputs returnDetails = new FlowOutputs();
        Boolean success = sendTemplatedEmail.sendTemplatedEmail(request.toRecipients, request.ccRecipients, request.emailTemplateDevName, request.targetObjId, request.whatId, request.orgWideEmailId, request.saveAsActivity);
        if (success == true){
            returnDetails.emailSuccessful = true;
        } else {
            returnDetails.emailSuccessful = false;
        }
        return returnDetails;   
    }
    
    // Inputs to this class coming from a flow
    public class FlowInputs{
        
        @InvocableVariable
        public String[] toRecipients;
        
        @InvocableVariable
        public String[] ccRecipients;
        
        @InvocableVariable
        public String emailTemplateDevName;
        
        @InvocableVariable
        public ID targetObjId;
        
        @InvocableVariable
        public Id whatId;
        
        @InvocableVariable
        public ID orgWideEmailId;
        
        @InvocableVariable
        public Boolean saveAsActivity;
    }
    
    //output details which goes from apex to process builder
    public class FlowOutputs{
        
        @InvocableVariable
        public Boolean emailSuccessful;
    }
}
/**
 * This class exists exclusively to assign a household and owner to a new email case record when an incoming email is received.
 * We check information on the 1st email associated with the case to see if we can identify a single household to link the case to. If we can, we also check whether there is a dedicated specialist that should own the case.
 * We start by looking at who the email is from. If it is from an external party, we simply need to look at their email address, see if we have a person account associated with that email address, and link it to their household if they are a client in one.
 * If the email is from an internal Nova email address, we need to check the other parties on the email and see if we can associate it with a single household. We do this by checking the other external email addresses in to and cc.
 * If no household can be found, we leave the case to go to the email queue and the AccountId field is not updated.
 * If a household is found, we update the AccountId field but the case will only be assigned to a dedicated specialist instead of the email queue if there is one assigned and not OOO.
 */
public without sharing class FlowHelperCaseEmailCreated {
    /**
     * Invocable method that takes a list of cases to process as an input via the FlowInputs class.
	 * As the processing and updates are all completed within the method, there is no return.
    */
    @invocableMethod (label = 'Case email created invocable' description = 'Assign household and owner to an email case' category = 'Flow Helpers' iconName='slds:standard:custom_component_task')
    public static void assignHouseholdFromEmailMessage(List<FlowInputs> inputs){
        
        List<Case> cases = new List<Case>();
        for(FlowInputs input : inputs) {
            cases.add(input.record);
        }
        Map<Id,List<String>> emailAddressMap = new Map<Id, List<String>>();
        Set<String> emailAddressesToFind = new Set<String>();
        
        for(Case emailCase : [SELECT Id, (SELECT Id, ParentId, Subject, FromAddress, ToAddress, CcAddress FROM EmailMessages ORDER BY MessageDate ASC LIMIT 1) FROM Case WHERE Id =: cases]){
            if(!emailCase.EmailMessages.isEmpty()){
                EmailMessage eMessage = emailCase.EmailMessages[0];         
                List<String> emailAddressesInMessage = new List<String>();
                // Check if from Nova or external
                if(!eMessage.FromAddress.endsWith('@novawm.com')){
                    emailAddressesInMessage.add(eMessage.FromAddress);
                } else {
                    // If email is from an internal email, check To and CC fields if not blank
                    if(String.isNotBlank(eMessage.ToAddress)) {
                        emailAddressesInMessage.addAll(eMessage.ToAddress.deleteWhiteSpace().split(';'));
                    }
                    if(String.isNotBlank(eMessage.ccAddress)){
                        emailAddressesInMessage.addAll(eMessage.ccAddress.deleteWhiteSpace().split(';'));
                    }
                    //Remove internal emails
                    for(Integer i = (emailAddressesInMessage.size()-1); i>=0; i--) {
                        String emailAddress = emailAddressesInMessage[i];
                        if(emailAddress.endsWith('@novawm.com')){
                            emailAddressesInMessage.remove(i);
                        }
                    }
                }
                if(!emailAddressesInMessage.isEmpty()){
                    emailAddressMap.put(emailCase.Id, emailAddressesInMessage);
                    emailAddressesToFind.addAll(emailAddressesInMessage);
                }
            } 
        }
        
        Map<String, AccountContactRelation> emailAddressPersonMap = new Map<String, AccountContactRelation>();
        List<AccountContactRelation> relationships = [SELECT Id, AccountId, Account.OW_dedicated_specialist__c, Account.OW_dedicated_specialist__r.OutOfOfficeMessage, ContactId, Contact.Account.PersonEmail FROM AccountContactRelation WHERE Contact.Account.PersonEmail IN: emailAddressesToFind AND Roles = 'Client'];
        Map<Id, Id> householdDedicatedSpecialistMap = new Map<Id, Id>();
        for(AccountContactRelation relationship : relationships){
            emailAddressPersonMap.put(relationship.Contact.Account.PersonEmail, relationship);
            if(String.isBlank(relationship.Account.OW_dedicated_specialist__r.OutOfOfficeMessage) && !String.isBlank(relationship.Account.OW_dedicated_specialist__c)){
                householdDedicatedSpecialistMap.put(relationship.AccountId, relationship.Account.OW_dedicated_specialist__c);
            }
        }

        List<Case> casesToAssign = new List<Case>();        // Cases that should be assigned to a household and dedicated specialist or email queue
        for(String caseId : emailAddressMap.keySet()){
            Set<Id> accountIds = new Set<Id>();
            Boolean allClients = true;
            for(String emailAddress : emailAddressMap.get(caseId)){
                if(allClients && emailAddressPersonMap.containsKey(emailAddress)){
                    accountIds.add(emailAddressPersonMap.get(emailAddress).AccountId);
                } else {
                    allClients = false;
                }
            }
            if(allClients && accountIds.size() == 1) {
                List<Id> accountIdsList = new List<Id>(accountIds);
                Id householdId = accountIdsList[0];
                Case caseRecord = new Case(
                    Id = caseId,
                    AccountId = householdId
                );
                if(householdDedicatedSpecialistMap.containsKey(householdId)){
                    caseRecord.OwnerId = householdDedicatedSpecialistMap.get(householdId);
                }
                casesToAssign.add(caseRecord);
            }
        }
        update casesToAssign;
    }
    
    public class FlowInputs {
        
        @InvocableVariable (label='Case record' description='The case record to be assigned' required=true)
        public Case record;
    }
}
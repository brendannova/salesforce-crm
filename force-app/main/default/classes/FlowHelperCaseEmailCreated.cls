//This class exists exclusively to assign a household and owner to a new email case record when an incoming email is received.
public class FlowHelperCaseEmailCreated {
    
    /**
    * This method checks if the FromAddress of an incoming email on a new email case is from an internal (@novawm.com)address
    * If not, searches for a known person account with the FromAddress and relates their household if they are a client in the household
    * If so, this code checks if all external emails listed in the ToAddress and CcAddress fields are person accounts in Salesforce 
    */

    @invocableMethod (label = 'Case email created invocable' description = 'Assign household and owner to an email case' category = 'Flow Helpers' iconName='slds:standard:custom_component_task')
    public static void assignHouseholdFromEmailMessage(List<FlowInputs> cases){
		List<Case> cas = new List<Case>();     
        for(FlowInputs fi : cases) {
            cas.add(fi.record);
        }
        EmailMessage[] emails = [SELECT Id, ParentId, Subject, FromAddress, ToAddress, CcAddress FROM EmailMessage WHERE ParentId =: cas ORDER BY MessageDate ASC];
        Map<Id,List<String>> emailMap = new Map<Id, List<String>>();
        Boolean externalEmail;
        List<String> emailsToCheck = new List<String>();
        Boolean emailFound;
        for(EmailMessage em : emails){
            // Check if from Nova or external
            if(!em.FromAddress.endsWith('@novawm.com')){
                emailsToCheck.add(em.FromAddress);
            } else {
                // If email is from an internal email, check To and CC fields if not blank
                if(String.isNotBlank(em.ToAddress)) {
                    emailsToCheck.addAll(em.ToAddress.deleteWhiteSpace().split(';'));
                }
                if(String.isNotBlank(em.ccAddress)){
                    emailsToCheck.addAll(em.ccAddress.deleteWhiteSpace().split(';'));
                }
                //Remove internal emails
                for(Integer i = (emailsToCheck.size()-1); i>=0; i--) {
                    String e = emailsToCheck[i];
                    if(e.endsWith('@novawm.com')){
                        emailsToCheck.remove(i);
                    }
                }
            }
        	emailMap.put(em.ParentId, emailsToCheck);
        }
        
        List<Account> people = [SELECT Id, PersonEmail, PersonContactId FROM Account WHERE PersonEmail IN: emailsToCheck];
        List<Id> personContactIds = new List<Id>();
        for(Account p : people){
                    personContactIds.add(p.PersonContactId);
                }
        List<AccountContactRelation> relationships = [SELECT Id, AccountId, ContactId FROM AccountContactRelation WHERE ContactId IN: personContactIds AND Roles = 'Client'];
        
        List<String> emailsInMessage = new List<String>();
        List<Account> peopleFound = new List<Account>();
        Set<String> accountIds = new Set<String>();
        List<String> accountIdList = new List<String>();
        List<AccountContactRelation> acrList = new List<AccountContactRelation>();
        Map<Id, Id> caseToAccountMap = new Map<Id, Id>();
        List<Case> caseList = new List<Case>();
        for(String caseId : emailMap.keySet()){
            emailsInMessage.addAll(emailMap.get(caseId));
			//Check if all people exist in the household
            for(Account p : people){
                if(emailsInMessage.Contains(p.PersonEmail)){
                    peopleFound.add(p);
                    personContactIds.add(p.PersonContactId);
                }
            }
            //If people found from emails in message match the total number of emails, then check if they are all in the same household
            if(peopleFound.size() == emailsInMessage.size()){
                for(AccountContactRelation acr : relationships) {
                    if(personContactIds.contains(acr.ContactId)){
                        accountIds.add(acr.AccountId);
                        acrList.add(acr);
                    }
                }
                System.debug(accountIds);
                System.debug(acrList);
                if(acrList.size() == emailsInMessage.size() && accountIds.size() == 1) {
                    accountIdList.addAll(accountIds);
                    caseToAccountMap.put(caseId, accountIdList.get(0));
                    //householdMatch = true;
                }
            }
        }
        
        List<Case> casesToUpdate = [SELECT Id FROM Case WHERE ID IN: caseToAccountMap.KeySet()];
        User[] ds = [SELECT Id FROM User WHERE Id IN (SELECT OW_dedicated_specialist__c FROM Account WHERE Id =: caseToAccountMap.Values()) AND Id NOT IN (SELECT UserId FROM OutOfOffice)LIMIT 1];
        Map<Id, Id> accountToDSMap = new Map<Id, Id>();
        for(Account a : [SELECT Id, OW_dedicated_specialist__c FROM Account WHERE Id =: caseToAccountMap.Values() AND OW_dedicated_specialist__c NOT IN (SELECT UserId FROM OutOfOffice)]) {
            if(a.OW_dedicated_Specialist__c != null){
                accountToDsMap.put(a.Id, a.OW_dedicated_specialist__c);
            }
        }
 
        for(Case c : casesToUpdate){
            c.AccountId = caseToAccountMap.get(c.Id);
            if(accountToDsMap.containsKey(caseToAccountMap.get(c.Id))) {
                c.OwnerId = accountToDsMap.get(caseToAccountMap.get(c.Id));
            }
            caseList.add(c);
        }
        update caseList;
	}
    
    public class FlowInputs {
        
        @InvocableVariable
        public Case record;
    }
}
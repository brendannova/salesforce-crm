//This class exists exclusively to assign a household and owner to a new email case record when an incoming email is received.
public class FlowHelperCaseEmailCreated {
    
    /**
    * This method checks if the FromAddress of an incoming email on a new email case is from an internal (@novawm.com)address
    * If not, searches for a known person account with the FromAddress and relates their household if they are a client in the household
    * If so, this code checks if all external emails listed in the ToAddress and CcAddress fields are person accounts in Salesforce 
    */

    @invocableMethod (label = 'Case email created invocable' description = 'Assign household and owner to an email case' category = 'Flow Helpers' iconName='slds:standard:custom_component_task')
    public static void assignHouseholdFromEmailMessage(List<FlowInputs> inputs){
		List<Case> cases = new List<Case>();
        for(FlowInputs input : inputs) {
            cases.add(input.record);
        }
        Map<Id,List<String>> emailMap = new Map<Id, List<String>>();
        Set<String> emailsToFind = new Set<String>();
        
        for(Case c : [SELECT Id, (SELECT Id, ParentId, Subject, FromAddress, ToAddress, CcAddress FROM EmailMessages ORDER BY MessageDate ASC LIMIT 1) FROM Case WHERE Id =: cases]){
            if(!c.EmailMessages.isEmpty()){
                EmailMessage em = c.EmailMessages[0]; //Review notes: error handling added - if email list is empty a debug line is printed. Maybe we can talk about how else to log errors.
                List<String> emailsInMessage = new List<String>(); //List instantiated insidee loop so is cleared for each iteration
                // Check if from Nova or external
                if(!em.FromAddress.endsWith('@novawm.com')){
                    emailsInMessage.add(em.FromAddress);
                } else {
                    // If email is from an internal email, check To and CC fields if not blank
                    if(String.isNotBlank(em.ToAddress)) {
                        emailsInMessage.addAll(em.ToAddress.deleteWhiteSpace().split(';'));
                    }
                    if(String.isNotBlank(em.ccAddress)){
                        emailsInMessage.addAll(em.ccAddress.deleteWhiteSpace().split(';'));
                    }
                    //Remove internal emails
                    for(Integer i = (emailsInMessage.size()-1); i>=0; i--) {
                        String e = emailsInMessage[i];
                        if(e.endsWith('@novawm.com')){
                            emailsInMessage.remove(i);
                        }
                    }
                }
                emailMap.put(c.Id, emailsInMessage);
                //@Cian, Review comment: This set was created so we could search people's email addresses in the query on line 62. I tried using emailMap.values() but doesn't work as it's a List<List<String>>
                emailsToFind.addAll(emailsInMessage);
            } else{
                    System.debug('No email message found for ' + c);
            }
        }
        
        List<Case> casesToAssign = new List<Case>(); // Cases that should be assigned to a household and dedicated specialist or email queue
        List<Account> people = [SELECT Id, PersonEmail, PersonContactId FROM Account WHERE PersonEmail IN: emailsToFind];
        List<Id> personContactIds = new List<Id>();
        for(Account p : people){
                    personContactIds.add(p.PersonContactId);
                }
        List<AccountContactRelation> relationships = [SELECT Id, AccountId, ContactId FROM AccountContactRelation WHERE ContactId IN: personContactIds AND Roles = 'Client'];
        
        List<String> emailsInMessage = new List<String>(); //List of emails in given email message
        List<Account> peopleFound = new List<Account>(); //List of people found from emails in given email message
        Set<String> accountIds = new Set<String>(); //Unique list of accounts linked from all ACR's of people found. Remove duplicates to determine if all people are found in same household
        List<String> accountIdList = new List<String>(); //Once satisfied all people belong to the same household, add household to caseToAccountMap. A list allows us to specify the index of the row we add to the map
        List<AccountContactRelation> acrList = new List<AccountContactRelation>(); //Used to compare the size of relationships found with emails in message to ensure all people are clients in the household
        Map<Id, Id> caseToAccountMap = new Map<Id, Id>(); //Used to map the case we want to update with it's assigned household
        
        for(String caseId : emailMap.keySet()){
            emailsInMessage.addAll(emailMap.get(caseId));
			//Check if all people exist in the household
            for(Account p : people){
                if(emailsInMessage.contains(p.PersonEmail)){
                    peopleFound.add(p);
                    personContactIds.add(p.PersonContactId);
                }
            }
            //If people found from emails in message, then match the total number of emails, then check if they are all in the same household
            if(peopleFound.size() == emailsInMessage.size()){
                for(AccountContactRelation acr : relationships) {
                    if(personContactIds.contains(acr.ContactId)){
                        accountIds.add(acr.AccountId);
                        acrList.add(acr);
                    }
                }
                if(acrList.size() == emailsInMessage.size() && accountIds.size() == 1) {
                    accountIdList.addAll(accountIds);
                    caseToAccountMap.put(caseId, accountIdList.get(0));
                    //householdMatch = true;
                }
            }
            //Clear all lists before restarting the loop
            emailsInMessage.clear();
            peopleFound.clear();
            personContactIds.clear();
            accountIds.clear();
            acrList.clear();
        }
        
        Map<Id, Id> accountToDSMap = new Map<Id, Id>();
        for(Account a : [SELECT Id, OW_dedicated_specialist__c FROM Account WHERE Id =: caseToAccountMap.Values() AND OW_dedicated_specialist__c NOT IN (SELECT UserId FROM OutOfOffice)]) {
            if(a.OW_dedicated_Specialist__c != null){
                accountToDsMap.put(a.Id, a.OW_dedicated_specialist__c);
            }
        }
 
        for(Id caseId : caseToAccountMap.keySet()){
            Case c = new Case();
            c.Id = caseId;
            c.AccountId = caseToAccountMap.get(c.Id);
            if(accountToDsMap.containsKey(caseToAccountMap.get(c.Id))) {
                c.OwnerId = accountToDsMap.get(caseToAccountMap.get(c.Id));
            }
            casesToAssign.add(c);
        }
        update casesToAssign;
	}
    
    public class FlowInputs {
        
        @InvocableVariable (label='Case record'description = 'The case record to be assigned' required=true)
        public Case record;
    }

   /* private class EmailDetails {
        
        private Id caseId;
        private Case caseRecord;
        private List<String> emailAddresses;
        private Boolean assignHousehold;
        private Boolean allPeopleInHousehold;
        private Boolean onlyOneHousehold;
    } */
}
// Things we need to know
        // - 1st email received
        // - FromEmail - nova or not
        // - If from Nova, list of to/cc email addresses, stripped of Nova ones
        // - Are they all person accounts? 
        // - Are they all in the same household?
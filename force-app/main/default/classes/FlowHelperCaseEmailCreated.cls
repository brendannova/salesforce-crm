public class FlowHelperCaseEmailCreated {
    
     /**
     * This class exists exclusively to assign a household and owner to a new email case record when an incoming email is received.
     * This class is set to run only when an Email Case is created
     * It should not be used in any other contexts.
     * The purpose of this class is to link an email case to a household and dedicated specialist if found.
     */

    @invocableMethod (label='Assign household from email message')
    public static void assignHouseholdFromEmailMessage(List<FlowInputs> cases){
        /**
        * This method checks if the FromAddress of an incoming email on a new email case is from an internal (@novawm.com)address
     	* If not, searches for a known person account with the FromAddress and relates their household if they are a client in the household
     	* If so, this code checks if all external emails listed in the ToAddress and CcAddress fields are person accounts in Salesforce 
        */
        Case c = cases.get(0).record;
        String householdId;
        EmailMessage email = [SELECT Id, ParentId, Subject, FromAddress, ToAddress, CcAddress FROM EmailMessage WHERE ParentId =: c.Id ORDER BY MessageDate ASC LIMIT 1];
        
        // Check if from Nova or external
        Boolean externalEmail;
        if(email.FromAddress.endsWith('@novawm.com')) {
            externalEmail = false;
        } else {
            externalEmail = true;
        }
		
        // Check if all people exist in Salesforce
        List<String> emailsToCheck = new List<String>();
        if(externalEmail){
            emailsToCheck.add(email.FromAddress);
        } else {
            // Logic to go through to and cc addresses
            // Strip any @novawm.com addresses
            emailsToCheck.addAll(email.ToAddress.deleteWhiteSpace().split(';'));
            if(email.ccAddress != null){
            	emailsToCheck.addAll(email.ccAddress.deleteWhiteSpace().split(';'));
            }
            for(Integer i = (emailsToCheck.size()-1); i>=0; i--) {
                String e = emailsToCheck[i];
                if(e.endsWith('@novawm.com')){
                    emailsToCheck.remove(i);
                }
            }
            System.debug(emailsToCheck);
        }
        
        List<Account> people = [SELECT Id, PersonEmail, PersonContactId FROM Account WHERE PersonEmail IN: emailsToCheck];
        System.debug(people);
        Boolean allArePersonAccounts;
        if(people.size() == emailsToCheck.size()) {
            allArePersonAccounts = true;
        } else {
            allArePersonAccounts = false;
        }
        
        if(allArePersonAccounts){
            // Logic to check if they are all in the same household
            // Adding to a set and checking only 1 result seems fine
            Boolean householdMatch = false;
            List<Id> personContactIds = new List<Id>();
            if(people.size() == emailsToCheck.size()){
                for(Account p : people){
                    personContactIds.add(p.PersonContactId);
                }
                // does the number of relationships match the number of emails? And do all relationships match the the same account?
                List<AccountContactRelation> relationships = [SELECT Id, AccountId FROM AccountContactRelation WHERE ContactId IN: personContactIds AND Roles = 'Client'];
                Set<String> accountIds = new Set<String>();
                for(AccountContactRelation acr : relationships) {
                    accountIds.add(acr.AccountId);
                }
                if(relationships.size() == emailsToCheck.size() && accountIds.size() == 1) {
                    List<String> accountIdList = new List<String>();
                    accountIdList.addAll(accountIds);
                    householdId = accountIdList.get(0);
                    householdMatch = true;
                }
        	}
            
            System.debug(householdMatch);
       	
            if(householdMatch) {
                c.AccountId = householdId;
                //check if household has a dedicated specialist they're not out of office
                User[] ds = [SELECT Id FROM User WHERE Id IN (SELECT OW_dedicated_specialist__c FROM Account WHERE Id =: householdId) AND Id NOT IN (SELECT UserId FROM OutOfOffice)LIMIT 1];
                if(ds.size() > 0) {
                    c.OwnerID = ds[0].Id;
                }
                Update c;
            }
        // Future to do: consider linking to a different contact
    	}
	}
    
    public class FlowInputs {
        
        @InvocableVariable
        public Case record;
    }
}
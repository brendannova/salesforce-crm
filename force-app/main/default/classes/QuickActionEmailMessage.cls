/* 
 * This class exists to set the ToAddress on emails sent using the send email quick action on the case
 * This class sets only the ToAddress field, Cc and From addresses are set using the default feilds from the quick action in the org
 * We start by getting the cases from all quick actions passed into the class, then all clients in the household and their email addresses and use this to set the ToAddress on the email message
 * If there are multiple clients to the household, we add both emails to the ToAddress field.
 */

public class QuickActionEmailMessage implements QuickAction.QuickActionDefaultsHandler {
    
    public void onInitDefaults(List<QuickAction.QuickActionDefaults> defaults){
        List<QuickAction.SendEmailQuickActionDefaults> sendEmailDefaults = new List<QuickAction.SendEmailQuickActionDefaults>();
        List<String> caseIds = new List<String>();
        /*
         * Make sure the quick action is the standard case on feed. 
         * Only add quick action to the list to action if it's the required action. Do nothing if any other quick action is used.
         */
        for (Integer j = 0; j < defaults.size(); j++) {
            String actionName = defaults.get(j).getActionName();
            String actionType = defaults.get(j).getActionType();
            if (defaults.get(j) instanceof QuickAction.SendEmailQuickActionDefaults && 
               defaults.get(j).getTargetSObject().getSObjectType() == EmailMessage.sObjectType && 
               defaults.get(j).getActionName().equals('Case.SendEmailBeta') && 
               defaults.get(j).getActionType().equals('SendEmail')) {
                   sendEmailDefaults.add((QuickAction.SendEmailQuickActionDefaults)defaults.get(j));
                   caseIds.add(defaults.get(j).getContextId());
               }
        }
        
        Map<Id,Id> caseToAccountIdMap = new Map<Id,Id>();
        for(Case c : [SELECT Id, AccountId, Account.IsPersonAccount FROM Case WHERE Id =: caseIds]) { //Loop through cases on quick actions and add to a map
            if(!String.IsBlank(c.AccountId) && c.Account.IsPersonAccount != true){ //Ensure case is assiged a household. Cannot be a person account.
            	caseToAccountIdMap.put(c.AccountId, c.Id);
            }
        }
        
        Map<Id,String> caseToEmailAddressMap = new Map<Id,String>();
        for(AccountContactRelation relationships : [SELECT Id, AccountId, ContactId, Contact.Email, Account.Owner.Email FROM AccountContactRelation WHERE AccountId =: caseToAccountIdMap.keySet() AND Roles = 'Client']){
            if(caseToEmailAddressMap.containsKey(caseToAccountIdMap.get(relationships.AccountId))){ //If a row already exists for the quick action case, then add the current client email address to the map
                String emailAddresses = caseToEmailAddressMap.get(caseToAccountIdMap.get(relationships.AccountId)) + ';' + relationships.Contact.Email;
                caseToEmailAddressMap.put(caseToAccountIdMap.get(relationships.AccountId), emailAddresses);
            }else{ //If a row does not already exist for the case, then add caseId and current item's email address
                caseToEmailAddressMap.put(caseToAccountIdMap.get(relationships.AccountId), relationships.Contact.Email);
            }
        }
        
        for(QuickAction.SendEmailQuickActionDefaults quickAction : sendEmailDefaults){ //Loop through quick actions and set ToAddress
            EmailMessage emailMessageRecord = (EmailMessage)quickAction.getTargetSObject();
            if(caseToEmailAddressMap.containsKey(quickAction.getContextId())){
                emailMessageRecord.ToAddress = caseToEmailAddressMap.get(quickAction.getContextId());
            }
        }
    }
}
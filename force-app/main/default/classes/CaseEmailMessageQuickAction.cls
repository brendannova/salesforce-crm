global class CaseEmailMessageQuickAction implements QuickAction.QuickActionDefaultsHandler {
    
    global void onInitDefaults(QuickAction.QuickActionDefaults[] defaults){
        
        QuickAction.SendEmailQuickActionDefaults sendEmailDefaults = null;
    	Boolean b = false;
    
        // Check if the quick action is the standard case feed Email action
        for (Integer j = 0; j < defaults.size(); j++) {
            String actionName = defaults.get(j).getActionName();
            String actionType = defaults.get(j).getActionType();
            System.debug(actionName + ' - Name | ' + actionType + ' - Type');
            if (defaults.get(j) instanceof QuickAction.SendEmailQuickActionDefaults && 
               defaults.get(j).getTargetSObject().getSObjectType() == 
                   EmailMessage.sObjectType && 
               defaults.get(j).getActionName().equals('Case.Send_email_POC') && 
               defaults.get(j).getActionType().equals('SendEmail')) {
                   sendEmailDefaults = 
                       (QuickAction.SendEmailQuickActionDefaults)defaults.get(j);
                   b = true;
                   break;
            }
        }
        System.debug(b);
        String s = sendEmailDefaults.getContextId();
        System.debug(s);
        
        
        Case c = [SELECT Id, AccountId FROM Case WHERE Id =: sendEmailDefaults.getContextId()];
        Account a = [SELECT Id, FinServ__PrimaryContact__r.Email, SecondaryContact__r.PersonEmail, OwnerId, Owner.Email FROM Account WHERE Id =: c.AccountId];
        
        EmailMessage emailMessageRecord = (EmailMessage)sendEmailDefaults.getTargetSObject();
        String emails = a.FinServ__PrimaryContact__r.Email;
        if(!String.isBlank(a.SecondaryContact__r.PersonEmail)){
            emails = emails + ';' + a.SecondaryContact__r.PersonEmail;
        } 
        emailMessageRecord.ToAddress = emails;
        emailMessageRecord.CcAddress = a.owner.Email;
    }

}
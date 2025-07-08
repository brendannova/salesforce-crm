public class EmailAddressRecipients {
    public String objectIdString{get;set;}
	public String emailTemplateDeveloperName{get;set;}
    private Id accountId;
    private Id householdId;
    public EmailConfiguration__c emailConfig;
    public String hiString;
    
    // Given the object ID and email template developer name, sets the email configuration record, account and household IDs appropriately
    public Configs setConfigDetails() {
        Configs result = new Configs();
        
        if(String.isBlank(objectIdString)){
            objectIdString = ApexPages.currentPage().getParameters().get('objectIdString');
        }
        
        Id objectId = Id.valueOf(objectIdString);
        String objectApiName = objectId.getSObjectType().getDescribe().getName();
        
        switch on objectApiName {
            when 'Fulfilment__c' {
                Fulfilment__c flfl = [SELECT Id, Recommendation__r.PrimaryOwner__c, Recommendation__r.RegisteredContact__c, Household__c FROM Fulfilment__c WHERE Id =: objectId LIMIT 1];
                if( flfl.Recommendation__r.RegisteredContact__c == null ) {
                    result.accountId = flfl.Recommendation__r.PrimaryOwner__c;
                } else {
                    result.accountId = flfl.Recommendation__r.RegisteredContact__c;
                }
                result.householdId = flfl.Household__c;
            }
            when 'Account' {
                Account acc = [SELECT Id, RecordType.DeveloperName, Household_Lookup__c FROM Account WHERE Id =: objectId LIMIT 1];
                if ( acc.RecordType.DeveloperName == 'IndustriesHousehold' ) {
                    result.householdId = objectId;
                	result.accountId = null;
                } else {
                    result.accountId = objectId;
                	result.householdId = acc.Household_Lookup__c;
                }
            }
            when 'Advice__c' {
                Advice__c adv = [SELECT Id, Advice_Household__c FROM Advice__c WHERE Id =: objectId LIMIT 1];
                result.accountId = null;
                result.householdId = adv.Advice_Household__c;
            }
            when else {
                throw new emailAddressRecipientsException('Cannot use the Hi line on this object type: ' + objectApiName);
            }
            
        }
        
        if(String.isBlank(emailTemplateDeveloperName)){
            emailTemplateDeveloperName = ApexPages.currentPage().getParameters().get('emailTemplateDeveloperName');
        }
        
        result.emailConfig = [SELECT Id, ClientsAddressed__c, Necessity__c FROM EmailConfiguration__c WHERE DeveloperName__c =: emailTemplateDeveloperName LIMIT 1];  
        
        return result;
    }
        
    // Method to return the address recipients line ('Hi <recipients>'), given the requirements from the email configuration
    public String getAddressRecipients() {
        Configs config = setConfigDetails();
        
        accountId = config.accountId;
        householdId = config.householdId;
        emailConfig = config.emailConfig;
        
        if( emailConfig.ClientsAddressed__c == 'All' || accountId == null ) {
            return getHiStringHousehold(householdId, emailConfig);
        } else if ( emailConfig.ClientsAddressed__c == 'One only' ) {
            return getHiStringIndividual(accountId);
        } 
        
        return '';
    }
    
    // Returns the string if only one client is addressed
    public String getHiStringIndividual(Id accountId) {
		Account client = [SELECT Id, AddressedName__pc FROM Account WHERE Id =: accountId LIMIT 1];
        return 'Hi ' + client.AddressedName__pc;
    }
    
    // Returns the string where all clients in the housheold should be addressed
    public String getHiStringHousehold(Id householdId, EmailConfiguration__c emailConfig) {
        AccountHouseholdMembers.HouseholdMemberRequest hmr = new AccountHouseholdMembers.HouseholdMemberRequest();
        
        hmr.householdId = householdId;
        
        Set<String> roles = new Set<String>();
        roles.add('Client');
        hmr.roles = roles;

        Map<String, List<Account>> hmrResult = AccountHouseholdMembers.getHouseholdMembers(hmr).memberAccountsByRole;

        List<String> recipients = new List<String>();

        for( Account household_member : hmrResult.get('Client') ) {
            if (emailConfig.Necessity__c == 'Required' || household_member.ServiceContactPreferences__pc == 'All emails') {
            	recipients.add(household_member.FinServ__PreferredName__pc);
           	}
        }
        recipients.sort();
        
        // Loop through the recipients to produce the recipient details to be displayed in the email
        Integer n = recipients.size();
        Integer i = 0;
        hiString = 'Hi ';
        
        if ( n == 1 ) {
            hiString = hiString + recipients[0] + ',';
        } else {
            i = 0;
            for(String recipient : recipients){
                if ( i < n - 2 ) {
                    hiString = hiString + recipients[i] + ', ';
                } else if ( i == n - 2 ) {
                    hiString = hiString + recipients[i] + ' & ';
                } else {
                    hiString = hiString + recipients[i] + ',';
                }
                i = i + 1;
            }
        }
        return hiString;  
    }
    
    public class Configs {
        public Id accountId;
        public Id householdId;
        public EmailConfiguration__c emailConfig;
    }
    
    public class emailAddressRecipientsException extends Exception {}

}
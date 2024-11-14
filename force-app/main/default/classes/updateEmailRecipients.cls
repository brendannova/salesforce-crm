public class updateEmailRecipients{
    
    // Create the variables that are needed throughout this flow or returned to the Visualforce component
    public String adviceId{get;set;}
    public String hi_string;
    
    // Method for the visualforce component to call to get a list of the owners
    public String getHi_string() {
        if(String.isBlank(adviceId)){
            adviceId = ApexPages.currentPage().getParameters().get('adviceId');                
        }
        if(String.isNotBlank(adviceId)){
            
            // Get details of the advice, primarily to identify the household
            Advice__c adv = [SELECT Advice_Household__c FROM Advice__c WHERE Id =: adviceId];
            
            // Generate a list of the people in the household using their first or preferred name appropriately and sort
            List<AccountContactRelation> household_members = [SELECT Contact.Account.FirstName, Contact.Account.FinServ__PreferredName__pc FROM AccountContactRelation WHERE AccountId =: adv.Advice_Household__c AND Roles = 'Client' AND Contact.Email != null];
            List<String> recipients = new List<String>();
            String name;
            for( AccountContactRelation household_member : household_members ){
                if( String.isBlank(household_member.Contact.Account.FinServ__PreferredName__pc) ){
                    name = household_member.Contact.Account.FirstName;
                } else {
                    name = household_member.Contact.Account.FinServ__PreferredName__pc;
                }
                recipients.add(name);
            }
            recipients.sort();
            
            // Loop through the recipients to produce the recipient details to be displayed in the email
            Integer n = recipients.size();
            Integer i = 0;
            hi_string = 'Hi ';
            
            if ( n == 1 ) {
                hi_string = hi_string + recipients[0] + ',';
            } else {
                i = 0;
                for(String recipient : recipients){
                    if ( i < n - 2 ) {
                        hi_string = hi_string + recipients[i] + ', ';
                    } else if ( i == n - 2 ) {
                        hi_string = hi_string + recipients[i] + ' & ';
                    } else {
                        hi_string = hi_string + recipients[i] + ',';
                    }
                    i = i + 1;
                }
            }
        }
        return hi_string;
    }
}
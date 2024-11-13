public class EmailHiString {
	public String objectIdString{get;set;}
	public String emailTemplateDevName{get;set;}
    public String hiString;

    public String getHiString() {
        Id householdId;
        if(String.isBlank(objectIdString)){
            objectIdString = ApexPages.currentPage().getParameters().get('objectIdString');
        }
        Id objectId = Id.valueOf(objectIdString);
        String objectApiName = objectId.getSObjectType().getDescribe().getName();
        if(objectApiName == 'Account'){
            householdId = objectId;
        } else if (objectApiName == 'Advice__c'){
            householdId = [SELECT Advice_household__c FROM Advice__c where Id = :objectId].Advice_household__c;
        }
        if(String.isBlank(emailTemplateDevName)){
            emailTemplateDevName = ApexPages.currentPage().getParameters().get('emailTemplateDevName');
        }
        List<EmailConfiguration__c> ecs = [SELECT Id, Necessity__c FROM EmailConfiguration__c WHERE DeveloperName__c =: emailTemplateDevName];
        String necessity = [SELECT Id, Necessity__c FROM EmailConfiguration__c WHERE DeveloperName__c =: emailTemplateDevName][0].Necessity__c;
        
        // Generate a list of the people in the household using their first or preferred name appropriately and sort
        List<AccountContactRelation> household_members = [SELECT Contact.Account.ServiceContactPreferences__pc, Contact.Account.FirstName, Contact.Account.FinServ__PreferredName__pc FROM AccountContactRelation WHERE AccountId =: householdId AND Roles = 'Client' AND Contact.Email != null];
        List<String> recipients = new List<String>();
        String name;
        for( AccountContactRelation household_member : household_members ){
            if (necessity == 'Required' || household_member.Contact.Account.ServiceContactPreferences__pc == 'All emails') {
                if( String.isBlank(household_member.Contact.Account.FinServ__PreferredName__pc) ){
                    name = household_member.Contact.Account.FirstName;
                } else {
                    name = household_member.Contact.Account.FinServ__PreferredName__pc;
                }
            	recipients.add(name);
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
}
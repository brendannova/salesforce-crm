public with sharing class InformationRequestHouseholdDisplay {
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> formattedData(String recordId) {
    	List<Map<String, String>> outputs = new List<Map<String, String>>();
        
        List<FinServ__FinancialAccount__c> accounts = [SELECT Id FROM FinServ__FinancialAccount__c WHERE Household__c =: recordId];
        Set<Id> ids = new Set<Id>(new Map<Id, FinServ__FinancialAccount__c>(accounts).keySet());
        List<InformationRequest__c> listIrs= [SELECT Id, Name, Status__c, InformationRequestType__r.Name, FinancialProductFinServ__c, InformationRequestType__c, FinancialProductFinServ__r.Name FROM InformationRequest__c WHERE FinancialProductFinServ__c IN :ids];
    	
        for( InformationRequest__c ir : listIrs ) {
        	Map<String, String> tempMap = new Map<String, String>();
        	tempMap.put('Id',ir.Id);
            tempMap.put('Name',ir.Name);
            tempMap.put('Link','https://octopuswealth--uat.sandbox.lightning.force.com/lightning/r/InformationRequest__c/' + ir.Id + '/view');
			tempMap.put('Status',ir.Status__c);
            tempMap.put('FinancialProductName',ir.FinancialProductFinServ__r.Name);
            tempMap.put('FinancialProductLink','https://octopuswealth--uat.sandbox.lightning.force.com/lightning/r/FinServ__FinancialAccount__c/' + ir.FinancialProductFinServ__c + '/view');
            tempMap.put('Type',ir.InformationRequestType__r.Name);
                    System.debug(tempMap);

            outputs.add(tempMap);
    	}
        System.debug(outputs);
        return outputs;
    }
}
/**
 * This class exists exclusively to provide support for the Information Request Related List for households LWC.
 * It should not be used in any other contexts.
 * It gets information requests for any financial product related to the household and formats the data into a list of maps for an LWC to use. 
 */
public with sharing class InformationRequestHouseholdDisplay {
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> formattedData(String recordId) {
    	List<Map<String, String>> outputs = new List<Map<String, String>>();
        
        List<FinServ__FinancialAccount__c> accounts = [SELECT Id FROM FinServ__FinancialAccount__c WHERE Household__c =: recordId];
        Set<Id> ids = new Set<Id>(new Map<Id, FinServ__FinancialAccount__c>(accounts).keySet());
        List<InformationRequest__c> listIrs= [SELECT Id, Name, Status__c, InformationRequestType__r.Name, FinancialProductFinServ__c, InformationRequestType__c, FinancialProductFinServ__r.Name FROM InformationRequest__c WHERE FinancialProductFinServ__c IN :ids AND Status__c NOT IN ('Complete', 'Cancelled')];
        String urlPrefix = URL.getOrgDomainURL().toExternalForm() + '/';
        
        List<Schema.PicklistEntry> statusValues = InformationRequest__c.Status__c.getDescribe().getPicklistValues();
        Map<String,String> statusApiToLabelMap = new Map<String,String>();
        For(Schema.PicklistEntry sp : statusValues){
            //Map to hold Picklist API as Key and Picklist Label as Value
            statusApiToLabelMap.put(sp.getValue(), sp.getLabel());
        }

        for( InformationRequest__c ir : listIrs ) {
        	Map<String, String> tempMap = new Map<String, String>();
        	tempMap.put('Id',ir.Id);
            tempMap.put('Name',ir.Name);
            tempMap.put('Link', urlPrefix + ir.Id);
			tempMap.put('Status',statusApiToLabelMap.get(ir.Status__c));
            tempMap.put('FinancialProductName',ir.FinancialProductFinServ__r.Name);
            tempMap.put('FinancialProductLink',urlPrefix + ir.FinancialProductFinServ__c);
            tempMap.put('Type',ir.InformationRequestType__r.Name);
            System.debug(tempMap);

            outputs.add(tempMap);
    	}
        System.debug(outputs);
        return outputs;
    }
    public List<Map<String, String>> getOutputs(String recordId){
        return formattedData(recordId);
    }
}
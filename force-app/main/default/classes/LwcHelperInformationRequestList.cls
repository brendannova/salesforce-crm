/**
 * This class exists exclusively to provide support for the Information Request Related List for households LWC.
 * It should not be used in any other contexts.
 * It gets information requests for any financial product related to the household and formats the data into a list of maps for an LWC to use. 
 */
public with sharing class LwcHelperInformationRequestList {

    // Method notes here
    @AuraEnabled(cacheable=true)
    public static List<Map<String, String>> getData(String recordId) {
    	List<Map<String, String>> informationRequestListData = new List<Map<String, String>>();
        List<InformationRequest__c> informationRequests = [SELECT Id, Name, Status__c, AuthorityStatus__c,InformationRequestType__r.Name, FinancialProductFinServ__c, InformationRequestType__c, FinancialProductFinServ__r.Name FROM InformationRequest__c WHERE FinancialProductFinServ__r.Household__c =: recordId AND ( Status__c != 'Complete' OR Status__c != 'Cancelled') ORDER BY Status__c ASC];
        String urlPrefix = URL.getOrgDomainURL().toExternalForm() + '/';
        Map<String,String> statusApiToLabelMap = getPicklistApiLabelMap();
        for( InformationRequest__c informationRequest : informationRequests ) {
        	Map<String, String> informationRequestData = new Map<String, String>();
        	informationRequestData.put('Id',informationRequest.Id);
            informationRequestData.put('Name',informationRequest.Name);
            informationRequestData.put('Link', urlPrefix + informationRequest.Id);
			informationRequestData.put('Status',statusApiToLabelMap.get(informationRequest.Status__c));
            informationRequestData.put('FinancialProductName',informationRequest.FinancialProductFinServ__r.Name);
            informationRequestData.put('FinancialProductLink',urlPrefix + informationRequest.FinancialProductFinServ__c);
            informationRequestData.put('Type',informationRequest.InformationRequestType__r.Name);
            informationRequestData.put('AuthStatus',informationRequest.AuthorityStatus__c);
            informationRequestListData.add(informationRequestData);
    	}
        return informationRequestListData;
    }

    // Get a map of picklist values to labels so that we can display the labels in the list
    private static Map<String,String> getPicklistApiLabelMap(){
        List<Schema.PicklistEntry> picklistItems = InformationRequest__c.Status__c.getDescribe().getPicklistValues();
        Map<String,String> picklistApiLabelMap = new Map<String,String>();
        For(Schema.PicklistEntry picklistItem : picklistItems){
            picklistApiLabelMap.put(picklistItem.getValue(), picklistItem.getLabel());
        }
        return picklistApiLabelMap; 
    }
}
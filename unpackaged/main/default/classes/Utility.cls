global with sharing class Utility {

    /*
    *	@methodName = getObjectNameById
    *	@return = Object API Name
    *	@params = A Salesforce record ID
    *	@description = Method takes a Salesforce record ID and returns the object API name
    */
    global static String getObjectNameById(Id objectId){
        return objectId.getSObjectType().getDescribe().getName();
    }

    /*
    *	@methodName = getObjectLabelById
    *	@return = Object label
    *	@params = A Salesforce record ID
    *	@description = Method takes a Salesforce record ID and returns the object's label
    */
    global static String getObjectLabelById(Id objectId){
        return objectId.getSObjectType().getDescribe().getLabel();
    }

    /*
    *	@methodName = getRecordTypeId
    *	@return = Record type ID
    *	@params = objectApiName for the developer name of an object, recordTypeDeveloperName for the developer name of a record type
    *	@description = Method takes object and record type developer names and retuns the record type ID
    */
    public static Id getRecordTypeId(String objectApiName, String recordTypeDeveloperName) {
        
        Map<String, Schema.SObjectType> m = Schema.getGlobalDescribe();
        Schema.SObjectType s = m.get(objectApiName);
        Schema.DescribeSObjectResult cfrSchema = s.getDescribe();
        Map<String,Schema.RecordTypeInfo> RecordTypeInfo = cfrSchema.getRecordTypeInfosByDeveloperName();
        Id recordTypeId = RecordTypeInfo.get(recordTypeDeveloperName).getRecordTypeId();
        return recordTypeId;
        
        /*Other methods for future consideration 
        -- SOQL query on the record type object, uses limits but dynamic --
		rtId = [SELECT Id FROM RecordType WHERE DeveloperName = :recordTypeDeveloperName AND sObjectType = :objectApiName].Id;
        -- If statements to get ID simply, can't run dynamically on object so would need to expand as objects grow --
        if(objectApiName == 'Advice__c'){
            rtID = Schema.SObjectType.Advice__c.getRecordTypeInfosByDeveloperName().get(recordTypeDeveloperName).getRecordTypeId();
        } else if (objectApiName == 'Account'){
            rtID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(recordTypeDeveloperName).getRecordTypeId();
        } */
    }

    /*
    *	@methodName = getBaseUrl
    *	@return = The base URL for the org
    *	@description = Returns the base URL for the Salesforce org in which the code executes
    */
    public static String getBaseUrl() {
        String baseUrl = System.URL.getOrgDomainURL().toExternalForm();
        return baseUrl;
    }
}
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

    public static BusinessHours defaultBusinessHours {
        get {
            if (defaultBusinessHours == null) {
                defaultBusinessHours = [SELECT Id, Name, IsActive, IsDefault, MondayStartTime, MondayEndTime FROM BusinessHours WHERE IsDefault = true LIMIT 1];
            }
            return defaultBusinessHours;
        }
        set;
    }

    public static Date getOffsetBusinessDate(date startDate, Integer daysOffset){
        //salesforce funciton will only accept datetimes
        Integer d = startDate.day();
        Integer m = startDate.month();
        Integer y = startDate.year();

        Long startTimeInMilliseconds = (defaultBusinessHours.MondayStartTime.hour() * 60L * 60L * 1000L) + (defaultBusinessHours.MondayStartTime.minute() * 60L * 1000L);
        Long endTimeInMilliseconds = (defaultBusinessHours.MondayEndTime.hour() * 60L * 60L * 1000L) + (defaultBusinessHours.MondayEndTime.minute() * 60L * 1000L);
        Long dayInMilliseconds = endTimeInMilliseconds - startTimeInMilliseconds;

        Long daysOffsetLong = (long) daysOffset;
        Long milisecondsOffset = (daysOffsetLong * 9L * 60L * 60L * 1000L); //Ignores less than 1 minute despite being in milliseconds. Have to tip over into the next day or will assume 6pm is valid and fall 1 day short.

        DateTime startDateTime = DateTime.newInstance(y, m, d, defaultBusinessHours.MondayEndTime.hour(), defaultBusinessHours.MondayEndTime.minute(), 0); //have to tip over to tomorrow otherwise will consume a days woth of milliseconds for the same day
                
        // Calculate the offset date using the default business hours (offset in milliseconds). Traverses only business hours... assuming 9 hours in a work day
        Datetime offsetDateTime = System.BusinessHours.add(defaultBusinessHours.Id, startDateTime, daysOffsetLong * dayInMilliseconds); //L forces long, to prevetn integer value overflowing if too large
        Date offsetDate = offsetDatetime.date();
        return offsetDate;
    }

    // Checks if the org in question is a sandbox. This can be used to ensure that logic is only executed in production/sandbox as appopriate.    
    public static Boolean isSandbox {
        get {
            isSandbox = isSandbox == null ? [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox : isSandbox;
            return isSandbox;
        }
        set;
    }

    // Returns the sandbox name. The return value will be null if run in production. 
    public static String sandboxName{
        get {
            sandboxName = System.DomainParser.parse(URL.getOrgDomainUrl()).getSandboxName();
            return sandboxName == null ? '' : sandboxName;
        }
        set;
    }

}
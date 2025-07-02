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
            return System.DomainParser.parse(URL.getOrgDomainUrl()).getSandboxName();
        }
        set;
    }
    
    /*
*	@methodName = getPicklistApiLabelMap
*	@return = Map from option values to labels
*	@params = A string with the API name of a Salesforce sObject, and a string with the API name of a picklist field on that object.
*	@description = Method takes a Salesforce object and field and returns a map from the picklist values to their labels. Field name MUST be for a field which is a picklist.
*/
    public static Map<String,String> getPicklistApiLabelMap(String objectName, String fieldName){
        Map <String,Schema.SObjectType> gd = Schema.getGlobalDescribe();
        Schema.SObjectType sobjType = gd.get(objectName);
        Schema.DescribeSObjectResult r = sobjType.getDescribe();
        Map<String, Schema.SObjectField> MapofField = r.fields.getMap();
        Schema.SObjectField field = MapofField.get(fieldName);
        
        List<Schema.PicklistEntry> picklistItems = field.getDescribe().getPicklistValues();
        
        Map<String,String> picklistApiLabelMap = new Map<String,String>();
        For(Schema.PicklistEntry picklistItem : picklistItems){
            picklistApiLabelMap.put(picklistItem.getValue(), picklistItem.getLabel());
        }
        return picklistApiLabelMap; 
    }
    
    /*
*	@methodName = tagSubstituter
*	@return = A string with all tags removed
*	@params = A string containing tags, an ID for an object which is refetrenced by the tags, a string containing the name of the object, a string containing the email type of the custom metadata
*	@description = Method which takes a message containing tags and replaces them with merge fields. The object name must be the same as the object referred to by the ID, and the emailType must be one of the values from the emailType picklist on the query fields custom metadata.
*/
    public static String tagSubstituter(String message, Id objectId, String objectName, String emailType) {
        String substitute_tag;
        String substitute_value;    
        
        // Get the query setting stored in custom metadata
        List<OW_query_field__mdt > query_settings = [SELECT OW_tag__c, OW_field__c FROM OW_query_field__mdt WHERE EmailType__c =: emailType ];
        
        // Create a map from a tag to a specific field value
        Map<String, String> substitution_map = new Map<String, String>();
            Set<String> query_fields_set = new Set<String>(); // Use a set initially to ensure there are no duplicate values
            for(OW_query_field__mdt  query_setting : query_settings){
                query_fields_set.add(query_setting.OW_field__c);
                if( !String.isBlank(query_setting.OW_tag__c)){
                    substitution_map.put(query_setting.OW_tag__c, query_setting.OW_field__c);
                }
            }
        List<String> query_fields_list = new List<String>(query_fields_set); // Convert from set to list to allow String.join method to be used
        if( query_fields_list.isEmpty() ) {
            return message;
        }
        String query_fields_string = String.join(query_fields_list, ',');
       
        sObject obj  = Database.query('SELECT ' + query_fields_string + ' FROM ' + objectName + ' WHERE Id =: objectId');
            
        
        // For this object instance, create a map from the field path names to their values
        Map<String, Object> fieldValues = new Map<String, Object>();
        fieldValues = genFieldValueMap(obj.getPopulatedFieldsAsMap(), '');
        
        // Create a Matcher to run through the input message
        Matcher tagIndicator = Pattern.compile('\\{(.*?)\\}').matcher(message);
        
        // While there are still tags in the message, use them to map the tag to a field name, then map from field name to the value
        while(tagIndicator.find()){
            substitute_tag = tagIndicator.group();
            if( !substitution_map.containsKey(substitute_tag) ) {
                throw new UtilityException('There is no custom setting for the tag ' + substitute_tag); 
            }
            if( !fieldValues.containsKey(substitution_map.get(substitute_tag)) ) {
                throw new UtilityException('The field value ' + substitution_map.get(substitute_tag) + ' does not exist'); 
            }
            if( fieldValues.get(substitution_map.get(substitute_tag)) instanceOf Date ){  // Format string if a date
                DateTime date_output = Date.valueOf(fieldValues.get(substitution_map.get(substitute_tag)));
                substitute_value = date_output.format('d MMMMM yyyy');
            } else {
                substitute_value = String.valueOf(fieldValues.get(substitution_map.get(substitute_tag)));
            }
            message = message.replace(substitute_tag, substitute_value);
        }
        
        return message;
    }
    
    // Given a map from field values of an object to their values, creates a new map where the keys contain the field names' full path -
    public static Map<String, Object> genFieldValueMap(Map<String, Object> fieldValues, String prefix) {
        Map<String, Object> field_values_temp = new Map<String, Object>();
        for (String fieldName : fieldValues.keySet()) {
            if (fieldValues.get(fieldName) instanceof sObject) { // If an sObject, this class is called again (nested) to get field values from parent relationships
                prefix = prefix + fieldName + '.' ;
                sObject obj = (sObject) fieldValues.get(fieldName);
                field_values_temp.putAll(genFieldValueMap(obj.getPopulatedFieldsAsMap(), prefix));
            } else {
                field_values_temp.put(prefix + fieldName, fieldValues.get(fieldName));
            }
        }
        return field_values_temp;
    }
    
    public class UtilityException extends Exception {}
}
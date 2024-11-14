/**
    * @description This class controls the capturing of audit log entries. 
*/
public without sharing class AuditLogEntry {

    /**
    * @description Takes a record ID and object API name and captures audits who has viewed that record
        * @param recordId - the ID of the record being viewed
        * @param objectApiName - the object being viewed
        * @param audited - if the view has already been audited or not
        * @return audited - whether an audit record has been captured or not
    */
    @AuraEnabled
    public static Boolean createAuditLogEntry(String recordId, String objectApiName, Boolean audited){
        if(audited == false){
            if(!String.isEmpty(recordId) && !String.isEmpty(objectApiName)){
                String eventType = 'Page view';
                Id defaultOwnerId = '0054J000005ZwOKQA0';
                String recordName;
                List<sObject> records = Database.query('SELECT Id, Name FROM ' + objectApiName + ' WHERE Id = :recordId');
                if(records.size() == 1){
                    recordName = (String) records[0].get('Name');
                } else if(records.size() == 0){
                    recordName = 'Err: no record';
                } else {
                    recordName = 'Err: multiple records';
                }
                AuditLogEntry__c log = new AuditLogEntry__c(
                    RecordId__c = recordId, 
                    EventDate__c = DateTime.now(),
                    EventType__c = eventType,
                    UserId__c = UserInfo.getUserId(),
                    UserName__c = UserInfo.getName(),
                    OwnerId = defaultOwnerId,
                    RecordName__c = recordName,
                    RecordObject__c = objectApiName
                );
                try {
                    insert log;
                    audited = true;
                } catch(DmlException e) {
                    audited = false;
                    System.debug('Audit failed with exception: ' + e.getMessage());
                }
            } else {
                audited = false;
            }
            
        }
        return audited;
    }
}
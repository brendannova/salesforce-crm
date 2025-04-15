public with sharing class LwcHelperTaskOrchestrator {
    @AuraEnabled(cacheable=true)
    public static OW_task_information__c getTaskInfoByTaskName(String taskTypeName) {
        List<OW_task_information__c> info = [
            SELECT Id, OW_task_type__c, OW_task_description_google_doc_link__c
            FROM OW_task_information__c
            WHERE OW_task_type__c = :taskTypeName
            LIMIT 1
        ];

        if(info.size() > 0) {
            return info[0];
        }
        return null;
    }
}
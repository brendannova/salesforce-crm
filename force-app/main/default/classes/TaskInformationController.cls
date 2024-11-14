public class TaskInformationController {
    
    @AuraEnabled
    public static OW_task_information__c getTaskInfo(String taskId){
        
        // Get the record type first for the given task. 
        // No error handling for null return or multiple results as this class will be called by a Lightning component
        // on a task record page so we can trust that the task ID can only and will always return 1 result.
        Task t = [SELECT OW_task_information_identifier__c, RecordType.DeveloperName FROM Task WHERE Id =: taskId LIMIT 1];
        
        // Get the task information for the given task record type.
        // Max 1 result will be returned as the field in the WHERE statement is unique.
        // Error handling for a null result handled here with Aura exception thrown warning no task information record exists. 
        
        List<OW_task_information__c> taskinfos = new List<OW_task_information__c>();
        if( t.OW_task_information_identifier__c != null){
            taskInfos = [SELECT Id, Name, OW_assigned_to__c, OW_due_date__c, LastModifiedBy.Name, LastModifiedDate, OW_process_variant__c, OW_requires_4eye__c, OW_stage__c, OW_status__c, OW_task_description__c, OW_triggered_by__c, OW_triggers__c FROM OW_task_information__c WHERE Id =: t.OW_task_information_identifier__c LIMIT 1];
        } else {
            taskInfos = [SELECT Id, Name, OW_assigned_to__c, OW_due_date__c, LastModifiedBy.Name, LastModifiedDate, OW_process_variant__c, OW_requires_4eye__c, OW_stage__c, OW_status__c, OW_task_description__c, OW_triggered_by__c, OW_triggers__c FROM OW_task_information__c WHERE OW_record_type_developer_name__c =: t.RecordType.DeveloperName LIMIT 1];
        }
        //        if(!taskInfos.isEmpty()){
        return taskInfos[0];
        //      }
        //        else{
        //         throw new AuraHandledException('No task information found. Please set a record up for this record type.');
        //     }
    }
}
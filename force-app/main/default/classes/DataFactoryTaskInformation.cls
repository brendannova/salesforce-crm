/**
* This class generates task information records to assist in generating realistic but fake data in sandbox seeding and anonymisation.
* It should be used in the data factory and sandbox classes primarily and is not intended for any production use case. 
*/
public class DataFactoryTaskInformation {
    
    public OW_task_information__c generateTaskInformation(String taskType){
        if(String.isBlank(taskType)){
            taskType = 'RANDOM_TASK_TYPE_VALUE';
        }
        OW_task_information__c taskInformation = new OW_task_information__c(
        	OW_task_type__c = taskType,
            OW_record_type_developer_name__c = taskType,
            OW_task_description_google_doc_link__c = 'https://google.com',
            OW_status__c = 'Active',
            OW_team__c = 'Planners',
            OW_assigned_to__c = 'Queue',
            OW_due_date_offset__c = 0,
            OW_turnaround_time__c = 0,
            OW_priority__c = 'High',
            OW_process_variant__c = 'New customer',
            OW_stage__c = 'Discovery',
            OW_queue__c = 'OW_planners',
            OW_subject__c = 'test'
        );
        insert taskInformation;
        return taskInformation;
    }
}
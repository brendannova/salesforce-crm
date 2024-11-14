@istest
public class TaskInformationControllerTest {
    
    @istest
    private static void testFetchingTaskInformation() {
        
        String task_id = 'random_id'; 
        
        // Create and insert a task information record for the same record type specified in the line below        
        OW_task_information__c ti = new OW_task_information__c(
            OW_record_type_developer_name__c = 'record_type_name',
            OW_task_type__c = task_id,
            Name = 'Test task information ',
            OW_task_description__c = 'Test description'
        );
        insert ti;
        
        // Create and insert a task with the record type specified in the line below
        Task t = new Task(
            OW_task_information_identifier__c = ti.Id,
            Subject = 'Test subject'
        );
        insert t;
        
        // Run the class for the task created
        Test.startTest();
        OW_task_information__c taskInfo = TaskInformationController.getTaskInfo( t.Id );
        Test.stopTest();

        // Assert that the task information record returned by the class matches the one created above
        System.assertEquals(taskInfo.Id, ti.Id);
    }
    
    @istest
    private static void testFetchingTaskInformationLegacy() {
        
        // Create and insert a task with the record type specified in the line below
        String record_type_name = 'OW_task_ad_hoc'; 
        Task t = new Task(
            RecordTypeId = Schema.sObjectType.Task.getRecordTypeInfosByDeveloperName().get(record_type_name).getRecordTypeId(),
            Subject = 'Test subject'
        );
        insert t;
		
        // Create and insert a task information record for the same record type specified in the line below        
        OW_task_information__c ti = new OW_task_information__c(
            OW_record_type_developer_name__c = record_type_name,
            Name = 'Test task information ',
            OW_task_description__c = 'Test description'
        );
        insert ti;
        
        // Run the class for the task created
        Test.startTest();
        OW_task_information__c taskInfo = TaskInformationController.getTaskInfo( t.Id );
        Test.stopTest();

        // Assert that the task information record returned by the class matches the one created above
        System.assertEquals(taskInfo.Id, ti.Id);
    }
}
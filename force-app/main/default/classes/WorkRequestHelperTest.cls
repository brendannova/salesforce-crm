@isTest
public class WorkRequestHelperTest {
    
    @TestSetup
    static void makeData(){
        OW_task_information__c taskInfo = new OW_Task_Information__c();
        taskInfo.Name = 'Test';
        taskInfo.OW_record_type_developer_name__c = WorkRequestHelper.WORK_REQUEST_DEFAULT_TASK_INFORMATION_DEVELOPER_NAME; 
        taskInfo.OW_task_type__c = WorkRequestHelper.WORK_REQUEST_DEFAULT_TASK_INFORMATION_DEVELOPER_NAME;
        taskInfo.OW_status__c = taskEngine.TASK_TYPE_STATUS_ACTIVE;
        taskInfo.OW_subject__c = 'Test';
        taskInfo.OW_task_credit__c = 1;
        taskInfo.OW_due_date_offset__c = 1;
        taskInfo.OW_turnaround_time__c = 3;
        taskInfo.OW_priority__c = 'Medium';
        taskInfo.OW_process_variant__c = 'Protection advice';
        taskInfo.OW_stage__c = 'N/A';
        taskInfo.OW_team__c = 'Business operations';
        taskInfo.OW_assigned_to__c = TaskEngine.ASSIGNED_TO_SPECIFIC_USER;
        taskInfo.OW_specific_user__c = UserInfo.getUserId();

        insert taskInfo;
    }
    
    /**
     * @description Tests that the method handles null or empty lists gracefully without creating tasks.
     */
    @isTest
    static void testGenerateRequestsFromWorkRequestRecords_EmptyList() {
        // --- Arrange ---
        // No data is needed for this test.

        // --- Act ---
        Test.startTest();
        // Call with an empty list
        WorkRequestHelper.generateRequestsFromWorkRequestRecords(new List<WorkRequest__c>());
        // Call with a null list
        WorkRequestHelper.generateRequestsFromWorkRequestRecords(null);
        Test.stopTest();

        // --- Assert ---
        // Verify that no Task records were created
        List<Task> tasks = [SELECT Id FROM Task];
        System.assertEquals(0, tasks.size(), 'TaskEngine should not be called, and no tasks should be created.');
    }
    
    /**
     * @description Tests the successful creation of multiple Task records from a list of Work Request records.
     */
    @isTest
    static void testGenerateRequestsFromWorkRequestRecords_WithData() {
        // --- Arrange ---
        // Create a related Account to use for HouseholdId and WhatId
        List<Account> testHousehold = TestDataFactory.createHousehold(1, 0, 'test');
        
        // Create a list of test Work Request records to be processed
        List<WorkRequest__c> workRequests = new List<WorkRequest__c>();
        for(Integer i = 0; i < 3; i++) {
            workRequests.add(new WorkRequest__c(
                Subject__c = 'Test Work Request ' + (i + 1),
                TaskType__c = WorkRequestHelper.WORK_REQUEST_DEFAULT_TASK_INFORMATION_DEVELOPER_NAME,
                DueDate__c = Date.today().addDays(i),
                HouseholdId__c = testHousehold[0].Id,
                WhatId__c = testHousehold[0].Id,
                WhoId__c = null
            ));
        }

        // --- Act ---
        Test.startTest();
        insert workRequests;
        Test.stopTest();

        // --- Assert ---
        List<Task> createdTasks = [SELECT Id, Subject, ActivityDate, WhatId, WhoId, OW_task_information_name__c FROM Task];
        
        // Verify that the correct number of tasks were created
        System.assertEquals(3, createdTasks.size(), 'Should have created 3 Task records.');

        // Verify that the data was mapped correctly onto the new Task
        // We'll check the first task as a representative sample
        System.assertEquals(Date.today(), createdTasks[0].ActivityDate, 'Due Date should be mapped correctly.');
        System.assertEquals(testHousehold[0].Id, createdTasks[0].WhatId, 'WhatId should be mapped to the Account.');
        System.assertEquals('Test Work Request 1', createdTasks[0].Subject, 'Subject should be mapped correctly.');
    }
    
    /**
     * @description Tests that a null task type is replaced with the default developer name.
     */
    @isTest
    static void testGenerateRequestsFromWorkRequestRecords_WithDefaultTaskType() {
        // --- Arrange ---
        List<Account> testHousehold = TestDataFactory.createHousehold(1, 0, 'test');
        // Create a Work Request with a null task type
        WorkRequest__c workRequest = new WorkRequest__c(
            Subject__c = 'Test Work Request with Default Type',
            TaskType__c = null,
            DueDate__c = Date.today().addDays(7),
            HouseholdId__c = testHousehold[0].Id,
            WhatId__c = testHousehold[0].Id,
            WhoId__c = null
        );
        
        // --- Act ---
        Test.startTest();
        insert workRequest;
        Test.stopTest();

        // --- Assert ---
        // Find the created task
        List<Task> createdTasks = [SELECT Id, OW_task_information_name__c FROM Task];
        
        System.assertEquals(1, createdTasks.size(), 'Should have created one Task.');
        
        // Verify that the Task's Type field was set to the default constant
        System.assertEquals(
            WorkRequestHelper.WORK_REQUEST_DEFAULT_TASK_INFORMATION_DEVELOPER_NAME, 
            createdTasks[0].OW_task_information_name__c,
            'Task Type should be set to the default value when the source is null.'
        );
    }
}
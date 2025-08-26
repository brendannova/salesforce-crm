@isTest
private class TaskRequestHelperTest {

    @TestSetup
    static void makeData(){
        OW_task_information__c taskInfo = new OW_Task_Information__c();
        taskInfo.Name = 'Test';
        taskInfo.OW_record_type_developer_name__c = TaskRequestHelper.TASK_REQUEST_DEFAULT_TASK_INFORMATION_DEVELOPER_NAME; 
        taskInfo.OW_task_type__c = TaskRequestHelper.TASK_REQUEST_DEFAULT_TASK_INFORMATION_DEVELOPER_NAME;
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
     * @description Tests the successful creation of multiple Task records from a list of requests.
     */
    @isTest
    static void testGenerateRequests_CreatesTasksSuccessfully() {
        // --- Arrange ---
        // Create a related Account and Contact to use for WhatId and WhoId
        List<Account> testHousehold = TestDataFactory.createHousehold(1, 0, 'test');

        
        // Create a list of test records to be processed
        List<OW_task_request__c> testRequests = new List<OW_task_request__c>();
        for(Integer i = 0; i < 3; i++) {
            testRequests.add(new OW_task_request__c(
                OW_due_date_input__c = Date.today().addDays(i),
                OW_what_id__c = testHousehold[0].Id,
                OW_household_id__c = testHousehold[0].Id
            ));
        }


        Test.startTest();
        insert testRequests;
        Test.stopTest();

        List<Task> createdTasks = [SELECT Id, Type, ActivityDate, WhatId, WhoId FROM Task];
        
        // Verify that the correct number of tasks were created
        System.assertEquals(3, createdTasks.size(), 'Should have created 3 Task records.');

        // Verify that the data was mapped correctly onto the new Task
        // We'll check the first task as a representative sample
        System.assertEquals(Date.today(), createdTasks[0].ActivityDate, 'Due Date should be mapped correctly.');
        System.assertEquals(testHousehold[0].Id, createdTasks[0].WhatId, 'WhatId should be mapped to the Account.');
    }

    /**
     * @description Tests that a null task type is replaced with the default developer name.
     */
    @isTest
    static void testGenerateRequests_AppliesDefaultTaskType() {

        // --- Arrange ---
        List<Account> testHousehold = TestDataFactory.createHousehold(1, 0, 'test');
        // Create a request with a null task type
        OW_task_request__c testRequest = new OW_task_request__c(
            OW_due_date_input__c = Date.today().addDays(5),
            OW_what_id__c = testHousehold[0].Id,
            OW_household_id__c = testHousehold[0].Id
        );
        

        // --- Act ---
        Test.startTest();
        insert testRequest;
        Test.stopTest();

        // --- Assert ---
        // Find the created task
        List<Task> createdTasks = [SELECT Id, OW_task_information_name__c FROM Task];
        
        System.assertEquals(1, createdTasks.size(), 'Should have created one Task.');
        
        // Verify that the Task's Type field was set to the default constant
        System.assertEquals(
            TaskRequestHelper.TASK_REQUEST_DEFAULT_TASK_INFORMATION_DEVELOPER_NAME, 
            createdTasks[0].OW_task_information_name__c,
            'Task Type should be set to the default value when the source is null.'
        );
    }

    /**
     * @description Tests that the method handles null or empty lists gracefully without creating tasks.
     */
    @isTest
    static void testGenerateRequests_HandlesEmptyAndNullLists() {
        // --- Arrange ---
        // No data is needed for this test.

        // --- Act ---
        Test.startTest();
        // Call with an empty list
        TaskRequestHelper.generateRequestsFromTaskRequestRecords(new List<OW_task_request__c>());
        // Call with a null list
        TaskRequestHelper.generateRequestsFromTaskRequestRecords(null);
        Test.stopTest();

        // --- Assert ---
        // Verify that no Task records were created
        List<Task> tasks = [SELECT Id FROM Task];
        System.assertEquals(0, tasks.size(), 'TaskEngine should not be called, and no tasks should be created.');
    }
}
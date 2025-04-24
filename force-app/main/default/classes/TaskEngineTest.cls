@isTest
private class TaskEngineTest {

    static final string HOUSEHOLD_IDENTIFIER = 'testHousehold';
    static final string CASE_IDENTIFIER = 'testCase';
    static final string OPPORTUNITY_IDENTIFIER = 'testOpportuntiy';
    static final string QUEUE_IDENTIFIER = 'OperationsTeamA';
    static final string HOUSEHOLD_QUEUE_IDENTIFIER = 'OperationsTeamB';
    static final string USER_IDENTIFIER = 'testUser@testnova.com';
    static final string PARTNER_IDENTIFIER = 'testPartner@testnova.com';
    static final string CHOSEN_USER_IDENTIFIER = 'testChosenUser@testnova.com';
    static final string CASE_OWNER_IDENTIFIER = 'testCaseUser@testnova.com';
    static final string OPPORTUNITY_OWNER_IDENTIFIER = 'testOpportintyUser@testnova.com';
    static final string SUITIBILITY_PLANNER_IDENTIFIER = 'testSuitabilityUser@testnova.com';

    static final string TEAM_OPERATIONS = 'Operations';
    static final string TEAM_MORTGAGES = 'Mortgages';
    static final string TEAM_BUSINESS_OPERATIONS = 'Business operations';
    static final string TEAM_PARTNERS = 'Partners';

    public static User testUser = new User();
    public static User testPartner = new User();
    public static User testChosenUser = new User();
    public static User testCaseOwner = new User();
    public static User testOpportunityOwner = new User();
    public static User testSuitibilityPlanner = new User();

    public static Group testQueue = new Group();
    public static Group testHouseholdQueue = new Group();

    static List<String> assignmentTypeList = new List<String>{
        taskEngine.ASSIGNED_TO_CASE_OWNER,
        taskEngine.ASSIGNED_TO_CHOSEN_USER,
        taskEngine.ASSIGNED_TO_DEDICATED_TEAM,
        taskEngine.ASSIGNED_TO_HOUSEHOLD_TEAM,
        taskEngine.ASSIGNED_TO_OPPORTUNITY_OWNER,
        taskEngine.ASSIGNED_TO_PARTNER,
        taskEngine.ASSIGNED_TO_QUEUE,
        taskEngine.ASSIGNED_TO_SPECIFIC_USER,
        taskEngine.ASSIGNED_TO_SUITABILITY_PLANNER
    };

    @TestSetup
    static void makeData(){
       //List<sObject> ls5 = Test.loadData(OW_task_information__c.sObjectType, 'taskInformationRef');

        DataFactory df = new DataFactory();

        Id accountTestId = df.createHousehold(HOUSEHOLD_IDENTIFIER, 2, 1, 'Withdrawn', 'Full');
        Case testCase = df.createCase(CASE_IDENTIFIER, accountTestId);
        Opportunity testOpportunity = df.craeteOpportunity(accountTestId, OPPORTUNITY_IDENTIFIER);
        Advice__c testAdvice = df.createTopUpAdvice(accountTestId);

        List<OW_task_information__c> taskInfoList = new List<OW_task_information__c>();

        //Scope to insert in list to conserve DML statements
        testUser = df.createUser(USER_IDENTIFIER);
        testPartner = df.createUser(PARTNER_IDENTIFIER);
        testChosenUser = df.createUser(CHOSEN_USER_IDENTIFIER);
        testCaseOwner = df.createUser(CASE_OWNER_IDENTIFIER);
        testOpportunityOwner = df.createUser(OPPORTUNITY_OWNER_IDENTIFIER);
        testSuitibilityPlanner = df.createUser(SUITIBILITY_PLANNER_IDENTIFIER);

        //update partner as owner of household
        Account testHousehold = new Account(Id = accountTestId, OwnerId = testPartner.Id, OW_queue__c = HOUSEHOLD_QUEUE_IDENTIFIER);
        update testHousehold;

        testCase.OwnerId = testCaseOwner.Id;
        update testCase;

        testOpportunity.OwnerId = testOpportunityOwner.Id;
        update testOpportunity;

        testAdvice.Assigned_planner__c = testSuitibilityPlanner.Id;
        update testAdvice;

        testQueue = df.createQueue(QUEUE_IDENTIFIER);
        testHouseholdQueue = df.createQueue(HOUSEHOLD_QUEUE_IDENTIFIER);

        Integer i = 0;
        for(String assignmentType : assignmentTypeList){
            OW_task_information__c taskInfo = new OW_task_information__c();
            taskInfo.Name = 'task information ' + i;
            taskInfo.OW_task_type__c = 'task_information_' + i;
            taskInfo.OW_record_type_developer_name__c = 'task_information_' + i;
            taskInfo.OW_subject__c = assignmentType; //slightly hacky to reference in test to see if correct logic worked
            taskInfo.OW_status__c = taskEngine.TASK_TYPE_STATUS_ACTIVE;
            taskInfo.OW_task_credit__c = i;
            taskInfo.OW_due_date_offset__c = i;
            taskInfo.OW_turnaround_time__c = i + 2;
            taskInfo.OW_assigned_to__c = assignmentType;
            taskInfo.OW_priority__c = 'Medium';
            taskInfo.OW_process_variant__c = 'Protection advice';
            taskInfo.OW_stage__c = 'N/A';

            //have to deal with picklist dependancies
            if(new List<String>{TaskEngine.ASSIGNED_TO_CASE_OWNER, TaskEngine.ASSIGNED_TO_CHOSEN_USER, TaskEngine.ASSIGNED_TO_DEDICATED_TEAM, TaskEngine.ASSIGNED_TO_HOUSEHOLD_TEAM}.contains(assignmentType)){
                taskInfo.OW_team__c = TEAM_OPERATIONS;
            
            } else if(assignmentType == TaskEngine.ASSIGNED_TO_OPPORTUNITY_OWNER || assignmentType == TaskEngine.ASSIGNED_TO_SUITABILITY_PLANNER){
                taskInfo.OW_team__c = TEAM_MORTGAGES;

            } else if(assignmentType == taskEngine.ASSIGNED_TO_QUEUE){
                taskInfo.OW_queue__c = QUEUE_IDENTIFIER;
                taskInfo.OW_team__c = TEAM_OPERATIONS;

            } else if(assignmentType == taskEngine.ASSIGNED_TO_SPECIFIC_USER){
                taskInfo.OW_specific_user__c = testUser.Id;
                taskInfo.OW_team__c = TEAM_BUSINESS_OPERATIONS;
            
            } else if(assignmentType == TaskEngine.ASSIGNED_TO_PARTNER){
                taskInfo.OW_Team__c = TEAM_PARTNERS;
            }

            taskInfoList.add(taskInfo);
            i++;
        }

        insert taskInfoList;

    }

    @isTest
    static void testTaskEngine(){

        //query household to use as test data
        User chosenUser = [SELECT Id FROM User WHERE Username = :CHOSEN_USER_IDENTIFIER LIMIT 1];
        User testUser = [SELECT Id FROM User WHERE Username = :USER_IDENTIFIER LIMIT 1];
        User testSuitibilityPlanner = [SELECT Id FROM User WHERE Username = :SUITIBILITY_PLANNER_IDENTIFIER LIMIT 1];

        Account accountTest = [SELECT Id, Name, OwnerId FROM Account WHERE OW_admin_notes__c = :HOUSEHOLD_IDENTIFIER LIMIT 1];
        Case caseTest = [SELECT Id, ownerId FROM Case WHERE Subject = :CASE_IDENTIFIER LIMIT 1];
        Opportunity opportunityTest = [SELECT Id, ownerId FROM Opportunity WHERE AccountId = :accountTest.Id AND PlatformId__c = :OPPORTUNITY_IDENTIFIER LIMIT 1];
        Advice__c adviceTest = [SELECT Id, Assigned_planner__c FROM Advice__c WHERE Assigned_planner__c = :testSuitibilityPlanner.Id LIMIT 1];
        
        Group testQueue = [SELECT Id FROM Group WHERE DeveloperName = :QUEUE_IDENTIFIER LIMIT 1];
        Group testHouseholdQueue = [SELECT Id FROM Group WHERE DeveloperName = :HOUSEHOLD_QUEUE_IDENTIFIER LIMIT 1];

        List<OW_task_information__c> taskInformationList = [SELECT Id, OW_assigned_to__c, OW_task_type__c, OW_task_credit__c, OW_subject__c, OW_due_date_offset__c, OW_turnaround_time__c FROM OW_task_information__c];

        Map<String, OW_task_information__c> assignmentTypeTaskInfoMap = new Map<String, OW_task_information__c>();

        //find an example of one task for each assingment type
        for(String assignmentType : assignmentTypeList){
            for(OW_task_information__c taskInfo : taskInformationList){
                if(taskInfo.OW_assigned_to__c == assignmentType){
                    assignmentTypeTaskInfoMap.put(assignmentType, taskInfo);
                    break;
                }
            }
        }

        List<TaskEngineRequest> taskRequests = new List<TaskEngineRequest>();
        for(OW_task_information__c taskInfo : assignmentTypeTaskInfoMap.values()){
            TaskEngineRequest taskEngineRequest = new TaskEngineRequest();
            taskEngineRequest.taskType = taskInfo.OW_task_type__c;
            taskEngineRequest.householdId = accountTest.Id;
            taskEngineRequest.whatId = accountTest.Id;

            if(taskInfo.OW_assigned_to__c == TaskEngine.ASSIGNED_TO_CASE_OWNER){
                taskEngineRequest.whatId = caseTest.Id;
            }

            if(taskInfo.OW_assigned_to__c == TaskEngine.ASSIGNED_TO_OPPORTUNITY_OWNER){
                taskEngineRequest.whatId = opportunityTest.Id;
            }

            if(taskInfo.OW_assigned_to__c == TaskEngine.ASSIGNED_TO_CHOSEN_USER){
                taskEngineRequest.chosenUser = chosenUser.Id;   
            }

            if(taskInfo.OW_assigned_to__c == TaskEngine.ASSIGNED_TO_CASE_OWNER){
                taskEngineRequest.whatId = caseTest.Id;
            }

            if(taskInfo.OW_assigned_to__c == TaskEngine.ASSIGNED_TO_OPPORTUNITY_OWNER){
                taskEngineRequest.whatId = opportunityTest.Id;
            }

            if(taskInfo.OW_assigned_to__c == TaskEngine.ASSIGNED_TO_SUITABILITY_PLANNER){
                taskEngineRequest.whatId = adviceTest.Id;
            }

            taskRequests.add(taskEngineRequest);
            
        }

        //teskInvokable method too
        FlowUtilityTaskCreateList.FlowInputs taskRequestFlowInput = new FlowUtilityTaskCreateList.FlowInputs();
        taskRequestFlowInput.taskRequests = taskRequests;

        List<FlowUtilityTaskCreateList.FlowInputs> taskRequestFlowInputList = new List<FlowUtilityTaskCreateList.FlowInputs>();
        taskRequestFlowInputList.add(taskRequestFlowInput);

        //test method directly and via invokable method together as setup for test taks a long time
        Test.startTest();
        TaskEngine.generateTasks(taskRequests);
        List<FlowUtilityTaskCreateList.FlowOutputs> flowOutputs = FlowUtilityTaskCreateList.invocableGenerateTasks(taskRequestFlowInputList);
        Test.stopTest();

        for(FlowUtilityTaskCreateList.FlowOutputs flowOutput : flowOutputs){
            Assert.isTrue(flowOutput.isSuccess, 'Invokable apex task creation failure');
        }

        List<Task> generatedTaskList = [SELECT Id, Subject, OW_credit__c, ActivityDate, OW_target_start_date__c, OwnerId, WhatId FROM Task];

        Map<String, OW_task_information__c> taskAssignmentToInfoMap = new Map<String, OW_task_information__c>();

        for(OW_task_information__c t : taskInformationList){
            taskAssignmentToInfoMap.put(t.OW_assigned_to__c, t);
        }

        Assert.isTrue(generatedTaskList.size() > 0, 'No tasks were generated');
        Assert.areEqual(taskRequests.size() * 2, generatedTaskList.size(), 'An incorrect number of tasks have been generated');

        for(Task task : generatedTaskList){
            OW_task_information__c taskInfo = taskAssignmentToInfoMap.get(task.Subject);
            
            Assert.areEqual(task.OW_credit__c, taskInfo.OW_task_credit__c, 'Task credit not properly assinged');
            Assert.areEqual(task.Subject, taskInfo.OW_subject__c, 'Task subject not properly assinged');
             
            Date dueDate = Utility.getOffsetBusinessDate(Date.today(), (integer) taskInfo.OW_due_date_offset__c);
            Date startDate = Utility.getOffsetBusinessDate(dueDate,  (integer) -taskInfo.OW_turnaround_time__c);

            Assert.areEqual(dueDate, task.ActivityDate, 'Task due date not properly calculated');
            Assert.areEqual(startDate, task.OW_target_start_date__c, 'Task start date not properly calculated');

            if (task.WhatId != null && task.WhatId.getSObjectType() == Opportunity.sObjectType) {
                //assert opp user
                Assert.areEqual(opportunityTest.OwnerId, task.OwnerId, 'Task Owner is not the same as the Opportunity Owner');
            
            } else if (task.WhatId != null && task.WhatId.getSObjectType() == Case.sObjectType) {
                //assert opp user
                Assert.areEqual(caseTest.OwnerId, task.OwnerId, 'Task Owner is not the same as the Case Owner');
            
            } else if(taskInfo.OW_assigned_to__c == TaskEngine.ASSIGNED_TO_QUEUE){
                //assert queue user
                Assert.areEqual(testQueue.Id, task.OwnerId, 'Task Owner is not the same as the Queue Id');

            } else if(taskInfo.OW_assigned_to__c == TaskEngine.ASSIGNED_TO_HOUSEHOLD_TEAM){
                //assert household queue
                Assert.areEqual(testHouseholdQueue.Id, task.OwnerId, 'Task Owner is not the same as the Houshold Queue Id');
            
            } else if(taskInfo.OW_assigned_to__c == TaskEngine.ASSIGNED_TO_PARTNER){
                //assert partner user
                Assert.areEqual(accountTest.OwnerId, task.OwnerId, 'Task Owner is not the same as the Partner User Id');
            
            } else if(taskInfo.OW_assigned_to__c == taskEngine.ASSIGNED_TO_SUITABILITY_PLANNER){
                //assert suitability planner user
                Assert.areEqual(testSuitibilityPlanner.Id, task.OwnerId, 'Task Owner is not the same as the Suitability Planner Id');
            
            }
        }

    }
}
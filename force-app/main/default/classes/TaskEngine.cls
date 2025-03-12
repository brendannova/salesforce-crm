public with sharing class TaskEngine {
    
    final public static String ASSIGNED_TO_CASE_OWNER =                         'Case owner';
    final public static String ASSIGNED_TO_CHOSEN_USER =                        'Chosen user';
    final public static String ASSIGNED_TO_DEDICATED_TEAM =                     'Dedicated specialist/household team';
    final public static String ASSIGNED_TO_HOUSEHOLD_TEAM =                     'Household team';
    final public static String ASSIGNED_TO_OPPORTUNITY_OWNER =                  'Opportunity owner';
    final public static String ASSIGNED_TO_PARTNER =                            'Partner';
    final public static String ASSIGNED_TO_QUEUE =                              'Queue';
    final public static String ASSIGNED_TO_SPECIFIC_USER =                      'Specific user';
    final public static String ASSIGNED_TO_SUITABILITY_PLANNER =                'Suitability planner';

    final public static String MODE_INSERT =                                    'Create';
    final public static String MODE_UPDATE =                                    'Shift';

    final public static String TASK_STATUS_NOT_STARTED =                        'Not Started';
    final public static String TASK_RECORDTYPE_NAME_CLIENT_TASK_AUTOMATED =     'OW_task';
    final public static String TASK_RECORDTYPE_ID_CLIENT_TASK_AUTOMATED =       Utility.getRecordTypeId('Task', TASK_RECORDTYPE_NAME_CLIENT_TASK_AUTOMATED);
    final public static String TASK_ORCHESTRATION_TASK_STATUS_INCOMPLETE =      'Incomplete';
    final public static String TASK_ORCHESTRATION_TASK_STATUS_BLANK =           '';
    final public static String TASK_TYPE_STATUS_ACTIVE =                        'Active';

    final static String TASKINFO_ORCHESTRATION_CONTROLLED_YES =                 'Yes';

    final static String QUEUE_NAME_PLANNERS =                                   'OW_planners';
    

    
    public static List<taskError> taskErrors = new List<taskError>();
    public static List<Task> tasksToUpsert = new List<Task>();

    public class taskError{
        public String message;
        public taskEngineRequest taskRequest = new taskEngineRequest();
        
        public taskError(taskEngineRequest taskRequest, String message){
            this.taskRequest = taskRequest;
            this.message = message;
        }
    }
    
    public void newError(taskEngineRequest taskRequest, String message){
        taskErrors.add(new taskError(taskRequest, message));
    }
    
    public class taskEngineRequest{
       
        @InvocableVariable (label = 'Chosen User' 
                            description = 'Specify a user to assing the task to' 
                            required = false) public Id chosenUser;

        @InvocableVariable (label = 'Due Date' 
                            description = 'Overwrite default offset and specify a due date' 
                            required = false) public date dueDateInput;

        @InvocableVariable (label = 'Household Id' 
                            description = 'Id of related Household record' 
                            required = true) public Id householdId;

        @InvocableVariable (label = 'Orchestration Instance Id'
                            description = 'Id instance of orchestration this task is part of'
                            required = false) public Id orchestrationInstanceId;

        @InvocableVariable (label = 'Original Task Id'
                            description = 'Id of Original Task record'
                            required = false) public Id originalTask;

        @InvocableVariable (label = 'Related Advice Record Id'
                            description = 'Id of related Advice record'
                            required = false) public Id relatedAdviceId;

        @InvocableVariable (label = 'Related AML/KYC Id'
                            description = 'Id of related Anti Money Laundering / Know Your Client record'
                            required = false) public Id relatedAmlKycId;

        @InvocableVariable (label = 'Related Annaul Review Id'
                            description = 'Id of related Annual Review record'
                            required = false) public Id relatedAnnualReview;
                            
        @InvocableVariable (label = 'Related Fulfilment Id'
                            description = 'Id of related Fulfilment record'
                            required = false) public Id relatedFulfilment;

        @InvocableVariable (label = 'Related Information Request Id'
                            description = 'Id of related Information Request record'
                            required = false) public Id relatedInformationRequest;

        @InvocableVariable (label = 'Related LoA Id'
                            description = 'Id of related Letter of Authority record'
                            required = false) public Id relatedLoa;

        @InvocableVariable (label = 'Related Mortgage Application Id'
                            description = 'Id of related Mortgage Application record'
                            required = false) public Id relatedMortgageApplication;

        @InvocableVariable (label = 'Related Opportunity Id'
                            description = 'Id of related Opportunity record'
                            required = false) public Id relatedOpportunity;

        @InvocableVariable (label = 'Related Provider Id'
                            description = 'Id of related Provider record'
                            required = false) public Id relatedProvider;

        @InvocableVariable (label = 'Task Subject'
                            description = 'Overwrite default task subject'
                            required = false) public String subject;

        @InvocableVariable (label = 'Target Start Date'
                            description = 'Overwrite default target start date'
                            required = false) public Date targetStartDateInput;

        @InvocableVariable (label = 'Task Id'
                            description = 'Id of the Task record'
                            required = false) public Id taskId;

        @InvocableVariable (label = 'Task Type'
                            description = 'Type of the task (sets default values from Task Information records)'
                            required = true) public String taskType;

        @InvocableVariable (label = 'What Id'
                            description = 'Id of the related object (WhatId)'
                            required = true) public Id whatId;

        @InvocableVariable (label = 'Who Id'
                            description = 'Id of the related contact (WhoId)'
                            required = false) public Id whoId;
    }

    @InvocableMethod(label='Generate Tasks' description='Generates tasks based on provided task requests.' category='Flow Utility' iconName='slds:standard:task')
    public static void invocableGenerateTasks(List<taskEngineRequest> taskRequests){
        TaskEngine engine = new TaskEngine();
        engine.generateTasks(taskRequests);
    }
    
    
    public void generateTasks(List<taskEngineRequest> taskRequests){
        //Validate universal inputs
        taskRequests = validateTaskEngineRequests(taskRequests);

        //Collate task types to query
        Set<String> taskTypes = new Set<String>();
        for(taskEngineRequest t : taskRequests){
            if(!taskTypes.contains(t.taskType)){
                taskTypes.add(t.taskType);
            }
        }
         
        //Get task information record and store in a map against Task_Type__c
        Map<String, OW_task_information__c> taskInfoMap = new Map<String, OW_task_information__c>();

        for(OW_task_information__c taskInfo : [SELECT Id, OW_subject__c, OW_priority__c, OW_task_credit__c, OW_process_variant__c, OW_stage__c, OW_task_type__c, OW_due_date_offset__c, OW_specific_user__c, OW_queue__c, OW_assigned_to__c, Role__c, OrchestrationControlled__c FROM OW_task_information__c WHERE OW_task_type__c IN :taskTypes AND OW_status__c = :TASK_TYPE_STATUS_ACTIVE]){
            taskInfoMap.put(taskInfo.OW_task_type__c, taskInfo);
        }

        //Check that each valid taskRequest has a taskType that is in taskInfoMap keyset
        taskRequests = validateTaskEngineType(taskRequests, taskInfoMap);

        //Gather required info from lookups. Assume if field populated it will be used.
        Set<Id> householdIds = new Set<Id>();
        Map<Id, Account> householdMap = new Map<Id, Account>();
        List<String> ownerTypesRequiringHouseholdInfo = new List<String>{ASSIGNED_TO_PARTNER, ASSIGNED_TO_DEDICATED_TEAM, ASSIGNED_TO_HOUSEHOLD_TEAM}; 
        
        //also need to capture if not these but the dedicated specalist is populated
        for(taskEngineRequest t : taskRequests){
            //not possible to know ahead of time if dedicated specialist will be populated or not. Could do the task assignment logic to see if needed to request and then go trough again but double effort.
            if(!householdIds.contains(t.householdId)){
                householdIds.add(t.householdId);
            }
        }

        if(!householdIds.isEmpty()){
            householdMap = new Map<Id, Account>([SELECT Id, OwnerId, OW_dedicated_specialist__c, OW_queue__c FROM Account WHERE Id IN :householdIds]);
        }

        //Queue
        List<String> queueDeveloperNames = new List<String>();
        Map<String, Id> queueNameMap = new Map<String, Id>();

        queueDeveloperNames.add(QUEUE_NAME_PLANNERS);

        for(taskEngineRequest t : taskRequests){
            //queue specified on taskInfo object
            String queue = taskInfoMap.get(t.taskType).OW_queue__c;
            if(queue != null && !queueDeveloperNames.contains(queue)){
                queueDeveloperNames.add(queue);
            }

            //queue specified on household
            queue = householdMap.get(t.householdId).OW_queue__c;
            if(queue != null && !queueDeveloperNames.contains(queue)){
                queueDeveloperNames.add(queue);
            }
        }
        if(!queueDeveloperNames.isEmpty()){
            for(Group g : [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN :queueDeveloperNames]){
                queueNameMap.put(g.DeveloperName, g.Id);
            }
        }

        //Advice - Assigned Planner
        List<Id> adviceIds = new List<Id>();
        Map<Id, Advice__c> adviceMap = new Map<Id, Advice__c>();

        for(taskEngineRequest t : taskRequests){
            OW_task_information__c taskInfo = taskInfoMap.get(t.taskType);
            if(taskInfo.OW_assigned_to__c == ASSIGNED_TO_SUITABILITY_PLANNER){
                adviceIds.add(t.whatId);
            }
        }
        if(!adviceIds.isEmpty()){
            adviceMap = new Map<Id, Advice__c>([SELECT Id, Assigned_planner__c FROM Advice__c WHERE Id IN :adviceIds]);
        }

        //Case - Case Owner
        List<Id> caseIds = new List<Id>();
        Map<Id, Case> caseMap = new Map<Id, Case>();

        for(taskEngineRequest t : taskRequests){
            OW_task_information__c taskInfo = taskInfoMap.get(t.taskType);
            if(taskInfo.OW_assigned_to__c == ASSIGNED_TO_CASE_OWNER){
                caseIds.add(t.whatId);
            }
        }
        if(!caseIds.isEmpty()){
            caseMap = new Map<Id, case>([SELECT Id, OwnerId FROM Case WHERE Id IN :caseIds]);
        }

        //Opporutnity - Opporutntiy Owner
        List<Id> opportunityIds = new List<Id>();
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();

        for(taskEngineRequest t : taskRequests){
            OW_task_information__c taskInfo = taskInfoMap.get(t.taskType);
            if(taskInfo.OW_assigned_to__c == ASSIGNED_TO_OPPORTUNITY_OWNER){
                opportunityIds.add(t.whatId);
            }
        }
        if(!opportunityIds.isEmpty()){
            opportunityMap = new Map<Id, Opportunity>([SELECT Id, OwnerId FROM Opportunity WHERE Id IN :opportunityIds]);
        }

        //Assign task variables from task information
        for(taskEngineRequest t : taskRequests){
            Task tempTask = new Task();
            OW_task_information__c taskInfo = taskInfoMap.get(t.taskType);

            if(t.subject != null){
                tempTask.Subject = t.subject;
            } else {
                tempTask.Subject = taskInfo.OW_subject__c;
            }

            if(t.dueDateInput != null){
                tempTask.ActivityDate = t.dueDateInput;
            } else {
                tempTask.ActivityDate = Utility.getOffsetBusinessDate(System.today(), (integer) taskInfo.OW_due_date_offset__c);
            }

            if(t.targetStartDateInput != null){
                tempTask.OW_target_start_date__c = t.targetStartDateInput;
            } else {
                tempTask.OW_target_start_date__c = Utility.getOffsetBusinessDate(tempTask.ActivityDate, (integer) -taskInfo.OW_turnaround_time__c);
            }

            tempTask.Type = taskInfo.OW_subject__c;
            tempTask.Status = TASK_STATUS_NOT_STARTED;
            tempTask.Priority = taskInfo.OW_priority__c;
            tempTask.whatId = t.whatId;
            tempTask.whoId = t.whoId;
            tempTask.FinServ__Household__c = t.householdId;
            tempTask.OW_task_information_identifier__c = taskInfo.Id;
            tempTask.OW_credit__c = taskInfo.OW_task_credit__c;
            tempTask.RecordTypeId = TASK_RECORDTYPE_ID_CLIENT_TASK_AUTOMATED;
            tempTask.OW_process__c = taskInfo.OW_process_variant__c;
            tempTask.OW_stage__c = taskInfo.OW_stage__c;
            tempTask.OW_task_information_name__c = taskInfo.OW_task_type__c;
            tempTask.Related_Advice__c = t.relatedAdviceId;
            tempTask.Related_AML_KYC_Check__c = t.relatedAmlKycId;
            tempTask.Related_Annual_Review__c = t.relatedAnnualReview;
            tempTask.Related_LOA__c = t.relatedLoa;
            tempTask.Related_Opportunity__c = t.relatedOpportunity;
            tempTask.Related_Provider__c = t.relatedProvider;
            tempTask.OW_mortgage_application__c = t.relatedMortgageApplication;
            tempTask.Role__c = taskInfo.Role__c;
            tempTask.OrchestrationInstanceID__c = t.orchestrationInstanceId;
            tempTask.RelatedFulfilment__c = t.relatedFulfilment;
            tempTask.OrchestrationTaskStatus__c = taskInfo.OrchestrationControlled__c == TASKINFO_ORCHESTRATION_CONTROLLED_YES ? TASK_ORCHESTRATION_TASK_STATUS_INCOMPLETE : TASK_ORCHESTRATION_TASK_STATUS_BLANK;
            tempTask.RelatedInformationRequest__c = t.relatedInformationRequest;

            //perform different assignment logic based on taskType OW_assigned_to__c value
            //Would use a switch statment but it does not support global variables 

            String assignedToType = taskinfo.OW_assigned_to__c;

            if(assignedToType == ASSIGNED_TO_QUEUE){
                tempTask.OwnerId = queueNameMap.get(taskInfo.OW_queue__c);

            } else if(assignedToType == ASSIGNED_TO_PARTNER){
                tempTask.OwnerId = householdMap.get(t.householdId).OwnerId;

            } else if (assignedToType == ASSIGNED_TO_SPECIFIC_USER){
                tempTask.OwnerId = taskInfo.OW_specific_user__c;

            } else if(assignedToType == ASSIGNED_TO_CHOSEN_USER){
                if(t.chosenUser!= null){
                    tempTask.OwnerId = t.chosenUser;
                }else{
                    newError(t, 'Chosen User Ownership selected, but no user specified');
                    break;
                }

            } else if(assignedToType == ASSIGNED_TO_SUITABILITY_PLANNER){
                Id planner = adviceMap.get(t.relatedAdviceId).Assigned_planner__c;
                if(planner != null){
                    tempTask.OwnerId = planner;
                }else{
                    tempTask.OwnerId = queueNameMap.get(QUEUE_NAME_PLANNERS);
                }

            } else if(assignedToType == ASSIGNED_TO_CASE_OWNER){
                tempTask.OwnerId = caseMap.get(t.whatId).OwnerId;

            } else if(assignedToType == ASSIGNED_TO_OPPORTUNITY_OWNER){
                tempTask.OwnerId = opportunityMap.get(t.whatId).OwnerId;

            } else if(assignedToType == ASSIGNED_TO_HOUSEHOLD_TEAM){
                tempTask.OwnerId = queueNameMap.get(householdMap.get(t.householdId).OW_queue__c);

            } else if(assignedToType == ASSIGNED_TO_DEDICATED_TEAM){
                Id specialist = householdMap.get(t.householdId).OW_dedicated_specialist__c;
                if(specialist != null){
                    tempTask.OwnerId = specialist;
                }else{
                    tempTask.OwnerId = queueNameMap.get(householdMap.get(t.householdId).OW_queue__c);
                }
            
            } else {
                Id specialist = householdMap.get(t.householdId).OW_dedicated_specialist__c;
                if(specialist != null){
                    tempTask.OwnerId = specialist;
                }
            }  

            tasksToUpsert.add(tempTask);
        }
        
        databaseUpsert(tasksToUpsert, true);
        handleErrors();
    }

    public void databaseUpsert(List<SObject> recordsToUpsert, Boolean allOrNone){
        Database.UpsertResult[] upsertResults = Database.upsert(recordsToUpsert, allOrNone);
        for(Database.UpsertResult upsertResult : upsertResults){
            if(!upsertResult.isSuccess()){
                for(Database.Error err : upsertResult.getErrors()){
                    newError(new taskEngineRequest(), err.getMessage());
                }
            }
        }
    }
    
    public List<taskEngineRequest> validateTaskEngineRequests(List<taskEngineRequest> taskRequests){
        
        Boolean valid;
        List<taskEngineRequest> validTaskEngineRequests = new List<taskEngineRequest>();
        
        
        for(taskEngineRequest t : taskRequests){
            valid = True;
            if(t.taskType == null){
                valid = False;
                newError(t, 'Task Type Missing');
            }

            if(valid){
                validTaskEngineRequests.add(t);
            }
            
        }
        
        return validTaskEngineRequests;
    }

    public List<taskEngineRequest> validateTaskEngineType(List<taskEngineRequest> taskRequests,  Map<String, OW_task_information__c> taskInfoMap){
        List<taskEngineRequest> validTaskEngineRequests = new List<taskEngineRequest>();
        for(taskEngineRequest t : taskRequests){
            if(!taskInfoMap.containsKey(t.taskType)){
                newError(t, 'Task Type Not Found');
            }else{
                validTaskEngineRequests.add(t);
            }
        }

        return validTaskEngineRequests;
    }

    public void handleErrors(){
        //Future Todo - Pass errors to logging system
    }

}
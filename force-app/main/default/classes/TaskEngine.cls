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

    final public static String TASK_STATUS_NOT_STARTED =                        'Not Started';
    final public static String TASK_RECORD_TYPE_NAME_CLIENT_TASK_AUTOMATED =    'OW_task';
    final public static String TASK_RECORD_TYPE_ID_CLIENT_TASK_AUTOMATED =       Utility.getRecordTypeId('Task', TASK_RECORD_TYPE_NAME_CLIENT_TASK_AUTOMATED);
    final public static String TASK_ORCHESTRATION_TASK_STATUS_INCOMPLETE =      'Incomplete';
    final public static String TASK_ORCHESTRATION_TASK_STATUS_BLANK =           '';
    final public static String TASK_TYPE_STATUS_ACTIVE =                        'Active';

    final public static String TASKINFO_ORCHESTRATION_CONTROLLED_YES =          'Yes';

    final public static String QUEUE_NAME_PLANNERS =                            'OW_planners';
    
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

        @InvocableVariable (label = 'Household ID' 
                            description = 'ID of related Household record' 
                            required = true) public Id householdId;

        @InvocableVariable (label = 'Original Task ID'
                            description = 'Id of Original Task record'
                            required = false) public Id originalTask;

        @InvocableVariable (label = 'Related Advice Record ID'
                            description = 'Id of related Advice record'
                            required = false) public Id relatedAdviceId;

        @InvocableVariable (label = 'Related AML/KYC ID'
                            description = 'Id of related Anti Money Laundering / Know Your Client record'
                            required = false) public Id relatedAmlKycId;

        @InvocableVariable (label = 'Related Annual Review ID'
                            description = 'ID of related Annual Review record'
                            required = false) public Id relatedAnnualReview;
                            
        @InvocableVariable (label = 'Related Fulfilment ID'
                            description = 'ID of related Fulfilment record'
                            required = false) public Id relatedFulfilment;

        @InvocableVariable (label = 'Related Information Request ID'
                            description = 'ID of related Information Request record'
                            required = false) public Id relatedInformationRequest;

        @InvocableVariable (label = 'Related LoA ID'
                            description = 'ID of related Letter of Authority record'
                            required = false) public Id relatedLoa;

        @InvocableVariable (label = 'Related Mortgage Application ID'
                            description = 'ID of related Mortgage Application record'
                            required = false) public Id relatedMortgageApplication;

        @InvocableVariable (label = 'Related Opportunity ID'
                            description = 'ID of related Opportunity record'
                            required = false) public Id relatedOpportunity;

        @InvocableVariable (label = 'Related Provider ID'
                            description = 'ID of related Provider record'
                            required = false) public Id relatedProvider;

        @InvocableVariable (label = 'Task Subject'
                            description = 'Overwrite default task subject'
                            required = false) public String subject;

        @InvocableVariable (label = 'Target Start Date'
                            description = 'Overwrite default target start date'
                            required = false) public Date targetStartDateInput;

        @InvocableVariable (label = 'Task ID'
                            description = 'ID of the Task record'
                            required = false) public Id taskId;

        @InvocableVariable (label = 'Task Type'
                            description = 'Type of the task (sets default values from Task Information records)'
                            required = true) public String taskType;

        @InvocableVariable (label = 'What ID'
                            description = 'ID of the related object'
                            required = true) public Id whatId;

        @InvocableVariable (label = 'Who ID'
                            description = 'ID of the related contact'
                            required = false) public Id whoId;
    }

    @InvocableMethod(label='Generate Task' description='Generate a task based on provided task request.' category='Flow utilities' iconName='slds:standard:task')
    public static void invocableGenerateTasks(List<taskEngineRequest> taskRequests){
        TaskEngine engine = new TaskEngine();
        engine.generateTasks(taskRequests);
    }
    
    
    public void generateTasks(List<taskEngineRequest> taskEngineRequests){
        //Validate universal inputs
        taskEngineRequests = validateTaskEngineRequests(taskEngineRequests);

        //Collate task types to query
        Set<String> taskTypes = new Set<String>();
        for(taskEngineRequest taskEngineRequest : taskEngineRequests){
            if(!taskTypes.contains(taskEngineRequest.taskType)){
                taskTypes.add(taskEngineRequest.taskType);
            }
        }
         
        //Get task information record and store in a map against Task_Type__c
        Map<String, OW_task_information__c> taskInfoMap = new Map<String, OW_task_information__c>();

        for(OW_task_information__c taskInfo : [SELECT Id, OW_subject__c, OW_priority__c, OW_task_credit__c, OW_process_variant__c, OW_stage__c, OW_task_type__c, OW_due_date_offset__c, OW_specific_user__c, OW_queue__c, OW_assigned_to__c, Role__c, OrchestrationControlled__c FROM OW_task_information__c WHERE OW_task_type__c IN :taskTypes AND OW_status__c = :TASK_TYPE_STATUS_ACTIVE]){
            taskInfoMap.put(taskInfo.OW_task_type__c, taskInfo);
        }

        //Check that each valid taskRequest has a taskType that is in taskInfoMap keyset
        taskEngineRequests = validateTaskEngineType(taskEngineRequests, taskInfoMap);

        //Gather required info from lookups. Assume if field populated it will be used.
        Set<Id> householdIds = new Set<Id>();
        Map<Id, Account> householdMap = new Map<Id, Account>();

        //Queue
        List<String> queueDeveloperNames = new List<String>();
        Map<String, Id> queueNameMap = new Map<String, Id>();

        //Advice - Assigned Planner
        List<Id> adviceIds = new List<Id>();
        Map<Id, Advice__c> adviceMap = new Map<Id, Advice__c>();

        //Case - Case Owner
        List<Id> caseIds = new List<Id>();
        Map<Id, Case> caseMap = new Map<Id, Case>();

        //Opporutnity - Opporutntiy Owner
        List<Id> opportunityIds = new List<Id>();
        Map<Id, Opportunity> opportunityMap = new Map<Id, Opportunity>();
        
        //also need to capture if not these but the dedicated specalist is populated
        for(taskEngineRequest taskEngineRequest : taskEngineRequests){
            
            OW_task_information__c taskInfo = taskInfoMap.get(taskEngineRequest.taskType);
            
            //not possible to know ahead of time if dedicated specialist will be populated or not. Could do the task assignment logic to see if needed to request and then go trough again but double effort.
            if(!householdIds.contains(taskEngineRequest.householdId)){
                householdIds.add(taskEngineRequest.householdId);
            }

            //queue specified on taskInfo object
            String queue = taskInfoMap.get(taskEngineRequest.taskType).OW_queue__c;
            if(queue != null && !queueDeveloperNames.contains(queue)){
                queueDeveloperNames.add(queue);
            }

            //queue specified on household
            queue = householdMap.get(taskEngineRequest.householdId).OW_queue__c;
            if(queue != null && !queueDeveloperNames.contains(queue)){
                queueDeveloperNames.add(queue);
            }

            if(taskInfo.OW_assigned_to__c == ASSIGNED_TO_SUITABILITY_PLANNER){
                adviceIds.add(taskEngineRequest.whatId);

            } else if(taskInfo.OW_assigned_to__c == ASSIGNED_TO_CASE_OWNER){
                caseIds.add(taskEngineRequest.whatId);

            } else if(taskInfo.OW_assigned_to__c == ASSIGNED_TO_OPPORTUNITY_OWNER){
                opportunityIds.add(taskEngineRequest.whatId);
            }
        }

        if(!householdIds.isEmpty()){
            householdMap = new Map<Id, Account>([SELECT Id, OwnerId, OW_dedicated_specialist__c, OW_queue__c FROM Account WHERE Id IN :householdIds]);
        }

        if(!queueDeveloperNames.isEmpty()){
            //'group' is a reserved identifier and cannot be used as a variable name
            for(Group queue : [SELECT Id, DeveloperName FROM Group WHERE Type = 'Queue' AND DeveloperName IN :queueDeveloperNames]){
                queueNameMap.put(queue.DeveloperName, queue.Id);
            }
        }

        if(!adviceIds.isEmpty()){
            adviceMap = new Map<Id, Advice__c>([SELECT Id, Assigned_planner__c FROM Advice__c WHERE Id IN :adviceIds]);
        }

        if(!caseIds.isEmpty()){
            caseMap = new Map<Id, case>([SELECT Id, OwnerId FROM Case WHERE Id IN :caseIds]);
        }

        if(!opportunityIds.isEmpty()){
            opportunityMap = new Map<Id, Opportunity>([SELECT Id, OwnerId FROM Opportunity WHERE Id IN :opportunityIds]);
        }

        //Assign task variables from task information
        for(taskEngineRequest taskEngineRequest : taskEngineRequests){
            Task tempTask = new Task();
            OW_task_information__c taskInfo = taskInfoMap.get(taskEngineRequest.taskType);

            if(taskEngineRequest.subject != null){
                tempTask.Subject = taskEngineRequest.subject;
            } else {
                tempTask.Subject = taskInfo.OW_subject__c;
            }

            if(taskEngineRequest.dueDateInput != null){
                tempTask.ActivityDate = taskEngineRequest.dueDateInput;
            } else {
                tempTask.ActivityDate = Utility.getOffsetBusinessDate(System.today(), (integer) taskInfo.OW_due_date_offset__c);
            }

            if(taskEngineRequest.targetStartDateInput != null){
                tempTask.OW_target_start_date__c = taskEngineRequest.targetStartDateInput;
            } else {
                tempTask.OW_target_start_date__c = Utility.getOffsetBusinessDate(tempTask.ActivityDate, (integer) -taskInfo.OW_turnaround_time__c);
            }

            tempTask.Type = taskInfo.OW_subject__c;
            tempTask.RecordTypeId = TASK_RECORD_TYPE_ID_CLIENT_TASK_AUTOMATED;
            tempTask.Status = TASK_STATUS_NOT_STARTED;
            tempTask.Priority = taskInfo.OW_priority__c;
            tempTask.whatId = taskEngineRequest.whatId;
            tempTask.whoId = taskEngineRequest.whoId;
            tempTask.FinServ__Household__c = taskEngineRequest.householdId;
            tempTask.Role__c = taskInfo.Role__c;
            tempTask.OW_mortgage_application__c = taskEngineRequest.relatedMortgageApplication;
            tempTask.OW_task_information_identifier__c = taskInfo.Id;
            tempTask.OW_credit__c = taskInfo.OW_task_credit__c;  
            tempTask.OW_process__c = taskInfo.OW_process_variant__c;
            tempTask.OW_stage__c = taskInfo.OW_stage__c;
            tempTask.OW_task_information_name__c = taskInfo.OW_task_type__c;
            tempTask.OrchestrationTaskStatus__c = taskInfo.OrchestrationControlled__c == TASKINFO_ORCHESTRATION_CONTROLLED_YES ? TASK_ORCHESTRATION_TASK_STATUS_INCOMPLETE : TASK_ORCHESTRATION_TASK_STATUS_BLANK;
            
            tempTask.Related_Advice__c = taskEngineRequest.relatedAdviceId;
            tempTask.Related_AML_KYC_Check__c = taskEngineRequest.relatedAmlKycId;
            tempTask.Related_Annual_Review__c = taskEngineRequest.relatedAnnualReview;
            tempTask.Related_LOA__c = taskEngineRequest.relatedLoa;
            tempTask.Related_Opportunity__c = taskEngineRequest.relatedOpportunity;
            tempTask.Related_Provider__c = taskEngineRequest.relatedProvider;
            tempTask.RelatedFulfilment__c = taskEngineRequest.relatedFulfilment;
            tempTask.RelatedInformationRequest__c = taskEngineRequest.relatedInformationRequest;

            //perform different assignment logic based on taskType OW_assigned_to__c value
            //Would use a switch statment but it does not support global variables 
            String assignedToType = taskinfo.OW_assigned_to__c;

            if(assignedToType == ASSIGNED_TO_QUEUE){
                tempTask.OwnerId = queueNameMap.get(taskInfo.OW_queue__c);

            } else if(assignedToType == ASSIGNED_TO_PARTNER){
                tempTask.OwnerId = householdMap.get(taskEngineRequest.householdId).OwnerId;

            } else if (assignedToType == ASSIGNED_TO_SPECIFIC_USER){
                tempTask.OwnerId = taskInfo.OW_specific_user__c;

            } else if(assignedToType == ASSIGNED_TO_CHOSEN_USER){
                if(taskEngineRequest.chosenUser!= null){
                    tempTask.OwnerId = taskEngineRequest.chosenUser;
                }else{
                    newError(taskEngineRequest, 'Chosen User Ownership selected, but no user specified');
                    break;
                }

            } else if(assignedToType == ASSIGNED_TO_SUITABILITY_PLANNER){
                Id planner = adviceMap.get(taskEngineRequest.relatedAdviceId).Assigned_planner__c;
                if(planner != null){
                    tempTask.OwnerId = planner;
                }else{
                    tempTask.OwnerId = queueNameMap.get(QUEUE_NAME_PLANNERS);
                }

            } else if(assignedToType == ASSIGNED_TO_CASE_OWNER){
                tempTask.OwnerId = caseMap.get(taskEngineRequest.whatId).OwnerId;

            } else if(assignedToType == ASSIGNED_TO_OPPORTUNITY_OWNER){
                tempTask.OwnerId = opportunityMap.get(taskEngineRequest.whatId).OwnerId;

            } else if(assignedToType == ASSIGNED_TO_HOUSEHOLD_TEAM){
                tempTask.OwnerId = queueNameMap.get(householdMap.get(taskEngineRequest.householdId).OW_queue__c);

            } else if(assignedToType == ASSIGNED_TO_DEDICATED_TEAM){
                Id specialist = householdMap.get(taskEngineRequest.householdId).OW_dedicated_specialist__c;
                if(specialist != null){
                    tempTask.OwnerId = specialist;
                }else{
                    tempTask.OwnerId = queueNameMap.get(householdMap.get(taskEngineRequest.householdId).OW_queue__c);
                }
            
            } else {
                Id specialist = householdMap.get(taskEngineRequest.householdId).OW_dedicated_specialist__c;
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
    
    public List<taskEngineRequest> validateTaskEngineRequests(List<taskEngineRequest> taskEngineRequests){
        
        Boolean valid;
        List<taskEngineRequest> validTaskEngineRequests = new List<taskEngineRequest>();
        
        
        for(taskEngineRequest taskEngineRequest : taskEngineRequests){
            valid = True;
            if(taskEngineRequest.taskType == null){
                valid = False;
                newError(taskEngineRequest, 'Task Type Missing');
            }

            if(valid){
                validTaskEngineRequests.add(taskEngineRequest);
            }
            
        }
        
        return validTaskEngineRequests;
    }

    public List<taskEngineRequest> validateTaskEngineType(List<taskEngineRequest> taskEngineRequests,  Map<String, OW_task_information__c> taskInfoMap){
        List<taskEngineRequest> validTaskEngineRequests = new List<taskEngineRequest>();
        for(taskEngineRequest taskEngineRequest : taskEngineRequests){
            if(!taskInfoMap.containsKey(taskEngineRequest.taskType)){
                newError(taskEngineRequest, 'Task Type Not Found');
            }else{
                validTaskEngineRequests.add(taskEngineRequest);
            }
        }

        return validTaskEngineRequests;
    }

    public void handleErrors(){
        //Future Todo - Pass errors to logging system
    }

}
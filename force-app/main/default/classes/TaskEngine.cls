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
    
    //public static List<taskEngineRequest> taskEngineRequestBuffer = new List<taskEngineRequest>();
    public static List<taskError> taskErrors = new List<taskError>();
    public static List<Task> tasksToUpsert = new List<Task>();

    public class FlowInputs{
        @InvocableVariable(label='Task request' description='The developer name of the object' required=true) 
        public TaskEngineRequest taskRequest;
    }

    public class FlowOutputs{  
        @InvocableVariable(label='Tasks Created Sucessfully' description='Did any errors occur?' required=false) 
        public Boolean isSuccess;

        @InvocableVariable(label='Errors' description='Any errors that occured' required=false) 
        public List<taskError> errors;
    }

    @InvocableMethod(label='Generate Task' description='Generate a task based on provided task request.' category='Flow utilities' iconName='slds:standard:task')
    public static List<FlowOutputs> invocableGenerateTasks(List<FlowInputs> inputs){

        List<TaskEngineRequest> taskRequestsToProcess = new List<TaskEngineRequest>();
        for(FlowInputs input : inputs){
            taskRequestsToProcess.add(input.taskRequest);
        }
        
        if(taskRequestsToProcess.size() > 0){
            generateTasks(taskRequestsToProcess);
        }

        boolean isSuccess = taskErrors.size() == 0;

        List<FlowOutputs> flowOutputs = new List<FlowOutputs>();
        for(FlowInputs input : inputs){
            FlowOutputs output = new FlowOutputs();
            output.isSuccess = isSuccess;
            output.isSuccess = isSuccess;
            if(!isSuccess){
                output.errors = TaskEngine.taskErrors;
            }
            flowOutputs.add(output);
        }

        return flowOutputs;

    }

    public class taskError{
        public String message;
        public taskEngineRequest taskRequest = new taskEngineRequest();
        
        public taskError(taskEngineRequest taskRequest, String message){
            this.taskRequest = taskRequest;
            this.message = message;
        }
    }
    
    public static void newError(taskEngineRequest taskRequest, String message){
        taskErrors.add(new taskError(taskRequest, message));
    }
    
    public static void generateTasks(List<TaskEngineRequest> taskEngineRequests){
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

        for(OW_task_information__c taskInfo : [SELECT Id, OW_subject__c, OW_priority__c, OW_task_credit__c, OW_process_variant__c, OW_stage__c, OW_task_type__c, OW_due_date_offset__c, OW_specific_user__c, OW_queue__c, OW_assigned_to__c, Role__c, OrchestrationControlled__c, OW_turnaround_time__c 
                                                FROM OW_task_information__c 
                                                WHERE OW_task_type__c IN :taskTypes AND OW_status__c = :TASK_TYPE_STATUS_ACTIVE]){
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
        for(TaskEngineRequest taskEngineRequest : taskEngineRequests){
            
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

            if(taskInfo.OW_assigned_to__c == ASSIGNED_TO_SUITABILITY_PLANNER){
                adviceIds.add(taskEngineRequest.whatId); //would we also want to pull in related advice ids here?

            } else if(taskInfo.OW_assigned_to__c == ASSIGNED_TO_CASE_OWNER){
                caseIds.add(taskEngineRequest.whatId);

            } else if(taskInfo.OW_assigned_to__c == ASSIGNED_TO_OPPORTUNITY_OWNER){
                opportunityIds.add(taskEngineRequest.whatId);
            }
        }

        if(!householdIds.isEmpty()){
            householdMap = new Map<Id, Account>([SELECT Id, OwnerId, OW_dedicated_specialist__c, OW_queue__c FROM Account WHERE Id IN :householdIds]);
        }

        for(TaskEngineRequest taskEngineRequest : taskEngineRequests){
            //queue specified on household
            String queue = householdMap.get(taskEngineRequest.householdId).OW_queue__c;
            if(queue != null && !queueDeveloperNames.contains(queue)){
                queueDeveloperNames.add(queue);
            }
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
        for(TaskEngineRequest TaskEngineRequest : taskEngineRequests){
            Task tempTask = new Task();
            OW_task_information__c taskInfo = taskInfoMap.get(TaskEngineRequest.taskType);

            if(TaskEngineRequest.subject != null){
                tempTask.Subject = TaskEngineRequest.subject;
            } else {
                tempTask.Subject = taskInfo.OW_subject__c;
            }

            if(TaskEngineRequest.dueDateInput != null){
                tempTask.ActivityDate = TaskEngineRequest.dueDateInput;
            } else {
                tempTask.ActivityDate = Utility.getOffsetBusinessDate(System.today(), (integer) taskInfo.OW_due_date_offset__c);
            }

            if(TaskEngineRequest.targetStartDateInput != null){
                tempTask.OW_target_start_date__c = TaskEngineRequest.targetStartDateInput;
            } else {
                tempTask.OW_target_start_date__c = Utility.getOffsetBusinessDate(tempTask.ActivityDate, (integer) -taskInfo.OW_turnaround_time__c);
            }

            tempTask.Type = taskInfo.OW_subject__c;
            tempTask.RecordTypeId = TASK_RECORD_TYPE_ID_CLIENT_TASK_AUTOMATED;
            tempTask.Status = TASK_STATUS_NOT_STARTED;
            tempTask.Priority = taskInfo.OW_priority__c;
            tempTask.whatId = TaskEngineRequest.whatId;
            tempTask.whoId = TaskEngineRequest.whoId;
            tempTask.FinServ__Household__c = TaskEngineRequest.householdId;
            tempTask.Role__c = taskInfo.Role__c;
            tempTask.OW_mortgage_application__c = TaskEngineRequest.relatedMortgageApplication;
            tempTask.OW_task_information_identifier__c = taskInfo.Id;
            tempTask.OW_credit__c = taskInfo.OW_task_credit__c;  
            tempTask.OW_process__c = taskInfo.OW_process_variant__c;
            tempTask.OW_stage__c = taskInfo.OW_stage__c;
            tempTask.OW_task_information_name__c = taskInfo.OW_task_type__c;
            tempTask.OrchestrationTaskStatus__c = taskInfo.OrchestrationControlled__c == TASKINFO_ORCHESTRATION_CONTROLLED_YES ? TASK_ORCHESTRATION_TASK_STATUS_INCOMPLETE : TASK_ORCHESTRATION_TASK_STATUS_BLANK;
            
            tempTask.Related_Advice__c = TaskEngineRequest.relatedAdviceId;
            tempTask.Related_AML_KYC_Check__c = TaskEngineRequest.relatedAmlKycId;
            tempTask.Related_Annual_Review__c = TaskEngineRequest.relatedAnnualReview;
            tempTask.Related_LOA__c = TaskEngineRequest.relatedLoa;
            tempTask.Related_Opportunity__c = TaskEngineRequest.relatedOpportunity;
            tempTask.Related_Provider__c = TaskEngineRequest.relatedProvider;
            tempTask.RelatedFee__c = TaskEngineRequest.relatedFee;
            tempTask.RelatedFulfilment__c = TaskEngineRequest.relatedFulfilment;
            tempTask.RelatedInformationRequest__c = TaskEngineRequest.relatedInformationRequest;

            //perform different assignment logic based on taskType OW_assigned_to__c value
            //Would use a switch statment but it does not support global variables 
            String assignedToType = taskinfo.OW_assigned_to__c;

            if(assignedToType == ASSIGNED_TO_QUEUE){
                tempTask.OwnerId = queueNameMap.get(taskInfo.OW_queue__c);

            } else if(assignedToType == ASSIGNED_TO_PARTNER){
                tempTask.OwnerId = householdMap.get(TaskEngineRequest.householdId).OwnerId;

            } else if (assignedToType == ASSIGNED_TO_SPECIFIC_USER){
                tempTask.OwnerId = taskInfo.OW_specific_user__c;

            } else if(assignedToType == ASSIGNED_TO_CHOSEN_USER){
                if(TaskEngineRequest.chosenUser!= null){
                    tempTask.OwnerId = TaskEngineRequest.chosenUser;
                }else{
                    newError(TaskEngineRequest, 'Chosen User Ownership selected, but no user specified');
                    break;
                }

            } else if(assignedToType == ASSIGNED_TO_SUITABILITY_PLANNER){
                if(adviceMap.get(TaskEngineRequest.whatId) != null){ //if advice was not passed in as the whatId then this will be null
                    Id planner = adviceMap.get(TaskEngineRequest.whatId).Assigned_planner__c; //A straight copy of the logic have been using what ID but ehre we sued related advice id
                    if(planner != null){
                        tempTask.OwnerId = planner;
                    }else{
                        tempTask.OwnerId = queueNameMap.get(QUEUE_NAME_PLANNERS);
                    }
                }

            } else if(assignedToType == ASSIGNED_TO_CASE_OWNER){
                if(caseMap.get(TaskEngineRequest.whatId) != null){ //if case was not passed in as the whatId then this will be null
                    tempTask.OwnerId = caseMap.get(TaskEngineRequest.whatId).OwnerId;
                }

            } else if(assignedToType == ASSIGNED_TO_OPPORTUNITY_OWNER){
                if(opportunityMap.get(TaskEngineRequest.whatId) != null){ //if opportunity was not passed in as the whatId then this will be null
                    tempTask.OwnerId = opportunityMap.get(TaskEngineRequest.whatId).OwnerId;
                }

            } else if(assignedToType == ASSIGNED_TO_HOUSEHOLD_TEAM){
                tempTask.OwnerId = queueNameMap.get(householdMap.get(TaskEngineRequest.householdId).OW_queue__c);

            } else if(assignedToType == ASSIGNED_TO_DEDICATED_TEAM){
                Id specialist = householdMap.get(TaskEngineRequest.householdId).OW_dedicated_specialist__c;
                if(specialist != null){
                    tempTask.OwnerId = specialist;
                }else{
                    tempTask.OwnerId = queueNameMap.get(householdMap.get(TaskEngineRequest.householdId).OW_queue__c);
                }
            
            } else {
                Id specialist = householdMap.get(TaskEngineRequest.householdId).OW_dedicated_specialist__c;
                if(specialist != null){
                    tempTask.OwnerId = specialist;
                }
            }  

            tasksToUpsert.add(tempTask);
        }
        
        databaseUpsert(tasksToUpsert, true);
        handleErrors();
    }

    private static void databaseUpsert(List<SObject> recordsToUpsert, Boolean allOrNone){
        Database.UpsertResult[] upsertResults = Database.upsert(recordsToUpsert, allOrNone);
        for(Database.UpsertResult upsertResult : upsertResults){
            if(!upsertResult.isSuccess()){
                for(Database.Error err : upsertResult.getErrors()){
                    newError(new taskEngineRequest(), err.getMessage());
                }
            }
        }
    }
    
    private static List<TaskEngineRequest> validateTaskEngineRequests(List<TaskEngineRequest> taskEngineRequests){
        
        Boolean valid;
        List<TaskEngineRequest> validTaskEngineRequests = new List<TaskEngineRequest>();
        
        
        for(TaskEngineRequest taskEngineRequest : taskEngineRequests){
            valid = true;
            if(taskEngineRequest.taskType == null){
                valid = false;
                newError(taskEngineRequest, 'Task Type Missing');
            }
            //check whatId has been set
            if(taskEngineRequest.whatId == null){
                valid = false;
                newError(taskEngineRequest, 'What ID missing');
            }
            //check householdId has been set
            if(taskEngineRequest.householdId == null){
                valid = false;
                newError(taskEngineRequest, 'Household ID missing');
            }

            if(valid){
                validTaskEngineRequests.add(taskEngineRequest);
            }
            
        }
        
        return validTaskEngineRequests;
    }

    private static List<TaskEngineRequest> validateTaskEngineType(List<TaskEngineRequest> taskEngineRequests,  Map<String, OW_task_information__c> taskInfoMap){
        List<TaskEngineRequest> validTaskEngineRequests = new List<TaskEngineRequest>();
        for(TaskEngineRequest taskEngineRequest : taskEngineRequests){
            if(!taskInfoMap.containsKey(taskEngineRequest.taskType)){
                newError(taskEngineRequest, 'Task Type Not Found');
            }else{
                validTaskEngineRequests.add(taskEngineRequest);
            }
        }

        return validTaskEngineRequests;
    }

    private static void handleErrors(){
        //Future Todo - Pass errors to logging system
    }

}
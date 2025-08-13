public class TaskRequestHelper {

    public static final string TASK_REQUEST_DEFAULT_TASK_INFORMATION_DEVELOPER_NAME = 'DEFAULT_TASK_REQUEST';

    public static void generateRequestsFromTaskRequestRecords(List<OW_task_request__c> newRequests) {

        if (newRequests == null || newRequests.isEmpty()) {
            return;
        }

        List<TaskEngineRequest> taskEngineRequests = new List<TaskEngineRequest>();

        for (OW_task_request__c request : newRequests) {
            TaskEngineRequest engineRequest = new TaskEngineRequest();

            engineRequest.dueDateInput              = request.OW_due_date_input__c;
            engineRequest.householdId               = request.OW_household_id__c;
            engineRequest.originalTask              = request.OW_task_id__c;
            engineRequest.relatedAdviceId           = request.OW_related_advice__c;
            engineRequest.relatedAmlKycId           = request.OW_related_aml__c;
            engineRequest.relatedAnnualReview       = request.OW_related_annual_review__c;
            engineRequest.relatedLoa                = request.OW_related_loa__c;
            engineRequest.relatedMortgageApplication= request.OW_related_mortgage_application__c;
            engineRequest.relatedOpportunity        = request.OW_related_opportunity__c;
            engineRequest.relatedProvider           = request.OW_related_provider__c;
            engineRequest.targetStartDateInput      = request.OW_target_start_date__c;
            engineRequest.taskType                  = request.OW_task_type__c;
            engineRequest.whatId                    = request.OW_what_id__c;
            engineRequest.whoId                     = request.OW_who_id__c;

            if (request.OW_task_type__c == null) {
                engineRequest.taskType = TASK_REQUEST_DEFAULT_TASK_INFORMATION_DEVELOPER_NAME;
            }

            // Fields with NO source on OW_task_request__c will be null by default:
            // engineRequest.chosenUser
            // engineRequest.relatedFee
            // engineRequest.relatedFulfilment
            // engineRequest.relatedInformationRequest
            // engineRequest.subject
            // engineRequest.taskId    

            taskEngineRequests.add(engineRequest);
        }

        if (!taskEngineRequests.isEmpty()) {
            try {
                TaskEngine.generateTasks(taskEngineRequests);
                if(TaskEngine.taskErrors.size() > 0) {
                    throw new TaskRequestHelperException(JSON.serialize(TaskEngine.taskErrors));
                }
            } catch (Exception e) {
                System.debug('An error occurred calling TaskEngine.generateTasks: ' + e.getMessage());
                newRequests[0].addError('Failed to generate tasks. Error: ' + e.getMessage());
                //todo - add to nebula logger
            }
        }
    }

    public class TaskRequestHelperException extends Exception {}
}
/**
 * @description Helper class for processing WorkRequest__c records and converting them into TaskEngineRequest objects.
 * 
 * This class provides functionality to transform WorkRequest__c records into TaskEngineRequest objects
 * that can be processed by the TaskEngine to create Task records. It handles field mapping, validation,
 * and error handling for the task creation process.
 * 
 * The class maps WorkRequest__c fields to TaskEngineRequest properties and includes logic for
 * default task type assignment and ID field validation.
 */
public class WorkRequestHelper {

    /**
     * @description Default task type developer name used when WorkRequest__c.TaskType__c is null.
     * This constant defines the fallback task type that will be used for task creation
     * when no specific task type is provided in the work request.
     */
    public static final string WORK_REQUEST_DEFAULT_TASK_INFORMATION_DEVELOPER_NAME = 'DEFAULT_WORK_REQUEST';

    /**
     * @description Generates TaskEngineRequest objects from a list of WorkRequest__c records.
     * 
     * This method processes WorkRequest__c records and converts them into TaskEngineRequest objects
     * that can be processed by the TaskEngine to create Task records. It handles field mapping,
     * ID validation, default task type assignment, and error handling.
     * 
     * @param newRequests List of WorkRequest__c records to process
     * 
     * The method maps the following fields:
     * - WorkRequest__c.DueDate__c → TaskEngineRequest.dueDateInput
     * - WorkRequest__c.Subject__c → TaskEngineRequest.subject
     * - WorkRequest__c.TaskType__c → TaskEngineRequest.taskType (with default fallback)
     * - WorkRequest__c.HouseholdId__c → TaskEngineRequest.householdId 
     * - WorkRequest__c.WhatId__c → TaskEngineRequest.whatId 
     * - WorkRequest__c.WhoId__c → TaskEngineRequest.whoId 
     */
    public static void generateRequestsFromWorkRequestRecords(List<WorkRequest__c> newRequests) {

        if (newRequests == null || newRequests.isEmpty()) {
            return;
        }

        List<TaskEngineRequest> taskEngineRequests = new List<TaskEngineRequest>();

        for (WorkRequest__c request : newRequests) {
            TaskEngineRequest engineRequest = new TaskEngineRequest();

            engineRequest.dueDateInput              = request.DueDate__c;
            engineRequest.subject                   = request.Subject__c;
            engineRequest.taskType                  = request.TaskType__c;
            engineRequest.householdId               = request.HouseholdId__c;
            engineRequest.whatId                    = request.WhatId__c;
            engineRequest.whoId                     = request.WhoId__c;

            if (request.TaskType__c == null) {
                engineRequest.taskType = WORK_REQUEST_DEFAULT_TASK_INFORMATION_DEVELOPER_NAME;
            }

            // Fields with NO source on Work_Request__c will be null by default:
            // engineRequest.chosenUser
            // engineRequest.originalTask
            // engineRequest.relatedAdviceId
            // engineRequest.relatedAmlKycId
            // engineRequest.relatedAnnualReview
            // engineRequest.relatedFee
            // engineRequest.relatedFulfilment
            // engineRequest.relatedInformationRequest
            // engineRequest.relatedLoa
            // engineRequest.relatedMortgageApplication
            // engineRequest.relatedOpportunity
            // engineRequest.relatedProvider
            // engineRequest.targetStartDateInput
            // engineRequest.taskId

            taskEngineRequests.add(engineRequest);
        }

        if (!taskEngineRequests.isEmpty()) {
            try {
                TaskEngine.generateTasks(taskEngineRequests);
                if(TaskEngine.taskErrors.size() > 0) {
                    throw new WorkRequestHelperException(JSON.serialize(TaskEngine.taskErrors));
                }
            } catch (Exception e) {
                System.debug('An error occurred calling TaskEngine.generateTasks: ' + e.getMessage());
                newRequests[0].addError('Failed to generate tasks. Error: ' + e.getMessage());
                //todo - add to nebula logger
            }
        }
    }

    /**
     * @description Custom exception class for WorkRequestHelper errors.
     * This exception is thrown when there are errors during the task generation process,
     * such as TaskEngine errors or validation failures.
     */
    public class WorkRequestHelperException extends Exception {}
}
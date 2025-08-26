/**
 * @description Trigger handler for WorkRequest__c objects that processes after insert events
 * to generate tasks from work request records using the TaskEngine.
 * 
 * This class extends the TriggerHandler framework
 */
public class WorkRequestTriggerHandler extends TriggerHandler{

    //recast trigger variables from SObjects
    private Map<Id, WorkRequest__c> oldWorkRequestMap = (Map<Id, WorkRequest__c>) Trigger.oldMap;
    private Map<Id, WorkRequest__c> newWorkRequestMap = (Map<Id, WorkRequest__c>) Trigger.newMap;

    private List<WorkRequest__c> newWorkRequestList = (List<WorkRequest__c>) Trigger.new; //for insert when it will not have an id yet

    /**
     * @description Processes after insert events for WorkRequest__c records.
     * Calls the WorkRequestHelper to generate TaskEngineRequest objects from the newly inserted
     * work request records, which will then be processed by the TaskEngine to create Task records.
     */
    public override void afterInsert(){
        WorkRequestHelper.generateRequestsFromWorkRequestRecords(newWorkRequestList);
    }
}
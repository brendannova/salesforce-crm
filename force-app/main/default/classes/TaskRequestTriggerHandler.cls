public class TaskRequestTriggerHandler extends TriggerHandler{

    //recast trigger variables from SObjects
    private Map<Id, OW_Task_Request__c> oldTaskRequesttMap = (Map<Id, OW_Task_Request__c>) Trigger.oldMap;
    private Map<Id, OW_Task_Request__c> newTaskReqeustMap = (Map<Id, OW_Task_Request__c>) Trigger.newMap;

    private List<OW_Task_Request__c> newTaskReqeustList = (List<OW_Task_Request__c>) Trigger.new; //for insert when it will not have an id yet

    public override void afterInsert(){
        TaskRequestHelper.generateRequestsFromTaskRequestRecords(newTaskReqeustList);
    }
}
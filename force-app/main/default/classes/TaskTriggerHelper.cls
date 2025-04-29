/**
    * @description This class is a helper for a task trigge
*/
public with sharing class TaskTriggerHelper {

    /**
    * @description Takes a task map from a trigger and validates whether they can be deleted or not
        * @param taskMap - the oldMap of tasks from the trigger
    */
    public void checkDelete(Map<Id,Task> taskMap) {
        for(Task t : taskMap.values()){
            if(!String.isBlank(t.OrchestrationTaskStatus__c)){
                t.addError('Error: cannot delete an orchestrated task');
            }
        }
    }
}
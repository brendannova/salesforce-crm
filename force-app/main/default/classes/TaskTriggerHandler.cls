public class TaskTriggerHandler extends TriggerHandler {

    //recast trigger variables from SObjects
    private Map<Id, Task> oldTaskMap = (Map<Id, Task>) Trigger.oldMap;

    public override void beforeDelete() {
        TaskTriggerHelper th = new TaskTriggerHelper();
        th.checkDelete(this.oldTaskMap);
    }
}
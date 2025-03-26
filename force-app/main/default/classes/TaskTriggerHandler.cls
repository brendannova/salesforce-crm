public class TaskTriggerHandler extends TriggerHandler {

    //recast trigger variables from SObjects
    private Map<Id, Task> oldTaskMap = (Map<Id, Task>) Trigger.oldMap;

    public override void beforeDelete() {
        TaskHelper th = new TaskHelper();
        th.checkDelete(this.oldTaskMap);
    }
}
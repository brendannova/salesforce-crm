trigger TaskTrigger on Task (before delete) {
    if(Trigger.isBefore && Trigger.isDelete){
        TaskHelper th = new TaskHelper();
        th.checkDelete(Trigger.oldMap);
    }
}
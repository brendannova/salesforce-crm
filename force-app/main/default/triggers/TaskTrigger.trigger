trigger TaskTrigger on Task (before delete) {
    new TaskTriggerHandler().run();
}
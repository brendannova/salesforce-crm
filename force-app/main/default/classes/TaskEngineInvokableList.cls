public with sharing class TaskEngineInvokableList {
    @InvocableMethod(label='Generate Tasks' description='Generates multiple tasks based on provided task requests list/colleciton.' category='Flow utilities' iconName='slds:standard:task')
    public static void invocableGenerateTasks(List<List<TaskEngine.taskEngineRequest>> taskRequests){
        TaskEngine engine = new TaskEngine();

        List<TaskEngine.taskEngineRequest> taskRequestsToProcess = new List<TaskEngine.taskEngineRequest>();
        for(List<TaskEngine.taskEngineRequest> taskRequestList : taskRequests){
            taskRequestsToProcess.addAll(taskRequestList);
        }
        engine.generateTasks(taskRequestsToProcess);
    }
}
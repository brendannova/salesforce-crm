public with sharing class TaskEngineInvokableList {
    public class FlowInputs{
        @InvocableVariable(label='Task requests' description='Collection of taskEgnineRequest variables' required=true) 
        public List<TaskEngineRequest> taskRequests;
    }

    public class FlowOutputs{  
        @InvocableVariable(label='Tasks Created Sucessfully' description='If true, the tasks were created successfully. If false, an error occurred.' required=false) 
        public Boolean isSuccess;

        @InvocableVariable(label='Errors' description='Any errors that occured' required=false) 
        public List<TaskEngine.taskError> errors;

        @InvocableVariable(label='Error Messages' description='Any error messages that occured' required=false)
        public List<String> errorMessages;
    }
    
    @InvocableMethod(label='Generate Tasks' description='Generates multiple tasks based on provided task requests list/colleciton.' category='Flow utilities' iconName='slds:standard:task')
    public static list<FlowOutputs> invocableGenerateTasks(List<FlowInputs> inputs){

        List<TaskEngineRequest> taskRequestsToProcess = new List<TaskEngineRequest>();
        for(FlowInputs input : inputs){
            taskRequestsToProcess.addAll(input.taskRequests);
        }
        TaskEngine.generateTasks(taskRequestsToProcess);

        boolean isSuccess = TaskEngine.taskErrors.size() == 0;

        List<FlowOutputs> flowOutputs = new List<FlowOutputs>();
        for(FlowInputs input : inputs){
            FlowOutputs output = new FlowOutputs();
            output.isSuccess = isSuccess;
            if(!isSuccess){
                output.errors = TaskEngine.taskErrors;
                //and output error messages in more usable string
                for(TaskEngine.taskError taskError : TaskEngine.taskErrors){
                    output.errorMessages.add(taskError.message);
                }
            }
            flowOutputs.add(output);
        }

        return flowOutputs;
    }
}
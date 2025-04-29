public with sharing class FlowUtilityTaskCreate {
    public class FlowInputs{
        @InvocableVariable(label='Task request' description='TaskEngineRequest variable' required=true) 
        public TaskEngineRequest taskRequest;
    }

    public class FlowOutputs{  
        @InvocableVariable(label='Task Created Sucessfully' description='If true, the task was created successfully. If false, an error occurred.' required=false) 
        public Boolean isSuccess;

        @InvocableVariable(label='Errors' description='Any taskError variables that occured' required=false) 
        public List<TaskEngine.taskError> errors;

        @InvocableVariable(label='Error Messages' description='Any error messages that occured' required=false)
        public List<String> errorMessages;
    }

    @InvocableMethod(label='Generate Task' description='Generate a task based on provided task request.' category='Flow utilities' iconName='slds:standard:task')
    public static List<FlowOutputs> invocableGenerateTasks(List<FlowInputs> inputs){

        List<TaskEngineRequest> taskRequestsToProcess = new List<TaskEngineRequest>();
        for(FlowInputs input : inputs){
            taskRequestsToProcess.add(input.taskRequest);
        }
        
        if(taskRequestsToProcess.size() > 0){
            TaskEngine.generateTasks(taskRequestsToProcess);
        }

        boolean isSuccess = TaskEngine.taskErrors.size() == 0;

        List<FlowOutputs> flowOutputs = new List<FlowOutputs>();
        for(FlowInputs input : inputs){
            FlowOutputs output = new FlowOutputs();
            output.isSuccess = isSuccess;
            if(!isSuccess){
                output.errors = TaskEngine.taskErrors;
                output.errorMessages = new List<String>();
                //and output error messages in more usable string
                for(TaskEngine.taskError taskError : TaskEngine.taskErrors){
                    output.errorMessages.add(taskError.errorOutputString);
                }
            }
            flowOutputs.add(output);
        }

        return flowOutputs;

    }
}
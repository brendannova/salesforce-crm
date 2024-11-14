public class SplitStringInvocable {
    
    @InvocableMethod (label='Split String')
    public static List<FlowOutputs> invokeThisMethod(List<FlowInputs> requests){
        List<FlowOutputs> results = new List<FlowOutputs>();
        FlowOutputs returnDetails = new FlowOutputs();
        for (FlowInputs request : requests) {
            returnDetails.tasksToCreate = splitString(request.stringToSplit);
            results.add(returnDetails);         
        }
        return results;
    }
    
    public static List<String> splitString (String stringToSplit) {
        List<String> tasksToCreate = stringToSplit.split(';');       
        return tasksToCreate;
    }
    
    public class FlowInputs{
        @InvocableVariable public String stringToSplit;
    }
    
    public class FlowOutputs {
        @InvocableVariable public List<String> tasksToCreate;
    }
}
public class StringListDeduplicate {
    @InvocableMethod (label='Deduplicate')
    public static List<FlowOutputs> invokeThisMethod(List<FlowInputs> requests){
        List<FlowOutputs> results = new List<FlowOutputs>();
        FlowOutputs returnDetails = new FlowOutputs();
        for (FlowInputs request : requests) {
            returnDetails.outputString = deDupe(request.inputString);
            results.add(returnDetails);         
        }
        return results;
    }
    
    public static List<String> deDupe (List<String> listToDeDupe) {
        Set<String> stringSet = new Set<String>(listToDeDupe);
        List<String> output = new List<String>(stringSet);
        return output;
    }
    
    public class FlowInputs{
        @InvocableVariable public List<String> inputString;
    }
    
    public class FlowOutputs {
        @InvocableVariable public List<String> outputString;
    }

}
/**
 * This class will take a list of records and return the 1st item in that list.
 * It is exposed as an Apex action so it can be used as a utility in flows.
 * This utility exists to allow flows to access the 1st item in a list repeatedly as this is not a commonly available method.
 */
public with sharing class FlowUtilityGetFirstListItem {

    // The inputs provided by the flow
    public class FlowInputs {
        @InvocableVariable(label='Collection' description='The collection you want the 1st item from' required=true)
        public List<SObject> inputCollection;     
    }
    
    // The outputs returned to the flow
    public class FlowOutputs {
        @InvocableVariable(label='Record' description='The 1st record from the collection input' required=true)
        public SObject outputItem;
    }
    
    // The invocable method exposed to the flow. This simply loops the requests and calls another method to get the results. 
    @InvocableMethod(label='Get 1st item from collection' description = 'Pass in a collection of sObjects in order to get the 1st item' category = 'Flow utilities' iconName='slds:standard:custom_component_task')
    public static List<FlowOutputs> processRequests(List<FlowInputs> requests){
        List<FlowOutputs> results = new List<FlowOutputs>();
        for (FlowInputs request : requests) {
            results.add(getResult(request));
        }
        return results;
    }

    // Gets the 1st item in the collection provided for a given request
    private static FlowOutputs getResult(FlowInputs request) {
        FlowOutputs result = new FlowOutputs();
        result.outputItem = request.inputCollection[0];
        return result;
    }
}
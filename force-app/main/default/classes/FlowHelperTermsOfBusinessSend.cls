/**
 * This class will make a callout to the take a list of records and return the 1st item in that list.
 * It is exposed as an Apex action so it can be used as a utility in flows.
 * This utility exists to allow flows to access the 1st item in a list repeatedly as this is not a commonly available method.
 */
public with sharing class FlowHelperTermsOfBusinessSend {

    // The inputs provided by the flow
    public class FlowInputs {
        @InvocableVariable(label='Account ID' description='The ID of the person account you want to trigger TOB for' required=true)
        public String accountId;     
    }
    
    // The outputs returned to the flow
    public class FlowOutputs {
        @InvocableVariable(label='Status code' description='The status code returned by the API' required=true)
        public Integer statusCode;
    }
    
    // The invocable method exposed to the flow. This simply loops the requests and calls another method to get the results. 
    @InvocableMethod(label='Send TOB to person' description = 'Pass in a person account ID to send the person TOB' category = 'Flow Helpers' iconName='slds:standard:custom_component_task')
    public static List<FlowOutputs> processRequests(List<FlowInputs> requests){
        List<FlowOutputs> results = new List<FlowOutputs>();
        for (FlowInputs request : requests) {
            results.add(getResult(request));
        }
        return results;
    }

    // Makes the send TOB callout for the given request item
    private static FlowOutputs getResult(FlowInputs request) {
        FlowOutputs result = new FlowOutputs();
        String accountId = request.accountId;
        Integer responseCode = SendTermsController.makePostCallout(accountId);
        result.statusCode = responseCode;
        return result;
    }
}
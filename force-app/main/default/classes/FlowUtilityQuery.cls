/**
 * This class will take a query string and execute that, returning the results to the flow. 
 */
public with sharing class FlowUtilityQuery {

    // The inputs provided by the flow
    public class FlowInputs {
        @InvocableVariable(label='Query string' description='The query you want to execute' required=true)
        public String queryString;     
    }
    
    // The outputs returned to the flow
    public class FlowOutputs {
        @InvocableVariable(label='Records' description='The records returned by the query' required=true)
        public List<SObject> outputRecords;
    }
    
    // The invocable method exposed to the flow. This simply loops the requests and calls another method to get the results. 
    @InvocableMethod(label='Execute query (not bulkified)' description = 'Pass in a query string and get back the results of a Database.query() on that string. Must be executed in a screenflow unbulkified context only.' category = 'Flow utilities' iconName='slds:standard:custom_component_task')
    public static List<FlowOutputs> processRequests(List<FlowInputs> requests){
        if(requests.size() > 1 ){
            throw new FlowUtilityQueryException('This utility only accepts 1 request');
        }
        List<FlowOutputs> results = new List<FlowOutputs>();
        for (FlowInputs request : requests) {
            results.add(getResult(request));
        }
        return results;
    }

    // Gets the 1st item in the collection provided for a given request
    private static FlowOutputs getResult(FlowInputs request) {
        FlowOutputs result = new FlowOutputs();
        result.outputRecords = Database.query(request.queryString);
        return result;
    }

    public class FlowUtilityQueryException extends Exception {}

}
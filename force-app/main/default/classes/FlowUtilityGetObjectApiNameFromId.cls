public with sharing class FlowUtilityGetObjectApiNameFromId {
    
    public class FlowInputs {
        @InvocableVariable(label='Record ID' description='A Salesforce ID' placeholderText='0018e000003CNciAAG' required=true)
        public String recordId;
    }
    
    public class FlowOutputs {
        @InvocableVariable(label='Object API name' description='The API name of the object, like Account or Advice__c' required=true)
        public String objectApiName;
    }

    // Invocable method to be called from the flow
    @InvocableMethod(label='Get object API name from ID' description='Pass in an ID and receive a string containing the object API name as an output' category='Flow utilities' iconName='slds:standard:custom_component_task')
    public static List<FlowOutputs> processRequests(List<FlowInputs> requests){
        List<FlowOutputs> results = new List<FlowOutputs>();
        for (FlowInputs request : requests) {
            results.add(getResult(request));
        }
        return results;
    }

    // Gets the object API name from the ID 
    private static FlowOutputs getResult(FlowInputs request) {
        FlowOutputs result = new FlowOutputs();
        result.objectApiName = Id.ValueOf(request.recordId).getSObjectType().getDescribe().getName();
        return result;
    }
}
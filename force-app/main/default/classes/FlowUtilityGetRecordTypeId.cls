/**
 * This class will take object and record type developer names and return a record type ID.
 * It is exposed as an Apex action so it can be used in flow.
 * This utility exists to allow flows to access record type IDs without the need for a query. 
 * Using the following notation was considered but this did not work as the object name cannot be inserted dynamically: Schema.SObjectType.{object}.getRecordTypeInfosByDeveloperName().get({recordTypeDeveloperName}).getRecordTypeId();
 */
public without sharing class FlowUtilityGetRecordTypeId {

    // The inputs required from the flow in order to get the record type ID
    public class FlowInputs{
        @InvocableVariable(label='sObject type' description='The developer name of the object' required=true) 
        public String sObjectType;
        
        @InvocableVariable(label='Developer name' description='The developer name of the record type' required=true) 
        public String recordTypeDeveloperName;
    }
    
    // The outputs returned to the flow
    public class FlowOutputs{  
        @InvocableVariable(label='Record type ID' description='The ID of the record type requested' required=true) 
        public Id recordTypeId;
    }

    // Invocable method to be called from the flow
    @InvocableMethod(label='Get record type ID' description='Returns a record type ID given object and record type developer names' category='Flow utilities' iconName='slds:standard:custom_component_task')
    public static List<FlowOutputs> processRequests(List<FlowInputs> requests){
        List<FlowOutputs> results = new List<FlowOutputs>();
        for (FlowInputs request : requests) {
            results.add(getResult(request));
        }
        return results;
    }

    // Gets the record type ID. This is contained as an independent method in case we want to change how the ID is retrieved. 
    private static FlowOutputs getResult(FlowInputs request) {
        Map<String, Schema.SObjectType> sObjectTypeMap = Schema.getGlobalDescribe();
        Schema.SObjectType sObjectType = sObjectTypeMap.get(request.sObjectType);
        Schema.DescribeSObjectResult sObjectResult = sObjectType.getDescribe();
        Map<String,Schema.RecordTypeInfo> recordTypeMap = sObjectResult.getRecordTypeInfosByDeveloperName();
        FlowOutputs result = new FlowOutputs();
        result.recordTypeId = recordTypeMap.get(request.recordTypeDeveloperName).getRecordTypeId();
        return result;
    }
}
/**
 * This class exists to support building picklists dynamically in flows.
 * It is exposed as an Apex action so it can be used in flow.
 * It takes a list of picklist entry API names alongside the object and field identifiers. 
 * It returns an Apex data type that contains simply the picklist entry labels and values.
 */
public without sharing class FlowUtilityGetPicklistEntries {

    // The inputs required from the flow in order to get the record type ID
    public class FlowInputs{
        @InvocableVariable(label='sObject type' description='The developer name of the object' required=true) 
        public String sObjectType;
        
        @InvocableVariable(label='Field' description='The developer name of the field' required=true) 
        public String field;

        @InvocableVariable(label='Picklist values' description='A list of the picklist entry API names' required=true) 
        public List<String> picklistValues;

        @InvocableVariable(label='Custom sort' description='If true, the order of the values passed in will be maintained. Otherwise the picklist configuration will be used.' defaultValue='false') 
        public Boolean customSort;
    }
    
    // The outputs returned to the flow
    public class FlowOutputs{  
        @InvocableVariable(label='Picklist entries' description='A list of the picklist entries containing labels and values' required=true) 
        public List<FlowUtilityPicklistEntry> picklistEntries;
    }

    // Invocable method to be called from the flow
    @InvocableMethod(label='Get picklist entries' description='Given your input object, field, and picklist values, a list of picklist labels and values will be returned' category='Flow utilities' iconName='slds:standard:custom_component_task')
    public static List<FlowOutputs> processRequests(List<FlowInputs> requests){
        List<FlowOutputs> results = new List<FlowOutputs>();
        for (FlowInputs request : requests) {
            results.add(getResult(request));
        }
        return results;
    }

    // Constructs the result, a list of our custom Apex data type
    private static FlowOutputs getResult(FlowInputs request) {

        // Get the picklist entries for the given object and field
        List<Schema.PicklistEntry> fieldPicklistEntries = Schema.getGlobalDescribe().get(request.sObjectType).getDescribe().fields.getMap().get(request.field).getDescribe().getPicklistValues();
        List<FlowUtilityPicklistEntry> customPicklistEntries = new List<FlowUtilityPicklistEntry>();
        
        if(!request.customSort){
            // As we don't want custom ordering, we'll build the list using the schema definition as the starting point
            for( Schema.PicklistEntry fieldPicklistEntry : fieldPicklistEntries){
                if(request.picklistValues.contains(fieldPicklistEntry.getValue())){
                    FlowUtilityPicklistEntry customPicklistEntry = new FlowUtilityPicklistEntry();
                    customPicklistEntry.label = fieldPicklistEntry.getLabel();
                    customPicklistEntry.value = fieldPicklistEntry.getValue();
                    customPicklistEntries.add(customPicklistEntry);
                }
            }
        } else {
             // As we do want customer ordering, we'll build a map of picklist entries but construct the list based on the request
            Map<String, Schema.PicklistEntry> fieldPicklistEntriesMap = new Map<String, Schema.PicklistEntry>();
            for( Schema.PicklistEntry fieldPicklistEntry : fieldPicklistEntries){
                fieldPicklistEntriesMap.put(fieldPicklistEntry.getValue(), fieldPicklistEntry);
            }
            
            for(String picklistValue : request.picklistValues){
                FlowUtilityPicklistEntry customPicklistEntry = new FlowUtilityPicklistEntry();
                customPicklistEntry.label = fieldPicklistEntriesMap.get(picklistValue).getLabel();
                customPicklistEntry.value = fieldPicklistEntriesMap.get(picklistValue).getValue();
                customPicklistEntries.add(customPicklistEntry);
            }
        }
        FlowOutputs result = new FlowOutputs();
        result.picklistEntries = customPicklistEntries;
        return result;
    }
}
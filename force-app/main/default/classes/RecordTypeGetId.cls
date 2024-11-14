public class RecordTypeGetId {
    public static Id getId(String objectDevName, String recordTypedevName) {
        
        Map<String, Schema.SObjectType> m = Schema.getGlobalDescribe();
        Schema.SObjectType s = m.get(objectDevName);
        Schema.DescribeSObjectResult cfrSchema = s.getDescribe();
        Map<String,Schema.RecordTypeInfo> RecordTypeInfo = cfrSchema.getRecordTypeInfosByDeveloperName();
        Id rtId = RecordTypeInfo.get(recordTypedevName).getRecordTypeId();
        return rtId;
        
        /*Other methods for future consideration 
         -- SOQL query on the record type object, uses limits but dynamic --
		 rtId = [SELECT Id FROM RecordType WHERE DeveloperName = :recordTypedevName AND sObjectType = :objectDevName].Id;
        -- If statements to get ID simply, can't run dynamically on object so would need to expand as objects grow --
        
        if(objectDevName == 'Advice__c'){
            rtID = Schema.SObjectType.Advice__c.getRecordTypeInfosByDeveloperName().get(recordTypedevName).getRecordTypeId();
        } else if (objectDevName == 'Account'){
            rtID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(recordTypedevName).getRecordTypeId();
        } */
    }
    
    //The method is invocable to ensure this can be called from a flow, allowing us to use this within declarative automation. 
    @InvocableMethod(label = 'Get record type ID' description = 'Get a record type ID from sObject name and record type developer name' category = 'Utility')
    public static List<FlowOutputs> invokeThisMethod(List<FlowInputs> requests){
        List<FlowOutputs> results = new List<FlowOutputs>();
        for (FlowInputs request : requests) {
            results.add(invokeLocalMethod(request));
        }
        return results;
    }
    
    public static FlowOutputs invokeLocalMethod(FlowInputs request){        
        FlowOutputs returnDetails = new FlowOutputs();
        returnDetails.recordTypeId = getId(request.sObjectType, request.recordTypeDeveloperName);
        return returnDetails;   
    }
    
    public class FlowInputs{
        
        @InvocableVariable
        public String sObjectType;
        
        @InvocableVariable
        public String recordTypeDeveloperName;
    }
    
    public class FlowOutputs{
        
        @InvocableVariable
        public Id recordTypeId;
    }
}
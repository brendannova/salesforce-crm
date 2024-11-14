public class GetObjectFromRecordId {
    
    @InvocableMethod(label='Get object name from Id' description='Reusable method to fetch the name of the object using only its Id')
    public static List<FlowOutputs> GetObjectName(List<FlowInputs> recordIds) {
        
        
        Id convertedRecordId = Id.ValueOf(recordIds.get(0).recordId);
        string objectName = convertedrecordID.getSObjectType().getDescribe().getName();
        
        FlowOutputs objName = new FlowOutputs();
        objName.ObjectApiName = objectName;
        List<FlowOutputs> outputList = new List<FlowOutputs>();
        outputList.add(objName);
        return outputList;
        
    }
    
    public class FlowInputs {
        
        @InvocableVariable
        public String recordId;
    }
    
    public class FlowOutputs {
        
        @InvocableVariable
        public String ObjectApiName;
    }

}
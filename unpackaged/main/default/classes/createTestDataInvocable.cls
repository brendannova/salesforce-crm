public class createTestDataInvocable {
    
    @InvocableMethod(label = 'Create portal test data' description = 'Creates household data to allow portal testing to take place.' category = 'Testing')
    public static List<FlowOutputs> processInputs (List<FlowInputs> inputs) {
        
        List<FlowOutputs> results = new List<FlowOutputs>();
        for (FlowInputs input : inputs) {
            results.add(createHousehold(input));
        }
        return results;
    }
    
    public static FlowOutputs createHousehold(FlowInputs request){        
        FlowOutputs returnDetails = new FlowOutputs();
        CreateTestData testHousehold = new CreateTestData();
        returnDetails.householdId = createTestData.createHousehold(request.numClients, request.numChildren, request.factFindType);
        return returnDetails;   
    }    
    
    // Inputs to this class coming from a flow
    public class FlowInputs{
        
        @InvocableVariable
        public Integer numClients;
        
        @InvocableVariable
        public Integer numChildren;
        
        @InvocableVariable
        public String factFindType;
    }
    
    // Outputs to return to the flow
    public class FlowOutputs{
        
        @InvocableVariable
        public String householdId;
    }
}
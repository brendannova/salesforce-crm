/**
 * Reusable flow utility class to randomly generate a version 4 universally unique identifier (UUID)
 */
public class FlowUtilityGenerateUuid {
    
    @InvocableMethod (label='Generate UUID' description='Generate random UUID' category = 'Flow utilities' iconName='slds:standard:custom_component_task')
    public static List<FlowOutputs> GenerateUuid() {
        UUID randomUuid = UUID.randomUUID();
        List<FlowOutputs> results = new List<FlowOutputs>();
        FlowOutputs returnDetails = new FlowOutputs();
        returnDetails.uuid = String.valueOf(UUID.randomUUID());
        results.add(returnDetails);         
        return results;        
    }
    
     public class FlowOutputs {
        @InvocableVariable (label='UUID' description='String to store UUID' required=true)
        public String uuid;
    }  
}
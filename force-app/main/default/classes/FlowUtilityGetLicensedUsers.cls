/**
 * This class exposes the licence class to flow so that a list of users with a licence can be retrieved.
 */
public with sharing class FlowUtilityGetLicensedUsers {
    
    // The inputs provided by the flow
    public class FlowInputs {
        @InvocableVariable(label='Licence developer name' description='The developer name of the licence you want the licenced users for' required=true)
        public String licenceDeveloperName;     
    }
    
    // The outputs returned to the flow
    public class FlowOutputs {
        @InvocableVariable(label='Licenced users' description='The users who are assigned the licenced' required=true)
        public List<User> licensedUsers;
    }
    
    // The invocable method exposed to the flow. This simply call another method to get the results, where the processing is done. 
    @InvocableMethod(label='Get licenced users' description = 'Pass in a licence developer and get back the licenced users' category = 'Flow utilities' iconName='slds:standard:custom_component_task')
    public static List<FlowOutputs> processRequests(List<FlowInputs> requests){
        List<FlowOutputs> results = getResults(requests);
        return results;
    }

    // Gets the users for each licence and constructs and returns the results
    private static List<FlowOutputs> getResults(List<FlowInputs> requests) {
        Set<String> licenceDeveloperNames = new Set<String>();
        for(FlowInputs request : requests){
            licenceDeveloperNames.add(request.licenceDeveloperName);
        }
        Map<String, List<User>> usersByLicence = Licence.getLicensedUsers(licenceDeveloperNames);
           
        // Construct the results
        List<FlowOutputs> results = new List<FlowOutputs>();
        for(FlowInputs request : requests){
            FlowOutputs result = new FlowOutputs();
            result.licensedUsers = usersByLicence.get(request.licenceDeveloperName);
            results.add(result);
        }
        return results;
    }
}
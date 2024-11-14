public with sharing class CustomerFactConflictEvaluation {
    
    @InvocableMethod
    public static List<FlowOutputs> evaluateConflicts(List<FlowInputs> requests){
        List<FlowOutputs> results = new List<FlowOutputs>();
        for (FlowInputs request : requests) {
            FlowOutputs result = new FlowOutputs();
            result.success = CustomerFactConflictOfInterestHandler.evaluateConflictOfInterest(request.accountList);
            results.add(result);
        }
        return results;
    }
    
    public class FlowInputs {
        @InvocableVariable
        public List<Account> accountList;
        
    }
    
    public class FlowOutputs {
        @InvocableVariable
        public Boolean success;
    }

}
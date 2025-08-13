public class FlowUtilityGetHouseholds {

    public class FlowInputs{
        @InvocableVariable(label='Household Ids' description='A list hosuehold Ids' required=true) 
        public List<String> houseHoldIds;
    }
    
    // The outputs returned to the flow
    public class FlowOutputs{  
        @InvocableVariable(label='Households' description='A list hosueholds' required=true) 
        public List<HouseholdRequest> households;

        @InvocableVariable(label='HouseholdsJson' description='Household list stringified' required=true) 
        public String householdsJson;
    }


    /**
     * @description This method can be called from a Flow. It takes a list of Account IDs.
     * @param householdIds A list of Account IDs provided by the Flow.
     * @return A list of wrapper objects ready for the LWC.
     */
    @InvocableMethod(label='Get Household Accounts by Ids' description='Returns account details for the datatable, including the dedicated specialist.')
    public static List<FlowOutputs> getAccounts(List<FlowInputs> flowInputs) {
        List<FlowOutputs> outputsList = new List<FlowOutputs>();
        Set<String> allHouseholdIds = new Set<String>();

        // Step 1: Collect all unique IDs from all inputs into a single Set for one efficient query.
        for (FlowInputs inputs : flowInputs) {
            if (inputs.houseHoldIds != null) {
                allHouseholdIds.addAll(inputs.houseHoldIds);
            }
        }

        // If there are no IDs to process, exit early.
        if (allHouseholdIds.isEmpty()) {
            // Still need to return an output for every input, so create empty outputs.
            for(FlowInputs inputs : flowInputs){
                 FlowOutputs output = new FlowOutputs();
                 output.households = new List<HouseholdRequest>();
                 outputsList.add(output);
            }
            return outputsList;
        }

        // Step 2: Query all required accounts in a single, bulk-safe query.
        Map<Id, Account> accountMap = new Map<Id, Account>([
            SELECT 
                Id, 
                Name, 
                OW_dedicated_specialist__r.Name, 
                FinServ__Status__c 
            FROM Account
            WHERE Id IN :allHouseholdIds
        ]);

        // Step 3: Iterate through the original inputs to build a corresponding output for each.
        for (FlowInputs inputs : flowInputs) {
            FlowOutputs output = new FlowOutputs();
            output.households = new List<HouseholdRequest>();

            if (inputs.houseHoldIds != null) {
                for (String accountId : inputs.houseHoldIds) {
                    // Find the queried account in our map
                    if (accountMap.containsKey(accountId)) {
                        Account acc = accountMap.get(accountId);
                        
                        // Create the wrapper and add it to the current output's list
                        HouseholdRequest wrapper = new HouseholdRequest();
                        wrapper.id = acc.Id;
                        wrapper.name = acc.Name;
                        wrapper.status = acc.FinServ__Status__c;
                        wrapper.specialistName = (acc.OW_dedicated_specialist__r != null) ? acc.OW_dedicated_specialist__r.Name : null;
                        
                        output.households.add(wrapper);
                    }
                }
            }
            if(output.households != null){
                output.householdsJson = JSON.serialize(output.households);
            }
            outputsList.add(output);
        }

        return outputsList;
    }
}
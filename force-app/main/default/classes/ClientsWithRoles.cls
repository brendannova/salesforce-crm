public class ClientsWithRoles {
    
    /**
    * TITLE:    Get clients with existing roles
    * GOAL:     Invoked from flow. Accepts a list of accounts and asset roles, checks if account id exists in any of the existing asset roles and returns the clients that are. 
    * NOTES:    
    **/
    
    @InvocableMethod (label='Get clients with existing roles' description='Iterate over clients in household and check which already have an asset role')
    public static List<OutputParams> getClientsWithRoles(List<InputParams> clientsToSort) {
        List<Account> clientsInHousehold = clientsToSort.get(0).clients;
        List<string> existingClientRoles = clientsToSort.get(0).Roles;
        List<id> clientRoleIds = new List<id>();
        for(string str : existingClientRoles) {
            clientRoleIds.add(Id.valueOf(str));
        }
        List<Account> returnClients = new List<Account>();
        
        for(Account ac : clientsInHousehold) {
            if(clientRoleIds.contains(ac.id)) {
                returnClients.add(ac);
            }
        }
        
       OutputParams accs = new OutputParams();
        accs.clientsWithRoles = returnClients;
        list<OutputParams> outputs = new List<OutputParams>();
        outputs.add(accs);
        return outputs;
    }
    
    
    
    public class InputParams {
        
        @InvocableVariable
        public list<Account> clients;
        
        @InvocableVariable
        public list<string> Roles;
    }
    
    public class OutputParams {
        
        @InvocableVariable
        public list<Account> clientsWithRoles;
    }
}
public with sharing class AccountHouseholdMembers {
    //should have a general constants class that stores reuable things like this
    public static final String ROLE_CLIENT = 'Client';
    public static final String ROLE_CHILD = 'Child';
    public static final String ROLE_OTHER_IMPORTANT_FAMILY_MEMBER = 'Other Important Family Member';
    public static final String ROLE_MORTGAGE_BORROWER = 'Mortgage Borrower';
    public static final String ROLE_SETTLOR = 'Settlor';
    public static final String ROLE_TRUSTEE = 'Trustee';
    public static final String ROLE_BENEFICIARY = 'Beneficiary';
    public static final String ROLE_EMPLOYEE = 'Employee';
    public static final String ROLE_DECEASED_CLIENT = 'Deceased Client';
    
    public HouseholdMemberResult getHouseholdMembers(HouseholdMemberRequest request) {
        List<HouseholdMemberRequest> requests = new List<HouseholdMemberRequest>();
        requests.add(request);
        return getHouseholdMembers(requests).get(request.householdId);
    }

    public Map<Id, HouseholdMemberResult> getHouseholdMembers(List<HouseholdMemberRequest> requests) {
        
        Set<Id> householdIds = new Set<Id>();
        Set<Id> accountIds = new Set<Id>();
        Map<Id, List<String>> householdRoleMap = new Map<Id, List<String>>();
        Map<Id, List<Boolean>> householdActiveMap = new Map<Id, List<Boolean>>();
        Map<Id, HouseholdMemberResult> results = new Map<Id, HouseholdMemberResult>();

        Map<Id, List<Id>> householdAccountMap = new Map<Id, List<Id>>();        // TBC
        List<List<Id>> householdAccountIds = new List<List<Id>>();              // TBC
    
        for (HouseholdMemberRequest request : requests) {
            householdIds.add(request.householdId);
        }

        Map<Id, Account> householdsMap = new Map<Id, Account>([SELECT Id, (SELECT Contact.AccountId, Contact.Account.Name, Contact.Account.AddressedName__pc, AccountId, Roles, IsActive FROM AccountContactRelations) FROM Account WHERE Id IN :householdIds]);

        
        for (HouseholdMemberRequest request : requests) {

            // Create the result the will be returned and define the key variables 
            HouseholdMemberResult result = new HouseholdMemberResult();
            result.household = householdsMap.get(request.householdId);
            result.memberAccountsByRole = new Map<String, List<Account>>();
            
            // Construct the details of the members we want to return
            for(String requestedRole : request.roles){
                result.memberAccountsByRole.put(requestedRole, new List<Account>());
            }

            // Loop the account contact relationships and build the map
            for (AccountContactRelation relation : result.household.AccountContactRelations) {
                
                Account memberAccount = new Account(
                    Id = relation.Contact.AccountId,
                    Name = relation.Contact.Account.Name
                    //AddressedName__pc = relation.Contact.Account.AddressedName__pc
                );
                    
                List<String> memberRoles = relation.Roles.split(';');
                for (String memberRole : memberRoles) {
                    if(result.memberAccountsByRole.containsKey(memberRole)){
                        result.memberAccountsByRole.get(memberRole).add(memberAccount);
                    }
                }                
            }
            results.put(request.householdId, result);
        }
        
        return results;
    }
    
    public class HouseholdMemberResult {
        public Account household;
        public Map<String, List<Account>> memberAccountsByRole;
        
    }

    public class HouseholdMemberRequest {
        public Id householdId;
        public Set<String> roles;
    }
}
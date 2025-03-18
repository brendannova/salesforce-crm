public with sharing class FlowUtilityGetHouseholdAccountIds {
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
    
    @InvocableMethod(label='Get Household Account IDs' description='Returns IDs of Accounts in the Household based on role type filters' category='Flow utilities')
    public static List<List<Id>> getHouseholdAccountIds(List<householdVars> filters) {
        
        Set<Id> householdIds = new Set<Id>();
        Map<Id, List<String>> householdRoleMap = new Map<Id, List<String>>();
        Map<Id, List<Boolean>> householdActiveMap = new Map<Id, List<Boolean>>();
        Map<Id, List<Id>> householdAccountMap = new Map<Id, List<Id>>();
        List<List<Id>> householdAccountIds = new List<List<Id>>(); //the return
        
        for (householdVars filter : filters) {
            householdIds.add(filter.householdId);
            List<String> roles = new List<String>();
            List<Boolean> selectedActive = new List<Boolean>();
            
            if (filter.includeClient) roles.add(ROLE_CLIENT);
            if (filter.includeChild) roles.add(ROLE_CHILD);
            if (filter.includeOtherImportantFamilyMember) roles.add(ROLE_OTHER_IMPORTANT_FAMILY_MEMBER);
            if (filter.includeMortgageBorrower) roles.add(ROLE_MORTGAGE_BORROWER);
            if (filter.includeSettlor) roles.add(ROLE_SETTLOR);
            if (filter.includeTrustee) roles.add(ROLE_TRUSTEE);
            if (filter.includeBeneficiary) roles.add(ROLE_BENEFICIARY);
            if (filter.includeEmployee) roles.add(ROLE_EMPLOYEE);
            if (filter.includeDeceasedClient) roles.add(ROLE_DECEASED_CLIENT);

            if (filter.includeActive) selectedActive.add(true);
            if (filter.includeInactive) selectedActive.add(false);
            
            householdRoleMap.put(filter.householdId, roles);
            householdActiveMap.put(filter.householdId, selectedActive);
        }
        
        if (!householdIds.isEmpty()) {
            for (AccountContactRelation relation : [
                SELECT Contact.AccountId, AccountId, Roles, isActive FROM AccountContactRelation
                WHERE AccountId IN :householdIds
            ]) {
                List<String> roles = householdRoleMap.get(relation.AccountId);
                List<Boolean> selectedActive = householdActiveMap.get(relation.AccountId);

                //Even if no results have to return no results for that id so correct ids get correct results
                if (!householdAccountMap.containsKey(relation.AccountId)) {
                    householdAccountMap.put(relation.AccountId, new List<Id>()); //invokable method does not support Set<Id> as a return type
                }

                if (roles.contains(relation.Roles) && selectedActive.contains(relation.isActive)) {
                    householdAccountMap.get(relation.AccountId).add(relation.Contact.AccountId);
                }
            }

            // Sorting householdAccountIds based on the order of householdIds
            for (Id householdId : householdIds) {
                if (householdAccountMap.containsKey(householdId)) {
                    List<Id> sortedAccountIds = new List<Id>(householdAccountMap.get(householdId));
                    sortedAccountIds.sort();
                    householdAccountIds.add(sortedAccountIds);
                }
            }
        }
        
        return householdAccountIds;
    }
    
    public class householdVars {
        @InvocableVariable(label='Household ID' description='The ID of the household' required=true)
        public Id householdId;
        
        @InvocableVariable(label='Include Clients' description='Include Clients' required=false)
        public Boolean includeClient = true;
        
        @InvocableVariable(label='Include Children' description='Include Children' required=false)
        public Boolean includeChild = false;
        
        @InvocableVariable(label='Include Other Important Family Members' description='Include Other Important Family Members' required=false)
        public Boolean includeOtherImportantFamilyMember = false;
        
        @InvocableVariable(label='Include Mortgage Borrowers' description='Include Mortgage Borrowers' required=false)
        public Boolean includeMortgageBorrower = false;
        
        @InvocableVariable(label='Include Settlors' description='Include Settlors' required=false)
        public Boolean includeSettlor = false;
        
        @InvocableVariable(label='Include Trustees' description='Include Trustees' required=false)
        public Boolean includeTrustee = false;
        
        @InvocableVariable(label='Include Beneficiaries' description='Include Beneficiaries' required=false)
        public Boolean includeBeneficiary = false;
        
        @InvocableVariable(label='Include Employees' description='Include Employees' required=false)
        public Boolean includeEmployee = false;
        
        @InvocableVariable(label='Include Deceased Clients' description='Include Deceased Clients' required=false)
        public Boolean includeDeceasedClient = false;

        @InvocableVariable(label='Include Active' description='Include Active Roles' required=false)
        public Boolean includeActive = true;

        @InvocableVariable(label='Include Inactive' description='Includes Active by default, also include roles that are inactive' required=false)
        public Boolean includeInactive = false;
    }
}
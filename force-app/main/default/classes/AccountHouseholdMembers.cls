/**
 * This class will return a data set containing a household record and a list of the people in each requested role.
 * It provides a single way to define who is in a household so that this is not being written each time. 
 * In addition to saving developers time, it gives us a central point of control over who will be returned. 
 * This allows us to expand this to focus on different use cases like who needs to accept recommentations, who can be emailed etc. 
 */
@SuppressWarnings('PMD.CognitiveComplexity, PMD.CyclomaticComplexity')
public with sharing class AccountHouseholdMembers {
    // Constants for each role the class supports. 
    public static final String ROLE_CLIENT = 'Client';
    public static final String ROLE_CHILD = 'Child';
    public static final String ROLE_OTHER_IMPORTANT_FAMILY_MEMBER = 'Other Important Family Member';
    public static final String ROLE_MORTGAGE_BORROWER = 'Mortgage Borrower';
    public static final String ROLE_SETTLOR = 'Settlor';
    public static final String ROLE_TRUSTEE = 'Trustee';
    public static final String ROLE_BENEFICIARY = 'Beneficiary';
    public static final String ROLE_EMPLOYEE = 'Employee';
    public static final String ROLE_DECEASED_CLIENT = 'Deceased Client';
    final private static String EMAIL_INCLUDE_TO = 'EMAIL_INCLUDE_TO';
    final private static String EMAIL_INCLUDE_CC = 'EMAIL_INCLUDE_CC';
    final private static String EMAIL_INCLUSION_TYPE_TO = 'TO';
    final private static String EMAIL_INCLUSION_TYPE_CC = 'CC';

    // A method that allows the information to be requested for a single household, simply converting into the bulk method
    public static HouseholdMemberResult getHouseholdMembers(HouseholdMemberRequest request) {
        List<HouseholdMemberRequest> requests = new List<HouseholdMemberRequest>();
        requests.add(request);
        return getHouseholdMembers(requests).get(request.householdId);
    }

    // A method that allows the information to be requested for multiple households
    public static Map<Id, HouseholdMemberResult> getHouseholdMembers(List<HouseholdMemberRequest> requests) {
        Set<Id> householdIds = new Set<Id>();
        Set<Id> memberIds = new Set<Id>();
        Map<Id, HouseholdMemberResult> results = new Map<Id, HouseholdMemberResult>();

        // Loop the requests to get all the household IDs
        for (HouseholdMemberRequest request : requests) {
            householdIds.add(request.householdId);
        }

        // Get all the households and cast them to a map, including the relationships for that households
        Map<Id, Account> householdsMap = new Map<Id, Account>(
            [SELECT 
                Id, 
                (SELECT Contact.AccountId, Roles, IsActive FROM AccountContactRelations), 
                (SELECT AdditionalRecipient__r.AccountId, MainRecipient__c, InclusionType__c FROM EmailInclusionRulesHousehold__r WHERE IsActive__c = true),
                OwnerId, Owner.Email 
            FROM 
                Account 
            WHERE 
                Id IN :householdIds
            ]);

        /**
         * Loop the relationships to get all the relationships then perform another query to get the individuals. 
         * A 2 query approach is needed here in all instances since we only start with the household IDs. 
         */
        for(Account household : householdsMap.values()){
            for(AccountContactRelation member : household.AccountContactRelations){
                memberIds.add(member.Contact.AccountId);
            }
            for(EmailInclusionRule__c member : household.EmailInclusionRulesHousehold__r ){
                memberIds.add(member.AdditionalRecipient__r.AccountId);
            }
        }
        Map<Id, Account> membersMap = new Map<Id, Account>([SELECT Id, PersonContactId, FirstName, LastName, AddressedName__pc, PersonEmail FROM Account WHERE Id IN :memberIds]);

        // Loop the requests to construct the results
        for (HouseholdMemberRequest request : requests) {

            // Create the result the will be returned and define the key variables 
            HouseholdMemberResult result = new HouseholdMemberResult();
            result.household = householdsMap.get(request.householdId);
            result.memberAccountsByRole = new Map<String, List<Account>>();

            // Construct the map for the list of each role requested
            for(String requestedRole : request.roles){
                result.memberAccountsByRole.put(requestedRole, new List<Account>());
            }

            // Loop the household's relationships and build the map
            for (AccountContactRelation relation : result.household.AccountContactRelations) {

                // Add a record of the member to the appropriate list for each role they hold, only if the role was requested
                List<String> memberRoles = relation.Roles.split(';');
                for (String memberRole : memberRoles) {
                    if(result.memberAccountsByRole.containsKey(memberRole)){
                        result.memberAccountsByRole.get(memberRole).add(membersMap.get(relation.Contact.AccountId));
                    }
                }
            }

            // Loop the household's email inclusion rules and build the map, only if the role was requested
            for (EmailInclusionRule__c rule : result.household.EmailInclusionRulesHousehold__r) {
                if( rule.InclusionType__c == EMAIL_INCLUSION_TYPE_TO && request.roles.contains(EMAIL_INCLUDE_TO)) {
                    result.memberAccountsByRole.get(EMAIL_INCLUDE_TO).add(membersMap.get(rule.AdditionalRecipient__r.AccountId));
                } else if ( rule.InclusionType__c == EMAIL_INCLUSION_TYPE_CC && request.roles.contains(EMAIL_INCLUDE_CC) ) {
                	result.memberAccountsByRole.get(EMAIL_INCLUDE_CC).add(membersMap.get(rule.AdditionalRecipient__r.AccountId));
                }
            }
            results.put(request.householdId, result);
        }
        return results;
    }

    // Class defining what the results look like
    public class HouseholdMemberResult {
        public Account household;
        public Map<String, List<Account>> memberAccountsByRole;
    }

    // Class defining what a request must contain
    public class HouseholdMemberRequest {
        public Id householdId;
        public Set<String> roles;
    }
}
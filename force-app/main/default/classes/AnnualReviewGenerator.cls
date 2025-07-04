/**
 * Kicks off the annual review process for households that need one based on status and proximity to the due date
 */
@SuppressWarnings('PMD.ApexCRUDViolation')
public without sharing class AnnualReviewGenerator{

    private final static String ACCOUNT_HOUSEHOLD_RECORD_TYPE_DEVELOPER_NAME = 'IndustriesHousehold';
    private final static String REVIEW_ANNUAL_RECORD_TYPE_DEVELOPER_NAME = 'OW_annual_review';
    private final static String ADVICE_ANNUAL_REVIEW_RECORD_TYPE_DEVELOPER_NAME = 'AnnualReview';
    private final static Id ACCOUNT_HOUSEHOLD_RECORD_TYPE_ID = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(ACCOUNT_HOUSEHOLD_RECORD_TYPE_DEVELOPER_NAME)?.getRecordTypeId();
    private final static Id REVIEW_ANNUAL_RECORD_TYPE_ID = Schema.SObjectType.OW_review__c.getRecordTypeInfosByDeveloperName().get(REVIEW_ANNUAL_RECORD_TYPE_DEVELOPER_NAME)?.getRecordTypeId();
    private final static Id ADVICE_ANNUAL_REVIEW_RECORD_TYPE_ID = Schema.SObjectType.Advice__c.getRecordTypeInfosByDeveloperName().get(ADVICE_ANNUAL_REVIEW_RECORD_TYPE_DEVELOPER_NAME)?.getRecordTypeId(); 
    private final static Date MAX_DATE = Date.today().addMonths(2).addDays(-1);
    private final static String STATUS_ACTIVE = 'Active';
    private final static String TYPE_EXECUTION_ONLY = 'Execution Only';
    private final static List<String> ADVICE_CONVERTIBLE_STATUSES = new List<String>{'Setup','Data gathering','Data analysis','Risk Call'};
    private final static List<String> ADVICE_CONVERTIBLE_TYPES = new List<String>{'AD_HOC','DRAWDOWN'};
    private final static String ADVICE_TYPE_ANNUAL_REVIEW = 'ANNUAL_REVIEW_ACCUMULATION';

    // The core method that retrieves the accounts and creates the annual review
    public static void createAnnualReviews(){

        // Find households that need an annual review
        List<Account> households = [
            SELECT
                Id, OwnerId, Name, FinServ__NextReview__c, OW_rtq_status__c, (SELECT Id FROM Advice__r WHERE Advice_Status__c IN :ADVICE_CONVERTIBLE_STATUSES AND AdviceType__r.DeveloperName__c IN :ADVICE_CONVERTIBLE_TYPES) FROM Account WHERE RecordType.DeveloperName = :ACCOUNT_HOUSEHOLD_RECORD_TYPE_DEVELOPER_NAME AND FinServ__Status__c = :STATUS_ACTIVE AND Type != :TYPE_EXECUTION_ONLY AND FinServ__NextReview__c <= :MAX_DATE
        ];

        // Get the members of the household
        AccountHouseholdMembers getMembers = new AccountHouseholdMembers();
        List<AccountHouseholdMembers.HouseholdMemberRequest> householdMemberRequests = new List<AccountHouseholdMembers.HouseholdMemberRequest>(); // Requests to get the clients that will need EGIs
        Set<String> roles = new Set<String>{'Client'};
        for (Account household : households) {
            AccountHouseholdMembers.HouseholdMemberRequest householdMemberRequest = new AccountHouseholdMembers.HouseholdMemberRequest();
            householdMemberRequest.householdId = household.Id;
            householdMemberRequest.roles = roles;
            householdMemberRequests.add(householdMemberRequest);
        }
        Map<Id, AccountHouseholdMembers.HouseholdMemberResult> householdMemberResults = getMembers.getHouseholdMembers(householdMemberRequests);

        // Create the lists we'll need for insert and update later on
        List<OW_review__c> annualReviews = new List<OW_review__c>();                                // The annual reviews for each household
        Map<Id, Advice__c> annualReviewAdviceMap = new Map<Id, Advice__c>();                        // The annual review advice for households that don't have any convertible advice in progress
        Map<External_Gains_Losses__c> egiMap = new Map<External_Gains_Losses__c>();         // The EGI records for each client in the households

        // Loop the households
        for (Account household : households) {
            String annualReviewYear = String.valueOf(household.FinServ__NextReview__c.year());

            // Push the household annual review date back 1 year
            household.FinServ__NextReview__c = Date.newInstance(household.FinServ__NextReview__c.year() + 1, household.FinServ__NextReview__c.month() + 1, 1).addDays(-1);

            // If there are no convertible advice, create the annual review advice
            if(household.Advice__r.isEmpty()){

                Advice__c advice = new Advice__c(
                    Advice_Household__c = household.Id,
                    Partner__c = household.OwnerId,
                    Name = 'Annual review ' + annualReviewYear,
                    Subject__c = 'Annual review ' + annualReviewYear,
                    RecordTypeId = ADVICE_ANNUAL_REVIEW_RECORD_TYPE_ID,
                    Advice_Status__c = 'Data gathering',
                    AdviceType__c = annualReviewAdviceTypeId,
                    New_or_existing_client__c = 'Existing'
                );

                // To do - define the link between the review and the advice. Will need to be done after insert.

                if(household.OW_rtq_status__c == 'Complete'){
                    advice.RtqStatus__c = 'No update required';
                } else if(household.OW_rtq_status__c == 'Pending'){
                    advice.RtqStatus__c = 'In progress';
                } else {
                    advice.RtqStatus__c = 'Not started';
                }
                annualReviewAdviceMap.put(household.Id, advice);
            }

            // Define the annual review 
            OW_review__c annualReview = new OW_review__c(
                OW_household__c = household.Id,
                OW_status__c = 'Prepare',
                OwnerId = household.OwnerId,
                RecordTypeId = REVIEW_ANNUAL_RECORD_TYPE_ID,
                Name = household.Name + ' - Annual review ' + annualReviewYear,
                OW_due_date__c = household.FinServ__NextReview__c
            );
            annualReviews.add(annualReview);

            for (Account client : householdMemberResults.get(household.Id).memberAccountsByRole.get('Client')){
                External_Gains_Losses__c egi = new External_Gains_Losses__c(
                    Name = client.FirstName + ' | ' + annualReviewYear,
                    Owner__c = client.Id,
                    Household__c = household.Id,
                    OW_stop_internal_change_processing__c = 1.0
                );
                egis.add(egi);
            }
        }
        
        try {
            insert annualReviews;
            insert egis;
            update households;
        } catch(DmlException e) {
            // To-do - handle exception
        }

        // To do - insert the advice
    }

    private static Id annualReviewAdviceTypeId{
        get{
            // to-do - handle no result, throw exception
            annualReviewAdviceTypeId = annualReviewAdviceTypeId == null ? [SELECT Id FROM AdviceType__c WHERE DeveloperName__c = :ADVICE_TYPE_ANNUAL_REVIEW].Id : annualReviewAdviceTypeId;
            return annualReviewAdviceTypeId;
        }
        set;
    }
}

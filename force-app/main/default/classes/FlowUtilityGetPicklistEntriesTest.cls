@isTest
private class FlowUtilityGetPicklistEntriesTest {
    
    final private static String OBJECT_API_NAME_ACCOUNT = 'Account';
    final private static String FIELD_ACCOUNT_INDUSTRY = 'Industry';
    final private static List<String> FIELD_ACCOUNT_INDUSTRY_VALUES = new List<String>{'Finance','Construction','Chemicals','Manufacturing'};
    final private static List<String> FIELD_ACCOUNT_INDUSTRY_LABELS_CUSTOM = FIELD_ACCOUNT_INDUSTRY_VALUES;
    final private static List<String> FIELD_ACCOUNT_INDUSTRY_LABELS_STANDARD = new List<String>{'Chemicals','Construction','Finance','Manufacturing'};
    
    private static FlowUtilityGetPicklistEntries.FlowInputs accountIndustryPicklistRequest {
        get{
            if(accountIndustryPicklistRequest == null){
                accountIndustryPicklistRequest = new FlowUtilityGetPicklistEntries.FlowInputs();
                accountIndustryPicklistRequest.sObjectType = OBJECT_API_NAME_ACCOUNT;
                accountIndustryPicklistRequest.field = FIELD_ACCOUNT_INDUSTRY;
                accountIndustryPicklistRequest.picklistValues = FIELD_ACCOUNT_INDUSTRY_VALUES;
            }
            return accountIndustryPicklistRequest;
        }
        set;
    }
    
    final private static String OBJECT_API_NAME_LEAD = 'Lead';
    final private static String FIELD_LEAD_LEAD_SOURCE = 'LeadSource';
    final private static List<String> FIELD_LEAD_LEAD_SOURCE_VALUES = new List<String>{'REFERRAL_CLIENT','YOUTUBE','REFERRAL_EMPLOYEE','DIGITAL_ADVERTISING'};
    final private static List<String> FIELD_LEAD_LEAD_SOURCE_LABELS_CUSTOM = new List<String>{'Referral | Client','YouTube','Referral | Employee','Digital Advertising'};
    final private static List<String> FIELD_LEAD_LEAD_SOURCE_LABELS_STANDARD = new List<String>{'Digital Advertising','Referral | Client','Referral | Employee','YouTube'};

    private static FlowUtilityGetPicklistEntries.FlowInputs leadLeadSourcePicklistRequest {
        get{
            if(leadLeadSourcePicklistRequest == null){
                leadLeadSourcePicklistRequest = new FlowUtilityGetPicklistEntries.FlowInputs();
                leadLeadSourcePicklistRequest.sObjectType = OBJECT_API_NAME_LEAD;
                leadLeadSourcePicklistRequest.field = FIELD_LEAD_LEAD_SOURCE;
                leadLeadSourcePicklistRequest.picklistValues = FIELD_LEAD_LEAD_SOURCE_VALUES;
            }
            return leadLeadSourcePicklistRequest;
        }
        set;
    }

    @isTest
    static void getPicklistEntriesCustomSort_success(){
        List<FlowUtilityGetPicklistEntries.FlowInputs> requests = new List<FlowUtilityGetPicklistEntries.FlowInputs>();
        System.debug(accountIndustryPicklistRequest);
        accountIndustryPicklistRequest.customSort = true;
        requests.add(accountIndustryPicklistRequest);
        leadLeadSourcePicklistRequest.customSort = true;
        requests.add(leadLeadSourcePicklistRequest);

        List<List<String>> labels = new List<List<String>>();
        labels.add(FIELD_ACCOUNT_INDUSTRY_LABELS_CUSTOM);
        labels.add(FIELD_LEAD_LEAD_SOURCE_LABELS_CUSTOM);

        List<FlowUtilityGetPicklistEntries.FlowOutputs> results = FlowUtilityGetPicklistEntries.processRequests(requests);
        System.assertEquals(requests.size(), results.size(), 'Unexpected number of results');
        Integer i = 0;
        for(FlowUtilityGetPicklistEntries.FlowOutputs result : results){
            Integer j = 0;
            for (FlowUtilityPicklistEntry picklistEntry : result.picklistEntries) {
                System.assertEquals(labels[i][j], picklistEntry.label, 'Label returned does not match');
                System.debug(labels[i][j] + ' | ' + picklistEntry);
                j++;
            }
            i++;
        }
    }

    @isTest
    static void getPicklistEntriesStandardSort_success(){
        List<FlowUtilityGetPicklistEntries.FlowInputs> requests = new List<FlowUtilityGetPicklistEntries.FlowInputs>();
        accountIndustryPicklistRequest.customSort = false;
        requests.add(accountIndustryPicklistRequest);
        leadLeadSourcePicklistRequest.customSort = false;
        requests.add(leadLeadSourcePicklistRequest);

        List<List<String>> labels = new List<List<String>>();
        labels.add(FIELD_ACCOUNT_INDUSTRY_LABELS_STANDARD);
        labels.add(FIELD_LEAD_LEAD_SOURCE_LABELS_STANDARD);

        List<FlowUtilityGetPicklistEntries.FlowOutputs> results = FlowUtilityGetPicklistEntries.processRequests(requests);
        System.assertEquals(requests.size(), results.size(), 'Unexpected number of results');
        Integer i = 0;
        for(FlowUtilityGetPicklistEntries.FlowOutputs result : results){
            Integer j = 0;
            for (FlowUtilityPicklistEntry picklistEntry : result.picklistEntries) {
                System.assertEquals(labels[i][j], picklistEntry.label, 'Label returned does not match');
                System.debug(labels[i][j] + ' | ' + picklistEntry);
                j++;
            }
            i++;
        }
    }
}
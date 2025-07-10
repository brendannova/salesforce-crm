/**
 * This class can be used for test purposes only in test classes or in seeing configuration data. 
 * It can create advice records against a specified household.
 */
public without sharing class DataFactoryAdvice {

    private final static String ADVICE_GENERIC_RECORD_TYPE_DEVELOPER_NAME = 'Advice_RT_General_Advice';
    private final static String ADVICE_TOP_UP_RECORD_TYPE_DEVELOPER_NAME = 'TopUp';
    private final static Id ADVICE_GENERIC_RECORD_TYPE_ID = Schema.SObjectType.Advice__c.getRecordTypeInfosByDeveloperName().get(ADVICE_GENERIC_RECORD_TYPE_DEVELOPER_NAME).getRecordTypeId();
    private final static Id ADVICE_TOP_UP_RECORD_TYPE_ID = Schema.SObjectType.Advice__c.getRecordTypeInfosByDeveloperName().get(ADVICE_TOP_UP_RECORD_TYPE_DEVELOPER_NAME).getRecordTypeId();

    // Creates ad-hoc advice
    public static Advice__c createAdHocAdvice(Id householdId){
        Advice__c advice = new Advice__c(
            Advice_Household__c = householdId,
            RecordTypeId = ADVICE_GENERIC_RECORD_TYPE_ID,
            New_or_existing_client__c = 'Existing',
            Partner__c = [ SELECT Id FROM User WHERE Id = :UserInfo.getUserId() ].Id,
            Fact_find_requirements__c = 'Not required',
            G_Drive_Advice_Folder__c = 'google.com',
            Update_valuations__c = 'No',
            New_LOAs_required__c = 'No', 
            Advice_Status__c = 'Data Gathering',
            Subject__c = 'Test advice',
            Name = 'Test advice',
            FulfilmentUpdateStatus__c = 'Receiving updates',
            AdviceType__c = [SELECT Id FROM AdviceType__c WHERE DeveloperName__c = 'AD_HOC' ].Id
        );
        insert advice;
        System.debug(advice);
        return advice;
    }   
}
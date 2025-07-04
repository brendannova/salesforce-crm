@isTest
private with sharing class DataFactoryConfigurationDataTest {

    @isTest
    private static void testConfigurationDataLoad(){
        DataFactoryConfigurationData.load();
        List<AdviceType__c> adviceTypes = [SELECT Id FROM AdviceType__c];
        List<OW_task_information__c> taskInformationRecords = [SELECT Id FROM OW_task_information__c];
        System.assert(!adviceTypes.isEmpty(), 'Advice types are empty');
        System.assert(!taskInformationRecords.isEmpty(), 'Advice types are empty');
    }
}
public with sharing class DataFactoryConfigurationData {
    public static void loadConfigurationData() {
        List<sObject> adviceTypes = Test.loadData(AdviceType__c.sObjectType, 'AdviceType');
    }
}
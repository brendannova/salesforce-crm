public with sharing class DataFactoryConfigurationData {
    public static void load() {
        List<sObject> adviceTypes = Test.loadData(AdviceType__c.sObjectType, 'AdviceType');
    }
}

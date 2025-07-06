/**
 * This class can be used for test purposes only. 
 * It will load configuration data with the Test.loadData method.
 * The configuration data is loaded from static resource csv files for each object. 
 * This only supports the simpler configuration data objects without relationships right now. 
 * It should expanded to support the others once we can easily transform our files in config-data to the appropriate format as part of our CI/CD pipeline.
 */
public without sharing class DataFactoryConfigurationData {
    
    // The currently supported configuration data objects. 
    public static final List<String> VALID_CONFIG_DATA_TEST_OBJECTS = new List<String>{
        'AdviceType__c',
        'AdviceTypeStatus__c',
        'AssetType__c',
        'EmailConfiguration__c',
        'FactCategory__c',
        'InformationRequestType__c',
        'Public_Provider_Names__c',
        'RecommendationType__c',
        'LiabilityType__c'
    };

    // The method that loads the configuration data. This is somewhat messy at this stage but is being left to allow expansion. 
    public static void load() {
        List<sObject> configData01 = Test.loadData(AdviceType__c.sObjectType, 'AdviceType');
        List<sObject> configData04 = Test.loadData(AdviceTypeStatus__c.sObjectType, 'AdviceTypeStatus');
        List<sObject> configData05 = Test.loadData(AssetType__c.sObjectType, 'AssetType');
        List<sObject> configData06 = Test.loadData(EmailConfiguration__c.sObjectType, 'EmailConfiguration');
        List<sObject> configData08 = Test.loadData(FactCategory__c.sObjectType, 'FactCategory');
        List<sObject> configData13 = Test.loadData(InformationRequestType__c.sObjectType, 'InformationRequestType');
        List<sObject> configData16 = Test.loadData(Public_Provider_Names__c.sObjectType, 'Public_Provider_Names');
        List<sObject> configData17 = Test.loadData(RecommendationType__c.sObjectType, 'RecommendationType');
        List<sObject> configData18 = Test.loadData(LiabilityType__c.sObjectType, 'LiabilityType');
		
        // The following can be made to work bug the static resource files will need some work
        //List<sObject> configData02 = Test.loadData(OW_task_information__c.sObjectType, 'OW_task_information');
        //List<sObject> configData03 = Test.loadData(AdviceTypeRecommendation__c.sObjectType, 'AdviceTypeRecommendation');
        //List<sObject> configData07 = Test.loadData(Fact__c.sObjectType, 'Fact');
        //List<sObject> configData09 = Test.loadData(FeeModel__c.sObjectType, 'FeeModel');
        //List<sObject> configData10 = Test.loadData(FinancialProductType__c.sObjectType, 'FinancialProductType');
        //List<sObject> configData11 = Test.loadData(FulfilmentType__c.sObjectType, 'FulfilmentType');
        //List<sObject> configData12 = Test.loadData(FulfilmentTypeStatus__c.sObjectType, 'FulfilmentTypeStatus');
        //List<sObject> configData14 = Test.loadData(Product__c.sObjectType, 'Product');
        //List<sObject> configData15 = Test.loadData(ProductType__c.sObjectType, 'ProductType');
    }
}
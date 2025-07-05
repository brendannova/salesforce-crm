@isTest
public without sharing class DataFactoryConfigurationDataTest {

    @testSetup static void setup() {
		DataFactoryConfigurationData.load();        
    }

    @isTest
    static void testAnnualReviewScheduler() {
        for(String objectApiName : DataFactoryConfigurationData.VALID_CONFIG_DATA_TEST_OBJECTS){
        	List<sObject> configurationDataRecords = Database.query('SELECT Id FROM ' + objectApiName);
            System.assert(!configurationDataRecords.isEmpty(), 'No configuration data records found for ' + objectApiName);
        }
    }
}

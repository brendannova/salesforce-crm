/**
 * Test class to ensure all supported configuration data loads in our data factory.
 */
@isTest
public without sharing class DataFactoryConfigurationDataTest {

    @testSetup
    static void setup() {
		DataFactoryConfigurationData.load();        
    }

    // Loop each configuration data object and ensure we have rows. No specific checks performed as we don't know how the files might evolve. 
    @isTest
    static void loadConfigurationData_success() {
        for(String objectApiName : DataFactoryConfigurationData.VALID_CONFIG_DATA_TEST_OBJECTS){
        	List<sObject> configurationDataRecords = Database.query('SELECT Id FROM ' + objectApiName);
            System.assert(!configurationDataRecords.isEmpty(), 'No configuration data records found for ' + objectApiName);
        }
    }
}

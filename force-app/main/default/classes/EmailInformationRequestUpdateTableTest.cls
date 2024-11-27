@isTest(SeeAllData=true)
public class EmailInformationRequestUpdateTableTest {
        
    @istest
    static void test_table_data(){
        // Define and create test data for 2 clients and 2 children
        Integer numClients = 2;
        Integer numChildren = 2;
        String household_status = 'Active';
        String household_identifier = '2clients2child'; 
        String profile_type = 'Full'; 
        fake_data_factory_v2 fdf = new fake_data_factory_v2();
        Id household_id = fdf.create_household(household_identifier, numClients, numChildren, household_status, profile_type);
        Advice__c advice = fdf.create_advice(household_identifier, 4, household_id);
        
        // Call the classes to run the code and ensure everything generates
        EmailInformationRequestUpdateTable updateTest = new EmailInformationRequestUpdateTable();
        updateTest.objectId = household_id;
        System.debug(updateTest.objectId);
        updateTest.getOwners();
        updateTest.getOutputs();
        System.assertEquals(updateTest.outputs.size(), 3);
    } 
    
    @istest
    static void test_table_data_solo(){
        // Define and create test data for 1 client
        Integer numClients = 1;
        Integer numChildren = 0;
        String household_status = 'Active';
        String household_identifier = '1client'; 
        String profile_type = 'Full'; 
        fake_data_factory_v2 fdf = new fake_data_factory_v2();
        Id household_id = fdf.create_household(household_identifier, numClients, numChildren, household_status, profile_type);
        Advice__c advice = fdf.create_advice(household_identifier, 2, household_id);
        
        // Call the classes to run the code and ensure everything generates
        EmailInformationRequestUpdateTable updateTest = new EmailInformationRequestUpdateTable();
        updateTest.objectId = household_id;
        System.debug(updateTest.objectId);
        updateTest.getOwners();
        updateTest.getOutputs();
        System.assertEquals(updateTest.outputs.size(), 1); 
    } 
    
    @istest
    static void test_table_data_3_person(){
        // Define and create test data for 4 clients
        Integer numClients = 4;
        Integer numChildren = 0;
        String household_status = 'Active';
        String household_identifier = '4clients'; 
        String profile_type = 'Full'; 
        fake_data_factory_v2 fdf = new fake_data_factory_v2();
        Id household_id = fdf.create_household(household_identifier, numClients, numChildren, household_status, profile_type);
        Advice__c advice = fdf.create_advice(household_identifier, 5, household_id);
        
        // Call the classes to run the code and ensure everything generates
        EmailInformationRequestUpdateTable updateTest = new EmailInformationRequestUpdateTable();
        updateTest.objectId = household_id;
        System.debug(updateTest.objectId);
        updateTest.getOwners();
        updateTest.getOutputs();
        System.assertEquals(updateTest.outputs.size(), 5); 
    } 

}
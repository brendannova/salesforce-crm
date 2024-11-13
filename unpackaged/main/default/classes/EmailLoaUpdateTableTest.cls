@isTest(SeeAllData=true)
global class EmailLoaUpdateTableTest{
    
    @istest
    static void test_table_data(){
        // Define and create test data for 2 clients and 2 children
        Integer numClients = 2;
        Integer numChildren = 2;
        String household_status = 'Active';
        String household_identifier = '2clients2child'; 
        String profile_type = 'Full'; 
        fake_data_factory fdf = new fake_data_factory();
        Id household_id = fdf.create_household(household_identifier, numClients, numChildren, household_status, profile_type);
        Advice__c advice = fdf.create_advice(household_identifier, 2, household_id);
        
        // Call the classes to run the code and ensure everything generates
        system.currentPageReference().getParameters().put('adviceId', advice.Id); 
        EmailLoaUpdateTable GetInfo = new EmailLoaUpdateTable();
        GetInfo.getOwners();    
        GetInfo.getOwner_loa_map();
        System.assertEquals(GetInfo.adviceId, advice.Id); 
    } 
    
    @istest
    static void test_table_data_solo(){
        // Define and create test data for 1 client
        Integer numClients = 1;
        Integer numChildren = 0;
        String household_status = 'Active';
        String household_identifier = '1client'; 
        String profile_type = 'Full'; 
        fake_data_factory fdf = new fake_data_factory();
        Id household_id = fdf.create_household(household_identifier, numClients, numChildren, household_status, profile_type);
        Advice__c advice = fdf.create_advice(household_identifier, 2, household_id);
        
        // Call the classes to run the code and ensure everything generates
        system.currentPageReference().getParameters().put('adviceId', advice.Id); 
        EmailLoaUpdateTable GetInfo = new EmailLoaUpdateTable();
        GetInfo.getOwners();    
        GetInfo.getOwner_loa_map();
        System.assertEquals(GetInfo.adviceId, advice.Id); 
    } 
    
    @istest
    static void test_table_data_3_person(){
        // Define and create test data for 3 clients
        Integer numClients = 3;
        Integer numChildren = 0;
        String household_status = 'Active';
        String household_identifier = '3clients'; 
        String profile_type = 'Full'; 
        fake_data_factory fdf = new fake_data_factory();
        Id household_id = fdf.create_household(household_identifier, numClients, numChildren, household_status, profile_type);
        Advice__c advice = fdf.create_advice(household_identifier, 2, household_id);
        
        // Call the classes to run the code and ensure everything generates
        system.currentPageReference().getParameters().put('adviceId', advice.Id); 
        EmailLoaUpdateTable GetInfo = new EmailLoaUpdateTable();
        GetInfo.getOwners();    
        GetInfo.getOwner_loa_map();
        System.assertEquals(GetInfo.adviceId, advice.Id); 
    } 
}
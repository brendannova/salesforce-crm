@isTest
private class OW_update_io_id_test {
    
    @isTest static void test_callout_success() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new MockHTTPResponseGenerator(200));
        
        // Set a fake customer ID
        String PersonRecordTypeDevName = 'PersonAccount';
        Account customer = new Account(
            FirstName = 'Test',
            LastName = 'Client',
            RecordtypeId = '0121t000000vGIzAAM',
            Intelligent_Office_ID__c = '1231441241'
        );
        insert customer;
        List<List<Account>> customers = new List<List<Account>>{
            new List<Account>{customer}
        };
        
        // Make the call to request the profile account using the fake customer ID 
        OW_update_io_id.process_accounts(customers);
    } 
    
    // This is method is as above but testing an error response from the API
    @isTest static void test_callout_failure() {
        
        Test.setMock(HttpCalloutMock.class, new MockHTTPResponseGenerator(401));
        String PersonRecordTypeDevName = 'PersonAccount';
        Account customer = new Account(
            FirstName = 'Test',
            LastName = 'Client',
            RecordtypeId = '0121t000000vGIzAAM',
            Intelligent_Office_ID__c = '1231441241'
        );
        insert customer;
        List<List<Account>> customers = new List<List<Account>>{
            new List<Account>{customer}
        };
        OW_update_io_id.process_accounts(customers);
    } 
    
}
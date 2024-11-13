@isTest
private class RequestRTQEmailsTest {
    
    @isTest static void testPostCalloutSuccess() {        
        
        String PersonRecordTypeDevName = 'PersonAccount';
        Id PersonRecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get(PersonRecordTypeDevName).getRecordTypeId();
        Account a = new Account(LastName = 'OM Client', RecordTypeId = PersonRecordTypeId);
        insert a;
        
        Account b = new Account(LastName = 'Nova Client', RecordTypeId = PersonRecordTypeId);
        insert b;
        
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new RequestRTQEmailsSuccessHttpCalloutMock());
        
        // Construct a list of fake customer IDs to submit
        List<List<String>> customerIds = new List<List<String>>{ 
            new List<String>{a.Id, b.Id} 
        };
            
            // Submit the fake customer IDs to the class and receive the success response from the HttpCalloutMock
            RequestRTQEmails.processCustomerList(customerIds);
        
    } 
    
	// This is method is as above but testing an error response from the API
    @isTest static void testPostCalloutFailure() {
        
        Test.setMock(HttpCalloutMock.class, new RequestRTQEmailsFailureHttpCalloutMock());
        
        List<List<String>> customerIds = new List<List<String>>{ 
            new List<String>{'123', '456', '789'}
        };        
            
            RequestRTQEmails.processCustomerList(customerIds);
    } 
}
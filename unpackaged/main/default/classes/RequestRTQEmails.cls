public class RequestRTQEmails {
    // This class manages the outbound HTTP request to a portal API that handles the sending of RTQ emails to customers
    // The class contains an invocable method to allow it to be called as part of a flow
    // It also contains a future method so the requests are made asynchronously and can be made after the creation of RTQ records (a DML statement)
    
    //The invocable method - this takes a list of customers IDs from a flow and loops through them, calling the future method for each
    @InvocableMethod(label = 'Request RTQ emails' description = 'Given a list of customers to whom emails should be sent, this method will loop through them and make the callout requesting the RTQ emails.' category = 'RTQ')
    public static void processCustomerList(List<List<String>> customerIds) {
            
    	String namedCred;
    	for(Account a : [SELECT id, groupCompany__c FROM Account WHERE id =: (List<String>)customerIds[0]]) {
        	if(a.groupCompany__c == 'OM') {
            	namedCred = 'OctopusMoneyPortal';
        	} else {
            	namedCred = 'OW_portal';
        	}
        	makePostCalloutWithNamedCred(a.Id, namedCred);
    	}
        
        /* // Debug line to check that IDs are being received: System.debug('Customer IDs received: ' + customerIds);
for(String customerId : (List<String>)customerIds[0]){

// Debug line to check which customer ID is received: System.debug('In loop, customer Id = ' + customerId);
makePostCallout(customerId);
} */     
    } 
    
    //The future method - this takes a single customer ID and makes a call to the portal API asking that the RTQ email is sent
    @future(callout=true)
    public static void makePostCalloutWithNamedCred(String customerId, String namedCred){
        
        // Debug line to check that IDs are being received: System.debug('In the callout method, customer ID = ' + customerId);
        //Initiate the call
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        //Construct the call
        request.setEndpoint('callout:' + namedCred + '/v0/jobs/send-rtq/');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json');
        request.setBody('{"record_id": "' + customerId + '"}'); 
        
        //Make the call
        HttpResponse response = http.send(request);
        
        // Log the outcome for monitoring purposes
        if (response.getStatusCode() != 200) {
            OW_system_log__c systemLog = new OW_system_log__c(OW_log_type__c = 'RTQ Email Request', OW_log_source__c = 'RequestRTQEmails', OW_source_type__c = 'Apex Class', OW_detail__c = 'Error requesting that an RTQ email is sent for customer ID '+ customerId, OW_response_code__c = response.getStatusCode(), OW_status__c = response.getStatus(), OW_error__c = true);
            insert systemLog;
        } else {
            OW_system_log__c systemLog = new OW_system_log__c(OW_log_type__c = 'RTQ Email Request',  OW_log_source__c = 'RequestRTQEmails', OW_source_type__c = 'Apex Class', OW_detail__c = 'RTQ email successfully requested for customer ID '+ customerId, OW_response_code__c = response.getStatusCode(), OW_status__c = response.getStatus(), OW_error__c = false);
            insert systemLog;
        }
    }
    
}
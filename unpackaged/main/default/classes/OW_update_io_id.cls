public class OW_update_io_id {
    // This class manages the outbound HTTP request to a portal API to let it know of a change to the IO ID of a customer
    // The class contains an invocable method to allow it to be called as part of a flow
    // It also contains a future method so the requests are made asynchronously and can be made after the update of customer records (a DML statement)
    
    //The invocable method - this takes a list of customers IDs from a flow and loops through them, calling the future method for each
    @InvocableMethod(label = 'Sync IO ID to portal' description = 'Given a list of customer accounts, make a callout to a portal endpoint to update the IO ID.' category = 'OW portal')
    public static void process_accounts(List<List<Account>> accounts) {
        
        for(Account account : (List<Account>)accounts[0]){
            make_callout(account.Id, account.Intelligent_Office_ID__c);
        }      
    }
    
    //The future method - this takes a single customer ID and makes a call to the portal API asking that the RTQ email is sent
    @future(callout=true)
    public static void make_callout(Id customer_id, String io_id){
        
        // Debug line to check that IDs are being received: System.debug('In the callout method, customer ID = ' + customerId);
        //Initiate the call
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        
        //Construct the call
        request.setEndpoint('callout:OW_portal/v0/jobs/update-io-id/');
        request.setMethod('PUT');
        request.setHeader('Content-Type', 'application/json');
        request.setBody('{"record_id": "' + customer_id + '", "io_id": "' + io_id + '"}'); 
        
        //Make the call
        HttpResponse response = http.send(request);
        
        // Log the outcome for monitoring purposes
        if (response.getStatusCode() != 200) {
            OW_system_log__c systemLog = new OW_system_log__c(OW_log_type__c = 'Update IO ID request', OW_log_source__c = 'UpdateIOID', OW_source_type__c = 'Apex Class', OW_detail__c = 'Error requesting IO ID update for '+ customer_id, OW_response_code__c = response.getStatusCode(), OW_status__c = response.getStatus(), OW_error__c = true);
            insert systemLog;
        } else {
            OW_system_log__c systemLog = new OW_system_log__c(OW_log_type__c = 'Update IO ID request',  OW_log_source__c = 'UpdateIOID', OW_source_type__c = 'Apex Class', OW_detail__c = 'Request to update IO ID in the portal made successfully for  '+ customer_id, OW_response_code__c = response.getStatusCode(), OW_status__c = response.getStatus(), OW_error__c = false);
            insert systemLog;
        }
    }
}
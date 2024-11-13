public class SendTermsController {
    
    @AuraEnabled
    public static Integer makePostCallout(String recordId) {
        String namedCred;
        for(Account a : [SELECT id, groupCompany__c FROM Account WHERE id =: recordId]) {
            if(a.groupCompany__c == 'OM') {
                namedCred = 'OctopusMoneyPortal';
            } else {
                namedCred = 'OW_portal';
            }
        }
        
        Integer responseCode = SendTermsController.makeCallout(recordId, namedCred);
        return responseCode;
        
    }
    
    public static Integer makeCallout (String recordId, String namedCred){
        Http http = new Http();
        HttpRequest request = new HttpRequest();
        request.setEndpoint('callout:' + namedCred + '/v0/jobs/accept-terms/');
        request.setMethod('POST');
        request.setHeader('Content-Type', 'application/json;charset=UTF-8');
        request.setBody('{"record_id": "' + recordId + '"}');
        HttpResponse response = http.send(request);
        // Parse the JSON response
        if (response.getStatusCode() != 201) {
            System.debug('The status code returned was not expected: ' +
                         response.getStatusCode() + ' ' + response.getStatus());
        } else {
            System.debug(response.getBody());
        }
        return response.getStatusCode();
    }
    
    
    @InvocableMethod(label = 'Send terms of business' description = 'Send terms of business' category = 'TOB')
    public static List<FlowOutputs> invokeThisMethod(List<FlowInputs> requests){
        List<FlowOutputs> results = new List<FlowOutputs>();
        for (FlowInputs request : requests) {
            results.add(invokeLocalMethod(request));
        }
        return results;
    }
    
    public static FlowOutputs invokeLocalMethod(FlowInputs request){        
        FlowOutputs returnDetails = new FlowOutputs();
        String personAccountId = request.personAccountId;
        Integer responseCode = SendTermsController.makePostCallout(personAccountId);
        Boolean success;
        if (responseCode != 201) {
            success = false;
        } else {
            success = true;
        }
        returnDetails.success = success;
        return returnDetails;
    }
    
    // Inputs to this class coming from a flow
    public class FlowInputs{
        
        @InvocableVariable
        public String personAccountId;
        
    }
    
    //output details which goes from apex to process builder
    public class FlowOutputs{
        
        @InvocableVariable
        public Boolean success;
    }
}
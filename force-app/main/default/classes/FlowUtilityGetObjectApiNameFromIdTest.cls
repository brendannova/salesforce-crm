@isTest
private class FlowUtilityGetObjectApiNameFromIdTest {
    
    @isTest
    static void getObjectFromRecordTest(){
        
        List<FlowUtilityGetObjectApiNameFromId.FlowInputs> requests = new List<FlowUtilityGetObjectApiNameFromId.FlowInputs>();
        Account testAccount = new Account(
            Name = 'Test Account'
        );
        insert testAccount;

        FlowUtilityGetObjectApiNameFromId.FlowInputs request = new FlowUtilityGetObjectApiNameFromId.FlowInputs();
        request.recordId = testAccount.Id;
        requests.add(request);

        Lead testLead = new Lead(
            FirstName = 'Test',
            LastName = 'Test'
        );
        insert testLead;

        request = new FlowUtilityGetObjectApiNameFromId.FlowInputs();
        request.recordId = testLead.Id;
        requests.add(request);
        
        List<FlowUtilityGetObjectApiNameFromId.FlowOutputs> results = FlowUtilityGetObjectApiNameFromId.processRequests(requests);
        System.debug(requests);
        System.debug(results);
        System.assertEquals(requests.size(), results.size(), 'Differing numbers of requests and results');
        System.assertEquals('Account', results[0].objectApiName, 'Expected Account but got ' + results[0].objectApiName);
        System.assertEquals('Lead', results[1].objectApiName, 'Expected Lead but got ' + results[1].objectApiName);
    }

}
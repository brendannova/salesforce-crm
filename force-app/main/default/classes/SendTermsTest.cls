@isTest
private class SendTermsTest {
    
    @isTest
    static void testPostCalloutSuccess() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new MockHTTPResponseGenerator(201)); 
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock.
        Integer responseStatusCode = SendTermsController.makeCallout('abc', 'OW_portal');
        System.assertEquals(201, responseStatusCode);
    }
    
    @isTest
    static void testPostCalloutError() {
        // Set mock callout class 
        Test.setMock(HttpCalloutMock.class, new MockHTTPResponseGenerator(401)); 
        // This causes a fake response to be sent
        // from the class that implements HttpCalloutMock.
        Integer responseStatusCode = SendTermsController.makeCallout('abc', 'OM_Portal');
        System.assertEquals(401, responseStatusCode);
    }
    
    @isTest
    static void testInvocablePostCalloutSuccess() {
        List<sendTermsController.FlowInputs> FlowInputs = new List<sendTermsController.FlowInputs>();
        sendTermsController.FlowInputs FlowInput = new sendTermsController.FlowInputs();
        FlowInput.personAccountId = 'fakeId';
        FlowInputs.add(FlowInput);
        Test.setMock(HttpCalloutMock.class, new MockHTTPResponseGenerator(201));
        sendTermsController.invokeThisMethod(FlowInputs);
    }
    
	@isTest
    static void testInvocablePostCalloutError() {
        List<sendTermsController.FlowInputs> FlowInputs = new List<sendTermsController.FlowInputs>();
        sendTermsController.FlowInputs FlowInput = new sendTermsController.FlowInputs();
        FlowInput.personAccountId = 'fakeId';
        FlowInputs.add(FlowInput);
        Test.setMock(HttpCalloutMock.class, new MockHTTPResponseGenerator(401));
        sendTermsController.invokeThisMethod(FlowInputs);
    }
    
}
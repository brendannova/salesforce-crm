@isTest
private class FlowHelperTermsOfBusinessSendTest {
    
    @isTest
    static void testInvocablePostCallout_Success() {
        List<FlowHelperTermsOfBusinessSend.FlowInputs> FlowInputs = new List<FlowHelperTermsOfBusinessSend.FlowInputs>();
        FlowHelperTermsOfBusinessSend.FlowInputs FlowInput = new FlowHelperTermsOfBusinessSend.FlowInputs();
        FlowInput.accountId = 'fakeId';
        FlowInputs.add(FlowInput);
        Test.setMock(HttpCalloutMock.class, new MockHTTPResponseGenerator(201));
        FlowHelperTermsOfBusinessSend.processRequests(FlowInputs);
    }
    
	@isTest
    static void testInvocablePostCallout_Failure() {
        List<FlowHelperTermsOfBusinessSend.FlowInputs> FlowInputs = new List<FlowHelperTermsOfBusinessSend.FlowInputs>();
        FlowHelperTermsOfBusinessSend.FlowInputs FlowInput = new FlowHelperTermsOfBusinessSend.FlowInputs();
        FlowInput.accountId = 'fakeId';
        FlowInputs.add(FlowInput);
        Test.setMock(HttpCalloutMock.class, new MockHTTPResponseGenerator(401));
        FlowHelperTermsOfBusinessSend.processRequests(FlowInputs);
    }
    
}
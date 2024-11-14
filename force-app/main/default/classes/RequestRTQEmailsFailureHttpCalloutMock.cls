@isTest
global class RequestRTQEmailsFailureHttpCalloutMock implements HttpCalloutMock {

    global HTTPResponse respond(HTTPRequest request) {
        // Create a fake error response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setStatusCode(500);
        return response;
    } 
}
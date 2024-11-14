@istest
global class MockHTTPResponseGenerator implements HttpCalloutMock {
    Integer statusCode;
    global MockHTTPResponseGenerator(Integer strStatusCode){
        statusCode = strStatusCode;
    }
    
    // Implement this interface method
    global HTTPResponse respond(HTTPRequest request) {
        // Create a fake response
        HttpResponse response = new HttpResponse();
        response.setHeader('Content-Type', 'application/json');
        response.setStatusCode(statusCode);
        
        if(statusCode == 200){
            //set response
        } else if(statusCode == 201){
            //set response
        } else {
            // set response
        }
        return response;
    }
}
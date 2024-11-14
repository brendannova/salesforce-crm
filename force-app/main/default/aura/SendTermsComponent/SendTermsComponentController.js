({
	sendTermsRequest : function(component, event) {
        var action = component.get("c.makePostCallout");
        action.setParams({
            recordId: component.get("v.recordId")
        });
        action.setCallback(this, function(response){
          var state = response.getState();
          var statusCode = response.getReturnValue();
          var resultToast = $A.get("e.force:showToast");
          if (state === "SUCCESS") {
              console.log("Status code: " + response.getReturnValue())
              
              if (statusCode === 201) {
                resultToast.setParams({
                  "title": "Success!",
                  "message": "Our terms of business have been sent."
              	});
        		resultToast.fire();
              } else {
                  resultToast.setParams({
                    "title": "Server error!",
                    "message": "Status code: " + response.getReturnValue()
                  });
        		  resultToast.fire();
              }
            }
            else if (state === "INCOMPLETE") {
                console.log("Error message: Continuation action is INCOMPLETE");
                
                resultToast.setParams({
                  "title": "Error!",
                  "message": "Continuation action is INCOMPLETE"
                });
        		resultToast.fire();
            }
            else if (state === "ERROR") {
                var errors = response.getError();
                if (errors) {
                    if (errors[0] && errors[0].message) {
                        console.log("Error message: " + errors[0].message);
                        
                        resultToast.setParams({
                          "title": "Error!",
                          "message": errors[0].message
                        });
        		        resultToast.fire();
                    }
                } else {
                    console.log("Unknown error");
                    
                    resultToast.setParams({
                      "title": "Error!",
                      "message": "Unknown error"
                    });
        		    resultToast.fire();
                }
            }
        });
        // Enqueue action that returns a continuation
        $A.enqueueAction(action);
    }
})
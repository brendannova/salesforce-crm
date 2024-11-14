({
    // Function called on initial page loading to get the task information from the server
    getTaskInformation : function(component, event, helper) {
        
        // Assign server method
        var action = component.get("c.getTaskInfo");
        
        // Get and pass through the task ID from the page
        action.setParams({
            taskId: component.get("v.recordId")
        });
        
        // Callback function to get the response
        action.setCallback(this, function(response) {
            
            // Getting the response state
            var state = response.getState();
            
            // Check if response state is success
            if(state === 'SUCCESS') {
                
                // Get the task information returned and store it in a js variable
                var taskInfos = response.getReturnValue();
                
                // Set the attribute in the component to the value returned by function
                component.set("v.taskInfor", taskInfos);
                
                component.set("v.url", window.location.origin);
            }
            else {
                // Show an alert if the state is incomplete or error
                //alert('Error in getting data');
            }
        });
        // Adding the action variable to the global action queue
        $A.enqueueAction(action);
    }    
})
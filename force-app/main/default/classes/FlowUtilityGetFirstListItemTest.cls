@isTest
public class FlowUtilityGetFirstListItemTest {
    
    @istest
    static void getRecordTypeId_success(){
        List<FlowUtilityGetFirstListItem.FlowInputs> requests = new List<FlowUtilityGetFirstListItem.FlowInputs>();
        Integer n1 = 5;
        Integer n2 = 7;
        for(Integer i = 0; i < n1; i++){
            List<Task> records = new List<Task>();
            for(Integer j = 0; j < n2; j++){
                records.add(new Task(Subject = 'Task_' + i + '_' + j));
            }
            FlowUtilityGetFirstListItem.FlowInputs request = new FlowUtilityGetFirstListItem.FlowInputs();
            request.inputCollection = records;
            requests.add(request);
        }

        System.assertEquals(requests.size(), n1, 'Unexected number of requests');
        List<FlowUtilityGetFirstListItem.FlowOutputs> results = FlowUtilityGetFirstListItem.processRequests(requests);
        System.assertEquals(results.size(), n1, 'Unexected number of results');
        for(Integer i = 0; i < n1; i++){
            Task outputItem = (Task)results[i].outputItem;
            System.assertEquals(outputItem.Subject , 'Task_' + i + '_0', 'Did not get the 1st item in the list');
        }   
    }
}
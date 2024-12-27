@isTest
public class FlowUtilityGetRecordTypeIdTest {
    
    @istest
    static void getRecordTypeId_success(){
        List<FlowUtilityGetRecordTypeId.FlowInputs> requests = new List<FlowUtilityGetRecordTypeId.FlowInputs>();
        Integer recordTypeCount = 20;
        List<RecordType> recordTypes = [SELECT Id, DeveloperName, SObjectType FROM RecordType LIMIT :recordTypeCount];
        Map<Id, RecordType> recordTypeMap = new Map<Id, RecordType>(recordTypes);
        for (RecordType rt : recordTypes){
            FlowUtilityGetRecordTypeId.FlowInputs request = new FlowUtilityGetRecordTypeId.FlowInputs();
            request.sObjectType = rt.SObjectType;
            request.recordTypeDeveloperName = rt.DeveloperName;
            requests.add(request);
        }
        List<FlowUtilityGetRecordTypeId.FlowOutputs> results = FlowUtilityGetRecordTypeId.processRequests(requests);
        System.assertEquals(results.size(), recordTypeCount, 'Unexpected number of results');
        Integer i = 0;
        for(RecordType rt : recordTypes){
            System.assertEquals(rt.Id, results[i].recordTypeId, 'Record type IDs do not match');
            i++;
        }
    }
}
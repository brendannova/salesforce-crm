@isTest
public class RecordTypeGetIdTest {
    
    @istest
    static void testGetId(){
        RecordType rt = [SELECT Id, DeveloperName, SObjectType FROM RecordType LIMIT 1];
        Id recordTypeId = RecordTypeGetId.getId(rt.SObjectType, rt.DeveloperName);
        System.assertEquals(rt.Id, recordTypeId);
    }
    
    @istest
    static void testGetIdInvocable(){
        RecordType rt = [SELECT Id, DeveloperName, SObjectType FROM RecordType LIMIT 1];
        List<RecordTypeGetId.FlowInputs> FlowInputs = new List<RecordTypeGetId.FlowInputs>();
        RecordTypeGetId.FlowInputs FlowInput = new RecordTypeGetId.FlowInputs();
        FlowInput.sObjectType = rt.SObjectType;
        FlowInput.recordTypeDeveloperName = rt.DeveloperName;
        FlowInputs.add(FlowInput);
        System.assertEquals(FlowInputs.size(), 1);
        List<RecordTypeGetId.FlowOutputs> results = RecordTypeGetId.invokeThisMethod(FlowInputs);
        Id recordtypeId = results[0].recordTypeId;
        System.assertEquals(results.size(), 1);
        System.assertEquals(rt.Id, recordTypeId);
    }
}
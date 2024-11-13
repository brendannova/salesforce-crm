@isTest
public class GetObjectFromRecordIdTest {
    
    @isTest
    static void getObjectFromRecordTest(){
        List<Account> testAccounts = TestDataFactory.createHousehold(1,0,'123');
        Account a = [SELECT Id FROM Account WHERE Id IN: testAccounts LIMIT 1];
        
        GetObjectFromRecordId.FlowInputs ids = new GetObjectFromRecordId.FlowInputs();
        ids.recordId = a.Id;
        List<GetObjectFromRecordId.FlowInputs> idLst = new List<GetObjectFromRecordId.FlowInputs>();
        idLst.add(ids);
        
        
        test.StartTest();
        GetObjectFromRecordId.GetObjectName(idLst);
        test.StopTest();
    }

}
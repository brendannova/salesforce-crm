@isTest
public class ClientsWithRolesTest {
    
    public static Id personRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
    
    @isTest
    static void testMethod1() {
        
        Account acc = new Account(LastName = 'test account', recordTypeId = personRT);
        insert acc;
        List<Account> accList = new List<Account>();
        accList.add(acc);
        List<String> idList = new List<String>();
        idList.add(acc.id);
        
        ClientsWithRoles.InputParams accs = new ClientsWithRoles.inputParams();
        accs.clients = accList;
        accs.Roles = idList;
        List<ClientsWithRoles.InputParams> accsList = new List<ClientsWithRoles.InputParams> ();
        accsList.add(accs);
        
        test.startTest();
        ClientsWithRoles.getClientsWithRoles(accsList);
        test.stopTest();
        
    }

}
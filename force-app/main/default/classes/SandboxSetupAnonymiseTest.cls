@isTest
public with sharing class SandboxSetupAnonymiseTest {

    final private static integer ACCOUNT_QUANTITY = 10;
    final private static string TEST_NAME = 'RANDOMNAME';
    final private static string TEST_MOBILE = '+447712345678';
    final private static string TEST_PHONE = '+442012345678';
    final private static string TEST_NINO = 'QQ123456B';
    
    @isTest
    private  static void testAnonymise_success(){
        List<Account> accounts = new List<Account>();
        for (Integer i = 0; i < ACCOUNT_QUANTITY; i++) {
            String testEmail = TEST_NAME + i + '@test.novawm.com';
            Account acc = new Account(
            FirstName = TEST_NAME,
            LastName = TEST_NAME,
            FinServ__PreferredName__pc = TEST_NAME,
            PersonEmail = testEmail,
            Secondary_Email__pc = testEmail,
            PersonMobilePhone = TEST_MOBILE,
            Phone = TEST_PHONE,
            National_Insurance_Number__pc = TEST_NINO
        );
            accounts.add(acc);
        }
        insert accounts;

        Test.startTest();
        SandboxSetupAnonymise batchJob = new SandboxSetupAnonymise();
        Id jobId = Database.executeBatch(batchJob, ACCOUNT_QUANTITY);
        Test.stopTest();
        accounts = [SELECT Id, FirstName, LastName, FinServ__PreferredName__pc, PersonEmail, Secondary_Email__pc, PersonMobilePhone, Phone, National_Insurance_Number__pc FROM Account];
        for(Account acc : accounts){
            System.Assert.areNotEqual(TEST_NAME, acc.FirstName);
            System.Assert.areNotEqual(TEST_NAME, acc.LastName);
            System.Assert.areNotEqual(TEST_NAME, acc.FinServ__PreferredName__pc);
            System.Assert.areNotEqual(TEST_NINO, acc.National_Insurance_Number__pc);
            System.Assert.areEqual(null, acc.PersonEmail);
            System.Assert.areEqual(null, acc.Secondary_Email__pc);
            System.Assert.areEqual(null, acc.PersonMobilePhone);
            System.Assert.areEqual(null, acc.Phone);
        }
    }
}
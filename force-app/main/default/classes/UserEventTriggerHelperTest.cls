@isTest
private class UserEventTriggerHelperTest {

    private final static String TEST_2_USERNAME = 'testupdateusereventtrigger@test.novawm.com';

    @testSetup static void methodName() {
        DataFactoryUser dfu = new DataFactoryUser();
        User testUser = dfu.createAdmin(TEST_2_USERNAME);
    }

    @isTest
    static void userInserted_success(){
        String TEST_1_USERNAME = 'testusereventtrigger@test.novawm.com';
        DataFactoryUser dfu = new DataFactoryUser();
        Test.startTest();
        User testUser = dfu.createAdmin(TEST_1_USERNAME);
        Test.getEventBus().deliver();
        Test.stopTest();
        testUser = [SELECT Id, ColleagueAccountId__c FROM User WHERE Username = :TEST_1_USERNAME];
        List<Account> colleagueAccounts = [SELECT Id FROM Account WHERE Colleague__c = :testUser.Id];
        System.assertEquals(1, colleagueAccounts.size(), 'Expected a colleague account but none found');
        System.assertEquals(colleagueAccounts[0].Id, testUser.ColleagueAccountId__c, 'Expected user.ColleagueAccountId__c to match colleagueAccount.Id');
    }

    @isTest
    static void userUpdated_success(){
        
        User testUser = [SELECT Id, FirstName, LastName, ColleagueAccountId__c FROM User WHERE Username = :TEST_2_USERNAME];
        Test.startTest();
        testUser.LastName = 'New-Forname';
        testUser.LastName = 'New-Surname';
        update testUser;
        Test.getEventBus().deliver();
        Test.stopTest();
        List<Account> colleagueAccounts = [SELECT Id, FirstName, LastName FROM Account WHERE Colleague__c = :testUser.Id];
        System.assertEquals(1, colleagueAccounts.size(), 'Expected a colleague account but none found');
        System.assertEquals(testUser.FirstName, colleagueAccounts[0].FirstName, 'Expected first names to match but they did not');
        System.assertEquals(testUser.LastName, colleagueAccounts[0].LastName,  'Expected last names to match but they did not');
    }
}
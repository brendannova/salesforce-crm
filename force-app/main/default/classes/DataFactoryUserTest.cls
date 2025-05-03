@isTest
private class DataFactoryUserTest {

    @isTest
    static void colleagueInserted_success(){
        DataFactoryUser dfu = new DataFactoryUser();
        User testUser = dfu.createColleague('testcolleague@test.novawm.com');
        List<User> testUsers = [SELECT Id FROM User WHERE Id = :testUser.Id];
        System.assertEquals(1, testUsers.size(), 'Expected 1 colleague user account but none found');
    }

    @isTest
    static void adminInserted_success(){
        DataFactoryUser dfu = new DataFactoryUser();
        User testUser = dfu.createAdmin('testadmin@test.novawm.com');
        List<User> testUsers = [SELECT Id FROM User WHERE Id = :testUser.Id];
        System.assertEquals(1, testUsers.size(), 'Expected 1 admin user account but none found');
    }
}
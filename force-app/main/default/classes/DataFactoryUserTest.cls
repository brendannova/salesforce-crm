@isTest
private class DataFactoryUserTest {

    @isTest
    static void colleagueInserted_success(){
        User testUser = DataFactoryUser.createColleague('testcolleague@test.novawm.com');
        List<User> testUsers = [SELECT Id FROM User WHERE Id = :testUser.Id];
        System.assertEquals(1, testUsers.size(), 'Expected 1 colleague user account but none found');
    }

    @isTest
    static void adminInserted_success(){
        User testUser = DataFactoryUser.createAdmin('testadmin@test.novawm.com');
        List<User> testUsers = [SELECT Id FROM User WHERE Id = :testUser.Id];
        System.assertEquals(1, testUsers.size(), 'Expected 1 admin user account but none found');
    }
}
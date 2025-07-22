@IsTest
private class DataFactoryUserTest {

    final private static String SANDBOX_NAME = Utility.isSandbox ? '.' + Utility.sandboxName : '';

    private static String generateUsername(){
        return UUID.randomUUID().toString() + '@test.novawm.com' + SANDBOX_NAME;
    }

    @IsTest
    static void colleagueInserted_success(){
        User testUser = DataFactoryUser.createColleague(generateUsername());
        List<User> testUsers = [SELECT Id FROM User WHERE Id = :testUser.Id];
        System.assertEquals(1, testUsers.size(), 'Expected 1 colleague user account but none found');
    }

    @IsTest
    static void adminInserted_success(){
        User testUser = DataFactoryUser.createAdmin(generateUsername());
        List<User> testUsers = [SELECT Id FROM User WHERE Id = :testUser.Id];
        System.assertEquals(1, testUsers.size(), 'Expected 1 admin user account but none found');
    }

    @IsTest
    static void colleaguesInserted_success(){
        Integer numUsers = 5;
        List<String> usernames = new List<String>();
        for(Integer i = 0; i < numUsers; i++){
            usernames.add(generateUsername());
        }
        DataFactoryUser.createColleagues(usernames);
        List<User> testUsers = [SELECT Id, Username, ProfileId FROM User WHERE Username IN :usernames];
        System.assertEquals(usernames.size(), testUsers.size(), 'Different number of requested and actual users');
        for(User testUser : testUsers){
            System.assert(usernames.contains(testUser.Username), 'Created user ' + testUser.Username + ' not found in list of requested users');
            System.assertEquals(testUser.ProfileId, DataFactoryUser.PROFILE_NOVA_COLLEAGUE.Id);
        }
    }
}
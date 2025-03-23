@isTest
private class UserTriggerTest {
    
    @isTest
    static void userUpdated_success(){
        User currentUser = [SELECT Id, ProfileId, Username, FederationIdentifier FROM User WHERE Id = :UserInfo.getUserId()];
        List<User> users = new List<User>();
        
        // Set common user values
        User testUser = new User(
            Lastname = 'User',
            EmailEncodingKey='UTF-8',
            LanguageLocaleKey='en_US',
            LocaleSidKey='en_US', 
            ProfileId = currentUser.ProfileId,
            IsActive = true,
            TimeZoneSidKey='America/Los_Angeles'
        );

        // Set inactive user values
        testUser.IsActive = false;
        testUser.FirstName = 'Inactive';
        testUser.Email = 'inactiveuser' + UserTriggerHelper.NOVA_EMAIL_DOMAIN;
        testUser.Username = testUser.Email + UserTriggerHelper.SANDBOX_EXTENSION;
        testUser.Alias = 'inactive';
        users.add(testUser);

        // Set inactive user values
        testUser = testUser.clone(false, false, false, false);
        testUser.IsActive = true;
        testUser.FirstName = 'Active';
        testUser.Email = 'activeuser' + UserTriggerHelper.NOVA_EMAIL_DOMAIN;
        testUser.Username = testUser.Email + UserTriggerHelper.SANDBOX_EXTENSION;
        testUser.Alias = 'active';
        users.add(testUser);

        insert users;

        users = [SELECT Id, FederationIdentifier, IsActive, Email, Username FROM User WHERE Id IN :users];
        for(User user : users){
            if(user.IsActive){
                System.debug(user);
                System.debug(user.FederationIdentifier);
                System.assertEquals(user.Email, user.FederationIdentifier, 'Expected email to match federation identifier');
                if(Utility.isSandbox){
                    System.assertNotEquals(user.Username, user.FederationIdentifier, 'Expected username and federation identifier to not equal');    
                }
                System.assert(user.Username.startsWith(user.FederationIdentifier), 'Expected username to start with the federation identifier.');
            } else {
                System.debug(user);
                System.debug(user.FederationIdentifier);
                System.assert(String.isBlank(user.FederationIdentifier), 'Expected blank federation identifier');
            }
        }
    }
}
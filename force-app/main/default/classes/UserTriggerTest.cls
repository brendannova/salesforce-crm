@isTest
private class UserTriggerTest {
    
    @isTest
    static void userUpdated_success(){
        User currentUser = [SELECT Id, Username, FederationIdentifier FROM User WHERE Id = :UserInfo.getUserId()];
        User updatedUser = currentUser;

        String updatedUsername = 'UserTriggerTestFakeUsername@novawm.com';
        updatedUser.Username = Utility.isSandbox ? updatedUsername : updatedUsername + '.' + Utility.sandboxName;
        update updatedUser;

        updatedUser = [ SELECT Id, Username, FederationIdentifier FROM User WHERE Id = :UserInfo.getUserId()];
        System.assertNotEquals(currentUser.Username, updatedUser.Username, 'Expected different usernames');
        System.assertNotEquals(currentUser.FederationIdentifier, updatedUser.FederationIdentifier, 'Expected different usernames');
        System.assert(updatedUser.Username.startsWith(updatedUser.FederationIdentifier), 'FederationIdentifier not updated');
    }
}
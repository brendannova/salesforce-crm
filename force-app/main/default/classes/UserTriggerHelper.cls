/**
 * This class exists to support the user trigger only, handling automation and validation on the user object.
 */
public with sharing class UserTriggerHelper {
    
    // The purpose of this method is to update the federation user ID so that it equals the production username. This allows the sandbox to be used for SSO with production Salesforce as the IdP
    public UserTriggerHelper(List<User> users){
        for(User user : users){
            user.FederationIdentifier = user.Username.toLowerCase().removeEnd('.' + Utility.sandboxName);
        }
    }
}
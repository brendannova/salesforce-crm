/**
 * This class exists to support the user trigger only, handling automation and validation on the user object.
 */
public with sharing class UserTriggerHelper {
    private static final String USER_TYPE_AUTOMATED_PROCESS = 'AutomatedProcess';
    private static final String USER_TYPE_CHATTER = 'CsnOnly';
    private static final String USER_TYPE_CLOUD_INTEGRATION = 'CloudIntegrationUser';
    private static final String USER_TYPE_GUEST = 'Guest';
    private static final List<String> USER_TYPES_EXCLUDED_FEDERATION = new List<String>{USER_TYPE_AUTOMATED_PROCESS, USER_TYPE_CHATTER, USER_TYPE_CLOUD_INTEGRATION, USER_TYPE_GUEST};
    private static final String NOVA_EMAIL_DOMAIN = '@novawm.com';
    private static final String SANDBOX_EXTENSION = Utility.isSandbox ? '.' + Utility.sandboxName : ''; 
    
    // The purpose of this method is to update the federation user ID so that it equals the production username. This allows the sandbox to be used for SSO with production Salesforce as the IdP
    public UserTriggerHelper(List<User> users){
        for(User user : users){
            if(user.IsActive && !USER_TYPES_EXCLUDED_FEDERATION.contains(user.UserType) && user.Username.endsWithIgnoreCase(NOVA_EMAIL_DOMAIN + SANDBOX_EXTENSION)){
                user.FederationIdentifier = user.Username.toLowerCase().removeEnd(SANDBOX_EXTENSION);
            }
        }
    }
}
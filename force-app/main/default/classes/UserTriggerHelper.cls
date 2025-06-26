/**
 * This class exists to support the user trigger only, handling automation and validation on the user object.
 */
public with sharing class UserTriggerHelper {
    private static final String SALESFORCE_USER_TYPE_AUTOMATED_PROCESS = 'AutomatedProcess';
    private static final String SALESFORCE_USER_TYPE_CHATTER = 'CsnOnly';
    private static final String SALESFORCE_USER_TYPE_CLOUD_INTEGRATION = 'CloudIntegrationUser';
    private static final String SALESFORCE_USER_TYPE_GUEST = 'Guest';
    private static final String NOVA_USER_TYPE_COLLEAGUE = 'COLLEAGUE';
    private static final String NOVA_USER_TYPE_CONSULTANT = 'CONSULTANT';
    private static final String NOVA_USER_TYPE_INTEGRATION = 'INTEGRATION';
    private static final List<String> USER_TYPES_EXCLUDED_FEDERATION = new List<String>{SALESFORCE_USER_TYPE_AUTOMATED_PROCESS, SALESFORCE_USER_TYPE_CHATTER, SALESFORCE_USER_TYPE_CLOUD_INTEGRATION, SALESFORCE_USER_TYPE_GUEST};
    @TestVisible private static final String NOVA_EMAIL_DOMAIN = '@novawm.com';
    @TestVisible private static final String SANDBOX_EXTENSION = Utility.isSandbox ? '.' + Utility.sandboxName : ''; 
    
    // The purpose of this method is to update the federation user ID so that it equals the production username. This allows the sandbox to be used for SSO with production Salesforce as the IdP
    public void checkFederationIdentifier(List<User> users){
        for(User user : users){
            String federationIdentifier = user.Username.toLowerCase().removeEnd(SANDBOX_EXTENSION);
            if(user.IsActive && !USER_TYPES_EXCLUDED_FEDERATION.contains(user.UserType) && user.Username.endsWithIgnoreCase(NOVA_EMAIL_DOMAIN + SANDBOX_EXTENSION)&& user.FederationIdentifier != federationIdentifier){
                user.FederationIdentifier = federationIdentifier;
            }
        }
    }

    // The purpose of this method is to update the federation user ID so that it equals the production username. This allows the sandbox to be used for SSO with production Salesforce as the IdP
    public void checkColleagueAccount(List<User> users){
        List<UserEvent__e> userEvents = new List<UserEvent__e>();
        for(User user : users){
            userEvents.add(new UserEvent__e(
                UserId__c = user.Id
            ));
        }
        if(!userEvents.isEmpty()){
            List<Database.SaveResult> saveResults = EventBus.publish(userEvents);
        }
    }
}
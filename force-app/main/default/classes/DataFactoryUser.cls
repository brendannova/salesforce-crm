/**
 * This data factory class supports creating users in a repeatable manner. 
 * It should be expanded to support other use cases in time such as other profile types. 
 */
public without sharing class DataFactoryUser {

    // Constants to support this class, particularly the BASE_USER, which simplifies creation by prepopulating tricky required fields
    private static final String PROFILE_NAME_SYSTEM_ADMINISTRATOR = 'System Administrator';
    private static final String PROFILE_NAME_NOVA_COLLEAGUE = 'Nova colleague';
    private static final User BASE_USER = new User(
        FirstName = 'Test',
        LastName='Testing',
        Alias = 'testy',
        IsActive = true,
        EmailEncodingKey='UTF-8',
        LanguageLocaleKey='en_US',
        LocaleSidKey='en_US',
        TimeZoneSidKey = 'Europe/London',
        UserType__c = 'COLLEAGUE'
    );

    // Create a single admin
    public static User createAdmin(String username){
        User user = defineUser(PROFILE_NAME_SYSTEM_ADMINISTRATOR, username);
        insert user;
        return user;
    }

    // Create a single colleague
    public static User createColleague(String username) {
        User user = defineUser(PROFILE_NAME_NOVA_COLLEAGUE, username);
        insert user;
        return user;
    }

    // Create multiple colleagues
    public static List<User> createColleagues(List<String> usernames) {
        List<User> users = new List<User>();
        for(String username : usernames){
            users.add(defineUser(PROFILE_NAME_NOVA_COLLEAGUE, username));
        }
        insert users;
        return users;
    }

    // Define a base user
    private static User defineUser(String userProfile, String username){
        User user = BASE_USER.clone();
        user.Username = username;
        user.Email = username;
        if(userProfile == PROFILE_NAME_SYSTEM_ADMINISTRATOR){
            user.ProfileId = PROFILE_SYSTEM_ADMINISTRATOR.Id;
        } else {
            user.ProfileId = PROFILE_NOVA_COLLEAGUE.Id;
        }
        return user;
    }

    // Get the system administrator profile
    public static profile PROFILE_SYSTEM_ADMINISTRATOR {
        get{
            if(PROFILE_SYSTEM_ADMINISTRATOR == null){
                PROFILE_SYSTEM_ADMINISTRATOR = [SELECT Id FROM Profile WHERE Name = :PROFILE_NAME_SYSTEM_ADMINISTRATOR LIMIT 1];
            }
            return PROFILE_SYSTEM_ADMINISTRATOR;
        }
        set;
    }

    // Get the Nova colleague profile
    public static profile PROFILE_NOVA_COLLEAGUE {
        get{
            if(PROFILE_NOVA_COLLEAGUE == null){
                PROFILE_NOVA_COLLEAGUE = [SELECT Id FROM Profile WHERE Name = :PROFILE_NAME_NOVA_COLLEAGUE LIMIT 1];
            }
            return PROFILE_NOVA_COLLEAGUE;
        }
        set;
    }
}
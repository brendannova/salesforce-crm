public with sharing class DataFactoryUser {

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
    
    public user createColleague(String username) {
        User user = BASE_USER.clone();
        user.ProfileId = PROFILE_NOVA_COLLEAGUE.Id;
        user.Username = username;
        user.Email = username;
        insert user;
        return user;
    }

    public user createAdmin(String username){
        User user = BASE_USER.clone();
        user.ProfileId = PROFILE_SYSTEM_ADMINISTRATOR.Id;
        user.Username = username;
        user.Email = username;
        insert user;
        return user;
    }

    public profile PROFILE_SYSTEM_ADMINISTRATOR {
        get{
            if(PROFILE_SYSTEM_ADMINISTRATOR == null){
                PROFILE_SYSTEM_ADMINISTRATOR = [SELECT Id FROM Profile WHERE Name = :PROFILE_NAME_SYSTEM_ADMINISTRATOR LIMIT 1];
            }
            return PROFILE_SYSTEM_ADMINISTRATOR;
        }
        set;
    }

    public profile PROFILE_NOVA_COLLEAGUE {
        get{
            if(PROFILE_NOVA_COLLEAGUE == null){
                PROFILE_NOVA_COLLEAGUE = [SELECT Id FROM Profile WHERE Name = :PROFILE_NAME_NOVA_COLLEAGUE LIMIT 1];
            }
            return PROFILE_NOVA_COLLEAGUE;
        }
        set;
    }
}
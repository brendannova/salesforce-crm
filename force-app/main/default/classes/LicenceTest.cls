@IsTest
public class LicenceTest {

    @TestVisible private static final List<String> USERNAMES = new List<String>{'licencedcolleague1@test.novawm.com', 'licencedcolleague2@test.novawm.com', 'licencedcolleague3@test.novawm.com'};
    @TestVisible private static final String LICENCE_DEVELOPER_NAME = 'ADVICE_WRITE_TOP_UP';
    
    @TestSetup
    static void setupData(){
        setUpLicenceTestData();
    }

    public static void setUpLicenceTestData(){
        List<User> licencedColleagues = DataFactoryUser.createColleagues(usernames);
        Licence__c licence = new Licence__c(
            Name = 'Test licence',
            DeveloperName__c = LICENCE_DEVELOPER_NAME,
            Type__c = 'ADVICE_WRITE',
            Reference__c = 'TOP_UP'
        );
        insert licence;

        List<UserLicence__c> userLicences = new List<UserLicence__c>();
        for(User licencedColleague : licencedColleagues){
            UserLicence__c userLicence = new UserLicence__c(
                User__c = licencedColleague.Id,
                Licence__c = licence.Id,
                IsActive__c = true
            );
            userLicences.add(userLicence);
        }
        insert userLicences;
    }


    

    @IsTest
    static void getLicencedUsers_success(){
        List<User> licencedUsers = Licence.getLicencedUsers(LICENCE_DEVELOPER_NAME);
        for(User licencedUser : licencedUsers){
            System.assert(USERNAMES.contains(licencedUser.Username));
        }
        System.assertEquals(USERNAMES.size(), licencedUsers.size(), 'Unexpected number of licenced users');
    }

    @IsTest
    static void getLicencedUsersExcludesInactiveUser_success(){
        List<User> licencedUsers = [SELECT Id, IsActive FROM User WHERE Username IN :USERNAMES];
        for(User licencedUser : licencedUsers){
            licencedUser.IsActive = false;
        }
        update licencedUsers;
        
        licencedUsers = Licence.getLicencedUsers(LICENCE_DEVELOPER_NAME);
        System.assertEquals(0, licencedUsers.size(), 'Expected 0 licenced users');
    }

    @IsTest
    static void getLicencedUsersExcludesInactiveLicences_success(){
        List<UserLicence__c> userLicences = [SELECT Id, IsActive__c FROM UserLicence__c];
        for(UserLicence__c userLicence : userLicences){
            userLicence.IsActive__c = false;
        }
        update userLicences;
        
        List<User> licencedUsers = Licence.getLicencedUsers(LICENCE_DEVELOPER_NAME);
        System.assertEquals(0, licencedUsers.size(), 'Expected 0 licenced users');
    }
}
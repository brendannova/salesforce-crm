@IsTest
public class FlowUtilityGetLicencedUsersTest {
    
    @TestSetup
    static void setupData(){
        LicenceTest.setUpLicenceTestData();
    }

    @IsTest
    static void getLicencedUsers_success(){
        List<FlowUtilityGetLicencedUsers.FlowInputs> requests = new List<FlowUtilityGetLicencedUsers.FlowInputs>();
        FlowUtilityGetLicencedUsers.FlowInputs request = new FlowUtilityGetLicencedUsers.FlowInputs();
        request.licenceDeveloperName = LicenceTest.LICENCE_DEVELOPER_NAME;
        requests.add(request);
        List<FlowUtilityGetLicencedUsers.FlowOutputs> results = FlowUtilityGetLicencedUsers.processRequests(requests);
        for(FlowUtilityGetLicencedUsers.FlowOutputs result : results) {
            System.assertEquals(LicenceTest.USERNAMES.size(), result.licencedUsers.size(), 'Unexpected number of licenced users');
            for(User user : result.licencedUsers) {
                System.assert(LicenceTest.USERNAMES.contains(user.Username), 'Licenced users not as expected');
            }
        }
    }
}
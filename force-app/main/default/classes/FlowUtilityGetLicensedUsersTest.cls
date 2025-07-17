@IsTest
public class FlowUtilityGetLicensedUsersTest {
    
    @TestSetup
    static void setupData(){
        LicenceTest.setUpLicenceTestData();
    }

    @IsTest
    static void getLicensedUsers_success(){
        List<FlowUtilityGetLicensedUsers.FlowInputs> requests = new List<FlowUtilityGetLicensedUsers.FlowInputs>();
        FlowUtilityGetLicensedUsers.FlowInputs request = new FlowUtilityGetLicensedUsers.FlowInputs();
        request.licenceDeveloperName = LicenceTest.LICENCE_DEVELOPER_NAME;
        requests.add(request);
        List<FlowUtilityGetLicensedUsers.FlowOutputs> results = FlowUtilityGetLicensedUsers.processRequests(requests);
        for(FlowUtilityGetLicensedUsers.FlowOutputs result : results) {
            System.assertEquals(LicenceTest.USERNAMES.size(), result.licensedUsers.size(), 'Unexpected number of licenced users');
            for(User user : result.licensedUsers) {
                System.assert(LicenceTest.USERNAMES.contains(user.Username), 'Licenced users not as expected');
            }
        }
    }
}
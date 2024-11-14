@isTest
public class UserExternalCredentialDeleteTest {
    
    //This class is no longer in use as colleagues can revoke and grant themselves access to the 
    //NOVA service through their permisissions.
    
    @isTest (SeeAllData=true)
    static void deleteUserCredential() {

        test.startTest();
        UserExternalCredentialDelete del = new UserExternalCredentialDelete();
        UserExternalCredentialDelete.deleteUserExternalCredential();
        test.stopTest();
    }
}
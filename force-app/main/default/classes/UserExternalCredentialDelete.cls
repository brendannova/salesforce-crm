public class UserExternalCredentialDelete {
    
    //This class is no longer in use as colleagues can revoke and grant themselves access to the 
    //NOVA service through their permisissions.
    
    @InvocableMethod(label='Delete external credential' description='Delete external credential for running user')
    public static void deleteUserExternalCredential (){
        String externalCredential = 'PlatformCognito';
		String principalName = 'Per User';
		ConnectApi.CredentialPrincipalType principalType = ConnectApi.CredentialPrincipalType.PerUserPrincipal;
		ConnectApi.NamedCredentials.deleteCredential(externalCredential, principalName, principalType);
    }
}
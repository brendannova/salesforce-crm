@isTest
public class UrlUtilityTest {
    
    @istest
    static void testGetDomain(){
        String baseUrl = UrlUtility.getBaseUrl();
        System.assertEquals(baseUrl, System.URL.getOrgDomainURL().toExternalForm());
    }
    
    @istest
    static void testGetDomainInvocable(){
        List<UrlUtility.FlowOutputs> results = UrlUtility.invokeThisMethod();
        String baseUrl = results[0].baseUrl;
        System.assertEquals(results.size(), 1);
        System.assertEquals(baseUrl, System.URL.getOrgDomainURL().toExternalForm());
    }
}
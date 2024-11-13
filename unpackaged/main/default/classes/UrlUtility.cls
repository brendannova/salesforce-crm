public with sharing class UrlUtility {
    public static String getBaseUrl() {
        String baseUrl = System.URL.getOrgDomainURL().toExternalForm();
        return baseUrl;
    }

    @InvocableMethod(label = 'Get base URL' description = 'Get base URL for the page. Do not use in bulk use cases.' category = 'Utility')
    public static List<FlowOutputs> invokeThisMethod(){
        List<FlowOutputs> results = new List<FlowOutputs>();
        results.add(invokeLocalMethod());
        return results;
    }

    public static FlowOutputs invokeLocalMethod(){        
        FlowOutputs returnDetails = new FlowOutputs();
        returnDetails.baseUrl = getBaseUrl();
        return returnDetails;
    }
    
    public class FlowOutputs{
        
        @InvocableVariable
        public String baseUrl;
    }
}
@isTest
private class FlowUtilityQueryTest {
    
    @istest
    static void executeQuery_success(){
        DataFactoryAccountHousehold dataFactory = new DataFactoryAccountHousehold();
        Account household = dataFactory.createHousehold('test', 2, 2, 'Active', 'Full');
        List<FlowUtilityQuery.FlowInputs> requests = new List<FlowUtilityQuery.FlowInputs>();
        FlowUtilityQuery.FlowInputs request = new FlowUtilityQuery.FlowInputs();
        request.queryString = 'SELECT Id, Name, FinServ__Status__c FROM Account';
        requests.add(request);
        List<FlowUtilityQuery.FlowOutputs> results = FlowUtilityQuery.processRequests(requests);
        List<Account> queryResults = (List<Account>)results[0].outputRecords;
        System.Assert.areEqual(5, queryResults.size(), 'Returned the wrong number of results');
        System.debug(queryResults);
        for(Account a : queryResults){
            System.debug(a);
        }
    }
}


SELECT Id, Name, Advice_Status__c FROM Advice WHERE Advice_Status__c IN ('Setup','Data gathering','Risk Call') AND AdviceType__r.DeveloperName__c IN ('AD_HOC','DRAWDOWN') AND Advice_Household__c = '
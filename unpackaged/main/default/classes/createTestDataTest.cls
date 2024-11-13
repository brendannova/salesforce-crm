@isTest(SeeAllData=true)
public class createTestDataTest {
    
    @istest
    static void testCreateHousehold(){
        
        // Specify test data parameters    
        Integer numClients = 1;
        Integer numChildren = 1;
        String factFindType = 'Full';
        
        // Create test data and capture ID of household created
        String householdId = createTestData.createHousehold(numClients, numChildren, factFindType);
        
        // Check person accounts have been created
        List<Account> personAccounts = [SELECT Id FROM Account WHERE Household_lookup__c =: householdId];
        System.assertEquals(numClients + numChildren, personAccounts.size());
        
        // Check relationships have been created
        List<AccountContactRelation> relationships = [SELECT Id, Roles FROM AccountContactRelation WHERE AccountId =: householdId];
        Integer countClients = 0;
        Integer countChildren = 0;
        for (AccountContactRelation relationship : relationships ){
            if( relationship.Roles == 'Client'){
                countClients = countClients + 1;
            } else if ( relationship.Roles == 'Child' ){
                countChildren = countChildren + 1;
            }
        }
        
        System.assertEquals(countChildren, numChildren);
        System.assertEquals(countClients, numClients);
    }
    
    @istest
    static void testCreateHouseholdInvocable(){
        
        // Specify test data parameters    
        Integer numClients = 1;
        Integer numChildren = 1;
        String factFindType = 'Full';
        
        // Build the list of invocable variables
        List<createTestDataInvocable.FlowInputs> FlowInputs = new List<createTestDataInvocable.FlowInputs>();
        createTestDataInvocable.FlowInputs FlowInput = new createTestDataInvocable.FlowInputs();
        
        FlowInput.numClients = numClients;
        FlowInput.numChildren = numChildren;
        FlowInput.factFindType = 'Full';
        FlowInputs.add(FlowInput);
        List<createTestDataInvocable.FlowOutputs> results = createTestDataInvocable.processInputs(FlowInputs);
        String householdId = results[0].householdId;
        
        // Check person accounts have been created
        List<Account> personAccounts = [SELECT Id FROM Account WHERE Household_lookup__c =: householdId];
        System.assertEquals(numClients + numChildren, personAccounts.size());
        
        // Check relationships have been created
        List<AccountContactRelation> relationships = [SELECT Id, Roles FROM AccountContactRelation WHERE AccountId =: householdId];
        Integer countClients = 0;
        Integer countChildren = 0;
        for (AccountContactRelation relationship : relationships ){
            if( relationship.Roles == 'Client'){
                countClients = countClients + 1;
            } else if ( relationship.Roles == 'Child' ){
                countChildren = countChildren + 1;
            }
        }
        
        System.assertEquals(countChildren, numChildren);
        System.assertEquals(countClients, numClients);
    }
}
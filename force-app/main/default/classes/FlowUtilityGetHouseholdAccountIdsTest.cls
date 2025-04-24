@isTest
public with sharing class FlowUtilityGetHouseholdAccountIdsTest {
    @isTest 
    static void getHouseholdAccountIdsTest() {
        DataFactory dataFactoryVar = new DataFactory();
        Id household1Id = dataFactoryVar.createHousehold('Household 1', 2, 2, 'Prospect', 'Discovery');
        Id household2Id = dataFactoryVar.createHousehold('Household 2', 2, 2, 'Prospect', 'Discovery');
        Id household3Id = dataFactoryVar.createHousehold('Household 3', 1, 3, 'Prospect', 'Discovery');

        //inactivate a relation
        AccountContactRelation acrRelationVar = [SELECT Id, AccountId, ContactId, IsActive, Roles FROM AccountContactRelation WHERE AccountId =: household2Id AND roles = 'Client' LIMIT 1];
        acrRelationVar.IsActive = false;
        update acrRelationVar;

        List<FlowUtilityGetHouseholdAccountIds.householdVars> request = new List<FlowUtilityGetHouseholdAccountIds.householdVars>();

        FlowUtilityGetHouseholdAccountIds.householdVars household1Filters = new FlowUtilityGetHouseholdAccountIds.householdVars();
        household1Filters.householdId = household1Id;
        household1Filters.includeClient = true;
        household1Filters.includeActive = true;
        household1Filters.includeInactive = false;

        FlowUtilityGetHouseholdAccountIds.householdVars household2Filters = new FlowUtilityGetHouseholdAccountIds.householdVars();
        household2Filters.householdId = household2Id;
        household2Filters.includeClient = true;
        household2Filters.includeActive = true;
        household2Filters.includeInactive = false;

        FlowUtilityGetHouseholdAccountIds.householdVars household3Filters = new FlowUtilityGetHouseholdAccountIds.householdVars();
        household3Filters.householdId = household3Id;
        household3Filters.includeClient = true;
        household3Filters.includeChild = true;
        household3Filters.includeActive = true;
        household3Filters.includeInactive = false;

        request.add(household1Filters);
        request.add(household2Filters);
        request.add(household3Filters);

        Test.startTest();
        List<List<Id>> result = FlowUtilityGetHouseholdAccountIds.getHouseholdAccountIds(request);
        Test.stopTest();

        Integer i = 1;
        for(List<Id> accountIds : result) {
            switch on i {
                when 1 {
                    Assert.areEqual(2, accountIds.size(), 'Wrong number of ids returned'); 
                }
                when 2 {
                    Assert.areEqual(1, accountIds.size(), 'Wrong number of ids returned'); 
                }
                when 3 {
                    Assert.areEqual(4, accountIds.size(), 'Wrong number of ids returned'); 
                }
            }
            i++;
        }
    }
}
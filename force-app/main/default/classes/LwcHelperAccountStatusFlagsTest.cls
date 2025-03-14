
@isTest
private class LwcHelperAccountStatusFlagsTest {

    public final static String HOUSEHOLD_IDENTIFIER = 'testHousehold';
    public final static String HOUSEHOLD_RECORD_TYPE_DEVELOPER_NAME = 'IndustriesHousehold';
    public final static Id HOUESHOLD_RECORD_TYPE_ID = Utility.getRecordTypeId('Account', HOUSEHOLD_RECORD_TYPE_DEVELOPER_NAME);

    public final static Integer NUMBER_OF_CLEINT_RECORDS = 2;
    public final static Integer NUMBER_OF_CHILD_RECORDS = 2;

    @testSetup
    static void createTestData() {
        DataFactory DataFactory = new DataFactory();
        DataFactory.createHousehold(HOUSEHOLD_IDENTIFIER, NUMBER_OF_CLEINT_RECORDS, NUMBER_OF_CHILD_RECORDS, 'Active', 'Discovery');
    }

    @isTest
    static void getAccountsByHouseholdId_success() {
        Account household = [SELECT Id FROM Account WHERE RecordTypeId = :HOUESHOLD_RECORD_TYPE_ID LIMIT 1];
        List<Account> accounts = [SELECT Id FROM Account WHERE RecordTypeId != :HOUESHOLD_RECORD_TYPE_ID];

        Test.startTest();
        List<Account> testAccounts = LwcHelperAccountStatusFlags.getAccountsByHouseholdId(household.Id);
        Test.stopTest();

        Assert.areEqual(NUMBER_OF_CLEINT_RECORDS, testAccounts.size(), 'Wrong number of accounts returned'); //children should not be returned
        for (Account testAccount : testAccounts) {
            Assert.isNotNull(testAccount.FinServ__Status__c, 'Status field not retrieved');
        }
    }
}
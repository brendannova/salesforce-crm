@isTest
private class RegularTransactionHelperTest {

    /*
    NOTE: This test class depends on your 'ExpectationHelper' class existing in the org.
    For these tests to pass, 'ExpectationHelper' must contain:
    1. A static Set<String> named 'DIRECTION_VALUES' (e.g., {'Credit', 'Debit'}).
    2. A static Set<String> named 'TRANSACTION_TYPE_VALUES' (e.g., {'REGULAR'}).
    3. A static method 'createExpections(List<ExpectationRequest> requests)' that performs DML on Expectation__c records.
    */

    // ## Test Setup: Create common data for all test methods ##
    @testSetup
    static void makeData() {

        DataFactory dataFactory = new DataFactory();
        dataFactory.createConfigurationData();
        Id householdId = dataFactory.createHousehold('test', 2, 0, 'Active', 'Full');
        dataFactory.createAdvice (1, householdId);

       FinServ__FinancialAccount__c product = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];

        // Create a test Regular Transaction
        RegularTransaction__c regularTransaction = dataFactory.createRegularTransaction(product.Id);
        
        // Create a base Transaction for the generation method
        Transaction__c baseTransaction = dataFactory.createTransaction(product.Id);
    }

    // ## Test Methods ##

    @isTest
    static void testProcessRegularTransactionsFromScheduledJob() {
        // ARRANGE: Get the test data and prepare the request
        RegularTransaction__c testRegTxn = [SELECT Id, NextTransactionDate__c, Amount__c, Direction__c, FinancialProduct__c, Frequency__c, Status__c, StartDate__c, EndDate__c FROM RegularTransaction__c LIMIT 1];
        
        // Update the RegularTransaction to have NextTransactionDate = today for the test
        testRegTxn.NextTransactionDate__c = Date.today();
        update testRegTxn;
        
        RegularTransactionRequest request = new RegularTransactionRequest();
        request.regularTransactionRecord = testRegTxn;
        request.convertRecordToRequest();
        
        List<RegularTransactionRequest> requests = new List<RegularTransactionRequest>{ request };

        Test.startTest();
        // ACT: Call the method to be tested
        RegularTransactionHelper.processRegularTransactionsFromScheduledJob(requests);
        Test.stopTest();

        // ASSERT: Verify the outcomes
        // 1. Check if an Expectation was created by the real ExpectationHelper
        List<Expectation__c> createdExpectations = [SELECT Id FROM Expectation__c];
        System.assertEquals(1, createdExpectations.size(), 'An expectation record should have been created.');

        // 2. Check if the Regular Transaction's next date was updated in the database
        RegularTransaction__c updatedRegTxn = [SELECT NextTransactionDate__c FROM RegularTransaction__c WHERE Id = :testRegTxn.Id];
        Date expectedDate = Date.today().addMonths(1);
        System.assertEquals(expectedDate, updatedRegTxn.NextTransactionDate__c, 'The next transaction date should have been moved forward by one month.');
    }

    @isTest
    static void testGenerateExpectationsFromRegularTransactions() {
        // ARRANGE: Get real test data
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        RegularTransaction__c testRegular = [SELECT Id FROM RegularTransaction__c LIMIT 1];
        
        RegularTransactionRequest request = new RegularTransactionRequest();
        request.id = testRegular.Id;
        request.nextTransactionDate = Date.today();
        request.productId = testProduct.Id;
        request.amount = 200.50;
        request.direction = ExpectationHelper.DIRECTION_CONTRIBUTION;

        // ACT
        List<ExpectationRequest> results = RegularTransactionHelper.generateExpectationsFromRegularTansactions(new List<RegularTransactionRequest>{request});

        // ASSERT
        System.assertEquals(1, results.size(), 'Should create one expectation request.');
        ExpectationRequest result = results[0];
        System.assertEquals(TransactionHelper.TRANSACTION_TYPE_REGULAR, result.transactionType, 'Transaction type should be REGULAR.');
        System.assertEquals(request.nextTransactionDate, result.expectationDate, 'Expectation date should match.');
        System.assertEquals(request.productId, result.productId, 'Product ID should match.');
    }

    @isTest
    static void testUpdateNextTransactionDates() {
        // ARRANGE
        RegularTransactionRequest request = new RegularTransactionRequest();
        request.nextTransactionDate = Date.newInstance(2025, 7, 24);
        request.frequency = 'Monthly';
        
        // ACT
        List<RegularTransactionRequest> updatedRequests = RegularTransactionHelper.updateNextTransactionDates(new List<RegularTransactionRequest>{request});
        
        // ASSERT
        Date expectedDate = Date.newInstance(2025, 8, 24);
        System.assertEquals(expectedDate, updatedRequests[0].nextTransactionDate, 'Date should be advanced by one month.');
    }
    
    @isTest
    static void testGenerateRegularTransactionFromTransactionRecords() {
        // ARRANGE: Get the base transaction record
        Transaction__c baseTransaction = [SELECT Id, FinancialProduct__c, Amount__c, Direction__c, Date__c FROM Transaction__c LIMIT 1];

        Test.startTest();
        // ACT: Call the generation method
        RegularTransactionHelper.generateRegularTransactionFromTransactionRecords(new List<Transaction__c>{ baseTransaction });
        Test.stopTest();

        // ASSERT: Verify a new RegularTransaction__c was created
        // We expect 2 total: 1 from @testSetup and 1 generated from this method
        List<RegularTransaction__c> regularTxns = [SELECT Id FROM RegularTransaction__c];
        System.assertEquals(2, regularTxns.size(), 'A new Regular Transaction should have been created.');
    }
    
    @isTest
    static void testUpdateRegularTransactions_HandlesValidationError() {
        // ARRANGE: Create a request that will fail validation based on your class's rules
        RegularTransactionRequest badRequest = new RegularTransactionRequest();
        badRequest.id = null; // New record
        badRequest.productId = null; // This will cause validation to fail
        badRequest.amount = 100;
        badRequest.direction = 'Credit'; // Valid direction
        badRequest.frequency = 'Weekly';
        badRequest.nextTransactionDate = Date.today();

        List<RegularTransactionRequest> requests = new List<RegularTransactionRequest>{ badRequest };

        Test.startTest();
        // ACT: Call the update method
        List<RegularTransactionRequest> results = RegularTransactionHelper.updateRegularTransactions(requests);
        Test.stopTest();

        // ASSERT: Verify the error was caught and handled
        System.assertEquals(true, results[0].isError, 'The request should be marked as an error.');
        System.assert(results[0].errorMessage.contains('Product not specified.'), 'The error message should indicate a missing product.');
        
        // Verify no DML was performed for the bad record
        List<RegularTransaction__c> regularTxns = [SELECT Id FROM RegularTransaction__c];
        System.assertEquals(1, regularTxns.size(), 'No new regular transaction should have been created.');
    }
}
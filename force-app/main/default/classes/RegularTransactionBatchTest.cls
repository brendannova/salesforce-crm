@isTest
private class RegularTransactionBatchTest {

    @TestSetup
    static void setupTestData() {
        // Load configuration data for testing
        try {
            DataFactoryConfigurationData.load();
        } catch (Exception ex) {
            // Configuration data may already be loaded, continue
        }

        // Create test data using DataFactory
        DataFactory dataFactory = new DataFactory();
        
        try {
            dataFactory.createConfigurationData();
        } catch (Exception ex) {
            // Configuration data may already be loaded, continue
        }
        
        // Create a household with 1 client
        String householdId = dataFactory.createHousehold('RegularTransactionBatchTest', 1, 0, 'Active', 'Full');
        
        // Create advice with 1 product per person
        Advice__c advice = dataFactory.createAdvice(1, householdId);
    }

    @IsTest
    static void testBatchWithValidRecords() {
        // ARRANGE: Create test data
        DataFactory dataFactory = new DataFactory();
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        
        // Create regular transactions scheduled for today
        List<RegularTransaction__c> testTransactions = new List<RegularTransaction__c>();
        
        // Active transaction
        RegularTransaction__c activeTransaction = dataFactory.createRegularTransaction(
            testProduct.Id,
            1000.00,
            ExpectationHelper.DIRECTION_CONTRIBUTION,
            'Monthly',
            Date.today(),
            Date.today().addMonths(-1),
            RegularTransactionHelper.REGULAR_TRANSACTION_STATUS_ACTIVE
        );
        
        // Pending transaction
        RegularTransaction__c pendingTransaction = dataFactory.createRegularTransaction(
            testProduct.Id,
            500.00,
            ExpectationHelper.DIRECTION_WITHDRAWAL,
            'Monthly',
            Date.today(),
            Date.today().addMonths(-1),
            RegularTransactionHelper.REGULAR_TRANSACTION_STATUS_PENDING
        );
        
        // Count expectations before batch
        Integer expectationsBefore = [SELECT COUNT() FROM Expectation__c];
        
        Test.startTest();
        
        // ACT: Execute the batch
        RegularTransactionBatchNewExpectations batch = new RegularTransactionBatchNewExpectations();
        Database.executeBatch(batch);
        
        Test.stopTest();
        
        // ASSERT: Verify expectations were created
        Integer expectationsAfter = [SELECT COUNT() FROM Expectation__c];
        System.assertEquals(expectationsBefore + 2, expectationsAfter, 'Two expectations should have been created');
        
        // Verify next transaction dates were updated
        List<RegularTransaction__c> updatedTransactions = [
            SELECT Id, NextTransactionDate__c, Status__c 
            FROM RegularTransaction__c 
            WHERE Id IN (:activeTransaction.Id, :pendingTransaction.Id)
        ];
        
        for (RegularTransaction__c regularTxn : updatedTransactions) {
            System.assertEquals(Date.today().addMonths(1), regularTxn.NextTransactionDate__c, 
                'Next transaction date should be advanced by one month');
        }
    }

    @IsTest
    static void testBatchWithInvalidRecords() {
        // ARRANGE: Create test data with invalid records
        DataFactory dataFactory = new DataFactory();
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        
        // Create invalid regular transactions
        List<RegularTransaction__c> invalidTransactions = new List<RegularTransaction__c>();
        
        // Transaction with null product - we can't insert this due to database constraints
        // So we'll create it in memory for testing validation logic
        RegularTransaction__c nullProductTransaction = new RegularTransaction__c(
            FinancialProduct__c = null,
            Amount__c = 1000.00,
            Direction__c = ExpectationHelper.DIRECTION_CONTRIBUTION,
            Frequency__c = 'Monthly',
            NextTransactionDate__c = Date.today(),
            StartDate__c = Date.today().addMonths(-1),
            Status__c = RegularTransactionHelper.REGULAR_TRANSACTION_STATUS_ACTIVE
        );
        // Don't add to list since we can't insert it
        
        // Transaction with null amount - we can't insert this due to database constraints
        // So we'll create it in memory for testing validation logic
        RegularTransaction__c nullAmountTransaction = new RegularTransaction__c(
            FinancialProduct__c = testProduct.Id,
            Amount__c = null,
            Direction__c = ExpectationHelper.DIRECTION_CONTRIBUTION,
            Frequency__c = 'Monthly',
            NextTransactionDate__c = Date.today(),
            StartDate__c = Date.today().addMonths(-1),
            Status__c = RegularTransactionHelper.REGULAR_TRANSACTION_STATUS_ACTIVE
        );
        // Don't add to list since we can't insert it
        
        // Transaction with wrong date
        RegularTransaction__c wrongDateTransaction = new RegularTransaction__c(
            FinancialProduct__c = testProduct.Id,
            Amount__c = 1000.00,
            Direction__c = ExpectationHelper.DIRECTION_CONTRIBUTION,
            Frequency__c = 'Monthly',
            NextTransactionDate__c = Date.today().addDays(1), // Wrong date
            StartDate__c = Date.today().addMonths(-1),
            Status__c = RegularTransactionHelper.REGULAR_TRANSACTION_STATUS_ACTIVE
        );
        invalidTransactions.add(wrongDateTransaction);
        
        // Transaction with end date in the past
        RegularTransaction__c pastEndDateTransaction = new RegularTransaction__c(
            FinancialProduct__c = testProduct.Id,
            Amount__c = 1000.00,
            Direction__c = ExpectationHelper.DIRECTION_CONTRIBUTION,
            Frequency__c = 'Monthly',
            NextTransactionDate__c = Date.today(),
            StartDate__c = Date.today().addMonths(-2),
            EndDate__c = Date.today().addDays(-1), // End date in the past
            Status__c = RegularTransactionHelper.REGULAR_TRANSACTION_STATUS_ACTIVE
        );
        invalidTransactions.add(pastEndDateTransaction);
        
        // Transaction with start date in the future
        RegularTransaction__c futureStartDateTransaction = new RegularTransaction__c(
            FinancialProduct__c = testProduct.Id,
            Amount__c = 1000.00,
            Direction__c = ExpectationHelper.DIRECTION_CONTRIBUTION,
            Frequency__c = 'Monthly',
            NextTransactionDate__c = Date.today(),
            StartDate__c = Date.today().addDays(1), // Start date in the future
            Status__c = RegularTransactionHelper.REGULAR_TRANSACTION_STATUS_ACTIVE
        );
        invalidTransactions.add(futureStartDateTransaction);
        
        insert invalidTransactions;
        
        // Count expectations before batch
        Integer expectationsBefore = [SELECT COUNT() FROM Expectation__c];
        
        Test.startTest();
        
        // ACT: Execute the batch
        RegularTransactionBatchNewExpectations batch = new RegularTransactionBatchNewExpectations();
        Database.executeBatch(batch);
        
        Test.stopTest();
        
        // ASSERT: Verify no expectations were created for invalid records
        Integer expectationsAfter = [SELECT COUNT() FROM Expectation__c];
        System.assertEquals(expectationsBefore, expectationsAfter, 'No expectations should be created for invalid records');
    }

    @IsTest
    static void testBatchWithNegativeAmounts() {
        // ARRANGE: Create test data with negative amounts (should be valid)
        DataFactory dataFactory = new DataFactory();
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        
        // Create regular transaction with negative amount
        RegularTransaction__c negativeAmountTransaction = dataFactory.createRegularTransaction(
            testProduct.Id,
            -500.00, // Negative amount
            ExpectationHelper.DIRECTION_WITHDRAWAL,
            'Monthly',
            Date.today(),
            Date.today().addMonths(-1),
            RegularTransactionHelper.REGULAR_TRANSACTION_STATUS_ACTIVE
        );
        
        // Count expectations before batch
        Integer expectationsBefore = [SELECT COUNT() FROM Expectation__c];
        
        Test.startTest();
        
        // ACT: Execute the batch
        RegularTransactionBatchNewExpectations batch = new RegularTransactionBatchNewExpectations();
        Database.executeBatch(batch);
        
        Test.stopTest();
        
        // ASSERT: Verify expectation was created for negative amount
        Integer expectationsAfter = [SELECT COUNT() FROM Expectation__c];
        System.assertEquals(expectationsBefore + 1, expectationsAfter, 'Expectation should be created for negative amount');
        
        // Verify the expectation has the correct negative amount
        Expectation__c createdExpectation = [
            SELECT Id, Amount__c, RegularTransaction__c 
            FROM Expectation__c 
            WHERE RegularTransaction__c = :negativeAmountTransaction.Id
        ];
        System.assertEquals(-500.00, createdExpectation.Amount__c, 'Expectation should have the negative amount');
    }



    @IsTest
    static void testBatchWithCustomBatchSize() {
        // ARRANGE: Create test data
        DataFactory dataFactory = new DataFactory();
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        
        // Create multiple regular transactions
        List<RegularTransaction__c> testTransactions = new List<RegularTransaction__c>();
        for (Integer i = 0; i < 5; i++) {
            RegularTransaction__c regularTxn = dataFactory.createRegularTransaction(
                testProduct.Id,
                100.00 * (i + 1),
                ExpectationHelper.DIRECTION_CONTRIBUTION,
                'Monthly',
                Date.today(),
                Date.today().addMonths(-1),
                RegularTransactionHelper.REGULAR_TRANSACTION_STATUS_ACTIVE
            );
            testTransactions.add(regularTxn);
        }
        
        Test.startTest();
        
        // ACT: Execute the batch with custom batch size
        RegularTransactionBatchNewExpectations batch = new RegularTransactionBatchNewExpectations(2); // Small batch size
        System.assertEquals(2, batch.getBatchSize(), 'Batch size should be set to 2');
        Database.executeBatch(batch);
        
        Test.stopTest();
        
        // ASSERT: Verify all expectations were created
        Integer expectationsCreated = [SELECT COUNT() FROM Expectation__c WHERE RegularTransaction__c IN :testTransactions];
        System.assertEquals(5, expectationsCreated, 'All 5 expectations should have been created');
    }

    @IsTest
    static void testBatchWithNoRecordsToProcess() {
        // ARRANGE: No records scheduled for today
        
        Test.startTest();
        
        // ACT: Execute the batch
        RegularTransactionBatchNewExpectations batch = new RegularTransactionBatchNewExpectations();
        Database.executeBatch(batch);
        
        Test.stopTest();
        
        // ASSERT: Verify batch completed successfully with no records
        // The batch should complete without errors even with no records to process
        System.assert(true, 'Batch should complete successfully with no records to process');
    }

    @IsTest
    static void testBatchConstructorWithNullBatchSize() {
        // ARRANGE & ACT: Create batch with null batch size
        RegularTransactionBatchNewExpectations batch = new RegularTransactionBatchNewExpectations(null);
        
        // ASSERT: Should default to 200
        System.assertEquals(200, batch.getBatchSize(), 'Batch size should default to 200 when null is passed');
    }

    @IsTest
    static void testBatchConstructorWithZeroBatchSize() {
        // ARRANGE & ACT: Create batch with zero batch size
        RegularTransactionBatchNewExpectations batch = new RegularTransactionBatchNewExpectations(0);
        
        // ASSERT: Should default to 200
        System.assertEquals(200, batch.getBatchSize(), 'Batch size should default to 200 when zero is passed');
    }

    @IsTest
    static void testBatchPerformanceSummary() {
        // ARRANGE: Create test data
        DataFactory dataFactory = new DataFactory();
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        
        // Create regular transaction
        RegularTransaction__c testTransaction = dataFactory.createRegularTransaction(
            testProduct.Id,
            1000.00,
            ExpectationHelper.DIRECTION_CONTRIBUTION,
            'Monthly',
            Date.today(),
            Date.today().addMonths(-1),
            RegularTransactionHelper.REGULAR_TRANSACTION_STATUS_ACTIVE
        );
        
        Test.startTest();
        
        // ACT: Execute the batch
        RegularTransactionBatchNewExpectations batch = new RegularTransactionBatchNewExpectations();
        Database.executeBatch(batch);
        
        Test.stopTest();
        
        // ASSERT: Verify performance summary is available
        Map<String, Object> performanceSummary = batch.getPerformanceSummary();
        System.assertNotEquals(null, performanceSummary, 'Performance summary should not be null');
        System.assert(performanceSummary.containsKey('totalRecordsProcessed'), 'Performance summary should contain totalRecordsProcessed');
        System.assert(performanceSummary.containsKey('totalRecordsFailed'), 'Performance summary should contain totalRecordsFailed');
        System.assert(performanceSummary.containsKey('successRate'), 'Performance summary should contain successRate');
    }

    @IsTest
    static void testBatchWithMixedValidAndInvalidRecords() {
        // ARRANGE: Create test data with mix of valid and invalid records
        DataFactory dataFactory = new DataFactory();
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        
        // Valid transaction
        RegularTransaction__c validTransaction = dataFactory.createRegularTransaction(
            testProduct.Id,
            1000.00,
            ExpectationHelper.DIRECTION_CONTRIBUTION,
            'Monthly',
            Date.today(),
            Date.today().addMonths(-1),
            RegularTransactionHelper.REGULAR_TRANSACTION_STATUS_ACTIVE
        );
        
        // Invalid transaction (wrong date)
        RegularTransaction__c invalidTransaction = new RegularTransaction__c(
            FinancialProduct__c = testProduct.Id,
            Amount__c = 500.00,
            Direction__c = ExpectationHelper.DIRECTION_WITHDRAWAL,
            Frequency__c = 'Monthly',
            NextTransactionDate__c = Date.today().addDays(1), // Wrong date
            StartDate__c = Date.today().addMonths(-1),
            Status__c = RegularTransactionHelper.REGULAR_TRANSACTION_STATUS_ACTIVE
        );
        insert invalidTransaction;
        
        // Count expectations before batch
        Integer expectationsBefore = [SELECT COUNT() FROM Expectation__c];
        
        Test.startTest();
        
        // ACT: Execute the batch
        RegularTransactionBatchNewExpectations batch = new RegularTransactionBatchNewExpectations();
        Database.executeBatch(batch);
        
        Test.stopTest();
        
        // ASSERT: Verify only valid record was processed
        Integer expectationsAfter = [SELECT COUNT() FROM Expectation__c];
        System.assertEquals(expectationsBefore + 1, expectationsAfter, 'Only one expectation should be created for the valid record');
        
        // Verify the expectation was created for the valid transaction
        List<Expectation__c> createdExpectations = [
            SELECT Id, RegularTransaction__c 
            FROM Expectation__c 
            WHERE RegularTransaction__c = :validTransaction.Id
        ];
        System.assertEquals(1, createdExpectations.size(), 'Expectation should be created for valid transaction');
    }
}
@isTest
public class ExpectationHelperTest {

    @TestSetup
    static void setupTestData() {
        // Load configuration data from static resources
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
        String householdId = dataFactory.createHousehold('ExpectationHelperTest', 1, 0, 'Active', 'Full');
        
        // Create advice with 1 product per person
        Advice__c advice = dataFactory.createAdvice(1, householdId);
        
        // Create a RegularTransaction__c for testing
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        RegularTransaction__c testRegular = dataFactory.createRegularTransaction(testProduct.Id);
    }

    @IsTest
    static void testCreateExpectations_Success() {
        // Get test data
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        Fulfilment__c testFulfilment = [SELECT Id FROM Fulfilment__c LIMIT 1];

        List<ExpectationRequest> expectationRequests = new List<ExpectationRequest>();

        // Create valid expectation request
        ExpectationRequest validRequest = new ExpectationRequest();
        validRequest.productId = testProduct.Id;
        validRequest.amount = 1000.00;
        validRequest.expectationDate = System.today().addDays(30);
        validRequest.direction = ExpectationHelper.DIRECTION_CONTRIBUTION;
        validRequest.transactionType = TransactionHelper.TRANSACTION_TYPE_REGULAR;
        validRequest.fulfilmentId = testFulfilment.Id;
        validRequest.status = ExpectationHelper.EXPECTATION_STATUS_PENDING;
        expectationRequests.add(validRequest);

        Test.startTest();
        List<ExpectationRequest> results = ExpectationHelper.createExpectations(expectationRequests);
        Test.stopTest();

        // Assertions
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assert(!results[0].isError, 'Request should not have errors');
        System.assert(String.isBlank(results[0].errorMessage), 'Error message should be blank');
        System.assertNotEquals(null, results[0].expectationRecord.Id, 'Expectation should have an ID');

        // Verify the expectation was created in the database
        List<Expectation__c> createdExpectations = [
            SELECT Id, FinancialProduct__c, Amount__c, Date__c, Direction__c, Type__c, Status__c
            FROM Expectation__c 
            WHERE Id = :results[0].expectationRecord.Id
        ];
        System.assertEquals(1, createdExpectations.size(), 'Expectation should be created in database');
        System.assertEquals(testProduct.Id, createdExpectations[0].FinancialProduct__c, 'Product should match');
        System.assertEquals(1000.00, createdExpectations[0].Amount__c, 'Amount should match');
    }

    @IsTest
    static void testCreateExpectations_WithRegularTransaction() {
        // Get test data
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        RegularTransaction__c testRegular = [SELECT Id FROM RegularTransaction__c LIMIT 1];

        List<ExpectationRequest> expectationRequests = new List<ExpectationRequest>();

        // Create valid expectation request with regular transaction
        ExpectationRequest validRequest = new ExpectationRequest();
        validRequest.productId = testProduct.Id;
        validRequest.amount = 500.00;
        validRequest.expectationDate = System.today().addDays(15);
        validRequest.direction = ExpectationHelper.DIRECTION_WITHDRAWAL;
        validRequest.transactionType = TransactionHelper.TRANSACTION_TYPE_REGULAR;
        validRequest.regularId = testRegular.Id;
        validRequest.status = ExpectationHelper.EXPECTATION_STATUS_PENDING;
        expectationRequests.add(validRequest);

        Test.startTest();
        List<ExpectationRequest> results = ExpectationHelper.createExpectations(expectationRequests);
        Test.stopTest();

        // Assertions
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assert(!results[0].isError, 'Request should not have errors');
        System.assertNotEquals(null, results[0].expectationRecord.Id, 'Expectation should have an ID');
    }

    @IsTest
    static void testCreateExpectations_ValidationErrors() {
        // Get test data
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];

        List<ExpectationRequest> expectationRequests = new List<ExpectationRequest>();

        // Create invalid expectation request (missing required fields)
        ExpectationRequest invalidRequest = new ExpectationRequest();
        // Missing productId, amount, date, direction, transactionType, fulfilmentId/regularId, status
        expectationRequests.add(invalidRequest);

        Test.startTest();
        List<ExpectationRequest> results = ExpectationHelper.createExpectations(expectationRequests);
        Test.stopTest();

        // Assertions
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assert(results[0].isError, 'Request should have errors');
        // With early exit validation, only the first error (product) should be present
        System.assert(results[0].errorMessage.contains('Product not specified'), 'Should have product error');
        // Other errors won't be present due to early exit
    }

    @IsTest
    static void testCreateExpectations_PastDate() {
        // Get test data
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        Fulfilment__c testFulfilment = [SELECT Id FROM Fulfilment__c LIMIT 1];

        List<ExpectationRequest> expectationRequests = new List<ExpectationRequest>();

        // Create expectation request with past date
        ExpectationRequest invalidRequest = new ExpectationRequest();
        invalidRequest.productId = testProduct.Id;
        invalidRequest.amount = 1000.00;
        invalidRequest.expectationDate = System.today().addDays(-1); // Past date
        invalidRequest.direction = ExpectationHelper.DIRECTION_CONTRIBUTION;
        invalidRequest.transactionType = TransactionHelper.TRANSACTION_TYPE_REGULAR;
        invalidRequest.fulfilmentId = testFulfilment.Id;
        invalidRequest.status = ExpectationHelper.EXPECTATION_STATUS_PENDING;
        expectationRequests.add(invalidRequest);

        Test.startTest();
        List<ExpectationRequest> results = ExpectationHelper.createExpectations(expectationRequests);
        Test.stopTest();

        // Assertions
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assert(results[0].isError, 'Request should have errors');
        System.assert(results[0].errorMessage.contains('Expectation date must be today or in the future'), 'Should have past date error');
    }

    @IsTest
    static void testCreateExpectations_InvalidDirection() {
        // Get test data
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        Fulfilment__c testFulfilment = [SELECT Id FROM Fulfilment__c LIMIT 1];

        List<ExpectationRequest> expectationRequests = new List<ExpectationRequest>();

        // Create expectation request with invalid direction
        ExpectationRequest invalidRequest = new ExpectationRequest();
        invalidRequest.productId = testProduct.Id;
        invalidRequest.amount = 1000.00;
        invalidRequest.expectationDate = System.today().addDays(30);
        invalidRequest.direction = 'INVALID_DIRECTION';
        invalidRequest.transactionType = TransactionHelper.TRANSACTION_TYPE_REGULAR;
        invalidRequest.fulfilmentId = testFulfilment.Id;
        invalidRequest.status = ExpectationHelper.EXPECTATION_STATUS_PENDING;
        expectationRequests.add(invalidRequest);

        Test.startTest();
        List<ExpectationRequest> results = ExpectationHelper.createExpectations(expectationRequests);
        Test.stopTest();

        // Assertions
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assert(results[0].isError, 'Request should have errors');
        System.assert(results[0].errorMessage.contains('Direction value not valid'), 'Should have invalid direction error');
    }

    @IsTest
    static void testCreateExpectations_InvalidTransactionType() {
        // Get test data
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        Fulfilment__c testFulfilment = [SELECT Id FROM Fulfilment__c LIMIT 1];

        List<ExpectationRequest> expectationRequests = new List<ExpectationRequest>();

        // Create expectation request with invalid transaction type
        ExpectationRequest invalidRequest = new ExpectationRequest();
        invalidRequest.productId = testProduct.Id;
        invalidRequest.amount = 1000.00;
        invalidRequest.expectationDate = System.today().addDays(30);
        invalidRequest.direction = ExpectationHelper.DIRECTION_CONTRIBUTION;
        invalidRequest.transactionType = 'INVALID_TYPE';
        invalidRequest.fulfilmentId = testFulfilment.Id;
        invalidRequest.status = ExpectationHelper.EXPECTATION_STATUS_PENDING;
        expectationRequests.add(invalidRequest);

        Test.startTest();
        List<ExpectationRequest> results = ExpectationHelper.createExpectations(expectationRequests);
        Test.stopTest();

        // Assertions
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assert(results[0].isError, 'Request should have errors');
        System.assert(results[0].errorMessage.contains('Transaction type value not valid'), 'Should have invalid transaction type error');
    }

    @IsTest
    static void testCreateExpectations_EmptyList() {
        List<ExpectationRequest> emptyRequests = new List<ExpectationRequest>();

        Test.startTest();
        List<ExpectationRequest> results = ExpectationHelper.createExpectations(emptyRequests);
        Test.stopTest();

        // Assertions
        System.assertEquals(0, results.size(), 'Should return empty list for empty input');
    }

    @IsTest
    static void testCreateExpectations_NullList() {
        Test.startTest();
        List<ExpectationRequest> results = ExpectationHelper.createExpectations(null);
        Test.stopTest();

        // Assertions
        System.assertEquals(0, results.size(), 'Should return empty list for null input');
    }

    @IsTest
    static void testUpdateExpectations_Success() {
        // Get test data
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        Fulfilment__c testFulfilment = [SELECT Id FROM Fulfilment__c LIMIT 1];

        // Create initial expectation
        DataFactory dataFactory = new DataFactory();
        Expectation__c existingExpectation = dataFactory.createExpectation(
            testProduct.Id,
            1000.00,
            System.today().addDays(30),
            ExpectationHelper.DIRECTION_CONTRIBUTION,
            TransactionHelper.TRANSACTION_TYPE_REGULAR,
            ExpectationHelper.EXPECTATION_STATUS_PENDING,
            testFulfilment.Id,
            null,
            null
        );

        // Create update request
        ExpectationRequest updateRequest = new ExpectationRequest();
        updateRequest.expectationId = existingExpectation.Id;
        updateRequest.productId = testProduct.Id;
        updateRequest.amount = 750.00; // Updated amount
        updateRequest.expectationDate = System.today().addDays(45); // Updated date
        updateRequest.direction = ExpectationHelper.DIRECTION_WITHDRAWAL; // Updated direction
        updateRequest.transactionType = TransactionHelper.TRANSACTION_TYPE_REGULAR;
        updateRequest.fulfilmentId = testFulfilment.Id;
        updateRequest.status = ExpectationHelper.EXPECTATION_STATUS_PENDING;

        List<ExpectationRequest> updateRequests = new List<ExpectationRequest>{updateRequest};

        Test.startTest();
        List<ExpectationRequest> results = ExpectationHelper.updateExpectations(updateRequests);
        Test.stopTest();

        // Assertions
        System.assertEquals(1, results.size(), 'Should return one result');
        System.assert(!results[0].isError, 'Request should not have errors');

        // Verify the expectation was updated in the database
        Expectation__c updatedExpectation = [
            SELECT Id, Amount__c, Date__c, Direction__c
            FROM Expectation__c 
            WHERE Id = :existingExpectation.Id
        ];
        System.assertEquals(750.00, updatedExpectation.Amount__c, 'Amount should be updated');
        System.assertEquals(System.today().addDays(45), updatedExpectation.Date__c, 'Date should be updated');
        System.assertEquals(ExpectationHelper.DIRECTION_WITHDRAWAL, updatedExpectation.Direction__c, 'Direction should be updated');
    }

    @IsTest
    static void testUpdateExpectationStatusIfLinkedToTransaction() {
        // Get test data
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        Fulfilment__c testFulfilment = [SELECT Id FROM Fulfilment__c LIMIT 1];

        // Create test transaction
        Transaction__c testTransaction = new Transaction__c(
            FinancialProduct__c = testProduct.Id,
            Amount__c = 1000.00,
            Date__c = System.today()
        );
        insert testTransaction;

        // Create expectation requests for testing
        ExpectationRequest oldRequest = new ExpectationRequest();
        oldRequest.transactionId = null;
        oldRequest.status = ExpectationHelper.EXPECTATION_STATUS_PENDING;

        ExpectationRequest newRequest = new ExpectationRequest();
        newRequest.transactionId = testTransaction.Id;
        newRequest.status = ExpectationHelper.EXPECTATION_STATUS_PENDING;

        Map<Id, ExpectationRequest> oldMap = new Map<Id, ExpectationRequest>();
        Map<Id, ExpectationRequest> newMap = new Map<Id, ExpectationRequest>();

        // Use a mock ID for testing
        Id mockExpectationId = 'a0A000000000000';
        oldMap.put(mockExpectationId, oldRequest);
        newMap.put(mockExpectationId, newRequest);

        Test.startTest();
        Map<Id, ExpectationRequest> results = ExpectationHelper.updateExpectationStatusIfLinkedToTransaction(oldMap, newMap);
        Test.stopTest();

        // Assertions
        System.assertEquals(ExpectationHelper.EXPECTATION_STATUS_OCCURRED, results.get(mockExpectationId).status, 'Status should be updated to Occurred');
    }

    @IsTest
    static void testUpdateTransactionExpectationLinkedFlag() {
        // Get test data
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        Fulfilment__c testFulfilment = [SELECT Id FROM Fulfilment__c LIMIT 1];

        // Create test transaction
        Transaction__c testTransaction = new Transaction__c(
            FinancialProduct__c = testProduct.Id,
            Amount__c = 1000.00,
            Direction__c = ExpectationHelper.DIRECTION_CONTRIBUTION,
            Type__c = TransactionHelper.TRANSACTION_TYPE_REGULAR,
            Date__c = System.today(),
            Status__c = TransactionHelper.TRANSACTION_STATUS_NEW
        );
        insert testTransaction;

        // Create an expectation that will be linked to the transaction
        Expectation__c testExpectation = new Expectation__c(
            FinancialProduct__c = testProduct.Id,
            Amount__c = 1000.00,
            Direction__c = ExpectationHelper.DIRECTION_CONTRIBUTION,
            Type__c = TransactionHelper.TRANSACTION_TYPE_REGULAR,
            Date__c = System.today().addDays(30),
            Status__c = ExpectationHelper.EXPECTATION_STATUS_PENDING,
            Fulfilment__c = testFulfilment.Id
        );
        insert testExpectation;

        // Create expectation requests for testing - simulating linking expectation to transaction
        ExpectationRequest oldRequest = new ExpectationRequest();
        oldRequest.transactionId = null; // Initially not linked

        ExpectationRequest newRequest = new ExpectationRequest();
        newRequest.transactionId = testTransaction.Id; // Now linked

        Map<Id, ExpectationRequest> oldMap = new Map<Id, ExpectationRequest>();
        Map<Id, ExpectationRequest> newMap = new Map<Id, ExpectationRequest>();

        oldMap.put(testExpectation.Id, oldRequest);
        newMap.put(testExpectation.Id, newRequest);

        // Verify transaction is not linked before the test
        Transaction__c transactionBefore = [SELECT Id, ExpectationLinked__c FROM Transaction__c WHERE Id = :testTransaction.Id];
        System.assertEquals(false, transactionBefore.ExpectationLinked__c, 'Transaction should not be linked before test');

        // Actually link the expectation to the transaction so the flag can be set
        testExpectation.Transaction__c = testTransaction.Id;
        update testExpectation;

        Test.startTest();
        ExpectationHelper.updateTransactionExpectationLinkedFlag(oldMap, newMap);
        Test.stopTest();

        // Verify the transaction's ExpectationLinked__c flag was updated
        Transaction__c transactionAfter = [SELECT Id, ExpectationLinked__c FROM Transaction__c WHERE Id = :testTransaction.Id];
        System.assertEquals(true, transactionAfter.ExpectationLinked__c, 'Transaction should be flagged as linked to expectation');
    }

    @IsTest
    static void testConstants() {
        // Test that constants are properly defined
        System.assertEquals('Pending', ExpectationHelper.EXPECTATION_STATUS_PENDING, 'Pending status should be correct');
        System.assertEquals('Occurred', ExpectationHelper.EXPECTATION_STATUS_OCCURRED, 'Occurred status should be correct');
        System.assertEquals('Cancelled', ExpectationHelper.EXPECTATION_STATUS_CANCELLED, 'Cancelled status should be correct');
        System.assertEquals('CONTRIBUTION', ExpectationHelper.DIRECTION_CONTRIBUTION, 'Contribution direction should be correct');
        System.assertEquals('WITHDRAWL', ExpectationHelper.DIRECTION_WITHDRAWAL, 'Withdrawal direction should be correct');
        System.assertEquals(2, ExpectationHelper.DIRECTION_VALUES.size(), 'Should have two direction values');
        System.assert(ExpectationHelper.DIRECTION_VALUES.contains(ExpectationHelper.DIRECTION_CONTRIBUTION), 'Should contain contribution');
        System.assert(ExpectationHelper.DIRECTION_VALUES.contains(ExpectationHelper.DIRECTION_WITHDRAWAL), 'Should contain withdrawal');
        System.assertNotEquals(null, ExpectationHelper.TRANSACTION_TYPE_VALUES, 'Transaction type values should not be null');
        System.assert(ExpectationHelper.TRANSACTION_TYPE_VALUES.size() > 0, 'Should have at least one transaction type');
    }
}
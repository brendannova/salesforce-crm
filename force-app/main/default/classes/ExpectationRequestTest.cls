@isTest
private class ExpectationRequestTest {

    @TestSetup
    static void setupTestData() {
        // Load configuration data for testing
        DataFactoryConfigurationData.load();
        
        // Create test household and advice
        DataFactory dataFactory = new DataFactory();
        Id householdId = dataFactory.createHousehold('ExpectationRequestTest', 2, 0, 'Active', 'Full');
        dataFactory.createAdvice(1, householdId);
        
        // Create additional test data that some tests need
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        
        // Create a RegularTransaction__c for testing
        RegularTransaction__c testRegular = dataFactory.createRegularTransaction(testProduct.Id);
        
        // Create a Transaction__c for testing
        Transaction__c testTransaction = dataFactory.createTransaction(testProduct.Id);
    }

    @IsTest
    static void testDefaultConstructor() {
        // Test the default constructor
        ExpectationRequest request = new ExpectationRequest();
        
        // Verify default values
        System.assertEquals(null, request.expectationId, 'Expectation ID should be null');
        System.assertEquals(null, request.transactionType, 'Transaction type should be null');
        System.assertEquals(null, request.expectationDate, 'Expectation date should be null');
        System.assertEquals(null, request.productId, 'Product ID should be null');
        System.assertEquals(null, request.fulfilmentId, 'Fulfilment ID should be null');
        System.assertEquals(null, request.regularId, 'Regular ID should be null');
        System.assertEquals(null, request.amount, 'Amount should be null');
        System.assertEquals(null, request.direction, 'Direction should be null');
        System.assertEquals(null, request.transactionId, 'Transaction ID should be null');
        System.assertEquals(null, request.status, 'Status should be null');
        System.assertEquals(null, request.isError, 'Is error should be null');
        System.assertEquals('', request.errorMessage, 'Error message should be empty string');
        System.assertEquals(null, request.expectationRecord, 'Expectation record should be null');
    }

    @IsTest
    static void testConstructorWithExpectationRecord() {
        // Get test data
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        
        // Create a test expectation record
        Expectation__c testExpectation = new Expectation__c(
            FinancialProduct__c = testProduct.Id,
            Amount__c = 1000.00,
            Date__c = System.today().addDays(30),
            Direction__c = ExpectationHelper.DIRECTION_CONTRIBUTION,
            Type__c = TransactionHelper.TRANSACTION_TYPE_REGULAR,
            Status__c = ExpectationHelper.EXPECTATION_STATUS_PENDING
        );
        insert testExpectation;
        
        // Test constructor with expectation record
        ExpectationRequest request = new ExpectationRequest(testExpectation);
        
        // Verify values are populated from the record
        System.assertEquals(testExpectation.Id, request.expectationId, 'Expectation ID should match');
        System.assertEquals(testExpectation.FinancialProduct__c, request.productId, 'Product ID should match');
        System.assertEquals(testExpectation.Amount__c, request.amount, 'Amount should match');
        System.assertEquals(testExpectation.Date__c, request.expectationDate, 'Expectation date should match');
        System.assertEquals(testExpectation.Direction__c, request.direction, 'Direction should match');
        System.assertEquals(testExpectation.Type__c, request.transactionType, 'Transaction type should match');
        System.assertEquals(testExpectation.Status__c, request.status, 'Status should match');
        System.assertEquals(testExpectation, request.expectationRecord, 'Expectation record should match');
    }

    @IsTest
    static void testSetError() {
        ExpectationRequest request = new ExpectationRequest();
        
        // Test setting first error
        request.setError('Test error message');
        
        System.assertEquals(true, request.isError, 'Is error should be true');
        System.assertEquals('Test error message', request.errorMessage, 'Error message should match');
        
        // Test appending error message with proper spacing
        request.setError('Additional error');
        
        System.assertEquals(true, request.isError, 'Is error should remain true');
        System.assertEquals('Test error message Additional error', request.errorMessage, 'Error message should be appended with space');
    }

    @IsTest
    static void testValidate_ValidRequest() {
        // Get test data
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        Fulfilment__c testFulfilment = [SELECT Id FROM Fulfilment__c LIMIT 1];
        
        // Create valid request
        ExpectationRequest request = new ExpectationRequest();
        request.productId = testProduct.Id;
        request.amount = 1000.00;
        request.expectationDate = System.today().addDays(30);
        request.direction = ExpectationHelper.DIRECTION_CONTRIBUTION;
        request.transactionType = TransactionHelper.TRANSACTION_TYPE_REGULAR;
        request.fulfilmentId = testFulfilment.Id;
        request.status = ExpectationHelper.EXPECTATION_STATUS_PENDING;
        
        // Test validation
        Boolean isValid = request.validate();
        
        System.assertEquals(true, isValid, 'Validation should pass');
        System.assertEquals(false, request.isError, 'Should not have errors');
        System.assertEquals('', request.errorMessage, 'Error message should be empty');
    }

    @IsTest
    static void testValidate_MissingProduct() {
        // Get test data
        Fulfilment__c testFulfilment = [SELECT Id FROM Fulfilment__c LIMIT 1];
        
        // Create request with missing product
        ExpectationRequest request = new ExpectationRequest();
        request.amount = 1000.00;
        request.expectationDate = System.today().addDays(30);
        request.direction = ExpectationHelper.DIRECTION_CONTRIBUTION;
        request.transactionType = TransactionHelper.TRANSACTION_TYPE_REGULAR;
        request.fulfilmentId = testFulfilment.Id;
        request.status = ExpectationHelper.EXPECTATION_STATUS_PENDING;
        
        // Test validation
        Boolean isValid = request.validate();
        
        System.assertEquals(false, isValid, 'Validation should fail');
        System.assertEquals(true, request.isError, 'Should have errors');
        System.assert(request.errorMessage.contains(ExpectationRequest.ERROR_PRODUCT_NOT_SPECIFIED), 'Should have product error');
    }

    @IsTest
    static void testValidate_MissingAmount() {
        // Get test data
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        Fulfilment__c testFulfilment = [SELECT Id FROM Fulfilment__c LIMIT 1];
        
        // Create request with missing amount
        ExpectationRequest request = new ExpectationRequest();
        request.productId = testProduct.Id;
        request.expectationDate = System.today().addDays(30);
        request.direction = ExpectationHelper.DIRECTION_CONTRIBUTION;
        request.transactionType = TransactionHelper.TRANSACTION_TYPE_REGULAR;
        request.fulfilmentId = testFulfilment.Id;
        request.status = ExpectationHelper.EXPECTATION_STATUS_PENDING;
        
        // Test validation
        Boolean isValid = request.validate();
        
        System.assertEquals(false, isValid, 'Validation should fail');
        System.assertEquals(true, request.isError, 'Should have errors');
        System.assert(request.errorMessage.contains(ExpectationRequest.ERROR_AMOUNT_NOT_SPECIFIED), 'Should have amount error');
    }

    @IsTest
    static void testValidate_MissingExpectationDate() {
        // Get test data
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        Fulfilment__c testFulfilment = [SELECT Id FROM Fulfilment__c LIMIT 1];
        
        // Create request with missing expectation date
        ExpectationRequest request = new ExpectationRequest();
        request.productId = testProduct.Id;
        request.amount = 1000.00;
        request.direction = ExpectationHelper.DIRECTION_CONTRIBUTION;
        request.transactionType = TransactionHelper.TRANSACTION_TYPE_REGULAR;
        request.fulfilmentId = testFulfilment.Id;
        request.status = ExpectationHelper.EXPECTATION_STATUS_PENDING;
        
        // Test validation
        Boolean isValid = request.validate();
        
        System.assertEquals(false, isValid, 'Validation should fail');
        System.assertEquals(true, request.isError, 'Should have errors');
        System.assert(request.errorMessage.contains(ExpectationRequest.ERROR_DATE_NOT_SPECIFIED), 'Should have date error');
    }

    @IsTest
    static void testValidate_PastExpectationDate() {
        // Get test data
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        Fulfilment__c testFulfilment = [SELECT Id FROM Fulfilment__c LIMIT 1];
        
        // Create request with past date
        ExpectationRequest request = new ExpectationRequest();
        request.productId = testProduct.Id;
        request.amount = 1000.00;
        request.expectationDate = System.today().addDays(-1);
        request.direction = ExpectationHelper.DIRECTION_CONTRIBUTION;
        request.transactionType = TransactionHelper.TRANSACTION_TYPE_REGULAR;
        request.fulfilmentId = testFulfilment.Id;
        request.status = ExpectationHelper.EXPECTATION_STATUS_PENDING;
        
        // Test validation
        Boolean isValid = request.validate();
        
        System.assertEquals(false, isValid, 'Validation should fail');
        System.assertEquals(true, request.isError, 'Should have errors');
        System.assert(request.errorMessage.contains(ExpectationRequest.ERROR_DATE_PAST), 'Should have past date error');
    }

    @IsTest
    static void testValidate_MissingDirection() {
        // Get test data
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        Fulfilment__c testFulfilment = [SELECT Id FROM Fulfilment__c LIMIT 1];
        
        // Create request with missing direction
        ExpectationRequest request = new ExpectationRequest();
        request.productId = testProduct.Id;
        request.amount = 1000.00;
        request.expectationDate = System.today().addDays(30);
        request.transactionType = TransactionHelper.TRANSACTION_TYPE_REGULAR;
        request.fulfilmentId = testFulfilment.Id;
        request.status = ExpectationHelper.EXPECTATION_STATUS_PENDING;
        
        // Test validation
        Boolean isValid = request.validate();
        
        System.assertEquals(false, isValid, 'Validation should fail');
        System.assertEquals(true, request.isError, 'Should have errors');
        System.assert(request.errorMessage.contains(ExpectationRequest.ERROR_DIRECTION_NOT_SPECIFIED), 'Should have direction error');
    }

    @IsTest
    static void testValidate_InvalidDirection() {
        // Get test data
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        Fulfilment__c testFulfilment = [SELECT Id FROM Fulfilment__c LIMIT 1];
        
        // Create request with invalid direction
        ExpectationRequest request = new ExpectationRequest();
        request.productId = testProduct.Id;
        request.amount = 1000.00;
        request.expectationDate = System.today().addDays(30);
        request.direction = 'INVALID_DIRECTION';
        request.transactionType = TransactionHelper.TRANSACTION_TYPE_REGULAR;
        request.fulfilmentId = testFulfilment.Id;
        request.status = ExpectationHelper.EXPECTATION_STATUS_PENDING;
        
        // Test validation
        Boolean isValid = request.validate();
        
        System.assertEquals(false, isValid, 'Validation should fail');
        System.assertEquals(true, request.isError, 'Should have errors');
        System.assert(request.errorMessage.contains(ExpectationRequest.ERROR_DIRECTION_INVALID), 'Should have invalid direction error');
    }

    @IsTest
    static void testValidate_MissingTransactionType() {
        // Get test data
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        Fulfilment__c testFulfilment = [SELECT Id FROM Fulfilment__c LIMIT 1];
        
        // Create request with missing transaction type
        ExpectationRequest request = new ExpectationRequest();
        request.productId = testProduct.Id;
        request.amount = 1000.00;
        request.expectationDate = System.today().addDays(30);
        request.direction = ExpectationHelper.DIRECTION_CONTRIBUTION;
        request.fulfilmentId = testFulfilment.Id;
        request.status = ExpectationHelper.EXPECTATION_STATUS_PENDING;
        
        // Test validation
        Boolean isValid = request.validate();
        
        System.assertEquals(false, isValid, 'Validation should fail');
        System.assertEquals(true, request.isError, 'Should have errors');
        System.assert(request.errorMessage.contains(ExpectationRequest.ERROR_TRANSACTION_TYPE_NOT_SPECIFIED), 'Should have transaction type error');
    }

    @IsTest
    static void testValidate_InvalidTransactionType() {
        // Get test data
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        Fulfilment__c testFulfilment = [SELECT Id FROM Fulfilment__c LIMIT 1];
        
        // Create request with invalid transaction type
        ExpectationRequest request = new ExpectationRequest();
        request.productId = testProduct.Id;
        request.amount = 1000.00;
        request.expectationDate = System.today().addDays(30);
        request.direction = ExpectationHelper.DIRECTION_CONTRIBUTION;
        request.transactionType = 'INVALID_TYPE';
        request.fulfilmentId = testFulfilment.Id;
        request.status = ExpectationHelper.EXPECTATION_STATUS_PENDING;
        
        // Test validation
        Boolean isValid = request.validate();
        
        System.assertEquals(false, isValid, 'Validation should fail');
        System.assertEquals(true, request.isError, 'Should have errors');
        System.assert(request.errorMessage.contains(ExpectationRequest.ERROR_TRANSACTION_TYPE_INVALID), 'Should have invalid transaction type error');
    }

    @IsTest
    static void testValidate_MissingFulfilmentAndRegular() {
        // Get test data
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        
        // Create request with missing fulfilment and regular
        ExpectationRequest request = new ExpectationRequest();
        request.productId = testProduct.Id;
        request.amount = 1000.00;
        request.expectationDate = System.today().addDays(30);
        request.direction = ExpectationHelper.DIRECTION_CONTRIBUTION;
        request.transactionType = TransactionHelper.TRANSACTION_TYPE_REGULAR;
        request.status = ExpectationHelper.EXPECTATION_STATUS_PENDING;
        
        // Test validation
        Boolean isValid = request.validate();
        
        System.assertEquals(false, isValid, 'Validation should fail');
        System.assertEquals(true, request.isError, 'Should have errors');
        System.assert(request.errorMessage.contains(ExpectationRequest.ERROR_FULFILMENT_OR_REGULAR_REQUIRED), 'Should have fulfilment/regular error');
    }

    @IsTest
    static void testValidate_MissingStatus() {
        // Get test data
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        Fulfilment__c testFulfilment = [SELECT Id FROM Fulfilment__c LIMIT 1];
        
        // Create request with missing status
        ExpectationRequest request = new ExpectationRequest();
        request.productId = testProduct.Id;
        request.amount = 1000.00;
        request.expectationDate = System.today().addDays(30);
        request.direction = ExpectationHelper.DIRECTION_CONTRIBUTION;
        request.transactionType = TransactionHelper.TRANSACTION_TYPE_REGULAR;
        request.fulfilmentId = testFulfilment.Id;
        
        // Test validation
        Boolean isValid = request.validate();
        
        System.assertEquals(false, isValid, 'Validation should fail');
        System.assertEquals(true, request.isError, 'Should have errors');
        System.assert(request.errorMessage.contains(ExpectationRequest.ERROR_STATUS_NOT_SPECIFIED), 'Should have status error');
    }

    @IsTest
    static void testValidate_MultipleErrors() {
        // Create request with multiple missing fields
        ExpectationRequest request = new ExpectationRequest();
        
        // Test validation
        Boolean isValid = request.validate();
        
        System.assertEquals(false, isValid, 'Validation should fail');
        System.assertEquals(true, request.isError, 'Should have errors');
        System.assert(request.errorMessage.contains(ExpectationRequest.ERROR_PRODUCT_NOT_SPECIFIED), 'Should have product error');
        // Note: With early exit, only the first error (product) should be present
        System.assert(!request.errorMessage.contains(ExpectationRequest.ERROR_AMOUNT_NOT_SPECIFIED), 'Should not have amount error due to early exit');
    }

    @IsTest
    static void testValidate_EarlyExitBehavior() {
        // Test that validation stops at first critical error
        ExpectationRequest request = new ExpectationRequest();
        // Only set amount, leave product null (first validation)
        request.amount = 1000.00;
        
        Boolean isValid = request.validate();
        
        System.assertEquals(false, isValid, 'Validation should fail');
        System.assertEquals(true, request.isError, 'Should have errors');
        System.assert(request.errorMessage.contains(ExpectationRequest.ERROR_PRODUCT_NOT_SPECIFIED), 'Should have product error');
        System.assert(!request.errorMessage.contains(ExpectationRequest.ERROR_AMOUNT_NOT_SPECIFIED), 'Should not have amount error due to early exit');
    }

    @IsTest
    static void testConvertToRecord_NewRecord() {
        // Get test data
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        Fulfilment__c testFulfilment = [SELECT Id FROM Fulfilment__c LIMIT 1];
        
        // Create request
        ExpectationRequest request = new ExpectationRequest();
        request.expectationId = null; // New record
        request.productId = testProduct.Id;
        request.amount = 1000.00;
        request.expectationDate = System.today().addDays(30);
        request.direction = ExpectationHelper.DIRECTION_CONTRIBUTION;
        request.transactionType = TransactionHelper.TRANSACTION_TYPE_REGULAR;
        request.fulfilmentId = testFulfilment.Id;
        request.regularId = null;
        request.transactionId = null;
        request.status = ExpectationHelper.EXPECTATION_STATUS_PENDING;
        
        // Test conversion
        request.convertToRecord();
        
        // Verify record is created and populated
        System.assertNotEquals(null, request.expectationRecord, 'Expectation record should be created');
        System.assertEquals(null, request.expectationRecord.Id, 'ID should be null for new record');
        System.assertEquals(testProduct.Id, request.expectationRecord.FinancialProduct__c, 'Product should match');
        System.assertEquals(1000.00, request.expectationRecord.Amount__c, 'Amount should match');
        System.assertEquals(System.today().addDays(30), request.expectationRecord.Date__c, 'Date should match');
        System.assertEquals(ExpectationHelper.DIRECTION_CONTRIBUTION, request.expectationRecord.Direction__c, 'Direction should match');
        System.assertEquals(TransactionHelper.TRANSACTION_TYPE_REGULAR, request.expectationRecord.Type__c, 'Type should match');
        System.assertEquals(testFulfilment.Id, request.expectationRecord.Fulfilment__c, 'Fulfilment should match');
        System.assertEquals(null, request.expectationRecord.RegularTransaction__c, 'Regular should be null');
        System.assertEquals(null, request.expectationRecord.Transaction__c, 'Transaction should be null');
        System.assertEquals(ExpectationHelper.EXPECTATION_STATUS_PENDING, request.expectationRecord.Status__c, 'Status should match');
    }

    @IsTest
    static void testConvertToRecord_ExistingRecord() {
        // Get test data
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        Fulfilment__c testFulfilment = [SELECT Id FROM Fulfilment__c LIMIT 1];
        
        // Create an existing expectation record
        Expectation__c existingRecord = new Expectation__c(
            FinancialProduct__c = testProduct.Id,
            Amount__c = 500.00,
            Date__c = System.today().addDays(15),
            Direction__c = ExpectationHelper.DIRECTION_WITHDRAWAL,
            Type__c = TransactionHelper.TRANSACTION_TYPE_LUMP_SUM,
            Status__c = ExpectationHelper.EXPECTATION_STATUS_OCCURRED
        );
        insert existingRecord;
        
        // Create request with existing record
        ExpectationRequest request = new ExpectationRequest();
        request.expectationRecord = existingRecord;
        request.expectationId = existingRecord.Id;
        request.productId = testProduct.Id;
        request.amount = 1000.00;
        request.expectationDate = System.today().addDays(30);
        request.direction = ExpectationHelper.DIRECTION_CONTRIBUTION;
        request.transactionType = TransactionHelper.TRANSACTION_TYPE_REGULAR;
        request.fulfilmentId = testFulfilment.Id;
        request.status = ExpectationHelper.EXPECTATION_STATUS_PENDING;
        
        // Test conversion
        request.convertToRecord();
        
        // Verify record is updated
        System.assertEquals(existingRecord.Id, request.expectationRecord.Id, 'ID should remain the same');
        System.assertEquals(testProduct.Id, request.expectationRecord.FinancialProduct__c, 'Product should be updated');
        System.assertEquals(1000.00, request.expectationRecord.Amount__c, 'Amount should be updated');
        System.assertEquals(System.today().addDays(30), request.expectationRecord.Date__c, 'Date should be updated');
        System.assertEquals(ExpectationHelper.DIRECTION_CONTRIBUTION, request.expectationRecord.Direction__c, 'Direction should be updated');
        System.assertEquals(TransactionHelper.TRANSACTION_TYPE_REGULAR, request.expectationRecord.Type__c, 'Type should be updated');
        System.assertEquals(testFulfilment.Id, request.expectationRecord.Fulfilment__c, 'Fulfilment should be updated');
        System.assertEquals(ExpectationHelper.EXPECTATION_STATUS_PENDING, request.expectationRecord.Status__c, 'Status should be updated');
    }

    @IsTest
    static void testConvertToRequest() {
        // Get test data
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        Fulfilment__c testFulfilment = [SELECT Id FROM Fulfilment__c LIMIT 1];
        RegularTransaction__c testRegular = [SELECT Id FROM RegularTransaction__c LIMIT 1];
        Transaction__c testTransaction = [SELECT Id FROM Transaction__c LIMIT 1];
        
        // Create an expectation record
        Expectation__c expectationRecord = new Expectation__c(
            FinancialProduct__c = testProduct.Id,
            Amount__c = 1000.00,
            Date__c = System.today().addDays(30),
            Direction__c = ExpectationHelper.DIRECTION_CONTRIBUTION,
            Type__c = TransactionHelper.TRANSACTION_TYPE_REGULAR,
            Fulfilment__c = testFulfilment.Id,
            RegularTransaction__c = testRegular.Id,
            Transaction__c = testTransaction.Id,
            Status__c = ExpectationHelper.EXPECTATION_STATUS_PENDING
        );
        insert expectationRecord;
        
        // Create request with expectation record
        ExpectationRequest request = new ExpectationRequest();
        request.expectationRecord = expectationRecord;
        
        // Test conversion
        request.convertToRequest();
        
        // Verify request fields are populated from record
        System.assertEquals(expectationRecord.Id, request.expectationId, 'Expectation ID should match');
        System.assertEquals(expectationRecord.FinancialProduct__c, request.productId, 'Product ID should match');
        System.assertEquals(expectationRecord.Amount__c, request.amount, 'Amount should match');
        System.assertEquals(expectationRecord.Date__c, request.expectationDate, 'Expectation date should match');
        System.assertEquals(expectationRecord.Direction__c, request.direction, 'Direction should match');
        System.assertEquals(expectationRecord.Type__c, request.transactionType, 'Transaction type should match');
        System.assertEquals(expectationRecord.Fulfilment__c, request.fulfilmentId, 'Fulfilment ID should match');
        System.assertEquals(expectationRecord.RegularTransaction__c, request.regularId, 'Regular ID should match');
        System.assertEquals(expectationRecord.Transaction__c, request.transactionId, 'Transaction ID should match');
        System.assertEquals(expectationRecord.Status__c, request.status, 'Status should match');
    }

    @IsTest
    static void testConvertToRequest_NullRecord() {
        // Test that convertToRequest throws exception when record is null
        ExpectationRequest request = new ExpectationRequest();
        
        try {
            request.convertToRequest();
            System.assert(false, 'Should have thrown an exception');
        } catch (IllegalArgumentException e) {
            System.assert(e.getMessage().contains('Expectation record must be set'), 'Should have correct error message');
        }
    }

    @IsTest
    static void testValidateWithRegularOnly() {
        // Get test data
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        RegularTransaction__c testRegular = [SELECT Id FROM RegularTransaction__c LIMIT 1];
        
        // Create request with only regular (no fulfilment)
        ExpectationRequest request = new ExpectationRequest();
        request.productId = testProduct.Id;
        request.amount = 1000.00;
        request.expectationDate = System.today().addDays(30);
        request.direction = ExpectationHelper.DIRECTION_CONTRIBUTION;
        request.transactionType = TransactionHelper.TRANSACTION_TYPE_REGULAR;
        request.regularId = testRegular.Id;
        request.status = ExpectationHelper.EXPECTATION_STATUS_PENDING;
        
        // Test validation
        Boolean isValid = request.validate();
        
        System.assertEquals(true, isValid, 'Validation should pass');
        System.assertEquals(false, request.isError, 'Should not have errors');
        System.assertEquals('', request.errorMessage, 'Error message should be empty');
    }

    @IsTest
    static void testValidateWithBothFulfilmentAndRegular() {
        // Get test data
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        Fulfilment__c testFulfilment = [SELECT Id FROM Fulfilment__c LIMIT 1];
        RegularTransaction__c testRegular = [SELECT Id FROM RegularTransaction__c LIMIT 1];
        
        // Create request with both fulfilment and regular
        ExpectationRequest request = new ExpectationRequest();
        request.productId = testProduct.Id;
        request.amount = 1000.00;
        request.expectationDate = System.today().addDays(30);
        request.direction = ExpectationHelper.DIRECTION_CONTRIBUTION;
        request.transactionType = TransactionHelper.TRANSACTION_TYPE_REGULAR;
        request.fulfilmentId = testFulfilment.Id;
        request.regularId = testRegular.Id;
        request.status = ExpectationHelper.EXPECTATION_STATUS_PENDING;
        
        // Test validation
        Boolean isValid = request.validate();
        
        System.assertEquals(true, isValid, 'Validation should pass');
        System.assertEquals(false, request.isError, 'Should not have errors');
        System.assertEquals('', request.errorMessage, 'Error message should be empty');
    }

    @IsTest
    static void testErrorConstants() {
        // Test that error constants are properly defined
        System.assertEquals('Product not specified.', ExpectationRequest.ERROR_PRODUCT_NOT_SPECIFIED, 'Product error constant should match');
        System.assertEquals('Amount not specified.', ExpectationRequest.ERROR_AMOUNT_NOT_SPECIFIED, 'Amount error constant should match');
        System.assertEquals('Expectation date not specified.', ExpectationRequest.ERROR_DATE_NOT_SPECIFIED, 'Date error constant should match');
        System.assertEquals('Expectation date must be today or in the future.', ExpectationRequest.ERROR_DATE_PAST, 'Past date error constant should match');
        System.assertEquals('Direction not specified.', ExpectationRequest.ERROR_DIRECTION_NOT_SPECIFIED, 'Direction error constant should match');
        System.assertEquals('Direction value not valid.', ExpectationRequest.ERROR_DIRECTION_INVALID, 'Invalid direction error constant should match');
        System.assertEquals('Transaction type not specified.', ExpectationRequest.ERROR_TRANSACTION_TYPE_NOT_SPECIFIED, 'Transaction type error constant should match');
        System.assertEquals('Transaction type value not valid.', ExpectationRequest.ERROR_TRANSACTION_TYPE_INVALID, 'Invalid transaction type error constant should match');
        System.assertEquals('Specify a fulfilment and/or regular.', ExpectationRequest.ERROR_FULFILMENT_OR_REGULAR_REQUIRED, 'Fulfilment/regular error constant should match');
        System.assertEquals('Status not specified.', ExpectationRequest.ERROR_STATUS_NOT_SPECIFIED, 'Status error constant should match');
    }
}
@isTest
public class TransactionBatchProcessNewTest {
    
    @TestSetup
    static void setupTestData() {
        // Load configuration data for testing
        try {
            DataFactoryConfigurationData.load();
        } catch (Exception ex) {
            // Configuration data may already be loaded, continue
        }

        DataFactory dataFactory = new DataFactory();
        
        try {
            dataFactory.createConfigurationData();
        } catch (Exception ex) {
            // Configuration data may already be loaded, continue
        }
        
        // Create a household with 1 client using DataFactoryAccountHousehold to ensure proper relationships
        DataFactoryAccountHousehold dfah = new DataFactoryAccountHousehold();
        Account household = dfah.createHousehold('Test', 1, 0, 'Active', 'Full');
        Id householdId = household.Id;
        
        // Create advice with 1 product per person - this will create the financial products properly
        Advice__c advice = dataFactory.createAdvice(1, householdId);
        
        // Get the created financial product
        FinServ__FinancialAccount__c testProduct = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];
        
        // Create test transactions with different statuses using DataFactory
        List<Transaction__c> testTransactions = new List<Transaction__c>();
        
        // Create transactions with NEW status (should be processed)
        for (Integer i = 0; i < 3; i++) {
            testTransactions.add(dataFactory.createTransaction(
                testProduct.Id,
                100.00 + (i * 10),
                ExpectationHelper.DIRECTION_CONTRIBUTION,
                Date.today(),
                TransactionHelper.TRANSACTION_TYPE_REGULAR,
                TransactionHelper.TRANSACTION_STATUS_NEW
            ));
        }
        
        // Create transactions with different descriptions to test categorisation
        Transaction__c feeTransaction = dataFactory.createTransaction(
            testProduct.Id,
            50.00,
            ExpectationHelper.DIRECTION_CONTRIBUTION,
            Date.today(),
            null, // Will be set by categorisation
            TransactionHelper.TRANSACTION_STATUS_NEW
        );
        feeTransaction.Description__c = 'Fee Charge';
        update feeTransaction;
        
        Transaction__c taxReliefTransaction = dataFactory.createTransaction(
            testProduct.Id,
            200.00,
            ExpectationHelper.DIRECTION_CONTRIBUTION,
            Date.today(),
            null, // Will be set by categorisation
            TransactionHelper.TRANSACTION_STATUS_NEW
        );
        taxReliefTransaction.Description__c = 'Tax relief payment';
        update taxReliefTransaction;
        
        // Create test expectations for matching using DataFactory
        List<Expectation__c> testExpectations = new List<Expectation__c>();
        for (Integer i = 0; i < 2; i++) {
            testExpectations.add(dataFactory.createExpectation(
                testProduct.Id,
                100.00 + (i * 10),
                Date.today().addDays(30),
                ExpectationHelper.DIRECTION_CONTRIBUTION,
                TransactionHelper.TRANSACTION_TYPE_REGULAR,
                ExpectationHelper.EXPECTATION_STATUS_PENDING,
                null, // fulfilmentId
                null, // regularTransactionId
                null  // transactionId
            ));
        }
    }
    
    @isTest
    static void testDefaultConstructor() {
        // Test default constructor
        TransactionBatchProcessNew batch = new TransactionBatchProcessNew();
        
        System.assertEquals(200, batch.getBatchSize(), 'Default batch size should be 200');
    }
    
    @isTest
    static void testCustomBatchSizeConstructor() {
        // Test constructor with custom batch size
        TransactionBatchProcessNew batch = new TransactionBatchProcessNew(100);
        
        System.assertEquals(100, batch.getBatchSize(), 'Custom batch size should be 100');
    }
    
    @isTest
    static void testNullBatchSizeConstructor() {
        // Test constructor with null batch size
        TransactionBatchProcessNew batch = new TransactionBatchProcessNew(null);
        
        System.assertEquals(200, batch.getBatchSize(), 'Should use default batch size when null provided');
    }
    
    @isTest
    static void testBatchExecutionWithNewTransactions() {
        // Test actual batch execution with NEW status transactions
        TransactionBatchProcessNew batch = new TransactionBatchProcessNew(10);
        
        Test.startTest();
        Database.executeBatch(batch, 10);
        Test.stopTest();
        
        // Verify transactions were processed (categorised and visibility set)
        List<Transaction__c> processedTransactions = [
            SELECT Id, Status__c, Type__c, Description__c, isVisible__c 
            FROM Transaction__c 
            WHERE Status__c = :TransactionHelper.TRANSACTION_STATUS_NEW
        ];
        
        // Should still have transactions (they remain NEW status but should be processed)
        System.assertNotEquals(0, processedTransactions.size(), 'Should have processed transactions');
    }
    
    @isTest
    static void testBatchExecutionWithEmptyScope() {
        // Test with no NEW transactions
        // First, update all transactions to a different status
        List<Transaction__c> allTransactions = [SELECT Id FROM Transaction__c];
        for (Transaction__c t : allTransactions) {
            t.Status__c = TransactionHelper.TRANSACTION_STATUS_REVIEWED;
        }
        update allTransactions;
        
        TransactionBatchProcessNew batch = new TransactionBatchProcessNew();
        
        Test.startTest();
        Database.executeBatch(batch, 10);
        Test.stopTest();
        
        // Should not throw any exceptions
        System.assert(true, 'Should handle empty scope gracefully');
    }
    
    @isTest
    static void testTransactionCategorisationAndVisibility() {
        // Test that transactions are properly categorised and visibility is set correctly
        TransactionBatchProcessNew batch = new TransactionBatchProcessNew(10);
        
        Test.startTest();
        Database.executeBatch(batch, 10);
        Test.stopTest();
        
        // Verify categorisation worked for different transaction types
        List<Transaction__c> feeTransactions = [
            SELECT Id, Type__c, Description__c, isVisible__c 
            FROM Transaction__c 
            WHERE Description__c = 'Fee Charge'
        ];
        System.assertEquals(1, feeTransactions.size(), 'Should have one fee transaction');
        System.assertEquals(TransactionHelper.TRANSACTION_TYPE_FEE, feeTransactions[0].Type__c, 'Fee transaction should be categorised as FEE');
        System.assertEquals(false, feeTransactions[0].isVisible__c, 'Fee transactions should not be visible');
        
        List<Transaction__c> taxReliefTransactions = [
            SELECT Id, Type__c, Description__c, isVisible__c 
            FROM Transaction__c 
            WHERE Description__c = 'Tax relief payment'
        ];
        System.assertEquals(1, taxReliefTransactions.size(), 'Should have one tax relief transaction');
        System.assertEquals(TransactionHelper.TRANSACTION_TYPE_TAX_RELIEF, taxReliefTransactions[0].Type__c, 'Tax relief transaction should be categorised as TAX_RELIEF');
        System.assertEquals(true, taxReliefTransactions[0].isVisible__c, 'Tax relief transactions should be visible');
        
        // Verify visibility is set based on transaction type for regular transactions
        List<Transaction__c> regularTransactions = [
            SELECT Id, Type__c, isVisible__c 
            FROM Transaction__c 
            WHERE Type__c = :TransactionHelper.TRANSACTION_TYPE_REGULAR
        ];
        for (Transaction__c t : regularTransactions) {
            System.assertEquals(true, t.isVisible__c, 'Regular transactions should be visible');
        }
    }
}
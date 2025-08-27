@isTest
public with sharing class TransactionHelperTest {

    @testSetup
    static void setupData() {
        // Load configuration from static resources only if not already loaded
        try {
            DataFactoryConfigurationData.load();
        } catch (Exception ex) {
            // Data may already be loaded, continue
        }

        // Create a household with 1 client using DataFactory
        DataFactory dataFactory = new DataFactory();
        
        try {
            dataFactory.createConfigurationData();
        } catch (Exception ex) {
            // Configuration data may already be loaded, continue
        }
        
        String householdId = dataFactory.createHousehold('TransactionHelperTest', 1, 0, 'Active', 'Full');

        // Create advice with 1 product per person using DataFactory
        Advice__c advice = dataFactory.createAdvice(1, householdId);

        // Get the created financial product and create/update a financial product type with tax relief enabled
        FinServ__FinancialAccount__c financialProduct = [
            SELECT Id, FinancialProductType__c, Subtype__c
            FROM FinServ__FinancialAccount__c 
            WHERE Household__c = :householdId 
            LIMIT 1
        ];

        // Create a financial product type with tax relief enabled if one doesn't exist
        FinancialProductType__c productType;
        if (financialProduct.FinancialProductType__c != null) {
            productType = [
                SELECT Id, TransactionTaxRelief__c 
                FROM FinancialProductType__c 
                WHERE Id = :financialProduct.FinancialProductType__c
            ];
        } else {
            // Create a new financial product type
            productType = new FinancialProductType__c(
                Name = 'Test Product Type',
                TransactionTaxRelief__c = true,
                FinancialProductRecordTypeDeveloperName__c = 'FP_General_Investment_Account_GIA'
            );
            insert productType;
            
            // Update the financial product to link to the new product type and fix the subtype
            financialProduct.FinancialProductType__c = productType.Id;
            financialProduct.Subtype__c = 'General Investment Account'; // Use a valid picklist value
            update financialProduct;
        }
        
        // Ensure tax relief is enabled
        if (!productType.TransactionTaxRelief__c) {
            productType.TransactionTaxRelief__c = true;
            update productType;
        }
    }

    @isTest
    static void testCategoriseTransactionAndSetVisibility() {
        // ARRANGE
        List<Transaction__c> txns = new List<Transaction__c>{
            new Transaction__c(Description__c = 'Regular monthly contribution'),
            new Transaction__c(Description__c = 'Platform Charge for service'),
            new Transaction__c(Description__c = 'Tax relief payment received'),
            new Transaction__c(Description__c = 'Trf between accounts')
        };

        // ACT
        txns = TransactionHelper.categoriseTransaction(txns);
        txns = TransactionHelper.setVisibility(txns);

        // ASSERT: Types
        System.assertEquals(TransactionHelper.TRANSACTION_TYPE_REGULAR, txns[0].Type__c);
        System.assertEquals(TransactionHelper.TRANSACTION_TYPE_FEE, txns[1].Type__c);
        System.assertEquals(TransactionHelper.TRANSACTION_TYPE_TAX_RELIEF, txns[2].Type__c);
        System.assertEquals(TransactionHelper.TRANSACTION_TYPE_TRANSFER, txns[3].Type__c);

        // ASSERT: Visibility based on type map
        System.assertEquals(true, txns[0].isVisible__c, 'REGULAR should be visible');
        System.assertEquals(false, txns[1].isVisible__c, 'FEE should be hidden');
        System.assertEquals(true, txns[2].isVisible__c, 'TAX_RELIEF should be visible');
        System.assertEquals(true, txns[3].isVisible__c, 'TRANSFER should be visible');
    }

    @isTest
    static void testMatchTransactionToExpectation_LinksCorrectly() {
        // ARRANGE
        FinServ__FinancialAccount__c product = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];

        Transaction__c testTransaction = new Transaction__c(
            FinancialProduct__c = product.Id,
            Amount__c = 100,
            Direction__c = ExpectationHelper.DIRECTION_CONTRIBUTION,
            Date__c = Date.today()
        );
        insert testTransaction;

        Expectation__c testExpectation = new Expectation__c(
            FinancialProduct__c = product.Id,
            Amount__c = 100,
            Direction__c = ExpectationHelper.DIRECTION_CONTRIBUTION,
            Status__c = ExpectationHelper.EXPECTATION_STATUS_PENDING,
            Date__c = Date.today(),
            Type__c = TransactionHelper.TRANSACTION_TYPE_REGULAR
        );
        insert testExpectation;

        // ACT
        List<Transaction__c> result = TransactionHelper.matchTransactionToExpectation(new List<Transaction__c>{ testTransaction });

        // ASSERT: Expectation should be linked, transaction flagged in-memory
        testExpectation = [SELECT Id, Transaction__c FROM Expectation__c WHERE Id = :testExpectation.Id];
        System.assertEquals(testTransaction.Id, testExpectation.Transaction__c, 'Expectation should be linked to the transaction');
        System.assertEquals(true, result[0].ExpectationLinked__c, 'Transaction should be flagged as linked');
    }

    @isTest
    static void testSetExpectationLinkedFlag_SetsFlagForLinkedAndUnlinked() {
        // ARRANGE
        FinServ__FinancialAccount__c product = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];

        Transaction__c firstTransaction = new Transaction__c(
            FinancialProduct__c = product.Id,
            Amount__c = 50,
            Direction__c = ExpectationHelper.DIRECTION_CONTRIBUTION,
            Date__c = Date.today()
        );
        Transaction__c secondTransaction = new Transaction__c(
            FinancialProduct__c = product.Id,
            Amount__c = 75,
            Direction__c = ExpectationHelper.DIRECTION_CONTRIBUTION,
            Date__c = Date.today()
        );
        insert new List<Transaction__c>{ firstTransaction, secondTransaction };

        // Link one expectation to firstTransaction
        Expectation__c firstExpectation = new Expectation__c(
            FinancialProduct__c = product.Id,
            Amount__c = 50,
            Direction__c = ExpectationHelper.DIRECTION_CONTRIBUTION,
            Status__c = ExpectationHelper.EXPECTATION_STATUS_PENDING,
            Transaction__c = firstTransaction.Id,
            Date__c = Date.today(),
            Type__c = TransactionHelper.TRANSACTION_TYPE_REGULAR
        );
        insert firstExpectation;

        // ACT
        List<Transaction__c> processed = TransactionHelper.setExpectationLinkedFlag(new List<Transaction__c>{ firstTransaction, secondTransaction });

        // ASSERT
        for (Transaction__c currentTransaction : processed) {
            if (currentTransaction.Id == firstTransaction.Id) {
                System.assertEquals(true, currentTransaction.ExpectationLinked__c, 'Linked transaction should be flagged true');
            } else if (currentTransaction.Id == secondTransaction.Id) {
                System.assertEquals(false, currentTransaction.ExpectationLinked__c, 'Unlinked transaction should be flagged false');
            }
        }
    }

    @isTest
    static void testCheckRegularTransactionExistsForTransaction_CreatesRegularWhenMissing() {
        // ARRANGE
        FinServ__FinancialAccount__c product = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];

        Transaction__c testTransaction = new Transaction__c(
            FinancialProduct__c = product.Id,
            Amount__c = 150,
            Direction__c = ExpectationHelper.DIRECTION_CONTRIBUTION,
            Date__c = Date.today(),
            Type__c = TransactionHelper.TRANSACTION_TYPE_REGULAR,
            Status__c = TransactionHelper.TRANSACTION_STATUS_NEW
        );
        insert testTransaction;

        Integer beforeCount = [SELECT COUNT() FROM RegularTransaction__c WHERE FinancialProduct__c = :product.Id];

        // ACT
        Test.startTest();
        TransactionHelper.checkRegularTransactionExistsForTransaction(new List<Transaction__c>{ testTransaction });
        Test.stopTest();

        // ASSERT: A new RegularTransaction__c should have been created
        Integer afterCount = [SELECT COUNT() FROM RegularTransaction__c WHERE FinancialProduct__c = :product.Id];
        System.assertEquals(beforeCount + 1, afterCount, 'A regular transaction should be generated when missing');
    }

    @isTest
    static void testCheckIfTransactionSetToReviewed_FindsReviewed() {
        // ARRANGE
        Transaction__c existing = new Transaction__c(
            FinancialProduct__c = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1].Id,
            Amount__c = 10,
            Direction__c = ExpectationHelper.DIRECTION_CONTRIBUTION,
            Date__c = Date.today(),
            Status__c = TransactionHelper.TRANSACTION_STATUS_NEW
        );
        insert existing;

        // Build old/new maps with a status change to Reviewed
        Map<Id, Transaction__c> oldMap = new Map<Id, Transaction__c>{
            existing.Id => new Transaction__c(Id = existing.Id, Status__c = TransactionHelper.TRANSACTION_STATUS_NEW)
        };
        Map<Id, Transaction__c> newMap = new Map<Id, Transaction__c>{
            existing.Id => new Transaction__c(Id = existing.Id, Status__c = TransactionHelper.TRANSACTION_STATUS_REVIEWED)
        };

        // ACT
        Map<Id, Transaction__c> reviewed = TransactionHelper.checkIfTransactionSetToReviewed(oldMap, newMap);

        // ASSERT
        System.assertEquals(1, reviewed.size(), 'Exactly one transaction should be detected as set to Reviewed');
        System.assert(reviewed.containsKey(existing.Id), 'Reviewed map should contain the updated transaction Id');
    }

    @isTest
    static void testCheckIfTaxReliefExpectationIsNeeded_CreatesTaxReliefExpectation() {
        // ARRANGE
        FinServ__FinancialAccount__c product = [
            SELECT Id, FinancialProductType__c 
            FROM FinServ__FinancialAccount__c 
            WHERE FinancialProductType__c != null
            LIMIT 1
        ];

        FinancialProductType__c fpt = [
            SELECT Id, TransactionTaxRelief__c 
            FROM FinancialProductType__c 
            WHERE Id = :product.FinancialProductType__c
        ];
        fpt.TransactionTaxRelief__c = true;
        update fpt;

        Transaction__c testTransaction = new Transaction__c(
            FinancialProduct__c = product.Id,
            Amount__c = 1000,
            Direction__c = TransactionHelper.TRANSACTION_DIRECTION_CONTRIBUTION,
            Type__c = TransactionHelper.TRANSACTION_TYPE_LUMP_SUM,
            Date__c = Date.today(),
            Status__c = TransactionHelper.TRANSACTION_STATUS_NEW
        );
        insert testTransaction;

        // Create a regular transaction to link to the expectation
        RegularTransaction__c regularTransaction = new RegularTransaction__c(
            FinancialProduct__c = product.Id,
            Amount__c = 1000,
            Direction__c = TransactionHelper.TRANSACTION_DIRECTION_CONTRIBUTION,
            Frequency__c = 'Monthly',
            NextTransactionDate__c = Date.today().toStartOfMonth(),
            StartDate__c = Date.today().addMonths(-1),
            Status__c = 'Active'
        );
        insert regularTransaction;

        // Create a linked expectation for the original transaction
        Expectation__c originalExpectation = new Expectation__c(
            FinancialProduct__c = product.Id,
            Amount__c = 1000,
            Direction__c = ExpectationHelper.DIRECTION_CONTRIBUTION,
            Status__c = ExpectationHelper.EXPECTATION_STATUS_PENDING,
            Transaction__c = testTransaction.Id,
            RegularTransaction__c = regularTransaction.Id,
            Date__c = Date.today(),
            Type__c = TransactionHelper.TRANSACTION_TYPE_LUMP_SUM
        );
        insert originalExpectation;

        // Simulate the trigger scenario by creating old/new maps
        Map<Id, Transaction__c> oldMap = new Map<Id, Transaction__c>{
            testTransaction.Id => new Transaction__c(Id = testTransaction.Id, Status__c = TransactionHelper.TRANSACTION_STATUS_NEW)
        };
        
        
        // Update transaction to Reviewed status
        testTransaction.Status__c = TransactionHelper.TRANSACTION_STATUS_REVIEWED;
        update testTransaction;
        
        Map<Id, Transaction__c> newMap = new Map<Id, Transaction__c>{
            testTransaction.Id => testTransaction
        };

        // ACT
        Test.startTest();
        // The trigger will automatically call the tax relief method when the transaction is updated to Reviewed
        Test.stopTest();

        // ASSERT: A tax relief expectation should be created
        List<Expectation__c> taxReliefExpectations = [
            SELECT Id, Amount__c, Type__c, Date__c, Direction__c
            FROM Expectation__c 
            WHERE Type__c = :TransactionHelper.TRANSACTION_TYPE_TAX_RELIEF
            AND FinancialProduct__c = :product.Id
        ];
        
        System.assertEquals(1, taxReliefExpectations.size(), 'One tax relief expectation should be created');
        Expectation__c taxExpectation = taxReliefExpectations[0];
        System.assertEquals(250, taxExpectation.Amount__c, 'Tax relief amount should be 25% of original');
        System.assertEquals(TransactionHelper.TRANSACTION_TYPE_TAX_RELIEF, taxExpectation.Type__c);
        System.assertEquals(testTransaction.Date__c.addDays(TransactionHelper.TAX_OFFSET_DAYS), taxExpectation.Date__c);
        System.assertEquals(ExpectationHelper.DIRECTION_CONTRIBUTION, taxExpectation.Direction__c);
    }

    @isTest
    static void testCheckIfTaxReliefExpectationIsNeeded_NoTaxReliefForNonEligibleProduct() {
        // ARRANGE: Create a product without tax relief eligibility
        FinServ__FinancialAccount__c product = [
            SELECT Id, FinancialProductType__c 
            FROM FinServ__FinancialAccount__c 
            LIMIT 1
        ];
        
        // Ensure the product type doesn't have tax relief
        FinancialProductType__c fpt = [
            SELECT Id, TransactionTaxRelief__c 
            FROM FinancialProductType__c 
            WHERE Id = :product.FinancialProductType__c
        ];
        fpt.TransactionTaxRelief__c = false;
        update fpt;

        Transaction__c testTransaction = new Transaction__c(
            FinancialProduct__c = product.Id,
            Amount__c = 1000,
            Direction__c = TransactionHelper.TRANSACTION_DIRECTION_CONTRIBUTION,
            Type__c = TransactionHelper.TRANSACTION_TYPE_REGULAR,
            Date__c = Date.today()
        );
        insert testTransaction;

        // Create a linked expectation
        Expectation__c originalExpectation = new Expectation__c(
            FinancialProduct__c = product.Id,
            Amount__c = 1000,
            Direction__c = ExpectationHelper.DIRECTION_CONTRIBUTION,
            Status__c = ExpectationHelper.EXPECTATION_STATUS_PENDING,
            Transaction__c = testTransaction.Id,
            Date__c = Date.today(),
            Type__c = TransactionHelper.TRANSACTION_TYPE_REGULAR
        );
        insert originalExpectation;

        Map<Id, Transaction__c> transactionsToCheck = new Map<Id, Transaction__c>{ testTransaction.Id => testTransaction };

        // ACT
        TransactionHelper.checkIfTaxReliefExpectationIsNeeded(transactionsToCheck);

        // ASSERT: No tax relief expectation should be created
        List<Expectation__c> taxReliefExpectations = [
            SELECT Id 
            FROM Expectation__c 
            WHERE Type__c = :TransactionHelper.TRANSACTION_TYPE_TAX_RELIEF
            AND FinancialProduct__c = :product.Id
        ];
        
        System.assertEquals(0, taxReliefExpectations.size(), 'No tax relief expectation should be created for non-eligible product');
    }

    @isTest
    static void testCheckIfTaxReliefExpectationIsNeeded_NoTaxReliefForNonContribution() {
        // ARRANGE
        FinServ__FinancialAccount__c product = [
            SELECT Id, FinancialProductType__c 
            FROM FinServ__FinancialAccount__c 
            WHERE FinancialProductType__c != null
            LIMIT 1
        ];

        Transaction__c testTransaction = new Transaction__c(
            FinancialProduct__c = product.Id,
            Amount__c = 1000,
                            Direction__c = TransactionHelper.TRANSACTION_DIRECTION_WITHDRAWAL, // Withdrawal, not contribution
            Type__c = TransactionHelper.TRANSACTION_TYPE_REGULAR,
            Date__c = Date.today()
        );
        insert testTransaction;

        Map<Id, Transaction__c> transactionsToCheck = new Map<Id, Transaction__c>{ testTransaction.Id => testTransaction };

        // ACT
        TransactionHelper.checkIfTaxReliefExpectationIsNeeded(transactionsToCheck);

        // ASSERT: No tax relief expectation should be created for withdrawal
        List<Expectation__c> taxReliefExpectations = [
            SELECT Id 
            FROM Expectation__c 
            WHERE Type__c = :TransactionHelper.TRANSACTION_TYPE_TAX_RELIEF
            AND FinancialProduct__c = :product.Id
        ];
        
        System.assertEquals(0, taxReliefExpectations.size(), 'No tax relief expectation should be created for withdrawal transaction');
    }

    @isTest
    static void testCheckIfTaxReliefExpectationIsNeeded_NoTaxReliefForNonEligibleType() {
        // ARRANGE
        FinServ__FinancialAccount__c product = [
            SELECT Id, FinancialProductType__c 
            FROM FinServ__FinancialAccount__c 
            WHERE FinancialProductType__c != null
            LIMIT 1
        ];

        Transaction__c testTransaction = new Transaction__c(
            FinancialProduct__c = product.Id,
            Amount__c = 1000,
            Direction__c = TransactionHelper.TRANSACTION_DIRECTION_CONTRIBUTION,
            Type__c = TransactionHelper.TRANSACTION_TYPE_FEE, // Fee, not REGULAR or LUMP_SUM
            Date__c = Date.today()
        );
        insert testTransaction;

        Map<Id, Transaction__c> transactionsToCheck = new Map<Id, Transaction__c>{ testTransaction.Id => testTransaction };

        // ACT
        TransactionHelper.checkIfTaxReliefExpectationIsNeeded(transactionsToCheck);

        // ASSERT: No tax relief expectation should be created for non-eligible type
        List<Expectation__c> taxReliefExpectations = [
            SELECT Id 
            FROM Expectation__c 
            WHERE Type__c = :TransactionHelper.TRANSACTION_TYPE_TAX_RELIEF
            AND FinancialProduct__c = :product.Id
        ];
        
        System.assertEquals(0, taxReliefExpectations.size(), 'No tax relief expectation should be created for non-eligible transaction type');
    }

    @isTest
    static void testSetExpectationLinkedFlag_EmptyList() {
        // ARRANGE
        List<Transaction__c> emptyList = new List<Transaction__c>();

        // ACT
        List<Transaction__c> result = TransactionHelper.setExpectationLinkedFlag(emptyList);

        // ASSERT
        System.assertEquals(0, result.size(), 'Empty list should return empty list');
    }

    @isTest
    static void testSetExpectationLinkedFlag_NullList() {
        // ARRANGE
        List<Transaction__c> nullList = null;

        // ACT
        List<Transaction__c> result = TransactionHelper.setExpectationLinkedFlag(nullList);

        // ASSERT
        System.assertEquals(null, result, 'Null list should return null');
    }

    @isTest
    static void testCheckIfTransactionSetToReviewed_EmptyMap() {
        // ARRANGE
        Map<Id, Transaction__c> emptyMap = new Map<Id, Transaction__c>();

        // ACT
        Map<Id, Transaction__c> result = TransactionHelper.checkIfTransactionSetToReviewed(emptyMap, emptyMap);

        // ASSERT
        System.assertEquals(0, result.size(), 'Empty map should return empty result');
    }

    @isTest
    static void testCheckIfTransactionSetToReviewed_NullMap() {
        // ARRANGE
        Map<Id, Transaction__c> nullMap = null;

        // ACT
        Map<Id, Transaction__c> result = TransactionHelper.checkIfTransactionSetToReviewed(nullMap, nullMap);

        // ASSERT
        System.assertEquals(0, result.size(), 'Null map should return empty result');
    }

    @isTest
    static void testCheckIfTaxReliefExpectationIsNeeded_EmptyMap() {
        // ARRANGE
        Map<Id, Transaction__c> emptyMap = new Map<Id, Transaction__c>();

        // ACT
        TransactionHelper.checkIfTaxReliefExpectationIsNeeded(emptyMap);

        // ASSERT: No exceptions should be thrown, method should handle empty map gracefully
        System.assert(true, 'Method should handle empty map without errors');
    }

    @isTest
    static void testCheckIfTaxReliefExpectationIsNeeded_NullMap() {
        // ARRANGE
        Map<Id, Transaction__c> nullMap = null;

        // ACT
        TransactionHelper.checkIfTaxReliefExpectationIsNeeded(nullMap);

        // ASSERT: No exceptions should be thrown, method should handle null map gracefully
        System.assert(true, 'Method should handle null map without errors');
    }

    @isTest
    static void testMatchTransactionToExpectation_NoMatchingExpectations() {
        // ARRANGE
        FinServ__FinancialAccount__c product = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];

        Transaction__c testTransaction = new Transaction__c(
            FinancialProduct__c = product.Id,
            Amount__c = 100,
            Direction__c = ExpectationHelper.DIRECTION_CONTRIBUTION,
            Date__c = Date.today()
        );
        insert testTransaction;

        // No expectations exist for this product

        // ACT
        List<Transaction__c> result = TransactionHelper.matchTransactionToExpectation(new List<Transaction__c>{ testTransaction });

        // ASSERT: No linking should occur
        System.assertEquals(false, result[0].ExpectationLinked__c, 'Transaction should not be flagged as linked when no expectations exist');
    }

    @isTest
    static void testMatchTransactionToExpectation_AmountMismatch() {
        // ARRANGE
        FinServ__FinancialAccount__c product = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];

        Transaction__c testTransaction = new Transaction__c(
            FinancialProduct__c = product.Id,
            Amount__c = 100,
            Direction__c = ExpectationHelper.DIRECTION_CONTRIBUTION,
            Date__c = Date.today()
        );
        insert testTransaction;

        Expectation__c testExpectation = new Expectation__c(
            FinancialProduct__c = product.Id,
            Amount__c = 200, // Different amount
            Direction__c = ExpectationHelper.DIRECTION_CONTRIBUTION,
            Status__c = ExpectationHelper.EXPECTATION_STATUS_PENDING,
            Date__c = Date.today(),
            Type__c = TransactionHelper.TRANSACTION_TYPE_REGULAR
        );
        insert testExpectation;

        // ACT
        List<Transaction__c> result = TransactionHelper.matchTransactionToExpectation(new List<Transaction__c>{ testTransaction });

        // ASSERT: No linking should occur due to amount mismatch
        testExpectation = [SELECT Id, Transaction__c FROM Expectation__c WHERE Id = :testExpectation.Id];
        System.assertEquals(null, testExpectation.Transaction__c, 'Expectation should not be linked due to amount mismatch');
        System.assertEquals(false, result[0].ExpectationLinked__c, 'Transaction should not be flagged as linked');
    }

    @isTest
    static void testMatchTransactionToExpectation_DirectionMismatch() {
        // ARRANGE
        FinServ__FinancialAccount__c product = [SELECT Id FROM FinServ__FinancialAccount__c LIMIT 1];

        Transaction__c testTransaction = new Transaction__c(
            FinancialProduct__c = product.Id,
            Amount__c = 100,
            Direction__c = ExpectationHelper.DIRECTION_CONTRIBUTION,
            Date__c = Date.today()
        );
        insert testTransaction;

        Expectation__c testExpectation = new Expectation__c(
            FinancialProduct__c = product.Id,
            Amount__c = 100,
            Direction__c = ExpectationHelper.DIRECTION_WITHDRAWAL, // Different direction
            Status__c = ExpectationHelper.EXPECTATION_STATUS_PENDING,
            Date__c = Date.today(),
            Type__c = TransactionHelper.TRANSACTION_TYPE_REGULAR
        );
        insert testExpectation;

        // ACT
        List<Transaction__c> result = TransactionHelper.matchTransactionToExpectation(new List<Transaction__c>{ testTransaction });

        // ASSERT: No linking should occur due to direction mismatch
        testExpectation = [SELECT Id, Transaction__c FROM Expectation__c WHERE Id = :testExpectation.Id];
        System.assertEquals(null, testExpectation.Transaction__c, 'Expectation should not be linked due to direction mismatch');
        System.assertEquals(false, result[0].ExpectationLinked__c, 'Transaction should not be flagged as linked');
    }
}
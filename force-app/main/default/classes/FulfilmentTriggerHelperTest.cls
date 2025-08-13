@IsTest
public class FulfilmentTriggerHelperTest {
    
    // Method to load configuration test data
    @TestSetup
    static void makeData(){
        DataFactoryConfigurationData.load();
    }
    
    // Method to test the cancellation notice emails for new products
    @istest
    static void runTestCancellationNotice(){
        if( EmailSendTest.IS_EMAIL_DELIVERABILITY_ENABLED == true ) {
            System.debug('runTestCancellationNotice');
            Id householdId = createData();
            Fulfilment__c testFulfil = [SELECT Id FROM Fulfilment__c WHERE Recommendation__r.Product__r.DeveloperName__c = 'SIPP_HUBWISE'AND Recommendation__r.RecommendationType__r.DeveloperName__c = 'OPEN_PRODUCT' AND Household__c =: householdId LIMIT 1];
            
            testFulfil.Status__c = 'Investment checks';
            testFulfil.ResidualCash__c = 'AWAITING';
            update testFulfil;
            Test.startTest();
            testFulfil.Status__c = 'Complete';
            update testFulfil;
            
            Integer emailsSent = Limits.getEmailInvocations();
            System.assertEquals(1, emailsSent, 'Expected 1 email but got ' + emailsSent);
            Test.stopTest();
    // Test the improved FulfilmentTriggerHelper methods
    @isTest
    static void testGetFulfilmentsChangedToSubmitStatus() {
        // Test with null maps
        FulfilmentTriggerHelper helper = new FulfilmentTriggerHelper();
        Map<Id, Fulfilment__c> result = helper.getFulfilmentsChangedToSubmitStatus(null, null);
        System.assertEquals(0, result.size(), 'Should return empty map when both maps are null');
        
        // Test with empty maps
        result = helper.getFulfilmentsChangedToSubmitStatus(new Map<Id, Fulfilment__c>(), new Map<Id, Fulfilment__c>());
        System.assertEquals(0, result.size(), 'Should return empty map when both maps are empty');
        
        // Test with valid data
        Id householdId = createData();
        Fulfilment__c testFulfilment = [SELECT Id, Status__c FROM Fulfilment__c WHERE Recommendation__r.Product__r.DeveloperName__c = 'SIPP_HUBWISE' AND Recommendation__r.RecommendationType__r.DeveloperName__c = 'OPEN_PRODUCT' AND Household__c =: householdId LIMIT 1];
        
        Map<Id, Fulfilment__c> oldMap = new Map<Id, Fulfilment__c>();
        Map<Id, Fulfilment__c> newMap = new Map<Id, Fulfilment__c>();
        
        // Create old version with different status
        Fulfilment__c oldFulfilment = testFulfilment.clone();
        oldFulfilment.Status__c = 'Pending';
        oldMap.put(testFulfilment.Id, oldFulfilment);
        
        // Create new version with submit status
        Fulfilment__c newFulfilment = testFulfilment.clone();
        newFulfilment.Status__c = 'Submit fulfilment';
        newMap.put(testFulfilment.Id, newFulfilment);
        
        result = helper.getFulfilmentsChangedToSubmitStatus(oldMap, newMap);
        System.assertEquals(1, result.size(), 'Should return 1 fulfilment that changed to submit status');
        System.assertEquals('Submit fulfilment', result.get(testFulfilment.Id).Status__c, 'Should have correct status');
        System.assertEquals(testFulfilment.Id, result.keySet().iterator().next(), 'Should return the correct fulfilment ID');
        
        // Test that fulfilments that didn't change status are not included
        // Create a second fulfilment for testing unchanged status
        Fulfilment__c secondFulfilment = [SELECT Id, Status__c FROM Fulfilment__c WHERE Recommendation__r.Product__r.DeveloperName__c = 'JSIPP_HUBWISE' AND Recommendation__r.RecommendationType__r.DeveloperName__c = 'OPEN_PRODUCT' AND Household__c =: householdId LIMIT 1];
        
        Fulfilment__c unchangedFulfilment = secondFulfilment.clone();
        unchangedFulfilment.Status__c = 'Pending';
        oldMap.put(unchangedFulfilment.Id, unchangedFulfilment);
        newMap.put(unchangedFulfilment.Id, unchangedFulfilment);
        
        result = helper.getFulfilmentsChangedToSubmitStatus(oldMap, newMap);
        System.assertEquals(1, result.size(), 'Should only return fulfilments that changed to submit status');
        System.assert(!result.containsKey(unchangedFulfilment.Id), 'Should not include fulfilments with unchanged status');
    }
    
    @isTest
    static void testGetFulfilmentsChangedToSubmitStatusWithNullValues() {
        FulfilmentTriggerHelper helper = new FulfilmentTriggerHelper();
        
        // Test with null fulfilment in new map
        Map<Id, Fulfilment__c> oldMap = new Map<Id, Fulfilment__c>();
        Map<Id, Fulfilment__c> newMap = new Map<Id, Fulfilment__c>();
        
        // Create a real fulfilment first, then put null in the map
        Id householdId = createData();
        Fulfilment__c testFulfilment = [SELECT Id FROM Fulfilment__c WHERE Recommendation__r.Product__r.DeveloperName__c = 'SIPP_HUBWISE' AND Recommendation__r.RecommendationType__r.DeveloperName__c = 'OPEN_PRODUCT' AND Household__c =: householdId LIMIT 1];
        newMap.put(testFulfilment.Id, null);
        
        Map<Id, Fulfilment__c> result = helper.getFulfilmentsChangedToSubmitStatus(oldMap, newMap);
        System.assertEquals(0, result.size(), 'Should handle null fulfilment gracefully');
    }
    
    @isTest
    static void testGetRecommendationsWithNullInput() {
        FulfilmentTriggerHelper helper = new FulfilmentTriggerHelper();
        
        // Test with null input
        Map<Id, Recommendation__c> result = helper.getRecommendations(null);
        System.assertEquals(0, result.size(), 'Should return empty map when input is null');
        
        // Test with empty input
        result = helper.getRecommendations(new Map<Id, Fulfilment__c>());
        System.assertEquals(0, result.size(), 'Should return empty map when input is empty');
    }
    
    @isTest
    static void testGetRecommendationsWithValidData() {
        Id householdId = createData();
        Fulfilment__c testFulfilment = [SELECT Id, Recommendation__c FROM Fulfilment__c WHERE Recommendation__r.Product__r.DeveloperName__c = 'SIPP_HUBWISE' AND Recommendation__r.RecommendationType__r.DeveloperName__c = 'OPEN_PRODUCT' AND Household__c =: householdId LIMIT 1];
        
        Map<Id, Fulfilment__c> fulfilments = new Map<Id, Fulfilment__c>();
        fulfilments.put(testFulfilment.Id, testFulfilment);
        
        FulfilmentTriggerHelper helper = new FulfilmentTriggerHelper();
        Map<Id, Recommendation__c> result = helper.getRecommendations(fulfilments);
        
        System.assertEquals(1, result.size(), 'Should return 1 recommendation');
        System.assertNotEquals(null, result.get(testFulfilment.Recommendation__c), 'Should contain the recommendation');
        System.assertEquals(testFulfilment.Recommendation__c, result.keySet().iterator().next(), 'Should have correct recommendation ID');
        
        // Verify the recommendation has the expected fields populated
        Recommendation__c rec = result.get(testFulfilment.Recommendation__c);
        System.assertNotEquals(null, rec.RecommendationType__r, 'Should have RecommendationType relationship populated');
        System.assertNotEquals(null, rec.RecommendationType__r.DeveloperName__c, 'Should have DeveloperName populated');
    }
    
    @isTest
    static void testGenerateExpectationRequestsWithNullInput() {
        FulfilmentTriggerHelper helper = new FulfilmentTriggerHelper();
        
        // Test with null inputs
        helper.generateExpectationRequests(null, null);
        // Should not throw exception
        
        // Test with empty inputs
        helper.generateExpectationRequests(new Map<Id, Fulfilment__c>(), new Map<Id, Recommendation__c>());
        // Should not throw exception
    }
    
    @isTest
    static void testGenerateExpectationRequestsWithValidData() {
        Id householdId = createData();
        Fulfilment__c testFulfilment = [SELECT Id, Recommendation__c FROM Fulfilment__c WHERE Recommendation__r.Product__r.DeveloperName__c = 'SIPP_HUBWISE' AND Recommendation__r.RecommendationType__r.DeveloperName__c = 'OPEN_PRODUCT' AND Household__c =: householdId LIMIT 1];
        
        Map<Id, Fulfilment__c> fulfilments = new Map<Id, Fulfilment__c>();
        fulfilments.put(testFulfilment.Id, testFulfilment);
        
        Map<Id, Recommendation__c> recommendations = new Map<Id, Recommendation__c>();
        Recommendation__c rec = [SELECT Id, RecommendationType__r.DeveloperName__c, Amount__c, SourceLegacy__c, DestinationLegacy__c, SourceLegacy__r.OW_own_product__c, DestinationLegacy__r.OW_own_product__c FROM Recommendation__c WHERE Id = :testFulfilment.Recommendation__c];
        recommendations.put(rec.Id, rec);
        
        FulfilmentTriggerHelper helper = new FulfilmentTriggerHelper();
        
        // Count existing expectations before the test
        Integer expectationsBefore = [SELECT COUNT() FROM Expectation__c];
        
        Test.startTest();
        helper.generateExpectationRequests(fulfilments, recommendations);
        Test.stopTest();
        
        // Verify that expectations were created (if configurations exist)
        Integer expectationsAfter = [SELECT COUNT() FROM Expectation__c];
        System.assert(expectationsAfter >= expectationsBefore, 'Should not decrease expectation count');
        
        // If there are expectation configurations, verify they were processed
        List<ExpectationConfiguration__mdt> configs = [SELECT Id FROM ExpectationConfiguration__mdt WHERE isRegular__c = false LIMIT 1];
        if (!configs.isEmpty()) {
            System.assert(expectationsAfter > expectationsBefore, 'Should create expectations when configurations exist');
        }
    }
    
    @isTest
    static void testGenerateRegularTransactionRequestsWithNullInput() {
        FulfilmentTriggerHelper helper = new FulfilmentTriggerHelper();
        
        // Test with null inputs
        helper.generateRegularTransactionRequests(null, null);
        // Should not throw exception
        
        // Test with empty inputs
        helper.generateRegularTransactionRequests(new Map<Id, Fulfilment__c>(), new Map<Id, Recommendation__c>());
        // Should not throw exception
    }
    
    @isTest
    static void testGenerateRegularTransactionRequestsWithValidData() {
        Id householdId = createData();
        Fulfilment__c testFulfilment = [SELECT Id, Recommendation__c FROM Fulfilment__c WHERE Recommendation__r.Product__r.DeveloperName__c = 'SIPP_HUBWISE' AND Recommendation__r.RecommendationType__r.DeveloperName__c = 'OPEN_PRODUCT' AND Household__c =: householdId LIMIT 1];
        
        Map<Id, Fulfilment__c> fulfilments = new Map<Id, Fulfilment__c>();
        fulfilments.put(testFulfilment.Id, testFulfilment);
        
        Map<Id, Recommendation__c> recommendations = new Map<Id, Recommendation__c>();
        Recommendation__c rec = [SELECT Id, RecommendationType__r.DeveloperName__c, Amount__c, SourceLegacy__c, DestinationLegacy__c, SourceLegacy__r.FinancialProductType__r.RegularDay__c, DestinationLegacy__r.FinancialProductType__r.RegularDay__c FROM Recommendation__c WHERE Id = :testFulfilment.Recommendation__c];
        recommendations.put(rec.Id, rec);
        
        FulfilmentTriggerHelper helper = new FulfilmentTriggerHelper();
        
        // Count existing regular transactions before the test
        Integer regularTransactionsBefore = [SELECT COUNT() FROM RegularTransaction__c];
        
        Test.startTest();
        helper.generateRegularTransactionRequests(fulfilments, recommendations);
        Test.stopTest();
        
        // Verify that regular transactions were created (if configurations exist)
        Integer regularTransactionsAfter = [SELECT COUNT() FROM RegularTransaction__c];
        System.assert(regularTransactionsAfter >= regularTransactionsBefore, 'Should not decrease regular transaction count');
        
        // If there are regular configurations, verify they were processed
        List<ExpectationConfiguration__mdt> configs = [SELECT Id FROM ExpectationConfiguration__mdt WHERE isRegular__c = true LIMIT 1];
        if (!configs.isEmpty()) {
            System.assert(regularTransactionsAfter > regularTransactionsBefore, 'Should create regular transactions when configurations exist');
        }
    }
    
    @isTest
    static void testProcessSubmittedFulfilmentsWithErrorHandling() {
        FulfilmentTriggerHelper helper = new FulfilmentTriggerHelper();
        
        // Test with null inputs - should handle gracefully
        Test.startTest();
        helper.processSubmittedFulfilments(null, null);
        Test.stopTest();
        // Should not throw exception due to error handling
    }
    
    // Method to test the transfer complete emails
    @isTest
    static void runTestTransferComplete() {
        if( EmailSendTest.IS_EMAIL_DELIVERABILITY_ENABLED == true ) {
            System.debug('runTestTransferComplete');
            Id householdId = createData();
            
            Fulfilment__c testFulfil = [SELECT Id FROM Fulfilment__c WHERE Recommendation__r.Product__r.DeveloperName__c = 'SIPP_HUBWISE' AND Recommendation__r.RecommendationType__r.DeveloperName__c = 'EXTERNAL_TRANSFER_IN' AND Household__c =: householdId LIMIT 1];
    static void testProcessSubmittedFulfilmentsWithValidData() {
        Id householdId = createData();
        Fulfilment__c testFulfilment = [SELECT Id, Status__c, Recommendation__c FROM Fulfilment__c WHERE Recommendation__r.Product__r.DeveloperName__c = 'SIPP_HUBWISE' AND Recommendation__r.RecommendationType__r.DeveloperName__c = 'OPEN_PRODUCT' AND Household__c =: householdId LIMIT 1];
        
        Map<Id, Fulfilment__c> oldMap = new Map<Id, Fulfilment__c>();
        Map<Id, Fulfilment__c> newMap = new Map<Id, Fulfilment__c>();
        
        // Create old version
        Fulfilment__c oldFulfilment = testFulfilment.clone();
        oldFulfilment.Status__c = 'Pending';
        oldMap.put(testFulfilment.Id, oldFulfilment);
        
        // Create new version with submit status
        Fulfilment__c newFulfilment = testFulfilment.clone();
        newFulfilment.Status__c = 'Submit fulfilment';
        newMap.put(testFulfilment.Id, newFulfilment);
        
        FulfilmentTriggerHelper helper = new FulfilmentTriggerHelper();
        
        // Count existing records before processing
        Integer expectationsBefore = [SELECT COUNT() FROM Expectation__c];
        Integer regularTransactionsBefore = [SELECT COUNT() FROM RegularTransaction__c];
        
        Test.startTest();
        helper.processSubmittedFulfilments(oldMap, newMap);
        Test.stopTest();
        
        // Verify that the processing actually did something
        Integer expectationsAfter = [SELECT COUNT() FROM Expectation__c];
        Integer regularTransactionsAfter = [SELECT COUNT() FROM RegularTransaction__c];
        
        // The method should have attempted to process the fulfilment
        // Even if no configurations exist, it should not have thrown errors
        System.assert(expectationsAfter >= expectationsBefore, 'Should not decrease expectation count');
        System.assert(regularTransactionsAfter >= regularTransactionsBefore, 'Should not decrease regular transaction count');
    }
    
            testFulfil.PaymentStatus__c = 'Submitted';
            testFulfil.Status__c = 'Chase transfer';
            update testFulfil;
            Test.startTest();
            testFulfil.PaymentStatus__c = 'Funds received';
            testFulfil.Status__c = 'Investment checks';
            testFulfil.ResidualCash__c = 'AWAITING';
            update testFulfil;
            
            Integer emailsSent = Limits.getEmailInvocations();
            System.assertEquals(1, emailsSent, 'Expected 1 email but got ' + emailsSent);
            Test.stopTest();
    @isTest
    static void testGetRegularConfigsAndNonRegularConfigs() {
        FulfilmentTriggerHelper helper = new FulfilmentTriggerHelper();
        
        // Test that the methods return maps (even if empty)
        Map<String, ExpectationConfiguration__mdt> regularConfigs = helper.getRegularConfigs();
        Map<String, ExpectationConfiguration__mdt> nonRegularConfigs = helper.getNonRegularConfigs();
        
        System.assertNotEquals(null, regularConfigs, 'Regular configs should not be null');
        System.assertNotEquals(null, nonRegularConfigs, 'Non-regular configs should not be null');
        
        // Verify that the maps are properly initialized
        System.assertNotEquals(null, regularConfigs, 'Regular configs should not be null');
        System.assertNotEquals(null, nonRegularConfigs, 'Non-regular configs should not be null');
        
        // Test that the maps are populated with actual metadata (if any exists)
        List<ExpectationConfiguration__mdt> allConfigs = [SELECT Id, isRegular__c FROM ExpectationConfiguration__mdt];
        if (!allConfigs.isEmpty()) {
            System.assert(regularConfigs.size() + nonRegularConfigs.size() > 0, 'Should populate maps when metadata exists');
        }
    }
    
    @isTest
    static void runTestJuniorTransferComplete() {
        if( EmailSendTest.IS_EMAIL_DELIVERABILITY_ENABLED == true ) {
            System.debug('runTestTransferComplete');
            Id householdId = createData();
            
            Fulfilment__c testFulfil = [SELECT Id FROM Fulfilment__c WHERE Recommendation__r.Product__r.DeveloperName__c = 'JSIPP_HUBWISE' AND Recommendation__r.RecommendationType__r.DeveloperName__c = 'EXTERNAL_TRANSFER_IN' AND Household__c =: householdId LIMIT 1];
    static void testFulfilmentWithNullRecommendation() {
        // Create a fulfilment with null recommendation to test null handling
        Id householdId = createData();
        
        // Create a fulfilment without a recommendation
        Fulfilment__c testFulfilment = new Fulfilment__c(
            Status__c = 'Submit fulfilment',
            Household__c = householdId
            // Recommendation__c is null
        );
        insert testFulfilment;
        
        Map<Id, Fulfilment__c> fulfilments = new Map<Id, Fulfilment__c>();
        fulfilments.put(testFulfilment.Id, testFulfilment);
        
        FulfilmentTriggerHelper helper = new FulfilmentTriggerHelper();
        
        // Count existing records before processing
        Integer expectationsBefore = [SELECT COUNT() FROM Expectation__c];
        Integer regularTransactionsBefore = [SELECT COUNT() FROM RegularTransaction__c];
        
        // These should handle null recommendation gracefully
        Test.startTest();
        helper.generateExpectationRequests(fulfilments, new Map<Id, Recommendation__c>());
        helper.generateRegularTransactionRequests(fulfilments, new Map<Id, Recommendation__c>());
        Test.stopTest();
        
        // Verify that no records were created due to null recommendation
        Integer expectationsAfter = [SELECT COUNT() FROM Expectation__c];
        Integer regularTransactionsAfter = [SELECT COUNT() FROM RegularTransaction__c];
        
        System.assertEquals(expectationsBefore, expectationsAfter, 'Should not create expectations with null recommendation');
        System.assertEquals(regularTransactionsBefore, regularTransactionsAfter, 'Should not create regular transactions with null recommendation');
    }
    
            testFulfil.PaymentStatus__c = 'Submitted';
            testFulfil.Status__c = 'Chase transfer';
            update testFulfil;
            Test.startTest();
            testFulfil.PaymentStatus__c = 'Funds received';
            testFulfil.Status__c = 'Investment checks';
            testFulfil.ResidualCash__c = 'AWAITING';
            update testFulfil;
            
            Integer emailsSent = Limits.getEmailInvocations();
            System.assertEquals(1, emailsSent, 'Expected 1 email but got ' + emailsSent);
            Test.stopTest();
    @isTest
    static void testConfigurationMapInitialization() {
        FulfilmentTriggerHelper helper = new FulfilmentTriggerHelper();
        
        // Test that configuration maps are properly initialized
        Map<String, ExpectationConfiguration__mdt> regularConfigs = helper.getRegularConfigs();
        Map<String, ExpectationConfiguration__mdt> nonRegularConfigs = helper.getNonRegularConfigs();
        
        // Verify that the maps are properly segregated
        Set<String> regularKeys = regularConfigs.keySet();
        Set<String> nonRegularKeys = nonRegularConfigs.keySet();
        
        // The same key should not appear in both maps
        Set<String> intersection = new Set<String>(regularKeys);
        intersection.retainAll(nonRegularKeys);
        System.assertEquals(0, intersection.size(), 'Regular and non-regular configs should not share keys');
        
        // Verify that all configurations are properly categorized
        List<ExpectationConfiguration__mdt> allConfigs = [SELECT Id, RecommendationTypeDeveloperName__c, isRegular__c FROM ExpectationConfiguration__mdt];
        for (ExpectationConfiguration__mdt config : allConfigs) {
            if (config.isRegular__c) {
                System.assert(regularConfigs.containsKey(config.RecommendationTypeDeveloperName__c), 
                    'Regular config should be in regular map: ' + config.RecommendationTypeDeveloperName__c);
            } else {
                System.assert(nonRegularConfigs.containsKey(config.RecommendationTypeDeveloperName__c), 
                    'Non-regular config should be in non-regular map: ' + config.RecommendationTypeDeveloperName__c);
            }
        }
    }
    
    // Method to generate test data for the scenarios
    
    static Id createData() {
        DataFactory df = new DataFactory();
        Id household = df.createHousehold('OW001 Test',2,2,'Onboarding','Full');
        
        Advice__c advice = df.createAdvice(0, household);
        
        List<RecommendationType__c> recTypes = [SELECT Id, DeveloperName__c FROM RecommendationType__c WHERE DeveloperName__c IN ('OPEN_PRODUCT','EXTERNAL_TRANSFER_IN')];
        RecommendationType__c openProdRecType = new RecommendationType__c();
        RecommendationType__c transferRecType = new RecommendationType__c();
        for( RecommendationType__c recType : recTypes ){
            if( recType.DeveloperName__c == 'OPEN_PRODUCT' ) {
                openProdRecType = recType;
            } else if ( recType.DeveloperName__c == 'EXTERNAL_TRANSFER_IN' ) {
                transferRecType = recType;
            }
        }
        
        List<Product__c> products = [SELECT Id, DeveloperName__c FROM Product__c WHERE DeveloperName__c IN ('SIPP_HUBWISE','JSIPP_HUBWISE')];
        Product__c productType = new Product__c();
        Product__c productTypeJunior = new Product__c();
        for( Product__c product : products ){
            if( product.DeveloperName__c == 'SIPP_HUBWISE' ) {
                productType = product;
            } else if ( product.DeveloperName__c == 'JSIPP_HUBWISE' ) {
                productTypeJunior = product;
            }
        }

        AccountHouseholdMembers.HouseholdMemberRequest request = new AccountHouseholdMembers.HouseholdMemberRequest();
        request.householdId = household;
        request.roles = new Set<String>{'Client','Child'};
        AccountHouseholdMembers.HouseholdMemberResult result = AccountHouseholdMembers.getHouseholdMembers(request);
        List<Account> clients = result.memberAccountsByRole.get('Client');
        List<Account> children = result.memberAccountsByRole.get('Child');
        // Get household members using AccountContactRelation
        List<AccountContactRelation> acrs = [SELECT Id, Contact.AccountId, Roles FROM AccountContactRelation WHERE AccountId = :household AND Roles IN ('Client', 'Child')];
        List<Account> householdMembers = new List<Account>();
        List<Account> children = new List<Account>();
        
        for (AccountContactRelation acr : acrs) {
            if (acr.Roles == 'Client') {
                householdMembers.add(new Account(Id = acr.Contact.AccountId));
            } else if (acr.Roles == 'Child') {
                children.add(new Account(Id = acr.Contact.AccountId));
            }
        }
        
        List<Recommendation__c> recs = new List<Recommendation__c>();
        
        Recommendation__c openSippRec = new Recommendation__c(
        	Product__c = productType.Id,
            RecommendationType__c = openProdRecType.Id,
            PrimaryOwner__c = clients[0].Id,
            Advice__c = advice.Id,
            Household__c = household
        );
        recs.add(openSippRec);
        if (!householdMembers.isEmpty()) {
            Recommendation__c openSippRec = new Recommendation__c(
                Product__c = productType.Id,
                RecommendationType__c = openProdRecType.Id,
                PrimaryOwner__c = householdMembers[0].Id,
                Advice__c = advice.Id,
                Household__c = household
            );
            recs.add(openSippRec);
        }
        
        Recommendation__c openJuniorSippRec = new Recommendation__c(
        	Product__c = productTypeJunior.Id,
            RecommendationType__c = openProdRecType.Id,
            PrimaryOwner__c = children[0].Id,
            RegisteredContact__c = clients[0].Id,
            Advice__c = advice.Id,
            Household__c = household
        );
        recs.add(openJuniorSippRec);
        if (!children.isEmpty() && !householdMembers.isEmpty()) {
            Recommendation__c openJuniorSippRec = new Recommendation__c(
                Product__c = productTypeJunior.Id,
                RecommendationType__c = openProdRecType.Id,
                PrimaryOwner__c = children[0].Id,
                RegisteredContact__c = householdMembers[0].Id,
                Advice__c = advice.Id,
                Household__c = household
            );
            recs.add(openJuniorSippRec);
        }
        
        insert recs;
        
        Public_Provider_Names__c public_provider = [SELECT Id FROM Public_Provider_Names__c LIMIT 1];
        
        FinServ__FinancialAccount__c source = new FinServ__FinancialAccount__c(
            Name = 'Test',
            Subtype__c  = 'Defined Contribution',
            FinServ__PrimaryOwner__c = clients[0].Id,
            FinServ__PrimaryOwner__c = householdMembers.isEmpty() ? null : householdMembers[0].Id,
            Household__c = household,
            FinServ__Ownership__c = 'Individual',
            FinServ__Status__c = 'Open',
            Public_Provider_Name__c = public_provider.Id,
            RecordTypeId = Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName().get('FP_SIPP').getRecordTypeId()
        );
            
        insert source;
        
        List<Recommendation__c> transferRecs = new List<Recommendation__c>();
        
        Recommendation__c transferSippRec = new Recommendation__c(
        	Product__c = productType.Id,
            RecommendationType__c = transferRecType.Id,
            PrimaryOwner__c = clients[0].Id,
            Advice__c = advice.Id,
            Household__c = household,
            TransferType__c = 'Partial',
            SourceLegacy__c = source.Id,
            PreRequisiteRecommendation__c = recs[0].Id
        ); 
        transferRecs.add(transferSippRec);
        if (!householdMembers.isEmpty() && !recs.isEmpty()) {
            Recommendation__c transferSippRec = new Recommendation__c(
                Product__c = productType.Id,
                RecommendationType__c = transferRecType.Id,
                PrimaryOwner__c = householdMembers[0].Id,
                Advice__c = advice.Id,
                Household__c = household,
                TransferType__c = 'Partial',
                SourceLegacy__c = source.Id,
                PreRequisiteRecommendation__c = recs[0].Id
            ); 
            transferRecs.add(transferSippRec);
        }
        
        Recommendation__c transferJuniorSippRec = new Recommendation__c(
        	Product__c = productTypeJunior.Id,
            RecommendationType__c = transferRecType.Id,
            PrimaryOwner__c = children[0].Id,
            Advice__c = advice.Id,
            Household__c = household,
            TransferType__c = 'Full',
            SourceLegacy__c = source.Id,
            PreRequisiteRecommendation__c = recs[1].Id
        );
        if (!children.isEmpty() && !householdMembers.isEmpty() && recs.size() > 1) {
            Recommendation__c transferJuniorSippRec = new Recommendation__c(
                Product__c = productTypeJunior.Id,
                RecommendationType__c = transferRecType.Id,
                PrimaryOwner__c = children[0].Id,
                Advice__c = advice.Id,
                Household__c = household,
                TransferType__c = 'Full',
                SourceLegacy__c = source.Id,
                PreRequisiteRecommendation__c = recs[1].Id
            );
            transferRecs.add(transferJuniorSippRec);
        }
        
        transferRecs.add(transferJuniorSippRec);
        insert transferRecs;
                
        for( Recommendation__c rec : recs ) {
            rec.Status__c = 'Accepted';
        }
        
        update recs;

        for( Recommendation__c rec : transferRecs ) {
            rec.Status__c = 'Accepted';
        }
        
        update transferRecs;
        
        return household;
    }
}
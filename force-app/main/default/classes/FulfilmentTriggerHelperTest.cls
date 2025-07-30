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
            update testFulfil;
            Test.startTest();
            testFulfil.Status__c = 'Complete';
            update testFulfil;
            
            Integer emailsSent = Limits.getEmailInvocations();
            System.assertEquals(1, emailsSent, 'Expected 1 email but got ' + emailsSent);
            Test.stopTest();
        }
    }
    
    // Method to test the transfer complete emails
    @isTest
    static void runTestTransferComplete() {
        if( EmailSendTest.IS_EMAIL_DELIVERABILITY_ENABLED == true ) {
            System.debug('runTestTransferComplete');
            Id householdId = createData();
            List<Fulfilment__c> fulfilments = [SELECT Id, SearchName__c, Recommendation__r.Product__r.DeveloperName__c, Recommendation__r.RecommendationType__r.DeveloperName__c FROM Fulfilment__c WHERE Advice__r.Advice_Household__c =: householdId ];
            
            Fulfilment__c testFulfil = [SELECT Id FROM Fulfilment__c WHERE Recommendation__r.Product__r.DeveloperName__c = 'SIPP_HUBWISE' AND Recommendation__r.RecommendationType__r.DeveloperName__c = 'EXTERNAL_TRANSFER_IN' AND Household__c =: householdId LIMIT 1];
    
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
        
        List<Recommendation__c> recs = new List<Recommendation__c>();
        
        Recommendation__c openSippRec = new Recommendation__c(
        	Product__c = productType.Id,
            RecommendationType__c = openProdRecType.Id,
            PrimaryOwner__c = clients[0].Id,
            Advice__c = advice.Id,
            Household__c = household
        );
        recs.add(openSippRec);
        
        Recommendation__c openJuniorSippRec = new Recommendation__c(
        	Product__c = productTypeJunior.Id,
            RecommendationType__c = openProdRecType.Id,
            PrimaryOwner__c = children[0].Id,
            RegisteredContact__c = clients[0].Id,
            Advice__c = advice.Id,
            Household__c = household
        );
        recs.add(openJuniorSippRec);
        
        insert recs;
        
        Public_Provider_Names__c public_provider = [SELECT Id FROM Public_Provider_Names__c LIMIT 1];
        
        FinServ__FinancialAccount__c source = new FinServ__FinancialAccount__c(
            Name = 'Test',
            Subtype__c  = 'Defined Contribution',
            FinServ__PrimaryOwner__c = clients[0].Id,
            Household__c = household,
            FinServ__Ownership__c = 'Individual',
            FinServ__Status__c = 'Open',
            Public_Provider_Name__c = public_provider.Id,
            RecordTypeId = Schema.SObjectType.FinServ__FinancialAccount__c.getRecordTypeInfosByDeveloperName().get('FP_SIPP').getRecordTypeId()
        );
            
        insert source;
        
        Recommendation__c transferSippRec = new Recommendation__c(
        	Product__c = productType.Id,
            RecommendationType__c = transferRecType.Id,
            PrimaryOwner__c = clients[0].Id,
            Advice__c = advice.Id,
            Household__c = household,
            TransferType__c = 'Full',
            SourceLegacy__c = source.Id,
            PreRequisiteRecommendation__c = recs[0].Id
        ); 
        
        insert transferSippRec;
                
        for( Recommendation__c rec : recs ) {
            rec.Status__c = 'Accepted';
        }
        
        update recs;
        
        transferSippRec.Status__c = 'Accepted';
        update transferSippRec;
        
        return household;
    }
}
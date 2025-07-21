@IsTest
public class FulfilmentTriggerHelperTest {
    
    @TestSetup
    static void makeData(){
        DataFactoryConfigurationData.load();
    }
    
    @istest
    static void runTestCancellationNotice(){
        System.debug('runTestCancellationNotice');
        Id householdId = createData();
        Fulfilment__c testFulfil = [SELECT 
                                    Id 
                                    FROM 
                                    Fulfilment__c 
                                    WHERE
                                    Recommendation__r.Product__r.ReferenceName__c = 'SIPP_HUBWISE'
                                    AND
                                    Recommendation__r.RecommendationType__r.ReferenceName__c = 'OPEN_PRODUCT'
                                    AND 
                                    Household__c =: householdId
                                    LIMIT 1
                                   ];

		testFulfil.Status__c = 'Investment checks';
		update testFulfil;
        Test.startTest();
        testFulfil.Status__c = 'Complete';
        update testFulfil;
        
        Integer emailsSent = Limits.getEmailInvocations();
        System.assertEquals(1, emailsSent, 'Expected 1 email but got ' + emailsSent);
        Test.stopTest();
    }
    
    @isTest
    static void runTestTransferComplete() {
        System.debug('runTestTransferComplete');
        Id householdId = createData();
        List<Fulfilment__c> fulfilments = [SELECT 
                                           Id, 
                                           SearchName__c,
                                           Recommendation__r.Product__r.ReferenceName__c,
                                           Recommendation__r.RecommendationType__r.ReferenceName__c 
                                           FROM Fulfilment__c 
                                           WHERE Advice__r.Advice_Household__c =: householdId 
                                          ];
        
        Fulfilment__c testFulfil = [SELECT 
                                    Id 
                                    FROM 
                                    Fulfilment__c 
                                    WHERE
                                    Recommendation__r.Product__r.ReferenceName__c = 'SIPP_HUBWISE'
                                    AND
                                    Recommendation__r.RecommendationType__r.ReferenceName__c = 'EXTERNAL_TRANSFER_IN'
                                    AND 
                                    Household__c =: householdId
                                    LIMIT 1
                                   ];

		testFulfil.PaymentStatus__c = 'Submitted';
		update testFulfil;
        Test.startTest();
        testFulfil.PaymentStatus__c = 'Funds received';
        update testFulfil;
        
        Integer emailsSent = Limits.getEmailInvocations();
        System.assertEquals(1, emailsSent, 'Expected 1 email but got ' + emailsSent);
        Test.stopTest();
    }
    
    static Id createData() {
        DataFactory df = new DataFactory();
        Id household = df.createHousehold('OW001 Test',2,2,'Onboarding','Full');
        
        Advice__c advice = df.createAdvice(0, household);
        
        List<RecommendationType__c> recTypes = [SELECT 
                                                Id, ReferenceName__c
                                               	FROM
                                                RecommendationType__c 
                                                WHERE
                                                ReferenceName__c 
                                                IN ('OPEN_PRODUCT','EXTERNAL_TRANSFER_IN')
                                               ];
        RecommendationType__c openProdRecType = new RecommendationType__c();
        RecommendationType__c transferRecType = new RecommendationType__c();
        for( RecommendationType__c recType : recTypes ){
            if( recType.ReferenceName__c == 'OPEN_PRODUCT' ) {
                openProdRecType = recType;
            } else if ( recType.ReferenceName__c == 'EXTERNAL_TRANSFER_IN' ) {
                transferRecType = recType;
            }
        }
        
        List<Product__c> products = [SELECT 
                                     Id, ReferenceName__c
                                     FROM
                                     Product__c 
                                     WHERE
                                     ReferenceName__c IN
                                     ('SIPP_HUBWISE','JSIPP_HUBWISE')
                                    ];
        Product__c productType = new Product__c();
        Product__c productTypeJunior = new Product__c();
        for( Product__c product : products ){
            if( product.ReferenceName__c == 'SIPP_HUBWISE' ) {
                productType = product;
            } else if ( product.ReferenceName__c == 'JSIPP_HUBWISE' ) {
                productTypeJunior = product;
            }
        }

        List<Id> clients = df.getPersonAccountIds(household, 'Client');
        List<Id> children = df.getPersonAccountIds(household, 'Child');
        
        List<Recommendation__c> recs = new List<Recommendation__c>();
        
        Recommendation__c openSippRec = new Recommendation__c(
        	Product__c = productType.Id,
            RecommendationType__c = openProdRecType.Id,
            PrimaryOwner__c = clients[0],
            Advice__c = advice.Id,
            Household__c = household
        );
        recs.add(openSippRec);
        
        Recommendation__c openJuniorSippRec = new Recommendation__c(
        	Product__c = productTypeJunior.Id,
            RecommendationType__c = openProdRecType.Id,
            PrimaryOwner__c = children[0],
            RegisteredContact__c = clients[0],
            Advice__c = advice.Id,
            Household__c = household
        );
        recs.add(openJuniorSippRec);
        
        insert recs;
        
                
        Recommendation__c transferSippRec = new Recommendation__c(
        	Product__c = productType.Id,
            RecommendationType__c = transferRecType.Id,
            PrimaryOwner__c = clients[0],
            Advice__c = advice.Id,
            Household__c = household,
            TransferType__c = 'Full',
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
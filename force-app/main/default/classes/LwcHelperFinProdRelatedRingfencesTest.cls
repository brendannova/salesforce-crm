/**
 * This class exists exclusively to provide testing coverage for the Ringfences Related List for financial products LWC.
 * It should not be used in any other contexts.
 */
@isTest
public class LwcHelperFinProdRelatedRingfencesTest {	 
    @istest
    static void test_household_creation(){
        DataFactory df = new DataFactory();
        Id household = df.createHousehold('OW001 Test',2,2,'Onboarding','Full');
        
        Advice__c advice = df.createAdvice(0, household);
        
        List<RecommendationType__c> recTypes = [SELECT 
                                                Id, ReferenceName__c
                                               	FROM
                                                RecommendationType__c 
                                                WHERE
                                                ReferenceName__c 
                                                IN ('OPEN_PRODUCT')
                                               ];
        RecommendationType__c openProdRecType = new RecommendationType__c();
        for( RecommendationType__c recType : recTypes ){
            if( recType.ReferenceName__c == 'OPEN_PRODUCT' ) {
                openProdRecType = recType;
            }
        }
        
        List<Product__c> products = [SELECT 
                                     Id, ReferenceName__c
                                     FROM
                                     Product__c 
                                     WHERE
                                     ReferenceName__c IN
                                     ('SIPP_HUBWISE')
                                    ];
        Product__c productType = new Product__c();
        for( Product__c product : products ){
            if( product.ReferenceName__c == 'SIPP_HUBWISE' ) {
                productType = product;
            } 
        }

        AccountHouseholdMembers ahm = new AccountHouseholdMembers();
        AccountHouseholdMembers.HouseholdMemberRequest request = new AccountHouseholdMembers.HouseholdMemberRequest();
        request.householdId = household;
        Set<String> roles = new Set<String>{'Client','Child'};
        request.roles = roles;
        
        AccountHouseholdMembers.HouseholdMemberResult result = AccountHouseholdMembers.getHouseholdMembers(request);
        
        List<Account> clients = result.memberAccountsByRole.get('Client');
        List<Account> children = result.memberAccountsByRole.get('Child');
        
        
        Recommendation__c openSippRec = new Recommendation__c(
        	Product__c = productType.Id,
            RecommendationType__c = openProdRecType.Id,
            PrimaryOwner__c = clients[0].Id,
            Advice__c = advice.Id,
            Household__c = household
        );
        
        insert openSippRec;
        openSippRec.Status__c = 'Accepted';     
        update openSippRec;
        
        Fulfilment__c testFulfil = [SELECT 
                                    Id, Recommendation__r.DestinationLegacy__c 
                                    FROM 
                                    Fulfilment__c 
                                    WHERE
                                    Recommendation__c =: openSippRec.Id
                                    LIMIT 1
                                   ];
        
        Ringfence__c ringfence = new Ringfence__c(
        	Fulfilment__c = testFulfil.Id,
            Amount__c = 100,
            Reason__c = 'Because',
            Status__c = 'Active'
        );
        
        insert ringfence;

       	LwcHelperDynamicRecordList.DataWrapper data = LwcHelperFinProdRelatedRingfences.getRingfences(testFulfil.Recommendation__r.DestinationLegacy__c );
        System.Assert.areEqual(1, data.rows.size(), 'Expected 1 row');
    }
}
@isTest(SeeAllData=true)
public class FulfilmentTriggerHelperTest {
    @istest
    static void runTest(){
        Fulfilment__c testFulfil = [SELECT Id FROM Fulfilment__c WHERE Id = 'a2iQz00000247JVIAY'][0];

		testFulfil.Status__c = 'Investment checks';
		update testFulfil;
        testFulfil.Status__c = 'Complete';
        update testFulfil;
        
        Integer emailsSent = Limits.getEmailInvocations();
        System.assertEquals(2, emailsSent, 'Expected 2 emails but not true');
    }

}
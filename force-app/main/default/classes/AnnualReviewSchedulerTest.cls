/**
 * Test class to ensure annual reviews are being generated as expected
 */
@isTest
public without sharing class AnnualReviewSchedulerTest {

    private final static Date ANNUAL_REVIEW_DATE_IN_RANGE = Date.newInstance(Date.today().year(), Date.today().month() + 2, 1).addDays(-1);
    private final static Date ANNUAL_REVIEW_DATE_OUT_OF_RANGE = Date.newInstance(Date.today().year(), Date.today().month() + 4, 1).addDays(-1);
    private final static String TEST_HOUSEHOLD_ACTIVE_1 = 'TEST_HOUSEHOLD_ACTIVE_1';
    private final static String TEST_HOUSEHOLD_ACTIVE_2 = 'TEST_HOUSEHOLD_ACTIVE_2';
    private final static String TEST_HOUSEHOLD_OUT_OF_RANGE = 'TEST_HOUSEHOLD_OUT_OF_RANGE';
    private final static String TEST_HOUSEHOLD_OFFBOARDING = 'TEST_HOUSEHOLD_OFFBOARDING';

    // Create an account whose access will be audited
    @TestSetup
    static void setup() {
        DataFactoryConfigurationData.load();
        
        Account testHouseholdActive1 = DataFactoryAccountHousehold.createHousehold('TEST_HOUSEHOLD_ACTIVE_1', 1, 0, 'Active', 'Full');
        testHouseholdActive1.FinServ__NextReview__c = ANNUAL_REVIEW_DATE_IN_RANGE;
        update testHouseholdActive1;

        Account testHouseholdActive2 = DataFactoryAccountHousehold.createHousehold('TEST_HOUSEHOLD_ACTIVE_2', 2, 0, 'Active', 'Full');
        testHouseholdActive2.FinServ__NextReview__c = ANNUAL_REVIEW_DATE_IN_RANGE;
        update testHouseholdActive2;

        Account testHouseholdOutOfRange = DataFactoryAccountHousehold.createHousehold('TEST_HOUSEHOLD_OUT_OF_RANGE', 1, 0, 'Active', 'Full');
        testHouseholdOutOfRange.FinServ__NextReview__c = ANNUAL_REVIEW_DATE_OUT_OF_RANGE;
        update testHouseholdOutOfRange;

        Account testHouseholdOffboarding = DataFactoryAccountHousehold.createHousehold('TEST_HOUSEHOLD_OFFBOARDING', 1, 0, 'Offboarding', 'Full');
        testHouseholdOffboarding.FinServ__NextReview__c = ANNUAL_REVIEW_DATE_IN_RANGE;
        update testHouseholdOffboarding;

    }

    @IsTest
    static void generateAnnualReview_success() {
        Test.startTest();
            String jobId = System.schedule('testAnnualReviewScheduler', AnnualReviewScheduler.CRON_EXP, new AnnualReviewScheduler());

            // Get the information from the CronTrigger API object
            CronTrigger ct = [SELECT Id, CronExpression, TimesTriggered, NextFireTime FROM CronTrigger WHERE Id = :jobId];

            // Verify the expressions are the same
            System.assertEquals(AnnualReviewScheduler.CRON_EXP, ct.CronExpression);

            // Verify the job has not run
            System.assertEquals(0, ct.TimesTriggered);

            // Verify the next time the job will run
            Time nextRunTime = Time.newInstance(2, 0, 0, 0);
            Date nextRunDate = Date.today().addDays(1);
            System.assertEquals(Datetime.newInstance(nextRunDate, nextRunTime), ct.NextFireTime);
            List<OW_review__c> reviews = [SELECT Id FROM OW_review__c];
            System.Assert.areEqual(reviews.size(), 0, 'Expected 0 reviews but ' + reviews.size() + 'have been generated');
        Test.stopTest();

        List<Account> households = [SELECT Id, TestId__c FROM Account WHERE RecordType.DeveloperName = 'IndustriesHousehold'];
        for(Account household : households) {
            if(household.TestId__c == TEST_HOUSEHOLD_ACTIVE_1 || household.TestId__c == TEST_HOUSEHOLD_ACTIVE_2){
                System.assertEquals(ANNUAL_REVIEW_DATE_IN_RANGE.addYears(1), household.FinServ__NextReview__c, 'Unexpected next review date where review generated');
            } else if(household.TestId__c == TEST_HOUSEHOLD_OUT_OF_RANGE){
                System.assertEquals(ANNUAL_REVIEW_DATE_OUT_OF_RANGE, household.FinServ__NextReview__c, 'Expected next review date to be unchanged');
            } else if(household.TestId__c == TEST_HOUSEHOLD_OFFBOARDING){
                System.assertEquals(ANNUAL_REVIEW_DATE_IN_RANGE, household.FinServ__NextReview__c, 'Expected next review date to be unchanged');
            }
        }
        reviews = [SELECT Id FROM OW_review__c];
        System.Assert.areEqual(reviews.size(), 2, 'Expected 2 reviews but ' + reviews.size() + ' have been generated');

        List<Advice__c> advice = [SELECT Id FROM Advice__c];
        System.Assert.areEqual(advice.size(), 2, 'Expected 2 advice but ' + advice.size() + ' have been generated');
        List<External_Gains_Losses__c> egis = [SELECT Id FROM External_Gains_Losses__c];
        System.Assert.areEqual(egis.size(), 3, 'Expected 3 reviews but ' + egis.size() + ' have been generated');
    }
}
/**
 * Schedulable class that works in conjunction with AnnualReviewGenerator to ensure that clients annual reviews are kicked off in line with their annual review schedule.
 */
public without sharing class AnnualReviewScheduler  implements System.Schedulable {
    
    @TestVisible private static final String CRON_EXP = '0 0 2 * * ?'; // Scheduled to run at 2 am every night

    public void execute(System.SchedulableContext schedulableContext) {
        AnnualReviewGenerator.createAnnualReviews();
    }
}
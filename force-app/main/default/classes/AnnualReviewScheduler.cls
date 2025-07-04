/**
 * Schedulable class that works in conjunction with AnnualReviewGenerator to ensure that clients annual reviews are kicked off in line with their annual review schedule.
 */
public without sharing class AnnualReviewScheduler  implements System.Schedulable {
    
    public void execute(System.SchedulableContext schedulableContext) {
        AnnualReviewGenerator.createAnnualReviews();
    }
}
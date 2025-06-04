public without sharing class DataRetentionScheduler implements Schedulable {

    private final static String CRON_EXPRESSION = '0 0 23 * * ?'; // Runs daily at 11 PM
    private final static Integer BATCH_SIZE = 200;

    public void execute(SchedulableContext context) {
        DataRetentionBatchProcessor batchJob = new DataRetentionBatchProcessor();
        Database.executeBatch(batchJob, BATCH_SIZE); 
    }

    public static void scheduleJob() {
        // Ensure only one instance of the scheduled job is running
        System.debug('Attempting to schedule DataRetentionScheduler.');
        if (!System.isBatch()) { // Prevent scheduling if already in a batch context
            String jobName = 'DataRetentionJob';
            Id jobId = System.schedule(jobName, CRON_EXPRESSION, new DataRetentionScheduler());
            System.debug('Scheduled job with ID: ' + jobId);
        } else {
            System.debug('Cannot schedule DataRetentionScheduler within a batch context.');
        }
    }
}

// Move this to querying the MDT records
// Queue a job with holding status per record
// Limit is 100 but that's ok
// Model on this: https://github.com/novawealth/salesforce-crm/blob/af0d00a92f03246e4620330f9f6bb1afefd1e8b0/force-app/main/default/classes/LogBatchPurger.cls
// Work through records and use 
// https://developer.salesforce.com/docs/atlas.en-us.apexcode.meta/apexcode/apex_classes_iterable.htm
// How to handle test class
// How to handle sandbox
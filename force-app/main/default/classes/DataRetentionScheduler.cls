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
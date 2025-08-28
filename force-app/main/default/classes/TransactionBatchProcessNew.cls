public class TransactionBatchProcessNew implements Database.Batchable<sObject>, Database.Stateful {

    // Configuration constants
    private static final Integer DEFAULT_BATCH_SIZE = 200;
    
    // Instance variables for configuration and monitoring
    private Integer batchSize;
    
    // Stateful variables for tracking across batches
    private Integer errorCount = 0;
    private Integer processedCount = 0;
    private Integer successCount = 0;

    /**
     * @description Default constructor with default configuration
     */
    public TransactionBatchProcessNew() {
        this(DEFAULT_BATCH_SIZE);
    }

    /**
     * @description Constructor with custom batch size
     * @param batchSize The batch size to use for processing
     */
    public TransactionBatchProcessNew(Integer batchSize) {
        this.batchSize = batchSize != null ? batchSize : DEFAULT_BATCH_SIZE;
    }

    /**
     * @description Returns the configured batch size
     * @return Integer The batch size to use for processing
     */
    public Integer getBatchSize() {
        return this.batchSize;
    }

    /**
     * @description Start method with SOQL injection protection
     * @param bc The batch context
     * @return Database.QueryLocator The query locator for the batch
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        String query = 'SELECT Id, Amount__c, Direction__c, Date__c, FinancialProduct__c, Status__c, Description__c, Type__c ' +
                       'FROM Transaction__c ' +
                       'WHERE Status__c = \'' + TransactionHelper.TRANSACTION_STATUS_NEW + '\' ' +
                       'ORDER BY CreatedDate ASC';
        return Database.getQueryLocator(query);
    }

    /**
     * @description Executes the processing logic for each batch of records
     * @param bc The batch context
     * @param scope A list of Transaction__c records to process
     */
    public void execute(Database.BatchableContext bc, List<Transaction__c> scope) {
        if (scope.isEmpty()) {
            return;
        }

        processedCount += scope.size();

        try {
            // 1. Categorise the transactions and set visibility
            List<Transaction__c> categorizedTransactions = TransactionHelper.categoriseTransaction(scope);
            List<Transaction__c> visibilitySetTransactions = TransactionHelper.setVisibility(categorizedTransactions);

            // 2. Match transactions to expectations
            List<Transaction__c> matchedTransactions = TransactionHelper.matchTransactionToExpectation(visibilitySetTransactions);

            // 3. Check for existing regular transactions (this method modifies the list directly)
            TransactionHelper.checkRegularTransactionExistsForTransaction(matchedTransactions);

            // 4. Perform the final update, allowing for partial success
            Database.SaveResult[] saveResults = Database.update(matchedTransactions, false);
            
            // Check for errors and log them
            for (Database.SaveResult saveResult : saveResults) {
                if (!saveResult.isSuccess()) {
                    errorCount++;
                    for (Database.Error error : saveResult.getErrors()) {
                        System.debug(LoggingLevel.ERROR, 'Failed to update Transaction ID ' + saveResult.getId() + 
                                     '. Error: ' + error.getStatusCode() + ' - ' + error.getMessage());
                    }
                }
            }
            
            successCount += scope.size();
            
        } catch (Exception e) {
            errorCount++;
            System.debug(LoggingLevel.ERROR, 'Error in batch processing: ' + e.getMessage() + ' Stacktrace: ' + e.getStackTraceString());
        }
    }

    /**
     * @description Executes after all batches are processed
     * @param bc The batch context
     */
    public void finish(Database.BatchableContext bc) {
        // Query for the job's final status
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email
                            FROM AsyncApexJob WHERE Id = :bc.getJobId()];

        System.debug(LoggingLevel.INFO, 'Batch Complete - Processed: ' + processedCount + 
                    ', Success: ' + successCount + ', Errors: ' + errorCount + 
                    ', JobStatus: ' + job.Status);
    }
}
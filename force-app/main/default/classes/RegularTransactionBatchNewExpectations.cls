/**
 * @description Batch class to process RegularTransaction__c records that are scheduled for today.
 * This batch creates Expectation__c records for regular transactions and updates their next transaction dates.
 * 
 * The batch processes records where:
 * - NextTransactionDate__c equals TODAY
 * - Status__c is either 'Pending' or 'Active'
 * 
 * For each processed record, it:
 * 1. Creates an Expectation__c record for the scheduled transaction
 * 2. Updates the NextTransactionDate__c based on the frequency
 * 3. Updates the RegularTransaction__c record
 * 
 * @example
 * // Execute the batch with default batch size
 * Database.executeBatch(new RegularTransactionBatchNewExpectations());
 * 
 * // Execute with custom batch size
 * RegularTransactionBatchNewExpectations batch = new RegularTransactionBatchNewExpectations();
 * batch.batchSize = 100;
 * Database.executeBatch(batch);
 * 
 * @see RegularTransactionHelper
 * @see RegularTransactionRequest
 * @see ExpectationHelper
 */
public class RegularTransactionBatchNewExpectations implements Database.Batchable<SObject>, Database.Stateful {
    
    // Configuration
    public Integer batchSize = 200;
    
    // Performance and error tracking
    private Integer totalRecordsProcessed = 0;
    private Integer totalRecordsFailed = 0;
    private Integer totalBatchesProcessed = 0;
    private List<String> errorMessages = new List<String>();
    private Long startTime;
    private Long totalProcessingTime = 0;
    
    // Constants for validation
    private static final Set<String> VALID_STATUSES = new Set<String>{
        RegularTransactionHelper.REGULAR_TRANSACTION_STATUS_ACTIVE, 
        RegularTransactionHelper.REGULAR_TRANSACTION_STATUS_PENDING
    };
    
    /**
     * @description Constructor with default batch size
     */
    public RegularTransactionBatchNewExpectations() {
        this.batchSize = 200;
    }
    
    /**
     * @description Constructor with custom batch size
     * @param customBatchSize The batch size to use for processing
     */
    public RegularTransactionBatchNewExpectations(Integer customBatchSize) {
        this.batchSize = (customBatchSize != null && customBatchSize > 0) ? customBatchSize : 200;
    }

    /**
     * @description Returns the query locator for records to be processed.
     * Queries RegularTransaction__c records scheduled for today with valid statuses.
     * 
     * @param bc The batchable context
     * @return Database.QueryLocator containing records to process
     */
    public Database.QueryLocator start(Database.BatchableContext bc) {
        startTime = System.currentTimeMillis();
        
        String query = 'SELECT Id, Name, Amount__c, NextTransactionDate__c, FinancialProduct__c, ' +
                       'Direction__c, Frequency__c, StartDate__c, EndDate__c, Status__c ' +
                       'FROM RegularTransaction__c ' +
                       'WHERE NextTransactionDate__c = TODAY ' +
                       'AND Status__c IN :VALID_STATUSES ' +
                       'ORDER BY Id';

        System.debug(LoggingLevel.INFO, 'RegularTransactionBatchNewExpectations: Starting batch with query: ' + query);
        return Database.getQueryLocator(query);
    }

    /**
     * @description Processes a batch of RegularTransaction__c records.
     * Creates expectations and updates next transaction dates for each valid record.
     * 
     * @param bc The batchable context
     * @param scope List of RegularTransaction__c records to process
     */
    public void execute(Database.BatchableContext bc, List<RegularTransaction__c> scope) {
        Long batchStartTime = System.currentTimeMillis();
        Integer batchRecordsProcessed = 0;
        Integer batchRecordsFailed = 0;
        
        try {
            // Validate and filter records
            List<RegularTransaction__c> validRecords = validateRecords(scope);
            List<RegularTransaction__c> invalidRecords = new List<RegularTransaction__c>();
            
            for (RegularTransaction__c record : scope) {
                if (!validRecords.contains(record)) {
                    invalidRecords.add(record);
                }
            }
            
            // Log invalid records
            if (!invalidRecords.isEmpty()) {
                String invalidRecordIds = String.join(new List<Id>(new Map<Id, RegularTransaction__c>(invalidRecords).keySet()), ', ');
                addErrorMessage('Batch ' + totalBatchesProcessed + ': Found ' + invalidRecords.size() + ' invalid records: ' + invalidRecordIds);
                batchRecordsFailed += invalidRecords.size();
            }
            
            // Process valid records
            if (!validRecords.isEmpty()) {
                List<RegularTransactionRequest> requests = new List<RegularTransactionRequest>();

                for (RegularTransaction__c regularTransaction : validRecords) {
                    try {
                        RegularTransactionRequest request = new RegularTransactionRequest();
                        request.regularTransactionRecord = regularTransaction;
                        request.convertRecordToRequest();
                        requests.add(request);
                        batchRecordsProcessed++;
                    } catch (Exception e) {
                        addErrorMessage('Failed to convert record ' + regularTransaction.Id + ': ' + e.getMessage());
                        batchRecordsFailed++;
                    }
                }

                if (!requests.isEmpty()) {
                    try {
                        RegularTransactionHelper.processRegularTransactionsFromScheduledJob(requests);
                        System.debug(LoggingLevel.INFO, 'RegularTransactionBatchNewExpectations: Successfully processed ' + requests.size() + ' requests');
                    } catch (Exception e) {
                        addErrorMessage('Failed to process regular transactions: ' + e.getMessage() + ' Stacktrace: ' + e.getStackTraceString());
                        batchRecordsFailed += requests.size();
                        batchRecordsProcessed -= requests.size();
                    }
                }
            }
        
        } catch (Exception e) {
            addErrorMessage('Critical error in batch execution: ' + e.getMessage() + ' Stacktrace: ' + e.getStackTraceString());
            batchRecordsFailed += scope.size();
        }
        
        // Update tracking variables
        totalRecordsProcessed += batchRecordsProcessed;
        totalRecordsFailed += batchRecordsFailed;
        totalBatchesProcessed++;
        
        Long batchProcessingTime = System.currentTimeMillis() - batchStartTime;
        totalProcessingTime += batchProcessingTime;
        
        System.debug(LoggingLevel.INFO, 'RegularTransactionBatchNewExpectations: Batch ' + totalBatchesProcessed + 
                    ' completed. Processed: ' + batchRecordsProcessed + 
                    ', Failed: ' + batchRecordsFailed + 
                    ', Time: ' + batchProcessingTime + 'ms');
    }

    /**
     * @description Executes after all batches are processed. Provides comprehensive job summary.
     * 
     * @param bc The batchable context
     */
    public void finish(Database.BatchableContext bc) {
        try {
            // Query for the job's final status
            AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, 
                               CreatedBy.Email, CreatedDate, CompletedDate
                               FROM AsyncApexJob WHERE Id = :bc.getJobId()];

            Long totalJobTime = System.currentTimeMillis() - startTime;
            
            // Log comprehensive job summary
            System.debug(LoggingLevel.INFO, 'RegularTransactionBatchNewExpectations: Job Summary');
            System.debug(LoggingLevel.INFO, 'Job ID: ' + job.Id);
            System.debug(LoggingLevel.INFO, 'Status: ' + job.Status);
            System.debug(LoggingLevel.INFO, 'Total Job Items: ' + job.TotalJobItems);
            System.debug(LoggingLevel.INFO, 'Job Items Processed: ' + job.JobItemsProcessed);
            System.debug(LoggingLevel.INFO, 'Number of Errors: ' + job.NumberOfErrors);
            System.debug(LoggingLevel.INFO, 'Created By: ' + job.CreatedBy.Email);
            System.debug(LoggingLevel.INFO, 'Created Date: ' + job.CreatedDate);
            System.debug(LoggingLevel.INFO, 'Completed Date: ' + job.CompletedDate);
            System.debug(LoggingLevel.INFO, 'Total Processing Time: ' + totalJobTime + 'ms');
            System.debug(LoggingLevel.INFO, 'Total Records Processed: ' + totalRecordsProcessed);
            System.debug(LoggingLevel.INFO, 'Total Records Failed: ' + totalRecordsFailed);
            System.debug(LoggingLevel.INFO, 'Total Batches Processed: ' + totalBatchesProcessed);
            
            if (!errorMessages.isEmpty()) {
                System.debug(LoggingLevel.ERROR, 'RegularTransactionBatchNewExpectations: Error Summary');
                for (String error : errorMessages) {
                    System.debug(LoggingLevel.ERROR, error);
                }
            }
            
            // TODO: nebula logger
            if (job.NumberOfErrors > 0 || totalRecordsFailed > 0) {
                // Consider sending email notification to administrators
                System.debug(LoggingLevel.WARN, 'RegularTransactionBatchNewExpectations: Job completed with errors. Consider sending notification.');
            }
            
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, 'RegularTransactionBatchNewExpectations: Error in finish method: ' + e.getMessage());
        }
    }
    
    /**
     * @description Validates RegularTransaction__c records before processing.
     * Uses RegularTransactionRequest validation logic and additional business rules.
     * 
     * @param records List of records to validate
     * @return List of valid records ready for processing
     */
    private List<RegularTransaction__c> validateRecords(List<RegularTransaction__c> records) {
        List<RegularTransaction__c> validRecords = new List<RegularTransaction__c>();
        
        for (RegularTransaction__c record : records) {
            // Create a RegularTransactionRequest to use its validation logic
            RegularTransactionRequest request = new RegularTransactionRequest();
            request.regularTransactionRecord = record;
            request.convertRecordToRequest();
            
            // Use the RegularTransactionRequest validation
            request.validate();
            
            // Additional business rule validations
            if (request.nextTransactionDate != Date.today()) {
                request.setError('NextTransactionDate__c must be today. ');
            }
            
            if (record.EndDate__c != null && record.EndDate__c < Date.today()) {
                request.setError('Transaction has ended (EndDate__c is in the past). ');
            }
            
            if (record.StartDate__c != null && record.StartDate__c > Date.today()) {
                request.setError('Transaction has not started yet (StartDate__c is in the future). ');
            }
            
            if (!request.isError) {
                validRecords.add(record);
            } else {
                addErrorMessage('Validation failed for record ' + record.Id + ': ' + request.errorMessage);
            }
        }
        
        return validRecords;
    }
    
    /**
     * @description Adds an error message to the tracking list.
     * 
     * @param errorMessage The error message to add
     */
    private void addErrorMessage(String errorMessage) {
        errorMessages.add(errorMessage);
    }
    
    /**
     * @description Returns the current batch size being used.
     * 
     * @return The batch size as an Integer
     */
    public Integer getBatchSize() {
        return this.batchSize;
    }
    
    /**
     * @description Returns a summary of the batch job performance.
     * 
     * @return Map containing performance metrics
     */
    public Map<String, Object> getPerformanceSummary() {
        return new Map<String, Object>{
            'totalRecordsProcessed' => totalRecordsProcessed,
            'totalRecordsFailed' => totalRecordsFailed,
            'totalBatchesProcessed' => totalBatchesProcessed,
            'totalProcessingTime' => totalProcessingTime,
            'errorCount' => errorMessages.size(),
            'successRate' => totalRecordsProcessed > 0 ? 
                ((Decimal)(totalRecordsProcessed - totalRecordsFailed) / totalRecordsProcessed * 100).setScale(2) : 0
        };
    }
}
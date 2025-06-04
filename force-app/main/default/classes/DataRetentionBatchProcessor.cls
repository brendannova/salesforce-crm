public with sharing class DataRetentionBatchProcessor implements Database.Batchable<SObject>, Database.Stateful {

    private Map<String, Integer> objectDeletionDaysMap;
    private List<String> objectsToProcess;
    private Datetime purgeCutoffDateTime;

    public DataRetentionBatchProcessor() {
        objectDeletionDaysMap = new Map<String, Integer>();
        objectsToProcess = new List<String>();
        
        // Get data retention policies and construct the references needed throughout
        for (DataRetentionPolicy__mdt policy : [SELECT ObjectAPIName__c, DeletionDays__c FROM DataRetentionPolicy__mdt]) {
            objectDeletionDaysMap.put(policy.ObjectAPIName__c, Integer.valueOf(policy.DeletionDays__c));
            objectsToProcess.add(policy.ObjectAPIName__c);
        }
        
        // Calculate the purge cutoff date/time based on the current time in UTC
        // Ensure time zone consistency for deletion. Salesforce records 'CreatedDate' in UTC.
        this.purgeCutoffDateTime = Datetime.now().addDays(-1 * getMaxDeletionDays()); 
    }

    public Database.QueryLocator start(Database.BatchableContext bc) {
        // This method will construct a dynamic SOQL query to fetch records for all objects
        // identified in the custom metadata.
        
        List<String> queryConditions = new List<String>();
        for (String objAPIName : objectsToProcess) {
            Integer deletionDays = objectDeletionDaysMap.get(objAPIName);
            if (deletionDays != null) {
                // We assume 'CreatedDate' for deletion eligibility. Adjust if a different date field is needed.
                // The query needs to fetch all records for the identified objects that are older than their policy.
                // However, a single QueryLocator for multiple objects isn't feasible directly.
                // Instead, we will iterate through objects in the execute method.
            }
        }
        
        // Return null or an empty query locator. The actual querying will happen in the execute method.
        // This start method is primarily for setting up the context for the execute method.
        return null;
    }

    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        // In a typical batch, 'scope' would contain records from the QueryLocator.
        // Since we're querying multiple objects dynamically, we'll query within the execute method
        // for each object. This approach might lead to higher query limits if not handled carefully,
        // but it's necessary for dynamic object processing within a single batch.
        
        List<SObject> recordsToDelete = new List<SObject>();

        for (String objAPIName : objectsToProcess) {
            Integer deletionDays = objectDeletionDaysMap.get(objAPIName);
            if (deletionDays != null) {
                // Calculate the specific cutoff date for the current object
                Datetime objectSpecificPurgeCutoff = Datetime.now().addDays(-1 * deletionDays);
                
                String query = 'SELECT Id FROM ' + objAPIName + ' WHERE CreatedDate < :objectSpecificPurgeCutoff LIMIT 2000'; // Limit to avoid hitting limits for a single query within the loop
                
                try {
                    for (SObject sObj : Database.query(query)) {
                        recordsToDelete.add(sObj);
                    }
                } catch (Exception e) {
                    System.debug(LoggingLevel.ERROR, 'Error querying ' + objAPIName + ': ' + e.getMessage());
                    // Consider logging this error to a custom object for monitoring
                }
            }
        }
        
        if (!recordsToDelete.isEmpty()) {
            try {
                Database.delete(recordsToDelete);
                System.debug(LoggingLevel.INFO, 'Deleted ' + recordsToDelete.size() + ' records.');
            } catch (Exception e) {
                System.debug(LoggingLevel.ERROR, 'Error deleting records: ' + e.getMessage());
                // Consider logging this error to a custom object for monitoring
            }
        }
    }

    public void finish(Database.BatchableContext bc) {
        System.debug('Data Retention Batch Process Finished.');
        // Optionally, send an email notification about the completion and results
    }
    
    // Helper method to get the maximum deletion days across all policies
    // This helps in setting an initial wider cutoff for the batch, though per-object is used in execute.
    private Integer getMaxDeletionDays() {
        Integer maxDays = 0;
        for (Integer days : objectDeletionDaysMap.values()) {
            if (days > maxDays) {
                maxDays = days;
            }
        }
        return maxDays;
    }
}
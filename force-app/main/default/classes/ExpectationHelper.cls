public class ExpectationHelper {

    final public static String EXPECTATION_STATUS_PENDING = 'Pending';
    final public static String EXPECTATION_STATUS_OCCURRED = 'Occurred';
    final public static String EXPECTATION_STATUS_CANCELLED = 'Cancelled';

    final public static String DIRECTION_CONTRIBUTION = 'CONTRIBUTION';
    final public static String DIRECTION_WITHDRAWAL = 'WITHDRAWL';
    final public static List<String> DIRECTION_VALUES = new List<String>{DIRECTION_CONTRIBUTION ,DIRECTION_WITHDRAWAL}; //TODO - get from picklist
    final public static List<String> TRANSACTION_TYPE_VALUES{
        get{
            if(TRANSACTION_TYPE_VALUES == null){
                TRANSACTION_TYPE_VALUES = new List<String>();
                Schema.DescribeFieldResult fieldResult = Expectation__c.Type__c.getDescribe();
                List<Schema.PicklistEntry> picklistEntries = fieldResult.getPicklistValues();

                for (Schema.PicklistEntry entry : picklistEntries) {
                    // We only want active picklist values
                    if (entry.isActive()) {
                        TRANSACTION_TYPE_VALUES.add(entry.getValue()); // getValue() returns the API name
                    }
                }
            }
            return TRANSACTION_TYPE_VALUES;
        }
        set;
    }

    //TODO - update status when transaciton linked
    

    public static List<ExpectationRequest> createExpectations(List<ExpectationRequest> expectationRequests) {
        return processExpectationsUpsert(expectationRequests);
    }

    public static List<ExpectationRequest> updateExpectations(List<ExpectationRequest> expectationRequests) {
        return processExpectationsUpsert(expectationRequests);
    }

    @testVisible
    private static List<ExpectationRequest> processExpectationsUpsert(List<ExpectationRequest> requestList) {
        if (requestList == null || requestList.isEmpty()) {
            return new List<ExpectationRequest>();
        }

        List<Expectation__c> expectationsToUpsert = new List<Expectation__c>();
        Map<Expectation__c, ExpectationRequest> expectationMap = new Map<Expectation__c, ExpectationRequest>();

        // Step 1: Prepare the list of sObjects for upsert and map them back to requests
        for (ExpectationRequest request : requestList) {
            request.validate();
            if (!request.isError) {
                request.convertToRecord();
                expectationsToUpsert.add(request.expectationRecord);
                expectationMap.put(request.expectationRecord, request); // Map sObject to its request wrapper
            }
        }

        system.debug('expectationsToUpsert');
        system.debug(expectationsToUpsert.size());

        // Only proceed with DML if there are valid records to upsert
        if (!expectationsToUpsert.isEmpty()) {
            List<Database.UpsertResult> saveResults = Database.upsert(expectationsToUpsert, false);

            for (Integer i = 0; i < saveResults.size(); i++) {
                Database.UpsertResult saveResult = saveResults[i];
                Expectation__c currentExpectation = expectationsToUpsert[i];
                ExpectationRequest originalRequest = expectationMap.get(currentExpectation);

                if (originalRequest != null) { 
                    if (saveResult.isSuccess()) {
                        originalRequest.isError = false;
                        originalRequest.errorMessage = null;
                        originalRequest.expectationRecord.Id = saveResult.getId(); // Ensure ID is set on the original record
                    } else {
                        originalRequest.isError = true;
                        List<Database.Error> errors = saveResult.getErrors();
                        String errorMessages = '';
                        for (Database.Error err : errors) {
                            errorMessages += err.getMessage() + ' ';
                            if (err.getFields() != null && !err.getFields().isEmpty()) {
                                errorMessages += '(Fields: ' + String.join(err.getFields(), ', ') + ')';
                            }
                            errorMessages += '; ';
                        }
                        originalRequest.errorMessage = 'DML Error: ' + errorMessages.trim();
                    }
                }
            }
        }
        return requestList;
    }

    public static Map<Id, ExpectationRequest> updateExpectationStatusIfLinkedToTransaction(Map<Id, ExpectationRequest> oldMap, Map<Id, ExpectationRequest> newMap){

        for(Id expectationId : newMap.keySet()){
            ExpectationRequest newRequest = newMap.get(expectationId);
            ExpectationRequest oldRequest = oldMap.get(expectationId);
            
            //has been linked so set to occurred
            if(newRequest.transactionId != null && oldRequest.transactionId == null){
                if(newRequest.status == EXPECTATION_STATUS_PENDING){
                    newRequest.status = EXPECTATION_STATUS_OCCURRED;
                }
            }

            //TODO - what if it gets unlinked?
            if(newRequest.transactionId == null && oldRequest.transactionId != null){

            }

        }

        return newMap;
    }

    public static void updateTransactionExpectationLinkedFlag(Map<Id, ExpectationRequest> oldMap, Map<Id, ExpectationRequest> newMap){
        Set<Id> transactionIds = new Set<Id>();
        List<Transaction__c> transactionsToCheck = new List<Transaction__c>();
        
        for(Id expectationId : newMap.keySet()){
            ExpectationRequest newRequest = newMap.get(expectationId);
            ExpectationRequest oldRequest = oldMap.get(expectationId);
            
            //has been linked so set to occurred
            if(newRequest.transactionId != null && oldRequest.transactionId == null){
                transactionIds.add(newRequest.transactionId);
            }

            if(newRequest.transactionId == null && oldRequest.transactionId != null){
                transactionIds.add(oldRequest.transactionId);
            }

        }

        system.debug('transactionIds');
        system.debug(transactionIds);

        for(Id transactionId : transactionIds){
            Transaction__c transactionRecord = new Transaction__c();
            transactionRecord.Id = transactionId;
            transactionsToCheck.add(transactionRecord);
        }

        system.debug(transactionsToCheck);

        if(transactionsToCheck.size() > 0){
            transactionsToCheck = TransactionHelper.setExpectationLinkedFlag(transactionsToCheck);
            system.debug(transactionsToCheck);
            update transactionsToCheck;
        }
    }
}
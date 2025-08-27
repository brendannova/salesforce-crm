public class RegularTransactionHelper {
    
    public static final string REGULAR_TRANSACTION_STATUS_ACTIVE = 'Active';
    public static final string REGULAR_TRANSACTION_STATUS_CANCELLED = 'Cancelled';
    public static final string REGULAR_TRANSACTION_STATUS_PENDING = 'Pending';

    public static void processRegularTransactionsFromScheduledJob(list<RegularTransactionRequest> regularTransactionRequests){
        
        List<ExpectationRequest> expectationsFromRegularTransactions = generateExpectationsFromRegularTansactions(regularTransactionRequests);
        ExpectationHelper.createExpectations(expectationsFromRegularTransactions);

        regularTransactionRequests = updateNextTransactionDates(regularTransactionRequests);

        //TODO - check end dates

        updateRegularTransactions(regularTransactionRequests);
    }
    
    //generate expectations from regular transacitons
    public static list<ExpectationRequest> generateExpectationsFromRegularTansactions(list<RegularTransactionRequest> regularTransactionRequests){
        list<ExpectationRequest> expectationsToCreate = new list<ExpectationRequest>();

        for(RegularTransactionRequest regularTransactionRequest : regularTransactionRequests){

            ExpectationRequest expectationRequest = new ExpectationRequest();

            expectationRequest.transactionType = TransactionHelper.TRANSACTION_TYPE_REGULAR;
            expectationRequest.expectationDate = regularTransactionRequest.nextTransactionDate;
            expectationRequest.productId = regularTransactionRequest.productId;
            expectationRequest.regularId = regularTransactionRequest.id;
            expectationRequest.amount = regularTransactionRequest.amount;
            expectationRequest.direction = regularTransactionRequest.direction;
            expectationRequest.status = ExpectationHelper.EXPECTATION_STATUS_PENDING;

            expectationsToCreate.add(expectationRequest);
        }
            
        return expectationsToCreate;
    }

    public static list<RegularTransactionRequest> updateNextTransactionDates(list<RegularTransactionRequest> regularTransactionRequests){
        for (RegularTransactionRequest request : regularTransactionRequests) {
            switch on request.frequency {
                when 'Monthly' {
                    request.nextTransactionDate = request.nextTransactionDate.addMonths(1);
                }
            }
        }

        return regularTransactionRequests;
    }

    //tempoary class to handle switch over
    public static void generateRegularTransactionFromTransactionRecords(list<Transaction__c> transactionRecords){
        list<RegularTransactionRequest> regularTransactionRequests = new list<RegularTransactionRequest>();

        for(Transaction__c transactionRecord : transactionRecords){
            RegularTransactionRequest transactionRequest = new RegularTransactionRequest();

            transactionRequest.productId = transactionRecord.FinancialProduct__c;
            transactionRequest.amount = transactionRecord.Amount__c;
            transactionRequest.direction = transactionRecord.Direction__c;
            transactionRequest.frequency = 'Monthly';
            transactionRequest.nextTransactionDate = transactionRecord.Date__c.addMonths(1);
            transactionRequest.startDate = transactionRecord.Date__c;
            transactionRequest.status = 'Active';

            regularTransactionRequests.add(transactionRequest);

        }

        if(regularTransactionRequests.size() > 0){
            generateRegularTransactions(regularTransactionRequests);
        }

        //TODO - then handle generation of expectation and linking

    }

    public static list<RegularTransactionRequest> generateRegularTransactions(list<RegularTransactionRequest> regularTransactionRequests){
        return processRegularTransactionUpsert(regularTransactionRequests);
    }

     public static list<RegularTransactionRequest> updateRegularTransactions(list<RegularTransactionRequest> regularTransactionRequests){
        return processRegularTransactionUpsert(regularTransactionRequests);
    }

    private static List<RegularTransactionRequest> processRegularTransactionUpsert(List<RegularTransactionRequest> requestList) {
        if (requestList == null || requestList.isEmpty()) {
            return new List<regularTransactionRequest>();
        }

        List<RegularTransaction__c> regularTransactionsToUpsert = new List<RegularTransaction__c>();
        Map<RegularTransaction__c, regularTransactionRequest> regularTransactionMap = new Map<RegularTransaction__c, regularTransactionRequest>();

        // Step 1: Prepare the list of sObjects for upsert and map them back to requests
        for (regularTransactionRequest request : requestList) {
            request.validate();
            if (!request.isError) {
                request.convertToRecord();
                regularTransactionsToUpsert.add(request.regularTransactionRecord);
                regularTransactionMap.put(request.regularTransactionRecord, request); // Map sObject to its request wrapper
            }
        }

        // Only proceed with DML if there are valid records to upsert
        if (!regularTransactionsToUpsert.isEmpty()) {
            List<Database.UpsertResult> saveResults = Database.upsert(regularTransactionsToUpsert, false);

            for (Integer i = 0; i < saveResults.size(); i++) {
                Database.UpsertResult saveResult = saveResults[i];
                RegularTransaction__c currentRegularTransaction = regularTransactionsToUpsert[i];
                regularTransactionRequest originalRequest = regularTransactionMap.get(currentRegularTransaction);

                if (originalRequest != null) { 
                    if (saveResult.isSuccess()) {
                        originalRequest.isError = false;
                        originalRequest.errorMessage = null;
                        originalRequest.regularTransactionRecord.Id = saveResult.getId(); // Ensure ID is set on the original record
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

}
public class TransactionHelper {

    //NOTE: 'Transaction' is a reserved variable name - so transactionRecord is used instead
    //TODO - Move to request/response or abstracted transaction data type so not directly setting database fields

    public static final String TRANSACTION_TYPE_REGULAR = 'REGULAR';
    public static final String TRANSACTION_TYPE_TAX_RELIEF = 'TAX_RELIEF';
    public static final String TRANSACTION_TYPE_LUMP_SUM = 'LUMP_SUM';
    public static final String TRANSACTION_TYPE_FEE = 'FEE';
    public static final String TRANSACTION_TYPE_REBATE = 'REBATE';
    public static final String TRANSACTION_TYPE_TRANSFER = 'TRANSFER';
    public static final String TRANSACTION_TYPE_IN_SPECIE = 'IN_SPECIE';
    public static final String TRANSACTION_TYPE_REDRESS = 'REDRESS';
    public static final String TRANSACTION_TYPE_RESIDUAL = 'RESIDUAL';
    public static final String TRANSACTION_TYPE_DIVIDEND = 'DIVIDEND';
    public static final String TRANSACTION_TYPE_DIVIDEND_VCT = 'DIVIDEND_VCT';
    public static final String TRANSACTION_TYPE_INTEREST = 'INTEREST';
    public static final String TRANSACTION_TYPE_REFUND = 'REFUND';

    public static final List<String> TAX_RELIEF_EXPECTATION_TRANSACTION_TYPES = new List<String>{TRANSACTION_TYPE_REGULAR, TRANSACTION_TYPE_LUMP_SUM };
    public static final Decimal TAX_PERCENTAGE = 0.25;
    public static final Integer TAX_OFFSET_DAYS = 60;

    public static final String TRANSACTION_STATUS_NEW = 'New';
    public static final String TRANSACTION_STATUS_LINKED = 'Linked To Expectation';
    public static final String TRANSACTION_STATUS_REVIEWED = 'Reviewed';

    public static final String TRANSACTION_DIRECTION_WITHDRAWAL = 'WITHDRAWAL';
    public static final String TRANSACTION_DIRECTION_CONTRIBUTION = 'CONTRIBUTION';

    //to do put in  a custom setting / record based - can have multiple match phrases per type
    public static final String TRANSACTION_DESCRIPTION_MATCH_PHRASE_REGULAR = 'Regular';
    public static final String TRANSACTION_DESCRIPTION_MATCH_PHRASE_TAX_RELIEF = 'Tax'; //?
    public static final String TRANSACTION_DESCRIPTION_MATCH_PHRASE_FEE = 'Fee';

    public static final Map<String, String> TRANSACTION_DESCRIPTION_TO_TYPE_MAP = new Map<String, String>{
        'Regular' => TRANSACTION_TYPE_REGULAR,
        'Fee' => TRANSACTION_TYPE_FEE,
        'Charge' => TRANSACTION_TYPE_FEE,
        'Tax relief' => TRANSACTION_TYPE_TAX_RELIEF,
        'Top Up' => TRANSACTION_TYPE_LUMP_SUM,
        'Transfer' => TRANSACTION_TYPE_TRANSFER,
        'Trf' => TRANSACTION_TYPE_TRANSFER,
        'Residual' => TRANSACTION_TYPE_RESIDUAL
    };


    public static final Map<String, Boolean> TRANSACTION_TYPE_VISIBILITY_MAP = new Map<String, Boolean>{
        TRANSACTION_TYPE_REGULAR => true,
        TRANSACTION_TYPE_LUMP_SUM => true,
        TRANSACTION_TYPE_FEE => false,
        TRANSACTION_TYPE_TAX_RELIEF => true,
        TRANSACTION_TYPE_REBATE => true,
        TRANSACTION_TYPE_TRANSFER => true,
        TRANSACTION_TYPE_IN_SPECIE => true,
        TRANSACTION_TYPE_REDRESS => true,
        TRANSACTION_TYPE_RESIDUAL => false,
        TRANSACTION_TYPE_DIVIDEND => false,
        TRANSACTION_TYPE_DIVIDEND_VCT => true,
        TRANSACTION_TYPE_INTEREST => false,
        TRANSACTION_TYPE_REFUND => true
    };

    //check if regularTransaction exists for transaction
    public static void checkRegularTransactionExistsForTransaction(List<Transaction__c> transactions){
        //should only be where not linked to an expectation as must have a regular transaction set up to match to an expectation
        
        //this initial filtering logic may get pulled into another function
        List<Transaction__c> transactionsToCheckForRegular = new List<Transaction__c>();
        for(Transaction__c transactionRecord : transactions){
            if(transactionRecord.Type__c == TRANSACTION_TYPE_REGULAR && transactionRecord.Status__c == TRANSACTION_STATUS_NEW){
                transactionsToCheckForRegular.add(transactionRecord);
            }
        }

        Map<Id, Transaction__c> productIdToTransactionMap = new Map<Id, Transaction__c>();
        for(Transaction__c transactionRecord : transactionsToCheckForRegular){
            productIdToTransactionMap.put(transactionRecord.FinancialProduct__c, transactionRecord);
        }

        List<RegularTransaction__c> regularTransactions = [SELECT Id, FinancialProduct__c
                                                            FROM RegularTransaction__c 
                                                            WHERE FinancialProduct__c IN :productIdToTransactionMap.keySet()
                                                            AND Status__c != :RegularTransactionHelper.REGULAR_TRANSACTION_STATUS_CANCELLED]; 

        Map<Id, RegularTransaction__c> productIdToRegularTransactionMap = new Map<Id, RegularTransaction__c>();                                                    
        for(RegularTransaction__c regularTransaction : regularTransactions){
            productIdToRegularTransactionMap.put(regularTransaction.FinancialProduct__c, regularTransaction);
        }

        List<Transaction__c> transactionsMissingRegular = new List<Transaction__c>();
        //check which are missing
        for(Id productId : productIdToTransactionMap.keySet()){
            if(!productIdToRegularTransactionMap.containsKey(productId)){
                transactionsMissingRegular.add(productIdToTransactionMap.get(productId));
            }
        }

        if(transactionsMissingRegular.size() > 0){
            RegularTransactionHelper.generateRegularTransactionFromTransactionRecords(transactionsMissingRegular);
        }
    }

    //match transaction to expectation
    public static List<Transaction__c> matchTransactionToExpectation(List<Transaction__c> transactions){

        Double matchingTolerancePercentage = 0;

        //get transactions linked to expectation
        Set<ID> productIds = new Set<Id>();
        for(Transaction__c transactionRecord : transactions){
            productIds.add(transactionRecord.FinancialProduct__c);
        }

        List<Expectation__c> expectations = [SELECT Id, Amount__c, Direction__c, FinancialProduct__c, Type__c 
                                                FROM Expectation__c 
                                                WHERE FinancialProduct__c IN :productIds
                                                    AND Transaction__c = NULL
                                                    AND Status__c = :ExpectationHelper.EXPECTATION_STATUS_PENDING]; //Not linked and not cancelled

        Map<Id, List<Expectation__c>> productIdToExpectationsMap = new Map<Id, List<Expectation__c>>();
        for(Expectation__c expectation : expectations){

            if(productIdToExpectationsMap.containsKey(expectation.FinancialProduct__c)){
                productIdToExpectationsMap.get(expectation.FinancialProduct__c).add(expectation);
            }else{
                productIdToExpectationsMap.put(expectation.FinancialProduct__c, new List<Expectation__c>{expectation});
            }
        }

        List<Expectation__c> expectationsToUpdate = new List<Expectation__c>(); //todo - convert to requests
        List<Transaction__c> transactionsToupdate = new List<Transaction__c>();
        //loop through transactions and compare
        for(Transaction__c transactionRecord : transactions){

            if(productIdToExpectationsMap.containsKey(transactionRecord.FinancialProduct__c)){
                Double amountLowerBound = transactionRecord.Amount__c * (1 - matchingTolerancePercentage); 
                Double amountUpperBound = transactionRecord.Amount__c * (1 + matchingTolerancePercentage);
                for(Expectation__c expectation : productIdToExpectationsMap.get(transactionRecord.FinancialProduct__c)){
                    if( expectation.Direction__c == transactionRecord.Direction__c){
                        //add in type?
                        //if >1 match we shoudl look at types or not match as cant make that call
                        if(expectation.Amount__c >= amountLowerBound && expectation.Amount__c <= amountUpperBound){
                            //transactionRecord.Expectation__c = expectation.Id;
                            expectation.Transaction__c = transactionRecord.Id;
                            expectationsToUpdate.add(expectation);

                            transactionRecord.ExpectationLinked__c = true;
                            //transactionsToupdate.add(transactionRecord);

                            break;
                        }

                    }
                }
            }
        }

        //update expectations
        if(expectationsToUpdate.size() > 0){
            update expectationsToUpdate;
        }
        return transactions;
    }

    //categorise transaction based on hubwise labling in despcription
    public static List<Transaction__c> categoriseTransaction(List<Transaction__c> transactions){
        //loop through transactions and look for description
        for(Transaction__c transactionRecord : transactions){
            if(transactionRecord.Description__c != null){
                for(String phrase : TRANSACTION_DESCRIPTION_TO_TYPE_MAP.keySet()){
                    if(transactionRecord.Description__c.toLowerCase().contains(phrase.toLowerCase())){
                        transactionRecord.Type__c = TRANSACTION_DESCRIPTION_TO_TYPE_MAP.get(phrase);
                        break;
                    }
                }
            }
        }



        return transactions;
    }

    //set visibility basecd on transaction category
    public static List<Transaction__c> setVisibility(List<Transaction__c> transactions){
        //default is currently visibile
        for(Transaction__c transactionRecord : transactions){
            if(transactionRecord.Type__c != null){
                if(TRANSACTION_TYPE_VISIBILITY_MAP.containsKey(transactionRecord.Type__c)){
                    transactionRecord.isVisible__c = TRANSACTION_TYPE_VISIBILITY_MAP.get(transactionRecord.Type__c);
                }
            }
        }
        return transactions;
    }

    public static List<Transaction__c> setExpectationLinkedFlag(List<Transaction__c> transactions) {
        // First, check if the list is empty to avoid running unnecessary code.
        if (transactions == null || transactions.isEmpty()) {
            return transactions;
        }

        Set<Id> transactionIdsWithExpectations = new Set<Id>();

        for (Expectation__c expectation : [
            SELECT Transaction__c
            FROM Expectation__c
            WHERE Transaction__c IN :transactions
        ]) {
            // The Transaction__c field will not be null due to the WHERE clause.
            transactionIdsWithExpectations.add(expectation.Transaction__c);
        }

        // Now, loop through the original list of transactions.
        for (Transaction__c transactionRecord : transactions) {
            // Set the checkbox to true if the transaction's Id is in our set, otherwise false.
            // This handles both setting and un-setting the flag correctly.
            transactionRecord.ExpectationLinked__c = transactionIdsWithExpectations.contains(transactionRecord.Id);
        }

        return transactions;
    }

    public static Map<Id, Transaction__c> checkIfTransactionSetToReviewed(Map<Id, Transaction__c> oldTransactions, Map<Id, Transaction__c> newTransactions) {
        Map<Id, Transaction__c> transactionsSetToReviewed = new Map<Id, Transaction__c>();

        if (newTransactions == null || newTransactions.isEmpty()) {
            return transactionsSetToReviewed;
        }

        for (Transaction__c newTransaction : newTransactions.values()) {
            Transaction__c oldTransaction = oldTransactions.get(newTransaction.Id);
            system.debug('newTransaction Status: ' + newTransaction.Status__c + ' oldTransaction.Status__c: ' + oldTransaction.Status__c);
            if(newTransaction.Status__c != oldTransaction.Status__c && newTransaction.Status__c == TRANSACTION_STATUS_REVIEWED){
                //do set to reviwed code
                transactionsSetToReviewed.put(newTransaction.Id, newTransaction);
            }
        }

        return transactionsSetToReviewed;
    }

    public static void checkIfTaxReliefExpectationIsNeeded(Map<Id, Transaction__c> transactions) {
        // Check if the transaction list is empty or null.
        if (transactions == null || transactions.isEmpty()) {
            return;
        }

        Map<Id, Transaction__c> transactionsToCheck = new Map<Id, Transaction__c>();
        for (Transaction__c transactionRecord : transactions.values()) {
            if(transactionRecord.Direction__c == TRANSACTION_DIRECTION_CONTRIBUTION && TAX_RELIEF_EXPECTATION_TRANSACTION_TYPES.contains(transactionRecord.Type__c)){
                transactionsToCheck.put(transactionRecord.id, transactionRecord);
            }
        }


        //query financial products to get product type record type to determine if tax releif expectation is needed
        List<Transaction__c> transactionList = [SELECT Id, FinancialProduct__r.RecordType.DeveloperName, FinancialProduct__r.FinancialProductType__r.TransactionTaxRelief__c, Amount__c, Date__c, FinancialProduct__c FROM Transaction__c WHERE Id IN :transactions.keySet()];
        //can save this reuqest if filtering logic later is pulled forward
        List<Expectation__c> linkedExpectations = [SELECT Id, Amount__c, Direction__c, FinancialProduct__c, Type__c, Fulfilment__c, RegularTransaction__c, Transaction__c, Date__c, Status__c 
                                                    FROM Expectation__c
                                                    WHERE Transaction__c IN :transactionsToCheck.keySet()];

        Map<Id, Expectation__c> transactionIdToExpectationMap = new Map<Id, Expectation__c>();
        for(Expectation__c expectation : linkedExpectations){
            transactionIdToExpectationMap.put(expectation.Transaction__c, expectation);
        }

        List<ExpectationRequest> taxExpectations = new List<ExpectationRequest>();

        for(Transaction__c transactionRecord : transactionList){
            if(transactionRecord.FinancialProduct__r.FinancialProductType__r.TransactionTaxRelief__c == true){
                //create tax releif expectation request
                //check if expectation already exist
                if(!transactionIdToExpectationMap.containsKey(transactionRecord.Id)){
                    break;
                    //log an error that an expectation should have been linked
                }

                ExpectationRequest origionalTransactionExpectation = new ExpectationRequest(transactionIdToExpectationMap.get(transactionRecord.Id));


                ExpectationRequest expectationRequest = new ExpectationRequest();
                expectationRequest.amount = transactionRecord.Amount__c * TAX_PERCENTAGE;
                expectationRequest.expectationDate = transactionRecord.Date__c.addDays(TAX_OFFSET_DAYS);
                expectationRequest.fulfilmentId = origionalTransactionExpectation.fulfilmentId;
                expectationRequest.regularId = origionalTransactionExpectation.regularId;
                expectationRequest.productId = transactionRecord.FinancialProduct__c;
                expectationRequest.direction = ExpectationHelper.DIRECTION_CONTRIBUTION;
                expectationRequest.transactionType = TRANSACTION_TYPE_TAX_RELIEF;
                expectationRequest.status = ExpectationHelper.EXPECTATION_STATUS_PENDING;
                


                taxExpectations.add(expectationRequest);
            }
        }

        if(taxExpectations.size() > 0){
            List<ExpectationRequest> expectations = ExpectationHelper.createExpectations(taxExpectations);
            //todo add logging of successes / errors
        }

    }

}
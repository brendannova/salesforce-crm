public class ExpectationRequest {
    
    // Error message constants for consistency and maintainability
    public static final String ERROR_PRODUCT_NOT_SPECIFIED = 'Product not specified.';
    public static final String ERROR_AMOUNT_NOT_SPECIFIED = 'Amount not specified.';
    public static final String ERROR_DATE_NOT_SPECIFIED = 'Expectation date not specified.';
    public static final String ERROR_DATE_PAST = 'Expectation date must be today or in the future.';
    public static final String ERROR_DIRECTION_NOT_SPECIFIED = 'Direction not specified.';
    public static final String ERROR_DIRECTION_INVALID = 'Direction value not valid.';
    public static final String ERROR_TRANSACTION_TYPE_NOT_SPECIFIED = 'Transaction type not specified.';
    public static final String ERROR_TRANSACTION_TYPE_INVALID = 'Transaction type value not valid.';
    public static final String ERROR_FULFILMENT_OR_REGULAR_REQUIRED = 'Specify a fulfilment and/or regular.';
    public static final String ERROR_STATUS_NOT_SPECIFIED = 'Status not specified.';
    
    // Cached transaction type values for performance optimization
    private static Set<String> cachedTransactionTypeValues;
    
    @AuraEnabled public Id expectationId;
    @AuraEnabled public String transactionType;
    @AuraEnabled public Date expectationDate;
    @AuraEnabled public Id productId;
    @AuraEnabled public Id fulfilmentId;
    @AuraEnabled public Id regularId;
    @AuraEnabled public Decimal amount;
    @AuraEnabled public String direction;
    @AuraEnabled public Id transactionId;
    @AuraEnabled public String status;

    @AuraEnabled public Boolean isError;
    @AuraEnabled public String errorMessage = '';

    @AuraEnabled public Expectation__c expectationRecord;

    /**
     * Default constructor.
     * Initializes a new ExpectationRequest with default values.
     */
    public ExpectationRequest(){
    }
    
    /**
     * Constructor that takes an Expectation__c record.
     * Initializes the request and converts the record to request format.
     * 
     * @param expectationRecord The Expectation__c record to convert
     */
    public ExpectationRequest(Expectation__c expectationRecord){
        this.expectationRecord = expectationRecord;
        this.convertToRequest();
    }

    /**
     * Adds an error message to the request.
     * Appends the error message with proper spacing for better formatting.
     * 
     * @param errorMessage The error message to add
     */
    public void setError(String errorMessage) {
        this.isError = true;
        if (String.isNotBlank(this.errorMessage)) {
            this.errorMessage += ' ' + errorMessage;
        } else {
            this.errorMessage = errorMessage;
        }
    }

    /**
     * Validates the request data with early exit for critical errors.
     * Validates required fields first, then business rules.
     * 
     * @return Boolean True if validation passes, false otherwise
     */
    public Boolean validate() {
        this.isError = false;
        this.errorMessage = '';

        // Validate required fields first (critical errors)
        if (!validateRequiredFields()) {
            return false;
        }

        // Validate business rules (non-critical errors)
        validateBusinessRules();
        
        return !this.isError;
    }

    /**
     * Validates required fields with early exit.
     * Returns false immediately if any critical required field is missing.
     * 
     * @return Boolean True if all required fields are present, false otherwise
     */
    private Boolean validateRequiredFields() {
        // Check product ID first as it's fundamental
        if (this.productId == null) {
            this.setError(ERROR_PRODUCT_NOT_SPECIFIED);
            return false;
        }

        // Check amount
        if (this.amount == null) {
            this.setError(ERROR_AMOUNT_NOT_SPECIFIED);
            return false;
        }

        // Check expectation date
        if (this.expectationDate == null) {
            this.setError(ERROR_DATE_NOT_SPECIFIED);
            return false;
        }

        // Check direction
        if (this.direction == null) {
            this.setError(ERROR_DIRECTION_NOT_SPECIFIED);
            return false;
        }

        // Check transaction type
        if (this.transactionType == null) {
            this.setError(ERROR_TRANSACTION_TYPE_NOT_SPECIFIED);
            return false;
        }

        // Check status
        if (this.status == null) {
            this.setError(ERROR_STATUS_NOT_SPECIFIED);
            return false;
        }

        return true;
    }

    /**
     * Validates business rules after required fields are confirmed.
     * These are non-critical validations that don't prevent further processing.
     */
    private void validateBusinessRules() {
        // Validate date logic
        if (this.expectationDate != null && this.expectationDate < Date.today()) {
            this.setError(ERROR_DATE_PAST);
        }

        // Validate direction values
        if (this.direction != null && !ExpectationHelper.DIRECTION_VALUES.contains(this.direction)) {
            this.setError(ERROR_DIRECTION_INVALID);
        }

        // Validate transaction type values (using cached values for performance)
        if (this.transactionType != null && !getCachedTransactionTypeValues().contains(this.transactionType)) {
            this.setError(ERROR_TRANSACTION_TYPE_INVALID);
        }

        // Validate fulfilment or regular requirement
        if (this.fulfilmentId == null && this.regularId == null) {
            this.setError(ERROR_FULFILMENT_OR_REGULAR_REQUIRED);
        }
    }

    /**
     * Gets cached transaction type values for performance optimization.
     * Caches the values on first access to avoid repeated picklist queries.
     * 
     * @return Set<String> Set of valid transaction type values
     */
    private static Set<String> getCachedTransactionTypeValues() {
        if (cachedTransactionTypeValues == null) {
            cachedTransactionTypeValues = new Set<String>(ExpectationHelper.TRANSACTION_TYPE_VALUES);
        }
        return cachedTransactionTypeValues;
    }

    /**
     * Converts the request data to an Expectation__c record.
     * Safely handles null values and creates a new record if needed.
     * Preserves existing record references to maintain trigger relationships.
     */
    public void convertToRecord() {
        // Create new record if none exists, otherwise preserve existing reference
        if (this.expectationRecord == null) {
            this.expectationRecord = new Expectation__c();
        }

        // Safely assign values with null checks
        this.expectationRecord.Id = this.expectationId;
        this.expectationRecord.FinancialProduct__c = this.productId;
        this.expectationRecord.Amount__c = this.amount;
        this.expectationRecord.Date__c = this.expectationDate;
        this.expectationRecord.Direction__c = this.direction;
        this.expectationRecord.Type__c = this.transactionType;
        this.expectationRecord.Fulfilment__c = this.fulfilmentId;
        this.expectationRecord.RegularTransaction__c = this.regularId;
        this.expectationRecord.Transaction__c = this.transactionId;
        this.expectationRecord.Status__c = this.status;
    }

    /**
     * Converts an Expectation__c record to request format.
     * Safely extracts values from the record with null checks.
     * Requires expectationRecord to be set before calling.
     */
    public void convertToRequest() {
        if (this.expectationRecord == null) {
            throw new IllegalArgumentException('Expectation record must be set before converting to request');
        }
        
        // Safely extract values from the record
        this.expectationId = this.expectationRecord.Id;
        this.productId = this.expectationRecord.FinancialProduct__c;
        this.amount = this.expectationRecord.Amount__c;
        this.expectationDate = this.expectationRecord.Date__c;
        this.direction = this.expectationRecord.Direction__c;
        this.transactionType = this.expectationRecord.Type__c;
        this.fulfilmentId = this.expectationRecord.Fulfilment__c;
        this.regularId = this.expectationRecord.RegularTransaction__c;
        this.transactionId = this.expectationRecord.Transaction__c;
        this.status = this.expectationRecord.Status__c;
    }
}
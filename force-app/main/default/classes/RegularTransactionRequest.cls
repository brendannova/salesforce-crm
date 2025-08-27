public class RegularTransactionRequest {
    
    @AuraEnabled public Id id;
    @AuraEnabled public Id productId;
    @AuraEnabled public Decimal amount;
    @AuraEnabled public String direction;
    @AuraEnabled public String transactionType;
    @AuraEnabled public String frequency;
    @AuraEnabled public Date nextTransactionDate;
    @AuraEnabled public Date startDate;
    @AuraEnabled public Date endDate;
    @AuraEnabled public string status;

    @AuraEnabled public Boolean isError;
    @AuraEnabled public String errorMessage = '';

    @AuraEnabled public RegularTransaction__c regularTransactionRecord;

    public void setError(string errorMessage) {
        this.isError = true;
        this.errorMessage += errorMessage;
    }
    
    public void validate() {
        this.isError = false;
        this.errorMessage = '';

        //todo extend validation

        if(this.productId == null) {
            this.setError('Product not specified. ');
        }

        if(this.amount == null){
            this.setError('Amount not specified. ');
        }

        if(this.direction == null) {
            this.setError('Direction not specified. ');
        } else if(!ExpectationHelper.DIRECTION_VALUES.contains(this.direction)) {
            this.setError('Direction value not valid. ');
        }

        if(this.status == null) {
            this.setError('Status not specified. ');
        }

        /*
        if(this.transactionType == null){
            this.setError('Transaction type not specified. ');
        } else if(!ExpectationHelper.TRANSACTION_TYPE_VALUES.contains(this.transactionType)){
            this.setError('Transaction type value not valid. ');
        }*/
    }

    public void convertToRecord(){

        if(this.regularTransactionRecord == null) {
            this.regularTransactionRecord = new RegularTransaction__c();
        }

        this.regularTransactionRecord.Id = this.id;
        this.regularTransactionRecord.FinancialProduct__c = this.productId;
        this.regularTransactionRecord.Amount__c = this.amount;
        this.regularTransactionRecord.Direction__c = this.direction;
        //this.regularTransactionRecord.Type__c = this.transactionType;
        this.regularTransactionRecord.Frequency__c = this.frequency;
        this.regularTransactionRecord.NextTransactionDate__c = this.nextTransactionDate;
        this.regularTransactionRecord.StartDate__c = this.startDate;
        this.regularTransactionRecord.EndDate__c = this.endDate;
        this.regularTransactionRecord.Status__c = this.status;
    }

    public void convertRecordToRequest(){

        this.id = this.regularTransactionRecord.Id;
        this.productId = this.regularTransactionRecord.FinancialProduct__c;
        this.amount = this.regularTransactionRecord.Amount__c;
        this.direction = this.regularTransactionRecord.Direction__c;
        this.frequency = this.regularTransactionRecord.Frequency__c;
        this.nextTransactionDate = this.regularTransactionRecord.NextTransactionDate__c;
        this.startDate = this.regularTransactionRecord.StartDate__c;
        this.endDate = this.regularTransactionRecord.EndDate__c;
        this.status = this.regularTransactionRecord.Status__c;
    }
}
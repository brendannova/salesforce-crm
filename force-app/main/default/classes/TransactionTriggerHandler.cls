public class TransactionTriggerHandler extends TriggerHandler{

    //recast trigger variables from SObjects
    private Map<Id, Transaction__c> oldTransactionMap = (Map<Id, Transaction__c>) Trigger.oldMap;
    private Map<Id, Transaction__c> newTransacitonMap = (Map<Id, Transaction__c>) Trigger.newMap;

    private List<Transaction__c> newTransacitonList = (List<Transaction__c>) Trigger.new; //for insert when it will not have an id yet

    public override void beforeInsert(){
        TransactionHelper.setVisibility(newTransacitonList);
    }
    
    public override void beforeUpdate(){
        TransactionHelper.setVisibility(newTransacitonMap.values());
    }

    public override void afterUpdate(){
        Map<Id, Transaction__c> transactionsSetToReviewed = TransactionHelper.checkIfTransactionSetToReviewed(oldTransactionMap, newTransacitonMap);
        TransactionHelper.checkIfTaxReliefExpectationIsNeeded(transactionsSetToReviewed);
    }

}
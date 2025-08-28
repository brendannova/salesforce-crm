public class ExpectationTriggerHandler extends TriggerHandler{

    //recast trigger variables from SObjects
    private Map<Id, Expectation__c> oldExpectationMap = (Map<Id, Expectation__c>) Trigger.oldMap;
    private Map<Id, Expectation__c> newExpectationMap = (Map<Id, Expectation__c>) Trigger.newMap;

    private Map<Id, ExpectationRequest> oldExpectationRequestMap = new Map<Id, ExpectationRequest>();
    private Map<Id, ExpectationRequest> newExpectationRequestMap = new Map<Id, ExpectationRequest>();

    public override void beforeUpdate(){
        recordMapsToRequestMaps();
        ExpectationHelper.updateExpectationStatusIfLinkedToTransaction(oldExpectationRequestMap, newExpectationRequestMap);
        requestMapsToRecordMaps(); 
    }

    public override void afterUpdate(){
        recordMapsToRequestMaps();
        ExpectationHelper.updateTransactionExpectationLinkedFlag(oldExpectationRequestMap, newExpectationRequestMap);
        //requestMapsToRecordMaps(); 
    }

    private void recordMapsToRequestMaps(){
        for(Expectation__c oldExpectation : oldExpectationMap.values()){
            ExpectationRequest expectationRequest = new ExpectationRequest();
            expectationRequest.expectationRecord = oldExpectation;
            expectationRequest.convertToRequest();

            oldExpectationRequestMap.put(oldExpectation.Id, expectationRequest);
        }
        
        for(Expectation__c newExpectation : newExpectationMap.values()){
            ExpectationRequest expectationRequest = new ExpectationRequest();
            expectationRequest.expectationRecord = newExpectation;
            expectationRequest.convertToRequest();

            newExpectationRequestMap.put(newExpectation.Id, expectationRequest);
        }
    }

    private void requestMapsToRecordMaps(){ //only new as old is read only

        for(ExpectationRequest newRequest : newExpectationRequestMap.values()){
            newRequest.convertToRecord();
            //newExpectationMap.put(newRequest.expectationRecord.Id, newRequest.expectationRecord);
        }
    }
}
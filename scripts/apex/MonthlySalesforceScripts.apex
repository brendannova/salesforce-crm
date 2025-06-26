/**
 * This script gets all recommendations that may need to be reviewed by CATS and ensures that their details 
 * are stamped appropriately on the FF_session__c record. This script is run to address an issue where we need them
 * to see the full list of recommendations but currently just dump this in a text field. This is run once per month 
 * so is not a priority to resolve. 
 */

List<FF_session__c> records = [SELECT Id, AdviceRecommendations__c, Related_Advice__c FROM ff_session__c where EligibleForComplianceReview__c = true];
List<Id> adviceIds = new List<Id>();
Map<Id, ff_session__c> sessionMap = new Map<Id,ff_session__c>();
for(ff_session__c record : records){
    sessionMap.put(record.Related_Advice__c, record);
}
List<Advice__c> advs = [SELECT Id, Profile_Snapshot__c, (SELECT RecommendationSummary__c FROM Recommendation__r), (SELECT Name FROM Fulfilment__r) FROM Advice__c WHERE Id IN :sessionMap.keySet()];
List<FF_session__c> seshUpdate = new List<FF_session__c>();
for(Advice__c adv : advs){
    FF_session__c sesh = sessionMap.get(adv.Id);
    String recSummary = '';
    for(Recommendation__c rec : adv.Recommendation__r){
        recSummary += rec.RecommendationSummary__c + '; ';
    }
    for(Fulfillment__c ff : adv.Fulfilment__r){
        recSummary += ff.Name + '; ';
    }
    sesh.AdviceRecommendations__c = recSummary;
    seshUpdate.add(sesh);    
    System.debug(sesh);
}
System.debug(records.size());
System.debug(advs.size());
System.debug(seshUpdate.size());
update seshUpdate;
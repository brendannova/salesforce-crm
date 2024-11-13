/*********************************************************
Apex Class Name    : AdvicePlanningPioritisationHelper
Created Date       : 2024-09-10
@description       : This class is a helper for a planning advice management/prioritisation LWC. Runs without sharing so summary level view always visible. 
@author            : Cian Morrissey
Modification Log:
Date         Author                               Modification
2024-09-10   Cian Morrissey                       Initial Version
*********************************************************/
public without sharing class AdvicePlanningPioritisationHelper {

    /**********************************************************
    @Method Name    : getAdvice
    @author         : Cian Morrissey
    @description    : This method runs a query to get the advice data then returns it
    @param          : N/A
    @return         : advice - the list of advice returned
    *********************************************************/
    @AuraEnabled(cacheable=true)
    public static List<Advice__c> getAdvice(){
        List<String> adviceStatuses = new List<String>{'Data gathering','Risk Call','Suitability in progress'};
        List<Advice__c> advice = [SELECT Id, Name, New_or_existing_client__c, PlanningNotes__c, IsPriority__c, AdviceType__r.Name, Advice_Household__r.Name,  Assigned_planner__c, Assigned_planner__r.Name, Advice_status__c, Partner__r.Name, RetirementCallStatus__c, RiskCallStatus__c, RiskCallDate__c, NarrativeStatus__c, DeckStatus__c, OW_review__c, OW_review__r.OW_due_date__c FROM Advice__c WHERE Advice_status__c IN ('risk call','data gathering','suitability in progress') WITH SECURITY_ENFORCED ORDER BY Advice_status__c DESC, DeckStatus__c DESC, NarrativeStatus__c DESC, RiskCallStatus__c DESC, RiskCallDate__c ASC NULLS LAST, DataAnalysisStatus__c DESC, DataGatheringStatus__c DESC, CreatedDate ASC];
        return advice;
    }
}
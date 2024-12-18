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
    public static List<Map<String, Object>> getAdvice(){
        List<Map<String, Object>> adviceDataList = new List<Map<String, Object>>();
        List<String> adviceStatuses = new List<String>{'Data gathering','Risk Call','Suitability in progress','Prepare advice'};
        List<Advice__c> adviceRecords = [SELECT Id, Name, New_or_existing_client__c, Advice_Household__r.OW_dedicated_specialist__r.Name, PlanningNotes__c, IsPriority__c, AdviceType__r.Name, AdviceType__r.DeveloperName__c, Advice_Household__r.Name,  Assigned_planner__c, Assigned_planner__r.Name, Advice_status__c, Partner__r.Name, RetirementCallStatus__c, RiskCallStatus__c, RiskCallDate__c, NarrativeStatus__c, DeckStatus__c, OW_review__c, OW_review__r.OW_due_date__c FROM Advice__c WHERE Advice_status__c IN :adviceStatuses WITH SECURITY_ENFORCED ORDER BY Advice_status__c DESC, DeckStatus__c DESC, NarrativeStatus__c DESC, RiskCallStatus__c DESC, RiskCallDate__c ASC NULLS LAST, DataAnalysisStatus__c DESC, DataGatheringStatus__c DESC, CreatedDate ASC];
        String urlPrefix = URL.getOrgDomainURL().toExternalForm() + '/';

        // Loop data to sort it
        for(Advice__c advice : adviceRecords){
            Map<String, Object> adviceData = new Map<String, Object>();
        	adviceData.put('Id', String.valueOf(advice.Id));
            adviceData.put('Name', advice.Name);
            adviceData.put('RecordLink', urlPrefix + advice.Id);
            adviceData.put('Status', advice.Advice_Status__c);
            adviceData.put('Planner', advice.Assigned_planner__r.Name);
            adviceData.put('AdviceType', advice.AdviceType__r.Name);
            adviceData.put('NewOrExisting', getOnboardingOrExisting(advice));
            adviceData.put('RiskCallDate', advice.RiskCallDate__c);
            adviceData.put('AnnualReviewDate', advice.OW_review__r.OW_due_date__c);
            adviceData.put('NarrativeStatus', advice.NarrativeStatus__c);
            adviceData.put('DeckStatus', advice.DeckStatus__c);
            adviceData.put('RiskCallStatus', advice.RiskCallStatus__c);
            adviceData.put('Partner', advice.Partner__r.Name);
            adviceData.put('IsPriority__c', advice.IsPriority__c);
            adviceData.put('PlanningNotes__c', advice.PlanningNotes__c);
            adviceData.put('Stage', getStage(advice));
            adviceData.put('RetirementCallStatus', getRetirementCallStatus(advice.RetirementCallStatus__c));
            adviceData.put('Specialist', advice.Advice_Household__r.OW_dedicated_specialist__r.Name);
            adviceDataList.add(adviceData);
        }
        return adviceDataList;
    }

    private static String getOnboardingOrExisting(Advice__c advice) {
        if(advice.New_or_existing_client__c == 'New'){
            return 'NEW';
        } else if (advice.AdviceType__r.DeveloperName__c == 'TOP_UP'){
            return 'TOP_UP';
        } else if (advice.AdviceType__r.DeveloperName__c == 'WITHDRAWAL'){
            return 'WITHDRAWAL';
        } else {
            return 'EXISTING';
        }
    }

    private static String getRetirementCallStatus(String retirementCallStatus){
        if(!String.isEmpty(retirementCallStatus)){
            return UtilityString.convertCaseUpperSnakeToSentence(retirementCallStatus);
        } else {
            return '';
        }
    }

    private static String getStage(Advice__c advice){
        String narrativeStatus = advice.NarrativeStatus__c;
        string deckStatus = advice.DeckStatus__c;
        String status = advice.Advice_Status__c;
        String stage;
        if(status == 'Data gathering'){
            stage = status;
        } else if(status == 'Risk Call'){
            stage = status + ' | ' + advice.RiskCallStatus__c;
        } else if (status == 'Suitability in progress' || status == 'Prepare advice'){
            if (narrativeStatus != '' && narrativeStatus != 'Complete'){
                stage = 'Narrative | ' + narrativeStatus;
            } else if (narrativeStatus == 'Complete') {
                stage = 'Deck | ' + deckStatus;
            }
        } 
        return stage;
    }
}
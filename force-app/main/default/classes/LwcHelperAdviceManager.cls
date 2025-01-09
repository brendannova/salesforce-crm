/**
 * This class exists solely to retrieve, process, and return data that is needed by the advice manager LWC.
 * In addition to a raw query, it also determines some custom formatted data that is not stored in the advice object.
 * If new data is needed in the LWC, it should be added here.
 * This class should not be used in any other context.
 */
 
public without sharing class LwcHelperAdviceManager {
    /**
     * The core method that is called from the LWC, this method retrieves, processes, and returns the data.
     * It accepts an advice type as an input, which is passed in from the LWC. Currently, this is not aligned to the advice type object but rather to the advice types on the LWC. 
     */
    @AuraEnabled(cacheable=true)
    public static List<Map<String, Object>> getAdvice(String adviceTypeRequested){
        List<Map<String, Object>> adviceDataList = new List<Map<String, Object>>();
        if(!String.isBlank(adviceTypeRequested)){
            List<String> adviceStatuses = new List<String>{'Data gathering','Risk Call','Suitability in progress','Prepare advice'};
            if(adviceTypeRequested == 'TOP_UP' || adviceTypeRequested == 'WITHDRAWAL' || adviceTypeRequested == 'PROTECTION' || adviceTypeRequested == 'REGULAR_AMENDMENT' ){
                adviceStatuses.add('Setup');
            }
            List<Advice__c> adviceRecords = [SELECT Id, Name, New_or_existing_client__c, Advice_Household__r.OW_dedicated_specialist__r.Name, PlanningNotes__c, IsPriority__c, AdviceType__r.Name, AdviceType__r.DeveloperName__c, Advice_Household__r.Name,  Assigned_planner__c, Assigned_planner__r.Name, Advice_status__c, Partner__r.Name, RetirementCallStatus__c, RiskCallStatus__c, RiskCallDate__c, NarrativeStatus__c, DeckStatus__c, OW_review__c, OW_review__r.OW_due_date__c FROM Advice__c WHERE Advice_status__c IN :adviceStatuses WITH SECURITY_ENFORCED ORDER BY Advice_status__c DESC, DeckStatus__c DESC, NarrativeStatus__c DESC, RiskCallStatus__c DESC, RiskCallDate__c ASC NULLS LAST, DataAnalysisStatus__c DESC, DataGatheringStatus__c DESC, CreatedDate ASC];
            String urlPrefix = URL.getOrgDomainURL().toExternalForm() + '/';
            Map<String,String> picklistApiLabelMap = getPicklistApiLabelMap();
            for(Advice__c advice : adviceRecords){
                String adviceType = getAdviceType(advice);
                if(adviceTypeRequested == adviceType){
                    Map<String, Object> adviceData = new Map<String, Object>();
                    adviceData.put('Id', String.valueOf(advice.Id));
                    adviceData.put('Name', advice.Name);
                    adviceData.put('RecordLink', urlPrefix + advice.Id);
                    adviceData.put('Status', advice.Advice_Status__c);
                    adviceData.put('Planner', advice.Assigned_planner__r.Name);
                    adviceData.put('AdviceType', advice.AdviceType__r.Name);
                    adviceData.put('NewOrExisting', adviceType);
                    adviceData.put('RiskCallDate', advice.RiskCallDate__c);
                    adviceData.put('AnnualReviewDate', advice.OW_review__r.OW_due_date__c);
                    adviceData.put('NarrativeStatus', advice.NarrativeStatus__c);
                    adviceData.put('DeckStatus', advice.DeckStatus__c);
                    adviceData.put('RiskCallStatus', advice.RiskCallStatus__c);
                    adviceData.put('Partner', advice.Partner__r.Name);
                    adviceData.put('IsPriority__c', advice.IsPriority__c);
                    adviceData.put('PlanningNotes__c', advice.PlanningNotes__c);
                    adviceData.put('Stage', getStage(advice));
                    adviceData.put('RetirementCallStatus', picklistApiLabelMap.get(advice.RetirementCallStatus__c));
                    adviceData.put('Specialist', advice.Advice_Household__r.OW_dedicated_specialist__r.Name);
                    adviceDataList.add(adviceData);
                }
            }
        }
        return adviceDataList;
    }

    // Create a custom categorisation for the advice that corresponds to filters in the LWC
    private static String getAdviceType(Advice__c advice) {
        if(advice.New_or_existing_client__c == 'New'){
            return 'ONBOARDING';
        } else if (advice.AdviceType__r.DeveloperName__c == 'TOP_UP'){
            return 'TOP_UP';
        } else if (advice.AdviceType__r.DeveloperName__c == 'WITHDRAWAL'){
            return 'WITHDRAWAL';
        } else if (advice.AdviceType__r.DeveloperName__c == 'PROTECTION'){
            return 'PROTECTION';
        } else {
            return 'EXISTING';
        }
    }

    // Converts the retirement call status from its API name to a human friendly version
    private static Map<String,String> getPicklistApiLabelMap(){
        List<Schema.PicklistEntry> picklistItems = Advice__c.RetirementCallStatus__c.getDescribe().getPicklistValues();
        Map<String,String> picklistApiLabelMap = new Map<String,String>();
        For(Schema.PicklistEntry picklistItem : picklistItems){
            picklistApiLabelMap.put(picklistItem.getValue(), picklistItem.getLabel());
        }
        return picklistApiLabelMap;
    }

    // This method calculates a text value for a stage that'll be displayed in the LWC
    private static String getStage(Advice__c advice){
        String narrativeStatus = advice.NarrativeStatus__c;
        string deckStatus = advice.DeckStatus__c;
        String status = advice.Advice_Status__c;
        String stage;
        if(status == 'Setup'){
            stage = status;
        } else if(status == 'Data gathering'){
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
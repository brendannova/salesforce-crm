/**
 * This script contains things that should be run on a daily basis 
 * to monitor for and resolve known issues that exist in Salesforce
 */

/**
 * Identify instances of missing chase recommendation acceptance tasks. 
 */
List<Advice__c> records = [SELECT Id, advice_household__c, (SELECT Id from Tasks WHERE OW_task_information_name__c = 'chase_recommendation_acceptance' AND IsClosed = false), (SELECT Id, Status__c from Recommendation__r WHERE Status__c = 'Awaiting decision') FROM Advice__c WHERE AdvicePresented__c = true ORDER BY Advice_status__c ASC, LastModifiedDate DESC];
Integer i = 0;
for(Advice__c record : records){
    if(record.Tasks.isEmpty() && !record.Recommendation__r.isEmpty() && i < 5){
        i++;
        System.debug(record.Id);
    }    
}
System.debug(i + ' missing tasks');

/**
 * Create tasks where there are instances of missing chase recommendation acceptance tasks. 
 */
List<Advice__c> records = [SELECT Id, advice_household__c, (SELECT Id from Tasks WHERE OW_task_information_name__c = 'chase_recommendation_acceptance' AND IsClosed = false), (SELECT Id, Status__c from Recommendation__r WHERE Status__c = 'Awaiting decision') FROM Advice__c WHERE AdvicePresented__c = true ORDER BY Advice_status__c ASC, LastModifiedDate DESC];
Integer i = 0;
for(Advice__c record : records){
    if(record.Tasks.isEmpty() && !record.Recommendation__r.isEmpty() && i < 5){
        System.debug('AdviceId: ' + record.Id + ' | HouseholdId: ' + record.Advice_household__c);
        Map<String, Object> params = new Map<String, Object>();
        params.put('related_advice_id', record.Id);
        params.put('what_id', record.Id);
        params.put('household_id', record.Advice_household__c);
        params.put('task_type', 'chase_recommendation_acceptance');
        
        // Instantiate and start the Flow
        Flow.Interview.OW_task_create_from_task_information yourFlow = new Flow.Interview.OW_task_create_from_task_information(params);
        yourFlow.start();
        i++;
    }    
}
System.debug(i + ' tasks created');

/**
 * Create RTQ task for advice that will be held up by lack of RTQs
 */
List<Advice__c> records = [SELECT Id, Advice_household__c, Advice_status__c, RtqStatus__c, (SELECT Id from Tasks WHERE OW_task_information_name__c = 'ADVICE_REFRESH_RTQ' AND IsClosed = false) FROM Advice__c WHERE Advicetype__r.IsOnboarding__c = false AND Advice_status__c IN ('Data gathering','Data analysis', 'Risk call', 'Suitability in progress', 'Prepare advice') AND RtqStatus__c IN ('Not started','In progress') ORDER BY Advice_status__c ASC, RtqStatus__c ASC];
Integer i = 0;
for(Advice__c record : records){
    if(record.Tasks.isEmpty()){
        Map<String, Object> params = new Map<String, Object>();
        params.put('related_advice_id', record.Id);
        params.put('what_id', record.Id);
        params.put('household_id', record.Advice_household__c);
        params.put('task_type', 'ADVICE_REFRESH_RTQ');
        
        // Instantiate and start the Flow
        Flow.Interview.OW_task_create_from_task_information yourFlow = new Flow.Interview.OW_task_create_from_task_information(params);
        yourFlow.start();
        i++;
    }    
}
System.debug(i + ' tasks created');

/**
 * Link FF FPs to FPs where this has failed.
 */

Integer i = 0;
List<FF_financial_product__c> fffps = [SELECT Id, name, Household__r.Finserv__status__c, createddate, match_id__c, validated__c, Household__r.Fact_Find_Validations_Outstanding__c, Deleted_By__c, Financial_Product__c from ff_financial_product__c where match_id__c != null and Financial_Product__c = null ORDER BY CreatedDate DESC];
Set<String> matchIds = new Set<String>();
for(FF_financial_product__c fffp : fffps){
    matchIds.add(fffp.match_id__c);
}
List<FinServ__financialaccount__c> fps = [SELECT Id, name, MATCH_id__c FROM FinServ__financialaccount__c where match_id__c IN :matchIds];
Map<String, FinServ__financialaccount__c> fpmap = new Map<String, FinServ__financialaccount__c>();
for(FinServ__financialaccount__c fp : fps){
    fpmap.put(fp.match_id__c, fp);
}
List<FF_financial_product__c> fffpsupdate = new List<FF_financial_product__c>();
for(FF_financial_product__c fffp : fffps){
    
    if(fpmap.containskey(fffp.match_id__c)){
        fffpsupdate.add(new FF_financial_product__c(Id = fffp.Id, Financial_Product__c = fpmap.get(fffp.match_id__c).Id));
        System.debug(fffp.match_id__c + ' | ' + i + ' | ' + fffp.Household__r.Finserv__status__c + ' | ' + fffp.name + ' | ' + fpmap.get(fffp.match_id__c).Name);

    }    
    i++;
}
System.debug(fffpsupdate.size());
System.debug(fffpsupdate);
update fffpsupdate;
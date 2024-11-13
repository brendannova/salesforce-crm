public with sharing class CustomerFactConflictOfInterestHandler {
    
    public static boolean evaluateConflictOfInterest(List<Account> accountList) {
        
        Final String COI_ENUM = 'CONFLICT_OF_INTEREST';
        List<CustomerFact__c> hhFacts = [SELECT Id FROM CustomerFact__c WHERE Status__c = 'Active' AND FactCategoryEnum__c =: COI_ENUM AND Household__c IN: accountList];
        List<Account> updateList = new List<Account>();
        Map<Id, Date> coiDateMap = new Map<Id, Date>();
        for(Account accs : [SELECT Id, DateConflictOfInterestAssessed__c FROM Account WHERE Id IN: accountList]){
            coiDateMap.put(accs.Id, accs.DateConflictOfInterestAssessed__c);
        }
        
        for(Account a : accountList) {
            Boolean accountUpdated = false;
        	if(!hhFacts.isEmpty() && a.ConflictOfInterest__c != 'Yes') {
            	a.conflictOfInterest__c = 'Yes';
                accountUpdated = true;
        	} else if(hhFacts.isEmpty() && a.ConflictofInterest__c != 'No') {
            	a.conflictOfInterest__c = 'No';
                accountUpdated = true;
        	}
            if(a.DateConflictOfInterestAssessed__c != null && a.DateConflictOfInterestAssessed__c != coiDateMap.get(a.Id)){
                accountUpdated = true;
            }
            if(accountUpdated){
                updateList.add(a);
            }
        }
        
        if(!updateList.isEmpty()){
            update updateList;
        }
        return true;
        
    }

}
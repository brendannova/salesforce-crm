public with sharing class LwcHelperAccountStatusFlags {

    public static final String ROLE_CLIENT = 'Client';
    
    public static Set<Id> getHouseholdAccountIds(Id householdId){
        Set<Id> accountIds = new Set<Id>();
        for(AccountContactRelation relation : [SELECT Id, ContactId, Contact.AccountId FROM AccountContactRelation WHERE AccountId = :householdId AND IsActive = True AND Roles = :ROLE_CLIENT]){
            accountIds.add(relation.Contact.AccountId);
        }
        return accountIds;
    }

    @AuraEnabled(cacheable=true)
    public static List<Account> getAccountsByHouseholdId(Id householdId) {
        Set<Id> accountIds = getHouseholdAccountIds(householdId);
        List<Account> accounts = [
            SELECT Id, FinServ__Status__c, OW_terms_of_Business_Status__c, OW_aml_check_account__c, OW_rtq_status__c, Vulnerable_Client__c, TempBankDetailIssues__c
            FROM Account
            WHERE Id 
            IN :accountIds
        ];

        return accounts;

    }

    @AuraEnabled(cacheable=true)
    public static flagWrapper getWrapperFromRecord(Id recordId, String objectName) {
        flagWrapper flags = new flagWrapper();
        switch on objectName {
            when 'Advice__c' {
                Advice__c advice = [SELECT Id, Advice_Household__c FROM Advice__c WHERE Id = :recordId];
                flags.householdId = advice.Advice_Household__c;
            }
            when 'Fulfilment__c'{
                Fulfilment__c fulfilment = [SELECT Id, Household__c FROM Fulfilment__c WHERE Id = :recordId];
                flags.householdId = fulfilment.Household__c;
            }
            when 'Opportunity'{
                Opportunity opp = [SELECT Id, AccountId FROM Opportunity WHERE Id = :recordId];
                flags.householdId = opp.AccountId;
            }
            when 'Case'{
                Case caseRecord = [SELECT Id, AccountId FROM Case WHERE Id = :recordId];
                flags.householdId = caseRecord.AccountId;
            }
            when 'OW_review__c'{
                OW_review__c review = [SELECT Id, OW_household__c FROM OW_review__c WHERE Id = :recordId];
                flags.householdId = review.OW_household__c;
            }
            when 'CustomerFact__c'{
                CustomerFact__c customerFact = [SELECT Id, Household__c FROM CustomerFact__c WHERE Id = :recordId];
                flags.householdId = customerFact.Household__c;
            }
            when 'FinServ__Employment__c'{
                FinServ__Employment__c employment = [SELECT Id, Household__c FROM FinServ__Employment__c WHERE Id = :recordId];
                flags.householdId = employment.Household__c;
            }
            when 'FinServ__FinancialAccount__c'{
                FinServ__FinancialAccount__c finAccount = [SELECT Id, Household__c FROM FinServ__FinancialAccount__c WHERE Id = :recordId];
                flags.householdId = finAccount.Household__c;

            }
            when 'Asset__c'{
                Asset__c asset = [SELECT Id, Household__c FROM Asset__c WHERE Id = :recordId];
                flags.householdId = asset.Household__c;
            }
            when 'BankAccount__c'{
                BankAccount__c bankAccount = [SELECT Id, Household__c FROM BankAccount__c WHERE Id = :recordId];
                flags.householdId = bankAccount.Household__c;
            }
            when 'Fee__c'{
                 Fee__c fee = [SELECT Id, Advice__r.Advice_Household__c FROM Fee__c WHERE Id = :recordId];
                 flags.householdId = fee.Advice__r.Advice_Household__c;
            }
            when 'InformationRequest__c'{
                 InformationRequest__c informationRequest = [SELECT Id, FinancialProductFinServ__r.Household__c FROM InformationRequest__c WHERE Id = :recordId];
                 flags.householdId = informationRequest.FinancialProductFinServ__r.Household__c;
            }
            when 'Liability__c'{
                 Liability__c liability = [SELECT Id, Household__c FROM Liability__c WHERE Id = :recordId];
                 flags.householdId = liability.Household__c;
            }
            when 'OW_rtq__c'{
                 OW_rtq__c rtq = [SELECT Id, OW_household__c FROM OW_rtq__c WHERE Id = :recordId];
                 flags.householdId = rtq.OW_household__c;
            }
            when 'Recommendation__c'{
                 Recommendation__c recommendation = [SELECT Id, Household__c FROM Recommendation__c WHERE Id = :recordId];
                 flags.householdId = recommendation.Household__c;
            }
            when 'AdviceChecklist__c'{
                 AdviceChecklist__c checklist = [SELECT Id, Household__c FROM AdviceChecklist__c WHERE Id = :recordId];
                 flags.householdId = checklist.Household__c;
            }
            when 'Transaction__c'{
                Transaction__c transactionRecord = [SELECT Id, FinancialProduct__r.Household__c FROM Transaction__c WHERE Id = :recordId];
                flags.householdId = transactionRecord.FinancialProduct__r.Household__c;
            }
            when 'Expectation__c'{
                 Expectation__c expectation = [SELECT Id, FinancialProduct__r.Household__c FROM Expectation__c WHERE Id = :recordId];
                 flags.householdId = expectation.FinancialProduct__r.Household__c;
            }
            when 'RegularTransaction__c'{
                 RegularTransaction__c regularTransaction = [SELECT Id, FinancialProduct__r.Household__c FROM RegularTransaction__c WHERE Id = :recordId];
                 flags.householdId = regularTransaction.FinancialProduct__r.Household__c;
            }
            
        }


        return flags;
    }

    public class flagWrapper {
        @AuraEnabled public String householdId;
        @AuraEnabled public Boolean exampleFlagValue;
    }
}
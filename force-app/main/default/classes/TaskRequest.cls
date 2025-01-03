/**
 * @description Used as an Apex variable in flows to gather information needed to request tasks. 
 */
public class TaskRequest {
    @AuraEnabled
    public Id householdId ;
    @AuraEnabled
    public String mode;
    @AuraEnabled
    public Id relatedAdviceId;
    @AuraEnabled
    public Id relatedAmlKycId;
    @AuraEnabled
    public Id relatedAnnualReviewId;
    @AuraEnabled
    public Id relatedLoaId;
    @AuraEnabled
    public Id relatedMortgageApplicationId;
    @AuraEnabled
    public Id relatedOpportunityId;
    @AuraEnabled
    public Id relatedProviderId;
    @AuraEnabled
    public Date targetStartDate;
    @AuraEnabled
    public Date dueDate;
    @AuraEnabled
    public Id originalTaskId;
    @AuraEnabled
    public String taskType;
    @AuraEnabled
    public Id whatId;
    @AuraEnabled
    public Id whoId;
    @AuraEnabled
    public Id RelatedFee;
    @AuraEnabled
    public Id relatedFulfilment ;
    @AuraEnabled
    public Id RelatedInformationRequest;
    @AuraEnabled
    public Id chosenUser ;
}
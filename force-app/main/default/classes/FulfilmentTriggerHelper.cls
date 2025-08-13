public class FulfilmentTriggerHelper {

    public static final String EXPECTATION_TRIGGER_STATUS = 'Submit fulfilment';

    private static final String TARGET_SOURCE_VALUE = 'Source';
    private static final String TARGET_DESTINATION_VALUE = 'Destination';
    private static final String TARGET_BOTH_VALUE = 'Both';
    
    // Constants for magic numbers and hard-coded values
    private static final String FREQUENCY_MONTHLY = 'Monthly';
    private static final String STATUS_PENDING = 'Pending';
    private static final Integer DAY_OFFSET_ADJUSTMENT = -1; // -1 because addDays is 0-indexed
    private static final Integer MONTHS_TO_ADD_FOR_FUTURE_DATE = 1;

    // Use private backing fields for lazy-loaded properties
    private transient Map<String, ExpectationConfiguration__mdt> recommendationTypeToExpectationConfigMap;
    private transient Map<String, ExpectationConfiguration__mdt> nonRegularRecommendationTypeToExpectationConfigMap;
    private transient Map<String, ExpectationConfiguration__mdt> regularRecommendationTypeToExpectationConfigMap;

    // This single getter now efficiently initializes all three maps at once.
    private void initializeConfigMaps() {
        if (this.recommendationTypeToExpectationConfigMap == null) {
            this.recommendationTypeToExpectationConfigMap = new Map<String, ExpectationConfiguration__mdt>();
            this.nonRegularRecommendationTypeToExpectationConfigMap = new Map<String, ExpectationConfiguration__mdt>();
            this.regularRecommendationTypeToExpectationConfigMap = new Map<String, ExpectationConfiguration__mdt>();

            List<ExpectationConfiguration__mdt> expectationConfigurations = [
                SELECT 
                    RecommendationTypeDeveloperName__c, Direction__c, DateOffset__c, 
                    TransactionType__c, Target__c, isRegular__c
                FROM ExpectationConfiguration__mdt
            ];

            for (ExpectationConfiguration__mdt config : expectationConfigurations) {
                this.recommendationTypeToExpectationConfigMap.put(config.RecommendationTypeDeveloperName__c, config);
                if (config.isRegular__c) {
                    this.regularRecommendationTypeToExpectationConfigMap.put(config.RecommendationTypeDeveloperName__c, config);
                } else {
                    this.nonRegularRecommendationTypeToExpectationConfigMap.put(config.RecommendationTypeDeveloperName__c, config);
                }
            }
        }
    }
    
    // Public methods now call the private initializer first
    public Map<String, ExpectationConfiguration__mdt> getRegularConfigs() {
        initializeConfigMaps();
        return this.regularRecommendationTypeToExpectationConfigMap;
    }

    public Map<String, ExpectationConfiguration__mdt> getNonRegularConfigs() {
        initializeConfigMaps();
        return this.nonRegularRecommendationTypeToExpectationConfigMap;
    }

    public Map<Id, Fulfilment__c> getFulfilmentsChangedToSubmitStatus(Map<Id, Fulfilment__c> oldFulfilmentMap, Map<Id, Fulfilment__c> newFulfilmentMap) {
        Map<Id, Fulfilment__c> fulfilmentsSubmitted = new Map<Id, Fulfilment__c>();
        
        if (newFulfilmentMap == null || newFulfilmentMap.isEmpty()) {
            return fulfilmentsSubmitted;
        }
        
        for(Id fulfilmentId : newFulfilmentMap.keySet()) {
            Fulfilment__c newFulfilment = newFulfilmentMap.get(fulfilmentId);
            if (newFulfilment == null) continue;
            
            // Check if old map contains the key to prevent null pointer on inserts
            if(oldFulfilmentMap != null && oldFulfilmentMap.containsKey(fulfilmentId)) {
                Fulfilment__c oldFulfilment = oldFulfilmentMap.get(fulfilmentId);
                if (oldFulfilment != null && 
                    newFulfilment.Status__c == EXPECTATION_TRIGGER_STATUS &&
                    oldFulfilment.Status__c != EXPECTATION_TRIGGER_STATUS) {
                    fulfilmentsSubmitted.put(fulfilmentId, newFulfilment);
                }
            }   
        }
        return fulfilmentsSubmitted;
    }
    
    public void processSubmittedFulfilments(Map<Id, Fulfilment__c> oldFulfilmentMap, Map<Id, Fulfilment__c> newFulfilmentMap) {
        try {
            Map<Id, Fulfilment__c> fulfilmentsSubmitted = getFulfilmentsChangedToSubmitStatus(oldFulfilmentMap, newFulfilmentMap);

            if(!fulfilmentsSubmitted.isEmpty()) {
                Map<Id, Recommendation__c> recommendationMap = getRecommendations(fulfilmentsSubmitted);
                generateExpectationRequests(fulfilmentsSubmitted, recommendationMap);
                generateRegularTransactionRequests(fulfilmentsSubmitted, recommendationMap);   
            }
        } catch (Exception e) {
            // Log the error and re-throw to maintain existing behaviour
            System.debug(LoggingLevel.ERROR, 'Error processing submitted fulfilments: ' + e.getMessage());
            throw e;
        }
    }

    public Map<Id, Recommendation__c> getRecommendations(Map<Id, Fulfilment__c> fulfilmentsSubmitted) {
        if (fulfilmentsSubmitted == null || fulfilmentsSubmitted.isEmpty()) {
            return new Map<Id, Recommendation__c>();
        }
        
        Set<Id> recommendationIds = new Set<Id>();
        for(Fulfilment__c fulfilment : fulfilmentsSubmitted.values()) {
            if (fulfilment != null && fulfilment.Recommendation__c != null) {
                recommendationIds.add(fulfilment.Recommendation__c);
            }
        }

        if (recommendationIds.isEmpty()) {
            return new Map<Id, Recommendation__c>();
        }

        return new Map<Id, Recommendation__c>([
            SELECT Id, DestinationLegacy__c, DestinationLegacy__r.OW_own_product__c, DestinationLegacy__r.FinancialProductType__r.RegularDay__c,
                   SourceLegacy__c, SourceLegacy__r.OW_own_product__c, SourceLegacy__r.FinancialProductType__r.RegularDay__c, Amount__c, 
                   RecommendationType__r.DeveloperName__c 
            FROM Recommendation__c
            WHERE Id IN :recommendationIds
        ]);
    }

    public void generateExpectationRequests(Map<Id, Fulfilment__c> fulfilmentsSubmitted, Map<Id, Recommendation__c> recommendationMap) {
        if (fulfilmentsSubmitted == null || fulfilmentsSubmitted.isEmpty() || recommendationMap == null) {
            return;
        }
        
        List<ExpectationRequest> requests = new List<ExpectationRequest>();
        Map<String, ExpectationConfiguration__mdt> configs = getNonRegularConfigs();

        for(Fulfilment__c fulfilment : fulfilmentsSubmitted.values()) {
            if (fulfilment == null || fulfilment.Recommendation__c == null) continue;
            
            Recommendation__c recommendation = recommendationMap.get(fulfilment.Recommendation__c);
            if (recommendation == null) continue; // Skip if no matching recommendation

            String recTypeDevName = recommendation.RecommendationType__r?.DeveloperName__c;
            if(String.isBlank(recTypeDevName) || !configs.containsKey(recTypeDevName)) continue;
            
            if(recommendation.DestinationLegacy__r?.OW_own_product__c == true || recommendation.SourceLegacy__r?.OW_own_product__c == true){
                ExpectationConfiguration__mdt expectationConfig = configs.get(recTypeDevName);
                
                ExpectationRequest expectationRequest = new ExpectationRequest();
                expectationRequest.fulfilmentId = fulfilment.Id;
                expectationRequest.direction = expectationConfig.Direction__c;
                
                // Safe casting with null check
                Integer dateOffset = expectationConfig.DateOffset__c != null ? 
                    (Integer)expectationConfig.DateOffset__c : 0;
                expectationRequest.expectationDate = Date.today().addDays(dateOffset);
                
                // Safe handling of amount
                expectationRequest.amount = recommendation.Amount__c != null ? recommendation.Amount__c : 0;
                expectationRequest.transactionType = expectationConfig.TransactionType__c;

                if(expectationConfig.Target__c == TARGET_SOURCE_VALUE) {
                    expectationRequest.productId = recommendation.SourceLegacy__c;
                } else if(expectationConfig.Target__c == TARGET_DESTINATION_VALUE) {
                    expectationRequest.productId = recommendation.DestinationLegacy__c;
                } else if(expectationConfig.Target__c == TARGET_BOTH_VALUE) {
                    expectationRequest.direction = ExpectationHelper.DIRECTION_WITHDRAWAL;
                    expectationRequest.productId = recommendation.SourceLegacy__c;

                    ExpectationRequest expectationRequest2 = expectationRequest.clone();
                    expectationRequest2.productId = recommendation.DestinationLegacy__c;
                    expectationRequest2.direction = ExpectationHelper.DIRECTION_CONTRIBUTION;
                    requests.add(expectationRequest2);
                }
                requests.add(expectationRequest);
            }
        }

        if(!requests.isEmpty()){
            ExpectationHelper.createExpectations(requests);
        }
    }

    public void generateRegularTransactionRequests(Map<Id, Fulfilment__c> fulfilmentsSubmitted, Map<Id, Recommendation__c> recommendationMap){
        if (fulfilmentsSubmitted == null || fulfilmentsSubmitted.isEmpty() || recommendationMap == null) {
            return;
        }
        
        List<RegularTransactionRequest> requests = new List<RegularTransactionRequest>();
        Map<String, ExpectationConfiguration__mdt> configs = getRegularConfigs();

        for(Fulfilment__c fulfilment : fulfilmentsSubmitted.values()){
            if (fulfilment == null || fulfilment.Recommendation__c == null) continue;
            
            Recommendation__c recommendation = recommendationMap.get(fulfilment.Recommendation__c);
            if(recommendation == null) continue;

            String recTypeDevName = recommendation.RecommendationType__r?.DeveloperName__c;
            if(String.isBlank(recTypeDevName) || !configs.containsKey(recTypeDevName)) continue;
            
            ExpectationConfiguration__mdt expectationConfig = configs.get(recTypeDevName);
            
            RegularTransactionRequest request = new RegularTransactionRequest();
            // Safe handling of amount
            request.amount = recommendation.Amount__c != null ? recommendation.Amount__c : 0;
            request.frequency = FREQUENCY_MONTHLY; //only monthly for now
            request.status = STATUS_PENDING;
            request.direction = expectationConfig.Direction__c;
            request.startDate = Date.today();

            if(expectationConfig.Target__c == TARGET_SOURCE_VALUE) {
                request.productId = recommendation.SourceLegacy__c;
                // Safe handling of RegularDay__c with null check
                Integer regularDay = recommendation.SourceLegacy__r?.FinancialProductType__r?.RegularDay__c != null ? 
                    (Integer)recommendation.SourceLegacy__r.FinancialProductType__r.RegularDay__c : 1;
                request.startDate = Date.today().toStartOfMonth().addDays(regularDay + DAY_OFFSET_ADJUSTMENT);
            } else if(expectationConfig.Target__c == TARGET_DESTINATION_VALUE) {
                request.productId = recommendation.DestinationLegacy__c;
                // Safe handling of RegularDay__c with null check
                Integer regularDay = recommendation.DestinationLegacy__r?.FinancialProductType__r?.RegularDay__c != null ? 
                    (Integer)recommendation.DestinationLegacy__r.FinancialProductType__r.RegularDay__c : 1;
                request.startDate = Date.today().toStartOfMonth().addDays(regularDay + DAY_OFFSET_ADJUSTMENT);
            } else if(expectationConfig.Target__c == TARGET_BOTH_VALUE) {
                request.productId = recommendation.SourceLegacy__c;
                request.direction = ExpectationHelper.DIRECTION_WITHDRAWAL;
                // Safe handling of RegularDay__c with null check
                Integer sourceRegularDay = recommendation.SourceLegacy__r?.FinancialProductType__r?.RegularDay__c != null ? 
                    (Integer)recommendation.SourceLegacy__r.FinancialProductType__r.RegularDay__c : 1;
                request.startDate = Date.today().toStartOfMonth().addDays(sourceRegularDay + DAY_OFFSET_ADJUSTMENT); 
                
                RegularTransactionRequest request2 = request.clone();
                request2.productId = recommendation.DestinationLegacy__c;
                request2.direction = ExpectationHelper.DIRECTION_CONTRIBUTION;
                // Safe handling of RegularDay__c with null check
                Integer destRegularDay = recommendation.DestinationLegacy__r?.FinancialProductType__r?.RegularDay__c != null ? 
                    (Integer)recommendation.DestinationLegacy__r.FinancialProductType__r.RegularDay__c : 1;
                request2.startDate = Date.today().toStartOfMonth().addDays(destRegularDay + DAY_OFFSET_ADJUSTMENT);

                if(request2.frequency == FREQUENCY_MONTHLY){
                    if(request2.startDate <= Date.today()){
                        request2.startDate = request.startDate.addMonths(MONTHS_TO_ADD_FOR_FUTURE_DATE);
                    }
                }

                request2.nextTransactionDate = request2.startDate;
                requests.add(request2);
            }
            
            if(request.frequency == FREQUENCY_MONTHLY){
                if(request.startDate <= Date.today()){
                    request.startDate = request.startDate.addMonths(MONTHS_TO_ADD_FOR_FUTURE_DATE);
                }
            }

            request.nextTransactionDate = request.startDate;
            requests.add(request);
        }

        if(!requests.isEmpty()){
            RegularTransactionHelper.generateRegularTransactions(requests);
        }
    }
}
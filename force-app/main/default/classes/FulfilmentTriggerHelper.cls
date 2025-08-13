public class FulfilmentTriggerHelper {
    // Class to collect the fulfilment details from those in the trigger, construct email requests and pass them to the email send class for sending
    public void sendNotices(Map<Id, SObject> fulfilmentsNewMap, Map<Id, SObject> fulfilmentsOldMap) {

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
        
        List<Fulfilment__c> fulfilments = [
            SELECT
                Id, 
                Household__c,
                Recommendation__c,
                Recommendation__r.Household__c,
                Recommendation__r.PrimaryOwner__r.PersonContactId, 
                Recommendation__r.Product__r.Name,
                Recommendation__r.RegisteredContact__c,
                Recommendation__r.RegisteredContact__r.PersonContactId,
                Recommendation__r.PrimaryOwner__r.AddressedName__pc,
                Recommendation__r.RegisteredContact__r.AddressedName__pc,
                Recommendation__r.Product__r.DeveloperName__c,
                Recommendation__r.RecommendationType__r.DeveloperName__c,
                Recommendation__r.TransferType__c,
                Recommendation__r.SourceLegacy__r.Public_Provider_Name__r.Name,
                Recommendation__r.DestinationLegacy__r.Public_Provider_Name__r.Name,
                Recommendation__r.DestinationLegacy__r.RecordType.DeveloperName,
                ResidualCash__c,
                Status__c,
                CancellationNoticeSent__c
            FROM
                Fulfilment__c
            WHERE
                ((Recommendation__r.RecommendationType__r.DeveloperName__c = 'OPEN_PRODUCT' AND Recommendation__r.Product__r.DeveloperName__c IN ('SIPP_HUBWISE', 'JSIPP_HUBWISE') AND Status__c = 'Complete' ) OR 
                (Recommendation__r.RecommendationType__r.DeveloperName__c = 'EXTERNAL_TRANSFER_IN' AND Recommendation__r.DestinationLegacy__r.RecordType.DeveloperName IN ('Junior_SIPP', 'FP_SIPP') AND PaymentStatus__c = 'Funds received'))
                AND Id IN :fulfilmentsNewMap.keySet()
            	AND CancellationNoticeSent__c = false
            ];
        if (newFulfilmentMap == null || newFulfilmentMap.isEmpty()) {
            return fulfilmentsSubmitted;
        }
        
        List<Fulfilment__c> fulfilmentsRequiringNotice = new List<Fulfilment__c>();
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
        
        for( Fulfilment__c fulfilment : fulfilments ) {
            Fulfilment__c fulfilmentOld = (Fulfilment__c) fulfilmentsOldMap.get(fulfilment.Id);
            if( fulfilmentOld.CancellationNoticeSent__c == false && ((fulfilmentOld.Status__c == 'Chase transfer' && fulfilment.Status__c == 'Investment checks'&& fulfilment.Recommendation__r.RecommendationType__r.DeveloperName__c == 'EXTERNAL_TRANSFER_IN')||(fulfilment.Recommendation__r.RecommendationType__r.DeveloperName__c == 'OPEN_PRODUCT'))) {
                fulfilmentsRequiringNotice.add(fulfilment);
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
        
        if( fulfilmentsRequiringNotice.size() > 0 ) {
            // Create a list of email requests for these fulfilments
            List<EmailSend.EmailSendRequestAutomatic> emailRequests = new List<EmailSend.EmailSendRequestAutomatic>();
        List<ExpectationRequest> requests = new List<ExpectationRequest>();
        Map<String, ExpectationConfiguration__mdt> configs = getNonRegularConfigs();

        for(Fulfilment__c fulfilment : fulfilmentsSubmitted.values()) {
            if (fulfilment == null || fulfilment.Recommendation__c == null) continue;
            
            for (Fulfilment__c fulfilment : fulfilmentsRequiringNotice) {
                emailRequests.add(constructEmailRequest(fulfilment));
                fulfilment.CancellationNoticeSent__c = true;
            }  
            Recommendation__c recommendation = recommendationMap.get(fulfilment.Recommendation__c);
            if (recommendation == null) continue; // Skip if no matching recommendation

            String recTypeDevName = recommendation.RecommendationType__r?.DeveloperName__c;
            if(String.isBlank(recTypeDevName) || !configs.containsKey(recTypeDevName)) continue;
            
            // Send the emails
            EmailSend emailSender = new EmailSend();
            emailSender.sendAutomaticTemplatedEmailCustomSubject(emailRequests);
            update fulfilmentsRequiringNotice;
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
        
    }
    
    // Method to take a piece of fulfilment and create an email request of the correct type with the correct parameters
    public static EmailSend.EmailSendRequestAutomatic constructEmailRequest(Fulfilment__c fulfilment) {
        EmailSend.EmailSendRequestAutomatic emailRequest = new EmailSend.EmailSendRequestAutomatic();
        emailRequest.householdId = fulfilment.Recommendation__r.Household__c;
        emailRequest.whatId = fulfilment.Id;
        emailRequest.saveAsActivity = true;
        if( fulfilment.Recommendation__r.RecommendationType__r.DeveloperName__c == 'EXTERNAL_TRANSFER_IN') {
			emailRequest.emailTemplateDeveloperName = 'CancellationNoticeTransfer';            
            emailRequest.parameters = EmailCancellationNoticeTransfer.getParameters(fulfilment);
        } else {
            emailRequest.emailTemplateDeveloperName = 'CancellationNoticeNewProduct'; 
            emailRequest.parameters = EmailCancellationNoticeNewProduct.getParameters(fulfilment);
            emailRequest.subject = EmailCancellationNoticeNewProduct.getSubject(fulfilment);
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
        emailRequest.targetObjectId = getContactId(fulfilment);
        return emailRequest; 
    }
    
    // Get correct contact for this email
    public static String getContactId(Fulfilment__c fulfilment) {
        if( fulfilment.Recommendation__r.Product__r.DeveloperName__c == 'SIPP_HUBWISE' ) {
            return fulfilment.Recommendation__r.PrimaryOwner__r.PersonContactId;
        } else {
            return fulfilment.Recommendation__r.RegisteredContact__r.PersonContactId;
        }
    }  
}
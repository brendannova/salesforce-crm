public class FulfilmentTriggerHelper {
    
    public void sendAutomaticNotices(List<Fulfilment__c> fulfilments) {
        List<String> fulfilmentIds = new List<String>();
        for (Fulfilment__c fulfilment : fulfilments) {
            fulfilmentIds.add(fulfilment.Id);
        }
        
        List<Fulfilment__c> fulfilmentsForNotice = [SELECT 
                                                    Id, 
                                                    Household__c,
                                                    Recommendation__r.Household__c,
                                                    Recommendation__r.PrimaryOwner__r.PersonContactId, 
                                                    Recommendation__r.Product__r.Name,
                                                    Recommendation__r.RegisteredContact__c,
                                                    Recommendation__r.RegisteredContact__r.PersonContactId,
                                                    Recommendation__r.PrimaryOwner__r.AddressedName__pc,
                                                    Recommendation__r.Product__r.ReferenceName__c,
                                                    Recommendation__r.RecommendationType__r.ReferenceName__c,
                                                    ResidualCash__c
                                                    FROM Fulfilment__c
                                                    WHERE 
                                                    (
                                                        (Recommendation__r.RecommendationType__r.ReferenceName__c = 'OPEN_PRODUCT'
                                                         AND
                                                         Recommendation__r.Product__r.ReferenceName__c IN ('SIPP_HUBWISE', 'JSIPP_HUBWISE')
                                                         AND Status__c = 'Complete' 
                                                        ) 
                                                        OR 
                                                        (Recommendation__r.RecommendationType__r.ReferenceName__c = 'EXTERNAL_TRANSFER_IN'
                                                         AND
                                                         Recommendation__r.Product__r.ReferenceName__c IN ('SIPP_HUBWISE', 'JSIPP_HUBWISE')
                                                         AND PaymentStatus__c = 'Funds received'  
                                                        )
                                                    )
                                                    AND Id IN :fulfilmentIds
                                                   ];
        if( fulfilmentsForNotice.size() > 0 ) {
            // Create a list of email requests for these fulfilments
            List<EmailSend.EmailSendRequestAutomatic> emails = new List<EmailSend.EmailSendRequestAutomatic>();
            
            for (Fulfilment__c fulfilment : fulfilmentsForNotice) {
                emails.add(setEmailRequestVariables(fulfilment));
            }  
            
            // Send the emails
            EmailSend emailSender = new EmailSend();
            emailSender.sendAutomaticTemplatedEmailCustomSubject(emails);
        }
        
    }
    
    public static EmailSend.EmailSendRequestAutomatic setEmailRequestVariables(Fulfilment__c fulfilment) {
        EmailSend.EmailSendRequestAutomatic emailRequest = new EmailSend.EmailSendRequestAutomatic();
        
        if( fulfilment.Recommendation__r.RecommendationType__r.ReferenceName__c == 'EXTERNAL_TRANSFER_IN') {
			emailRequest.emailTemplateDeveloperName = 'PensionTransferCompleteAutomated';            
        } else if( fulfilment.Recommendation__r.Product__r.ReferenceName__c == 'JSIPP_HUBWISE' ) {
            emailRequest.emailTemplateDeveloperName = 'CancellationNoticeJunior';    
        } else {
            emailRequest.emailTemplateDeveloperName = 'CancellationNotice'; 
        }
        
        emailRequest.targetObjectId = getContactId(fulfilment);
        emailRequest.householdId = fulfilment.Recommendation__r.Household__c;
        emailRequest.whatId = fulfilment.Id;
        emailRequest.saveAsActivity = true;
        
        return emailRequest; 
    }
    
    // Get correct contact for this email
    public static String getContactId(Fulfilment__c fulfilment) {
        if( fulfilment.Recommendation__r.RegisteredContact__c == null ) {
            return fulfilment.Recommendation__r.PrimaryOwner__r.PersonContactId;
        } else {
            return fulfilment.Recommendation__r.RegisteredContact__r.PersonContactId;
        }
    }  
}
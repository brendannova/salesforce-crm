public class FulfilmentTriggerHelper {
    
    public void sendAutomaticNotices(Map<Id, sObject> fulfilmentsNew, Map<Id, sObject> fulfilmentsOld) {
        
        List<Fulfilment__c> potentialFulfilmentsForNotice = [SELECT 
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
                                                    ResidualCash__c,
                                                    Status__c,
                                                    CancellationNoticeSent__c
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
                                                    AND Id IN :fulfilmentsNew.keySet()
                                                   ];
        
        List<Fulfilment__c> fulfilmentsForNotice = new List<Fulfilment__c>();
        
        for( Fulfilment__c flfl : potentialFulfilmentsForNotice ) {
            Fulfilment__c oldflfl = (Fulfilment__c)fulfilmentsOld.get(flfl.Id);
            if( oldflfl.Status__c == 'Chase transfer' 
                && flfl.Status__c == 'Investment checks'
                && oldflfl.CancellationNoticeSent__c == false ) {
                   fulfilmentsForNotice.add(flfl);
               } 
            
        }
        
        if( fulfilmentsForNotice.size() > 0 ) {
            // Create a list of email requests for these fulfilments
            List<EmailSend.EmailSendRequestAutomatic> emails = new List<EmailSend.EmailSendRequestAutomatic>();
            
            for (Fulfilment__c fulfilment : fulfilmentsForNotice) {
                emails.add(setEmailRequestVariables(fulfilment));
                fulfilment.CancellationNoticeSent__c = true;
            }  
            
            // Send the emails
            EmailSend emailSender = new EmailSend();
            emailSender.sendAutomaticTemplatedEmailCustomSubject(emails);
            update fulfilmentsForNotice;
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
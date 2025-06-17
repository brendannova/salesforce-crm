public class FulfilmentTriggerHelper {
    
    public void sendCancellationNotices(List<Fulfilment__c> fulfilments) {
        // Get recommendation details for the fulfilments sent in the trigger
        List<Fulfilment__c> fulfilmentsForNotice = getCancellationFulfilments(fulfilments);
        for(Fulfilment__c flfl : fulfilmentsForNotice) {
        	System.debug(flfl);
    	}
        
        // Create a list of email requests for these fulfilments
        List<EmailSend.EmailSendRequestAutomatic> emails = new List<EmailSend.EmailSendRequestAutomatic>();
        
        for (Fulfilment__c fulfilment : fulfilmentsForNotice) {
            emails.add(createCancellationNoticeRequest(fulfilment));
        }  
        
        System.debug(emails);
        // Send the emails
        EmailSend emailSender = new EmailSend();
        emailSender.sendAutomaticTemplatedEmail(emails);
    }
    
    public void sendTransferCompleteEmails(List<Fulfilment__c> fulfilments) {
        // Get recommendation details for the fulfilments sent in the trigger
        List<Fulfilment__c> fulfilmentsForNotice = getTransferFulfilments(fulfilments);
        for(Fulfilment__c flfl : fulfilmentsForNotice) {
        	System.debug(flfl);
    	}
        
        // Create a list of email requests for these fulfilments
        List<EmailSend.EmailSendRequestAutomatic> emails = new List<EmailSend.EmailSendRequestAutomatic>();
        
        for (Fulfilment__c fulfilment : fulfilmentsForNotice) {
            emails.add(createTransferCompleteRequest(fulfilment));
        }  
        
        System.debug(emails);
        // Send the emails
        EmailSend emailSender = new EmailSend();
        emailSender.sendAutomaticTemplatedEmail(emails);
        
    }
    
    // Create a cancellation notice email request for this specific piece of fulfilment
    public static EmailSend.EmailSendRequestAutomatic createCancellationNoticeRequest(Fulfilment__c fulfilment) {
        EmailSend.EmailSendRequestAutomatic emailRequest = new EmailSend.EmailSendRequestAutomatic();
        emailRequest.emailTemplateDeveloperName = 'CancellationNotice';         
        emailRequest.targetObjectId = getContactId(fulfilment);
        emailRequest.householdId = fulfilment.Recommendation__r.Household__c;
        emailRequest.whatId = fulfilment.Id;
        emailRequest.saveAsActivity = true;
        
        System.debug(emailRequest);
        return emailRequest;
    }
    

    // Create a transfer complete email request for this specific piece of fulfilment
    public static EmailSend.EmailSendRequestAutomatic createTransferCompleteRequest(Fulfilment__c fulfilment) {
        EmailSend.EmailSendRequestAutomatic emailRequest = new EmailSend.EmailSendRequestAutomatic();
        emailRequest.emailTemplateDeveloperName = 'PensionTransferCompleteAutomated';         
        emailRequest.targetObjectId = getContactId(fulfilment);
        emailRequest.householdId = fulfilment.Recommendation__r.Household__c;
        emailRequest.whatId = fulfilment.Id;
        emailRequest.saveAsActivity = true;
        
        System.debug(emailRequest);
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
    
    // Get recommendation details and filter fulfilments
    public static List<Fulfilment__c> getCancellationFulfilments(List<Fulfilment__c> fulfilments) {
        // Get fulfilment ids
        List<String> fulfilmentIds = new List<String>();
        for (Fulfilment__c fulfilment : fulfilments) {
            fulfilmentIds.add(fulfilment.Id);
        }
        
        List<Fulfilment__c> results = [SELECT 
                                       Id, 
                                       Household__c,
                                       Recommendation__r.Household__c,
                                       Recommendation__r.PrimaryOwner__r.PersonContactId, 
                                       Recommendation__r.Product__r.Name,
                                       Recommendation__r.RegisteredContact__r.PersonContactId,
                                       Recommendation__r.PrimaryOwner__r.AddressedName__pc
                                       FROM Fulfilment__c
                                       WHERE 
                                       Recommendation__r.RecommendationType__r.ReferenceName__c = 'OPEN_PRODUCT'
                                       AND
                                       Recommendation__r.Product__r.ReferenceName__c IN ('SIPP_HUBWISE', 'JSIPP_HUBWISE')
                                       AND Status__c = 'Complete'
                                       AND Id IN :fulfilmentIds
                                      ];

        return results;
    }
    
    // Get recommendation details and filter fulfilments
    public static List<Fulfilment__c> getTransferFulfilments(List<Fulfilment__c> fulfilments) {
        // Get fulfilment ids
        List<String> fulfilmentIds = new List<String>();
        for (Fulfilment__c fulfilment : fulfilments) {
            fulfilmentIds.add(fulfilment.Id);
        }
        
        List<Fulfilment__c> results = [SELECT 
                                       Id, 
                                       Household__c,
                                       Recommendation__r.Household__c,
                                       Recommendation__r.PrimaryOwner__r.PersonContactId, 
                                       Recommendation__r.Product__r.Name 
                                       FROM Fulfilment__c
                                       WHERE 
                                       Recommendation__r.RecommendationType__r.ReferenceName__c = 'EXTERNAL_TRANSFER_IN'
                                       AND
                                       Recommendation__r.Product__r.ReferenceName__c IN ('SIPP_HUBWISE', 'JSIPP_HUBWISE')
                                       AND PaymentStatus__c = 'Funds received'
                                       AND Id IN :fulfilmentIds
                                      ];

        return results;
    }
}
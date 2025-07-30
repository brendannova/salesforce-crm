public class FulfilmentTriggerHelper {
    // Class to collect the fulfilment details from those in the trigger, construct email requests and pass them to the email send class for sending
    public void sendNotices(Map<Id, SObject> fulfilmentsNewMap, Map<Id, SObject> fulfilmentsOldMap) {
        
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
                Recommendation__r.DestinationLegacy__r.RecordType,
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
        
        List<Fulfilment__c> fulfilmentsRequiringNotice = new List<Fulfilment__c>();
        
        for( Fulfilment__c fulfilment : fulfilments ) {
            Fulfilment__c fulfilmentOld = (Fulfilment__c) fulfilmentsOldMap.get(fulfilment.Id);
            if( fulfilmentOld.CancellationNoticeSent__c == false && ((fulfilmentOld.Status__c == 'Chase transfer' && fulfilment.Status__c == 'Investment checks'&& fulfilment.Recommendation__r.RecommendationType__r.DeveloperName__c == 'EXTERNAL_TRANSFER_IN')||(fulfilment.Recommendation__r.RecommendationType__r.DeveloperName__c == 'OPEN_PRODUCT'))) {
                fulfilmentsRequiringNotice.add(fulfilment);
            } 
        }
        
        if( fulfilmentsRequiringNotice.size() > 0 ) {
            // Create a list of email requests for these fulfilments
            List<EmailSend.EmailSendRequestAutomatic> emailRequests = new List<EmailSend.EmailSendRequestAutomatic>();
            
            for (Fulfilment__c fulfilment : fulfilmentsRequiringNotice) {
                emailRequests.add(constructEmailRequest(fulfilment));
                fulfilment.CancellationNoticeSent__c = true;
            }  
            
            // Send the emails
            EmailSend emailSender = new EmailSend();
            emailSender.sendAutomaticTemplatedEmailCustomSubject(emailRequests);
            update fulfilmentsRequiringNotice;
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
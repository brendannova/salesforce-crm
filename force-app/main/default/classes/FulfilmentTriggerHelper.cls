public class FulfilmentTriggerHelper {
    
    // Change type to Fulfilment__c from SObject
    public void sendNotices(Map<Id, SObject> fulfilmentsNewMap, Map<Id, SObject> fulfilmentsOldMap) {
        
        // Tidied presentation of this
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
                Recommendation__r.Product__r.ReferenceName__c,
                Recommendation__r.RecommendationType__r.ReferenceName__c,
                Recommendation__r.TransferType__c,
                Recommendation__r.SourceLegacy__r.Public_Provider_Name__r.Name,
                Recommendation__r.DestinationLegacy__r.Public_Provider_Name__r.Name,
                ResidualCash__c,
                Status__c,
                CancellationNoticeSent__c
            FROM
                Fulfilment__c
            WHERE
                ((Recommendation__r.RecommendationType__r.ReferenceName__c = 'OPEN_PRODUCT' AND Recommendation__r.Product__r.ReferenceName__c IN ('SIPP_HUBWISE', 'JSIPP_HUBWISE') AND Status__c = 'Complete' ) OR 
                (Recommendation__r.RecommendationType__r.ReferenceName__c = 'EXTERNAL_TRANSFER_IN' AND Recommendation__r.DestinationLegacy__r.RecordType.DeveloperName = 'FP_SIPP' AND PaymentStatus__c = 'Funds received'))
                AND Id IN :fulfilmentsNewMap.keySet()
            ];
        
        List<Fulfilment__c> fulfilmentsRequiringNotice = new List<Fulfilment__c>();
        
        for( Fulfilment__c fulfilment : fulfilments ) {
            Fulfilment__c fulfilmentOld = (Fulfilment__c) fulfilmentsOldMap.get(fulfilment.Id);
            //To do - the logic here needs improving
            if( fulfilmentOld.CancellationNoticeSent__c == false ) {
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
    
    public static EmailSend.EmailSendRequestAutomatic constructEmailRequest(Fulfilment__c fulfilment) {
        EmailSend.EmailSendRequestAutomatic emailRequest = new EmailSend.EmailSendRequestAutomatic();
        emailRequest.householdId = fulfilment.Recommendation__r.Household__c;
        emailRequest.whatId = fulfilment.Id;
        emailRequest.saveAsActivity = true;
        if( fulfilment.Recommendation__r.RecommendationType__r.ReferenceName__c == 'EXTERNAL_TRANSFER_IN') {
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
        if( fulfilment.Recommendation__r.RegisteredContact__c == null ) {
            return fulfilment.Recommendation__r.PrimaryOwner__r.PersonContactId;
        } else {
            return fulfilment.Recommendation__r.RegisteredContact__r.PersonContactId;
        }
    }  
}
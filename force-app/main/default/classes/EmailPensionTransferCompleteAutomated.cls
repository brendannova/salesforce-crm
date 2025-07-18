/**
 * This class is the controller for a SIPP/JSIPP transfer cancellation notice email template. 
 * It exists only to produce the content for this email and should be used for no other purpose. 
 */
public class EmailPensionTransferCompleteAutomated {

    public String objectId{get;set;}
    private Fulfilment__c fulfilment = new Fulfilment__c();
    Boolean constructorRun = false;
    
    // Constructor to set the fulfilment record
    public void EmailPensionTransferCompleteAutomated() {
        if(!constructorRun){
            constructorRun = true;
            if(String.isBlank(objectId)){
                objectId = ApexPages.currentPage().getParameters().get('objectId');
            }
            if (String.isNotBlank(objectId)) {
                fulfilment = [
                    SELECT 
                        Id, 
                        Recommendation__c,
                        Recommendation__r.PrimaryOwner__r.AddressedName__pc,
                        Recommendation__r.RegisteredContact__c,
                        Recommendation__r.RegisteredContact__r.AddressedName__pc,
                        Recommendation__r.Product__r.Name,
                        ResidualCash__c,
                        Recommendation__r.SourceLegacy__r.Public_Provider_Name__r.Name,
                        Recommendation__r.DestinationLegacy__r.Public_Provider_Name__r.Name,
                        Recommendation__r.TransferType__c
                    FROM
                        Fulfilment__c 
                    WHERE
                        Id = :objectId
                ];
            }
        }
    }
    
    // Method to format today's date into a client friendly format
    public String dateString {
        get {
            UtilityString us = new UtilityString();
            return us.formatDateForNovaEmail(Datetime.now());
        }
    }
    
    // Determines if there is residual cash or not, allowing the associate passage of text to be hidden/shown as appopriate.
    public Boolean residualCash {
        get{
            if (fulfilment.ResidualCash__c == 'NONE') {
                return false;
            } else {
                return true;
            }
        }
    }

    // Method to provide the friendly name of the destination
    public String finProdNameDestination{
        get{
            String result = '';
            if( fulfilment.Recommendation__r.RegisteredContact__c == null ) {
                result = result + 'your ';
            } else {
                result = result + fulfilment.Recommendation__r.PrimaryOwner__r.AddressedName__pc + '\'s ';
            }
            result = result 
                + fulfilment.Recommendation__r.DestinationLegacy__r.Public_Provider_Name__r.Name 
                + ' ' 
                + fulfilment.Recommendation__r.Product__r.Name;
            return result;
        }
    }
    
    // Method to provide the friendly name of the source
    public String finProdNameSource{
        get{
            String result = '';
            if( fulfilment.Recommendation__r.RegisteredContact__c == null ) {
                result = result + 'your ';
            } else {
                result = result + fulfilment.Recommendation__r.PrimaryOwner__r.AddressedName__pc + '\'s ';
            }
            result = result 
                + fulfilment.Recommendation__r.SourceLegacy__r.Public_Provider_Name__r.Name 
                + ' pension';
            return result;
        }
    }
    
    // Method to provide string for a partial transfer if required
    public String partialString{
        get{
            EmailPensionTransferCompleteAutomated();
            if (fulfilment.recommendation__r.TransferType__c == 'Partial') {
                return ' partial ';
            } else {
                return '';
            }
        }
    }
}
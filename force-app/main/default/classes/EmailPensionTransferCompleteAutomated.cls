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
                fulfilment = [SELECT 
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
                              FROM Fulfilment__c 
                              WHERE Id = :objectId
                             ];
            }
        }
    }
    
    // Method to format today's date into client friendly format
    public String getDateString() {
        UtilityString us = new UtilityString();
        return us.formatDateForNovaEmail(Datetime.now());
    }
    
    // Method to provide string for residual cash if required
    public String getResidualCash() {
        if (fulfilment.ResidualCash__c == 'None') {
            return '';
        } else {
            return 'There is residual cash remaining with the ceding provider, which we expect will transfer in the future. We will update your portal once this is received.';
        }
    }

    // Method to provide the friendly name of the destination
    public String getFinProdNameDestination(){
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
    
    // Method to provide the friendly name of the source
    public String getFinProdNameSource(){
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
    
    // Method to provide string for a partial transfer if required
    public String getPartialString() {
        EmailPensionTransferCompleteAutomated();
        if (fulfilment.recommendation__r.TransferType__c == 'Partial') {
            return ' partial ';
        } else {
			return '';
        }
    }
}
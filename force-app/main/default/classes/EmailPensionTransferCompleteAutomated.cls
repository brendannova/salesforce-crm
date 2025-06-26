public class EmailPensionTransferCompleteAutomated {
    public String objectId{get;set;}
    private Fulfilment__c fulfilment = new Fulfilment__c();
    Boolean constructorRun = false;
    
    public void EmailPensionTransferCompleteAutomated() {
        if(!constructorRun){
            constructorRun = true;
            System.debug('in constructor');
            if(String.isBlank(objectId)){
                objectId = ApexPages.currentPage().getParameters().get('objectId');
            }
            if (String.isNotBlank(objectId)) {
                // Get household status and set active flag
                fulfilment = [SELECT 
                              Id, 
                              Recommendation__c,
                              Recommendation__r.PrimaryOwner__r.AddressedName__pc,
                              Recommendation__r.RegisteredContact__c,
                              Recommendation__r.RegisteredContact__r.AddressedName__pc,
                              Recommendation__r.Product__r.Name,
                              Recommendation__r.DestinationLegacy__r.Public_Provider_Name__r.Name,
                              Recommendation__r.TransferType__c
                              FROM Fulfilment__c 
                              WHERE Id = :objectId
                             ];
            }
        }
    }
    
    public String getDateString() {
        return Datetime.newInstance(Date.today().year(),Date.today().month(),Date.today().day()).format('MMMMMMMMMMM dd, yyyy') + ' ';
    }
             
    public String getIntroString() {
        EmailPensionTransferCompleteAutomated();
        System.debug('introstring ' + fulfilment);
        String result = System.Label.EmailPensionTransferCompletePart1 + partialString()
            			+ ' ' + System.Label.EmailPensionTransferCompletePart2
            			+ ' ' + finProdName()
            			+ ' ' + System.Label.EmailPensionTransferCompletePart3 
            			+ ' ' + fulfilment.Recommendation__r.Product__r.Name + '.';
        return result;
    }
    
    public String partialString(){
        if( fulfilment.Recommendation__r.TransferType__c == 'Partial') {
            return ' partial';
        }
        return '';
    }
    
    public String finProdName(){
        String result = '';
        System.debug('reg contact' + fulfilment.Recommendation__r.RegisteredContact__c);
        if( fulfilment.Recommendation__r.RegisteredContact__c == null ) {
            result = result + ' your ';
        } else {
            result = result + fulfilment.Recommendation__r.RegisteredContact__r.AddressedName__pc + '\'s ';
        }
        result = result + fulfilment.Recommendation__r.DestinationLegacy__r.Public_Provider_Name__r.Name + ' pension';
        return result;
    }
    
    public String getSecondLine() {
        String result = System.Label.EmailPensionTransferCompletePart4;
        return result;
    }
    
    public String getPartialLine() {
        if (fulfilment.ResidualCash__c != 'None') {
            return '';
        } else {
            return System.Label.EmailPensionTransferCompletePart5;
        }
    }
    
    public String getCancellationSummary() {
        String result = System.Label.EmailPensionTransferCompletePart6;
        return result;
    }
    
    public String getCancellationParagraph1() {
        String result = System.Label.EmailPensionTransferCancellationPart1
            			+ fulfilment.Recommendation__r.DestinationLegacy__r.Public_Provider_Name__r.Name
            			+ System.Label.EmailPensionTransferCancellationPart2
           	 			+ getDateString()
            			+ System.Label.EmailPensionTransferCancellationPart3;
        return result;
    }
    
    public String getCancellationParagraph2() {
        return System.Label.EmailPensionTransferCancellationPart4;
    }
    
    public String getCancellationParagraph3() {
        return System.Label.EmailPensionTransferCancellationPart5;
    }

}
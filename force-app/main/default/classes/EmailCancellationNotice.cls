public class EmailCancellationNotice {
    
    public String objectId{get;set;}
    private Fulfilment__c fulfilment = new Fulfilment__c();
    Boolean constructorRun = false;
    
    public void EmailCancellationNotice() {
        if(!constructorRun){
            constructorRun = true;
            if(String.isBlank(objectId)){
                objectId = ApexPages.currentPage().getParameters().get('objectId');
            }
            if (String.isNotBlank(objectId)) {
                // Get household status and set active flag
                fulfilment = [SELECT 
                              Id, 
                              Recommendation__r.Product__r.Name,
                              Recommendation__r.PrimaryOwner__r.AddressedName__pc,
                              Recommendation__r.RegisteredContact__c,
                              Recommendation__r.RegisteredContact__r.AddressedName__pc
                              FROM Fulfilment__c WHERE Id = :objectId];
            }
        }
    }
    
    public String getClientName(){
        EmailCancellationNotice();
        String result = ' ';
        if( fulfilment.Recommendation__r.RegisteredContact__c == null) {
            result = result + 'your ';
        } else {
            result = result + fulfilment.Recommendation__r.PrimaryOwner__r.AddressedName__pc + '\'s ';
        }
        return result;
    }
    
    public String getProductName(){
        return fulfilment.Recommendation__r.Product__r.Name ;
    }
    
    public String getDateString(){
        UtilityString us = new UtilityString();
        return us.formatDateForNovaEmail(Datetime.now());
    }

}
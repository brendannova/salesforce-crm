public class EmailCancellationNotice {
    
    public String objectId{get;set;}
    private Fulfilment__c fulfilment = new Fulfilment__c();
    Boolean constructorRun = false;
    
    public void EmailCancellationNoticeGroupedConstructor() {
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
                              Recommendation__r.ProductName__c, 
                              Recommendation__r.Product__r.Name,
                              Recommendation__r.RegisteredContact__c,
                              Recommendation__r.RegisteredContact__r.AddressedName__pc
                              FROM Fulfilment__c WHERE Id = :objectId];
            }
        }
    }

    
    public String getIntroString() {
        System.debug('introstring ' + fulfilment);
        String result = System.Label.EmailCancellationNoticeIntroPart1 +  clientName() + ' new NOVA '
            			+ fulfilment.Recommendation__r.ProductName__c + ' '
            			+ System.Label.EmailCancellationNoticeIntroPart2 + ' '
           				+ fulfilment.Recommendation__r.Product__r.Name + ' '
            			+ System.Label.EmailCancellationNoticeIntroPart3;
        return result;
    }
    
    public String clientName(){
        String result = '';
        if( fulfilment.Recommendation__r.RegisteredContact__c == null) {
            result = result + 'your ';
        } else {
            result = result + fulfilment.Recommendation__r.PrimaryOwner__r.AddressedName__pc + '\'s ';
        }
        return result;
    }
    
    public String getCancellationStringPart1() {
        String result = System.Label.EmailCancellationNoticeCancellationDetailsPart1;
            
        return result;
    }
    
    public String getDateString() {
        String result = System.Label.EmailCancellationNoticeCancellationDetailsPart2 + ' '
           				+ Datetime.newInstance(Date.today().year(),Date.today().month(),Date.today().day()).format('MMMMMMMMMMM dd, yyyy') + ' '
            			+ System.Label.EmailCancellationNoticeCancellationDetailsPart3;
            
        return result;
    }
    
    public String getCancellationStringPart2() {
        String result = System.Label.EmailCancellationNoticeCancellationDetailsPart4;
            
        return result;
    }
    
    public String getCancellationStringPart3() {
        String result = System.Label.EmailCancellationNoticeCancellationDetailsPart5;
            
        return result;
    }

}
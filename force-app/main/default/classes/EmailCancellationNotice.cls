public class EmailCancellationNotice {
    
    public String objectId{get;set;}
    private Fulfilment__c fulfilment = new Fulfilment__c();
    Boolean constructorRun = false;
    private String dateString;
    
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
            dateString = Datetime.now().format('MMMMMMMMMMM d, yyyy');
        }
    }
    
    public String clientName(){
        String result = ' ';
        if( fulfilment.Recommendation__r.RegisteredContact__c == null) {
            result = result + 'your ';
        } else {
            result = result + fulfilment.Recommendation__r.PrimaryOwner__r.AddressedName__pc + '\'s ';
        }
        return result;
    }
    
    public String getCancellationStringParagraph1() {
        EmailCancellationNotice();
        String result = 'I’m very pleased to confirm that ' 
            + clientName() 
            + 'new NOVA ' 
            + fulfilment.Recommendation__r.Product__r.Name 
            + ' has now been set up. You do have a right to change your mind regarding your '
            + fulfilment.Recommendation__r.Product__r.Name 
            + ' so please also find details below of how you can do this.';
            
        return result;
    }
    
    public String getCancellationStringParagraph2() {
        String result = 'You have entered into a contract to establish a Self Invested Personal Pension (SIPP) with Hubwise Securities Ltd. Under the rules of The Financial Conduct Authority (FCA) you have the right to a period of reflection to consider the commitment you have made and to change your mind if you so wish.';
        return result;
    }
    
    public String getCancellationStringParagraph3() {
        String result = 'You have a period of 30 days from '
            + dateString
            + ' to do this.';
        return result;
    }
    
    public String getCancellationStringParagraph4() {
        String result = 'If you withdraw from the arrangement you are entitled to have returned to you any money which you have paid into your SIPP after deduction of any fees or charges which Hubwise Securities Ltd has already incurred in acting on your instructions to set up your SIPP. If you have instructed the administrators of your SIPP to invest money in a single premium investment which in turn has to be cancelled, you will only receive the value of the investment on the day your instruction to cancel was received by that firm. Please note that if you intend to use the proceeds of a pension transfer as the whole or part of your SIPP investment, we will conclude the SIPP contract and carry out your investment instructions without waiting for the expiry of the 30 day period.';
        return result;
    }
    
    public String getCancellationStringParagraph5() {
        String result = 'If you wish to cancel your SIPP, please email your adviser to notify them as such.';
        return result;
    }


}
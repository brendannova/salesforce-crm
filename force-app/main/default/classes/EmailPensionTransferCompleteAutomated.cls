public class EmailPensionTransferCompleteAutomated {
    public String objectId{get;set;}
    private Fulfilment__c fulfilment = new Fulfilment__c();
    Boolean constructorRun = false;
    Private STring dateString;
    
    public void EmailPensionTransferCompleteAutomated() {
        if(!constructorRun){
            constructorRun = true;
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
                              ResidualCash__c,
                              Recommendation__r.SourceLegacy__r.Public_Provider_Name__r.Name,
                              Recommendation__r.DestinationLegacy__r.Public_Provider_Name__r.Name,
                              Recommendation__r.TransferType__c
                              FROM Fulfilment__c 
                              WHERE Id = :objectId
                             ];
            }
            dateString = Datetime.now().format('MMMMMMMMMMM d, yyyy');
        }
    }
    
    public String getFirstLine() {
        EmailPensionTransferCompleteAutomated();
        String result = 'Good news. We’ve completed the '
            + partialString()
            + 'transfer of '
            + finProdNameSource()
            + ' to '
            + finProdNameDestination()
            + '.';
        return result;
    }
    
    public String getSecondLine() {
        String result = 'You can monitor the ongoing value of your assets through our portal and this will be updated in the coming days.';
    	return result;
    }
    
    public String getThirdLine() {
        if (fulfilment.ResidualCash__c != 'None') {
            return '';
        } else {
            return 'There is residual cash remaining with the ceding provider, which we expect will transfer in the future. We will update your portal once this is received.';
        }
    }
    
    public String getFourthLine() {
        return 'You do have a right to change your mind regarding your transfer, so please read below, confirming how you can do this.';

    }
    
    public String getCancellationLine1() {
        String result = 'Now that '
            + finProdNameSource()
            + ' has been successfully transferred to '
            + finProdNameDestination()
            + ', it is important to notify you of your right to change your mind.';
        return result;
    }
    
    public String getCancellationLine2() {
        String result = 'You have the right to a period of reflection to consider the commitment you have made and to change your mind if you so wish.';
        return result;
    }

    public String getCancellationLine3() {
        String result = 'You have a period of 30 days from '
            + dateString
            + ' to do this. ';
        return result;
    }

    public String getCancellationLine4() {
        String result = 'If you do wish to cancel this transfer, please email your adviser to notify them as such.';
        return result;
    }

	public String getCancellationLine5() {
        String result = 'If you change your mind about transferring pension benefits to us, we will try and send the funds back to the ceding scheme. However, if they are unwilling to accept the return of the funds, then you will need to find an alternative provider to accept the transfer. There is no charge for cancelling your transfer. However, transaction costs in relation to the purchase and sale of investments during the cancellation period may be charged, including those incurred through third parties. Details of these charges are available on request. If investments have been purchased during the cancellation period, any refund is subject to investment fluctuations. If any of the above applies, the value of your refund may be lower than the amount originally invested.';
        return result;
    }
    
    public String finProdNameDestination(){
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
    
    public String finProdNameSource(){
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
    
    public String partialString() {
        if (fulfilment.recommendation__r.TransferType__c == 'Partial') {
            return ' partial ';
        } else {
			return '';
        }
    }


}
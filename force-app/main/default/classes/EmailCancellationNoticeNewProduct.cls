public class EmailCancellationNoticeNewProduct {
    
    public String objectId {get;set;}
    private static Fulfilment__c fulfilment;
    
    // Constructor to set the fulfilment record
    public static Map<String, String> getParameters(Fulfilment__c fulfilmentInput) {
        fulfilment = fulfilmentInput;
        Map<String, String> parameters = new Map<String, String>();
        parameters.put('{{hiLine}}','Hi Bobbbbb');
        parameters.put('{{financialProductOwnership}}', financialProductOwnership);
        parameters.put('{{productName}}', productName);
        parameters.put('{{dateTodayString}}', dateString);
        return parameters;
    }
    
    // Returns your or child's name dependent on whether this is a SIPP or JSIPP
    public static String financialProductOwnership{
        get{
            if( fulfilment.Recommendation__r.RegisteredContact__c == null ) {
                return 'your';
            } else {
                return fulfilment.Recommendation__r.PrimaryOwner__r.AddressedName__pc + '\'s';
            }
        }
    }
    
    private static String productName{
        get{
            if(String.isNotBlank(fulfilment.Recommendation__r.Product__r.Name)) {
                return fulfilment.Recommendation__r.Product__r.Name;
            } else {
                throw new EmailCancellationNoticeTransferException('Blank value in product name'); 
            }
        }
    }
    
    private static String dateString{
        get{
            UtilityString us = new UtilityString();
            return us.formatDateForNovaEmail(Datetime.now());
        }
    }

    public static String getSubject(Fulfilment__c fulfilment){
        String subject = 'Your new SIPP';
        return subject;
    }
    
    public class EmailCancellationNoticeNewProductException extends Exception {}
}
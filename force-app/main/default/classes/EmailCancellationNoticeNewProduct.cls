public class EmailCancellationNoticeNewProduct {
    
    public String objectId {get;set;}
    private static Fulfilment__c fulfilment;
    
    // Constructor to set the fulfilment record
    public static Map<String, String> getParameters(Fulfilment__c fulfilmentInput) {
        fulfilment = fulfilmentInput;
        Map<String, String> parameters = new Map<String, String>();
        parameters.put('{{hiLine}}','Hi Bobbbbb');
        parameters.put('{{clientName}}', clientName);
        parameters.put('{{productName}}', productName);
        parameters.put('{{dateTodayString}}', dateString);
        return parameters;
    }
    
    private static String clientName {
        get{ 
            String result = '';
            if( fulfilment.Recommendation__r.RegisteredContact__c == null) {
                result = result + 'your ';
            } else {
                result = result + fulfilment.Recommendation__r.PrimaryOwner__r.AddressedName__pc + '\'s ';
            }
            return result;
        }
    }
    
    private static String productName{
        get{
            return fulfilment.Recommendation__r.Product__r.Name ;
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
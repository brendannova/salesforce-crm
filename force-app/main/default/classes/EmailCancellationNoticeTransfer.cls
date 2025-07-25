/**
 * This class is the controller for a SIPP/JSIPP transfer cancellation notice email template. 
 * It exists only to produce the content for this email and should be used for no other purpose. 
 */
public with sharing class EmailCancellationNoticeTransfer {

    public String objectId {get;set;}
    private static Fulfilment__c fulfilment;
    
    // Constructor to set the fulfilment record
    public static Map<String, String> getParameters(Fulfilment__c fulfilmentInput) {
        fulfilment = fulfilmentInput;
        Map<String, String> parameters = new Map<String, String>();
        parameters.put('{{hiLine}}','Hi Bobbbbb');
        parameters.put('{{partialString}}', partialString);
        parameters.put('{{financialProductNameSource}}', financialProductNameSource);
        parameters.put('{{financialProductNameDestination}}', financialProductNameDestination);
        parameters.put('{{dateTodayString}}', dateString);
        parameters.put('{{residualCashDisplay}}', residualCashDisplay);
        return parameters;
    }
    
    // Method to format today's date into a client friendly format
    public static String dateString {
        get {
            UtilityString us = new UtilityString();
            return us.formatDateForNovaEmail(Datetime.now());
        }
    }
    
    // Determines if there is residual cash or not, allowing the associate passage of text to be hidden/shown as appopriate.
    public static String residualCashDisplay {
        get{
            if (fulfilment.ResidualCash__c == 'NONE') {
                return '';
            } else {
                return 'none';
            }
        }
    }

    // Method to provide the friendly name of the destination
    public static String financialProductNameDestination{
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
    public static String financialProductNameSource{
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
    public static String partialString{
        get{
            if (fulfilment.recommendation__r.TransferType__c == 'Partial') {
                return ' partial ';
            } else {
                return '';
            }
        }
    }
}
/**
 * This class produces content for a SIPP/JSIPP transfer cancellation notice email template. 
 * It exists only to produce the content for this email and should be used for no other purpose. 
 */
public with sharing class EmailCancellationNoticeTransfer {

    public String objectId {get;set;}
    private static Fulfilment__c fulfilment;
    private final static String RESIDUAL_CASH_NONE = 'NONE';
    private final static String RESIDUAL_CASH_AWAITING = 'AWAITING';
    private final static String RESIDUAL_CASH_RECEIVED = 'RECEIVED';
    
    // Returns a map of parameter key value pairs to be substituted into the email template
    public static Map<String, String> getParameters(Fulfilment__c fulfilmentInput) {
        fulfilment = fulfilmentInput;
        Map<String, String> parameters = new Map<String, String>();
        parameters.put('{{partialTransfer}}', partialTransfer);
        parameters.put('{{residualCashDisplay}}', residualCashDisplay);
        parameters.put('{{sourceOwnership}}', sourceOwnership);
        parameters.put('{{financialProductNameSource}}', financialProductNameSource);
        parameters.put('{{destinationOwnership}}', destinationOwnership);
        parameters.put('{{financialProductNameDestination}}', financialProductNameDestination);
        parameters.put('{{dateString}}', dateString);
        return parameters;
    }
    
    // Determines if there is residual cash or not, allowing the associated passage of text to be hidden/shown as appopriate in the email.
    public static String residualCashDisplay {
        get{
            if (fulfilment.ResidualCash__c == RESIDUAL_CASH_NONE) {
                return 'none';
            } else if (fulfilment.ResidualCash__c == RESIDUAL_CASH_AWAITING || fulfilment.ResidualCash__c == RESIDUAL_CASH_RECEIVED) {
                return '';
            } else {
                throw new EmailCancellationNoticeTransferException('Unknown residual cash status'); 
            }
        }
    }

    // Method to provide string for a partial transfer if required
    public static String partialTransfer{
        get{
            if (fulfilment.recommendation__r.TransferType__c == 'Partial') {
                return '';
            } else if (fulfilment.recommendation__r.TransferType__c == 'Full') {
                return 'none';
            } else {
                throw new EmailCancellationNoticeTransferException('Unknown transfer type'); 
            }
        }
    }

    // Returns your or child's name dependent on whether this is a SIPP or JSIPP
    public static String sourceOwnership{
        get{
            if( fulfilment.Recommendation__r.DestinationLegacy__r.RecordType.DeveloperName == 'FP_SIPP' ) {
                return 'your';
            } else if( fulfilment.Recommendation__r.DestinationLegacy__r.RecordType.DeveloperName == 'Junior_SIPP' ){
                return fulfilment.Recommendation__r.PrimaryOwner__r.AddressedName__pc + '\'s';
            } else {
                throw new EmailCancellationNoticeTransferException('Unknown value for product developer name'); 
            }
        }

    }

    // Returns the name of the source financial product as it should be displayed in the email 
    public static String financialProductNameSource{
        get{
            if(String.isNotBlank(fulfilment.Recommendation__r.SourceLegacy__r.Public_Provider_Name__r.Name)) {
                return fulfilment.Recommendation__r.SourceLegacy__r.Public_Provider_Name__r.Name;
            } else {
                throw new EmailCancellationNoticeTransferException('Blank value in financial product source name'); 
            }
        }
    }

    // Returns "your" or "their" dependent on whether this is a SIPP or JSIPP
    public static String destinationOwnership{
        get{
            if( fulfilment.Recommendation__r.DestinationLegacy__r.RecordType.DeveloperName == 'FP_SIPP' ) {
                return 'your';
            } else if ( fulfilment.Recommendation__r.DestinationLegacy__r.RecordType.DeveloperName == 'Junior_SIPP'){
                return 'their';
            } else {
                throw new EmailCancellationNoticeTransferException('Unknown value for product developer name'); 
            }
        }
    }

    // Returns the name of the destination financial product as it should be displayed in the email 
    public static String financialProductNameDestination{
        get{
            if(String.isNotBlank(fulfilment.Recommendation__r.DestinationLegacy__r.Public_Provider_Name__r.Name) && String.isNotBlank(fulfilment.Recommendation__r.Product__r.Name)) {
                return fulfilment.Recommendation__r.DestinationLegacy__r.Public_Provider_Name__r.Name + ' ' + fulfilment.Recommendation__r.Product__r.Name;
            } else {
                throw new EmailCancellationNoticeTransferException('Blank value in financial product destination name'); 
            }
        }
    }

    // Returns the date from which cancellation can take place, formatted for the email
    public static String dateString {
        get {
            UtilityString us = new UtilityString();
            return us.formatDateForNovaEmail(Datetime.now());
        }
    }

    public class EmailCancellationNoticeTransferException extends Exception {}
}
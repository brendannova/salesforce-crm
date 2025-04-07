public with sharing class LwcHelperDynamicRecordList {

    public class DataWrapperException extends Exception {}
    private static final Set<String> VALID_COLUMN_TYPES = new Set<String>{'text', 'url', 'currency', 'number', 'date', 'percent', 'location'};

    @AuraEnabled
    public static DataWrapper getDynamicData(String logicReference, Id contextId) {
        DataWrapper dataWrapper = new DataWrapper();
        switch on logicReference {
            /*when 'LOGIC_NAME_HERE'{
                dataWrapper = ClassName.functionName(contextId);
            }*/
            when else{
                dataWrapper.errorMessage = 'No logic reference matched';
            }
        }

        List<String> errors = validateDataWrapper(dataWrapper);
        if(errors.size() > 0) {
            System.debug(errors);
            dataWrapper.errorMessage += String.join(errors, '; ');
        }
        return dataWrapper;
    }

    public class DataWrapper{
        @AuraEnabled public List<ColumnWrapper> columns = new List<ColumnWrapper>();
        @AuraEnabled public List<RowWrapper> rows = new List<RowWrapper>();
        @AuraEnabled public ConfigWrapper config = new ConfigWrapper();
        @AuraEnabled public string errorMessage;
    }

    public class ConfigWrapper{
        //@AuraEnabled public String objectAPIName;
        //@AuraEnabled public String sobjectLabel;
        @AuraEnabled public String keyFieldName;
        //@AuraEnabled public String idFieldNameToReference;
        //@AuraEnabled public String nameFieldNameToReference;
        //@AuraEnabled public boolean allowNew;
        //@AuraEnabled public boolean allowEdit;
        //@AuraEnabled public boolean allowDelete;
    }

    public class ColumnWrapper{
        @AuraEnabled public String label;
        @AuraEnabled public String fieldName;
        @AuraEnabled public String type;
        @AuraEnabled public Boolean sortable = true;
        @AuraEnabled public TypeAttributesWrapper typeAttributes = new TypeAttributesWrapper();
        @AuraEnabled public string iconName;
        @AuraEnabled public boolean hideLabel;

        public ColumnWrapper(String label, String fieldName, String type){
            this.label = label;
            this.fieldName = fieldName;
            this.type = type;
        }
    }

    public class TypeAttributesWrapper{
        //LWC will sort through and only apply relevant ones based on type
        
        //url
        @AuraEnabled public Map<String, String> label = new Map<String, String>{'fieldName' => ''};
        @AuraEnabled public String target = '_blank';
        @AuraEnabled public String tooltip;
        
        //currency - https://developer.salesforce.com/docs/component-library/bundle/lightning-formatted-number/specification
        @AuraEnabled public string currencyCode;
        @AuraEnabled public string currencyDisplayAs;
        @AuraEnabled public double step; // also used for percentacge
        //Also used for number & percentage
        @AuraEnabled public double minimumIntegerDigits;
        @AuraEnabled public double minimumFractionDigits;
        @AuraEnabled public double maximumFractionDigits;
        @AuraEnabled public double minimumSignificantDigits;
        @AuraEnabled public double maximumSignificantDigits;

        //date - https://developer.salesforce.com/docs/component-library/bundle/lightning-formatted-date-time/specification
        @AuraEnabled public string era;
        @AuraEnabled public string hour;
        @AuraEnabled public boolean hour12;
        @AuraEnabled public string minute;
        @AuraEnabled public string second;
        @AuraEnabled public string timeZone;
        @AuraEnabled public string timeZoneName;
        @AuraEnabled public string weekday;
        //also used for date-local
        @AuraEnabled public string day;
        @AuraEnabled public string month;
        @AuraEnabled public string year;

        //location
        @AuraEnabled public string latitude;
        @AuraEnabled public string longitude;
    }

    public class RowWrapper{
        @AuraEnabled public List<FieldWrapper> fields = new List<FieldWrapper>();
    }

    public class FieldWrapper{
        @AuraEnabled public String fieldName;
        @AuraEnabled public String value;

        public FieldWrapper(String fieldName, String value){
            this.fieldName = fieldName;
            this.value = value;
        }
    }


    public static List<String> validateDataWrapper(DataWrapper wrapper) {
        List<String> errors = new List<String>();

        Set<String> columnFieldNames = new Set<String>();

        // Validate columns
        for (ColumnWrapper col : wrapper.columns) {
            if (String.isBlank(col.fieldName)) {
                errors.add('Column is missing fieldName.');
            } else {
                columnFieldNames.add(col.fieldName);
            }

            if (String.isBlank(col.type) || !VALID_COLUMN_TYPES.contains(col.type)) {
                errors.add('Invalid or missing type for column: ' + col.label);
            }

            if (String.isBlank(col.label) && String.isBlank(col.iconName)) {
                errors.add('Column must have either label or iconName.');
            }

            // Validate typeAttributes for specific types
            if (col.type == 'url' && (col.typeAttributes == null || String.isBlank(col.typeAttributes.target))) {
                errors.add('URL column is missing required typeAttributes');
            }
            if (col.type == 'currency' && (col.typeAttributes == null || String.isBlank(col.typeAttributes.currencyCode))) {
                errors.add('Currency column is missing required typeAttributes');
            }
        }
        // Validate rows
        for (RowWrapper row : wrapper.rows) {
            Set<String> rowFieldNames = new Set<String>();
            for (FieldWrapper field : row.fields) {
                if (String.isBlank(field.fieldName)) {
                    errors.add('Field in row is missing fieldName.');
                }
                rowFieldNames.add(field.fieldName);
            }

            for (String colFieldName : columnFieldNames) {
                if (!rowFieldNames.contains(colFieldName)) {
                    errors.add('Row is missing field for column fieldName: ' + colFieldName);
                }
            }

            if(wrapper.config.keyFieldName == null || !rowFieldNames.contains(wrapper.config.keyFieldName)){
                errors.add('Key field not present in row list: ' + wrapper.config.keyFieldName);
            }
        }

        return errors;
    }

    public static DataWrapper getHouseholdMembers(Id householdId){
        DataWrapper dataWrapper = new DataWrapper();

        dataWrapper.config.keyFieldName = 'id';

        ColumnWrapper nameLinkColumn = new ColumnWrapper('Name', 'nameLink', 'url');
        nameLinkColumn.typeAttributes.label.put('fieldName', 'name');

        dataWrapper.columns.add(new ColumnWrapper('ID', 'id', 'text'));
        dataWrapper.columns.add(nameLinkColumn);
        
        List<AccountContactRelation> householdMembers = [SELECT Contact.AccountId, Contact.FirstName, Contact.LastName FROM AccountContactRelation WHERE AccountId =: householdId];

        for(AccountContactRelation householdMember: householdMembers){
            RowWrapper rowWrapper = new RowWrapper();
            rowWrapper.fields.add(new FieldWrapper('id', householdMember.Contact.AccountId));
            rowWrapper.fields.add(new FieldWrapper('name', householdMember.Contact.FirstName + ' ' + Contact.LastName));
            rowWrapper.fields.add(new FieldWrapper('nameLink', '/'+householdMember.Contact.Id));

            dataWrapper.rows.add(rowWrapper);
        }

        return dataWrapper;
    }

    public static DataWrapper getInformationRequests(Id recordId) {
        DataWrapper dataWrapper = new DataWrapper();
        dataWrapper.config.keyFieldName = 'id';

        ColumnWrapper nameLinkColumn = new ColumnWrapper('Name', 'nameLink', 'url');
        nameLinkColumn.typeAttributes.label.put('fieldName', 'name');

        ColumnWrapper finaicialProductLinkColumn = new ColumnWrapper('Financial Product', 'financialProductLink', 'url');
        finaicialProductLinkColumn.typeAttributes.label.put('fieldName', 'financialProduct');

        dataWrapper.columns.add(nameLinkColumn);
        dataWrapper.columns.add(new ColumnWrapper('Status', 'status', 'text'));
        dataWrapper.columns.add(finaicialProductLinkColumn);
        dataWrapper.columns.add(new ColumnWrapper('Type', 'type', 'text'));
        dataWrapper.columns.add(new ColumnWrapper('Authority Status', 'authStatus', 'text'));

        List<InformationRequest__c> informationRequests = [SELECT Id, Name, Status__c, AuthorityStatus__c,InformationRequestType__r.Name, FinancialProductFinServ__c, InformationRequestType__c, FinancialProductFinServ__r.Name FROM InformationRequest__c WHERE FinancialProductFinServ__r.Household__c =: recordId AND Status__c NOT IN ('Complete','Cancelled') ORDER BY Status__c ASC];
        String urlPrefix = URL.getOrgDomainURL().toExternalForm() + '/';
        Map<String,String> statusApiToLabelMap = getPicklistApiLabelMap();
        for( InformationRequest__c informationRequest : informationRequests ) {


            RowWrapper rowWrapper = new RowWrapper();
            rowWrapper.fields.add(new FieldWrapper('id', informationRequest.Id));
            rowWrapper.fields.add(new FieldWrapper('name', informationRequest.Name));
            rowWrapper.fields.add(new FieldWrapper('nameLink', urlPrefix+informationRequest.Id));
            rowWrapper.fields.add(new FieldWrapper('status', statusApiToLabelMap.get(informationRequest.Status__c)));
            rowWrapper.fields.add(new FieldWrapper('financialProduct', informationRequest.FinancialProductFinServ__r.Name));
            rowWrapper.fields.add(new FieldWrapper('financialProductLink', urlPrefix+informationRequest.FinancialProductFinServ__c));
            rowWrapper.fields.add(new FieldWrapper('type', informationRequest.InformationRequestType__r.Name));
            rowWrapper.fields.add(new FieldWrapper('authStatus', informationRequest.AuthorityStatus__c));

            dataWrapper.rows.add(rowWrapper);
    	}
        return dataWrapper;
    }

    // Get a map of picklist values to labels so that we can display the labels in the list
    private static Map<String,String> getPicklistApiLabelMap(){
        List<Schema.PicklistEntry> picklistItems = InformationRequest__c.Status__c.getDescribe().getPicklistValues();
        Map<String,String> picklistApiLabelMap = new Map<String,String>();
        For(Schema.PicklistEntry picklistItem : picklistItems){
            picklistApiLabelMap.put(picklistItem.getValue(), picklistItem.getLabel());
        }
        return picklistApiLabelMap; 
    }
}
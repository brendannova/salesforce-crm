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
                //could also throw an error here once logic above is added to prevent (unreachable logic error bellow)
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
        @AuraEnabled public String errorMessage;
    }

    public class ConfigWrapper{
        @AuraEnabled public String keyFieldName;
    }

    public class ColumnWrapper{
        @AuraEnabled public String label;
        @AuraEnabled public String fieldName;
        @AuraEnabled public String type;
        @AuraEnabled public Boolean sortable = true;
        @AuraEnabled public TypeAttributesWrapper typeAttributes = new TypeAttributesWrapper();
        @AuraEnabled public String iconName;
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
        @AuraEnabled public String currencyCode;
        @AuraEnabled public String currencyDisplayAs;
        @AuraEnabled public Double step; // also used for percentacge
        //Also used for number & percentage
        @AuraEnabled public Double minimumIntegerDigits;
        @AuraEnabled public Double minimumFractionDigits;
        @AuraEnabled public Double maximumFractionDigits;
        @AuraEnabled public Double minimumSignificantDigits;
        @AuraEnabled public Double maximumSignificantDigits;

        //date - https://developer.salesforce.com/docs/component-library/bundle/lightning-formatted-date-time/specification
        @AuraEnabled public String era;
        @AuraEnabled public String hour;
        @AuraEnabled public Boolean hour12;
        @AuraEnabled public String minute;
        @AuraEnabled public String second;
        @AuraEnabled public String timeZone;
        @AuraEnabled public String timeZoneName;
        @AuraEnabled public String weekday;
        //also used for date-local
        @AuraEnabled public String day;
        @AuraEnabled public String month;
        @AuraEnabled public String year;

        //location
        @AuraEnabled public String latitude;
        @AuraEnabled public String longitude;
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
}
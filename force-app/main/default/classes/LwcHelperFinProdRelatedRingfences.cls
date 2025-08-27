public class LwcHelperFinProdRelatedRingfences {

    public static LwcHelperDynamicRecordList.DataWrapper getRingfences(Id recordId) {
        LwcHelperDynamicRecordList.DataWrapper dataWrapper = new LwcHelperDynamicRecordList.DataWrapper();
        dataWrapper.config.keyFieldName = 'id';
        
        LwcHelperDynamicRecordList.ColumnWrapper nameLinkColumn = new LwcHelperDynamicRecordList.ColumnWrapper('Name', 'nameLink', 'url');
    	nameLinkColumn.typeAttributes.label.put('fieldName', 'name');
        dataWrapper.columns.add(nameLinkColumn);    
        
        LwcHelperDynamicRecordList.ColumnWrapper fulfilmentLinkColumn = new LwcHelperDynamicRecordList.ColumnWrapper('Fulfilment', 'fulfilmentLink', 'url');
        fulfilmentLinkColumn.typeAttributes.label.put('fieldName', 'fulfilment');
        dataWrapper.columns.add(fulfilmentLinkColumn); 
        
        dataWrapper.columns.add(new LwcHelperDynamicRecordList.ColumnWrapper('Status', 'status', 'text'));
        
        LwcHelperDynamicRecordList.ColumnWrapper amountColumn = new LwcHelperDynamicRecordList.ColumnWrapper('Amount', 'amount', 'currency');
        amountColumn.typeAttributes.currencyCode = 'GBP';
        dataWrapper.columns.add(amountColumn); 
        
        
        List<Ringfence__c> ringfences = [SELECT 
                                         Id, 
                                         Name, 
                                         Amount__c, 
                                         Status__c, 
                                         Fulfilment__c,
                                         Fulfilment__r.SearchName__c
                                         FROM 
                                         Ringfence__c 
                                         WHERE 
                                         Fulfilment__r.Recommendation__r.DestinationLegacy__c =: recordId 
                                         ORDER BY Status__c, Fulfilment__c ASC
                                        ];
        
        String urlPrefix = URL.getOrgDomainURL().toExternalForm() + '/';
        Map<String,String> statusApiToLabelMap = Utility.getPicklistApiLabelMap('Ringfence__c','Status__c');
        
        for( Ringfence__c ringfence : ringfences ) {
            
            LwcHelperDynamicRecordList.RowWrapper rowWrapper = new LwcHelperDynamicRecordList.RowWrapper();
            rowWrapper.fields.add(new LwcHelperDynamicRecordList.FieldWrapper('name', ringfence.Name));
        	rowWrapper.fields.add(new LwcHelperDynamicRecordList.FieldWrapper('nameLink', urlPrefix+ringfence.Id));
            rowWrapper.fields.add(new LwcHelperDynamicRecordList.FieldWrapper('id', ringfence.Id));
            rowWrapper.fields.add(new LwcHelperDynamicRecordList.FieldWrapper('amount', ringfence.Amount__c.toString()));
            rowWrapper.fields.add(new LwcHelperDynamicRecordList.FieldWrapper('status', statusApiToLabelMap.get(ringfence.Status__c)));
            rowWrapper.fields.add(new LwcHelperDynamicRecordList.FieldWrapper('fulfilment', ringfence.Fulfilment__r.SearchName__c));
            rowWrapper.fields.add(new LwcHelperDynamicRecordList.FieldWrapper('fulfilmentLink', urlPrefix+ringfence.Fulfilment__c));

            
            dataWrapper.rows.add(rowWrapper);
        }
        return dataWrapper;
    }
    



}
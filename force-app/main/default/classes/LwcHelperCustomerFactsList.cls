/* This class exists exclusively to get active customer facts to display for a given household
 * From a given household ID, this class gets all active customer facts and constructs a table to display them
 */
public with sharing class LwcHelperCustomerFactsList {
    public static LwcHelperDynamicRecordList.DataWrapper getCustomerFactData(Id contextId) {
        LwcHelperDynamicRecordList.DataWrapper dataWrapper = new LwcHelperDynamicRecordList.DataWrapper();
        dataWrapper.config.keyFieldName = 'factId';

        //define columns
        LwcHelperDynamicRecordList.ColumnWrapper factNameLink = new LwcHelperDynamicRecordList.ColumnWrapper('Fact', 'Id', 'url');
        factNameLink.typeAttributes.label.put('fieldName', 'Name');

        dataWrapper.columns.add(factNameLink);
        dataWrapper.columns.add(new LwcHelperDynamicRecordList.ColumnWrapper('Category', 'FactCategoryName__c', 'text'));
        dataWrapper.columns.add(new LwcHelperDynamicRecordList.ColumnWrapper('Notes', 'Notes__c', 'text'));
        dataWrapper.columns.add(new LwcHelperDynamicRecordList.ColumnWrapper('Last modified date', 'LastModifiedDate', 'date'));

        List<CustomerFact__c> customerFacts = [SELECT Id, Name, Fact__c, FactCategoryName__c, Household__c, Notes__c, LastModifiedDate FROM CustomerFact__c WHERE  Household__c =: contextId AND Status__c = 'Active' ORDER BY FactCategoryName__c];
        String urlPrefix = URL.getOrgDomainURL().toExternalForm() + '/';

        for(CustomerFact__c cf : customerFacts) {
            LwcHelperDynamicRecordList.RowWrapper rowWrapper = new LwcHelperDynamicRecordList.RowWrapper();
            rowWrapper.fields.add(new LwcHelperDynamicRecordList.FieldWrapper('factId', cf.Id));
            rowWrapper.fields.add(new LwcHelperDynamicRecordList.FieldWrapper('FactCategoryName__c', cf.FactCategoryName__c));
            rowWrapper.fields.add(new LwcHelperDynamicRecordList.FieldWrapper('Id', urlPrefix + cf.Id));
            rowWrapper.fields.add(new LwcHelperDynamicRecordList.FieldWrapper('Name', cf.Name));
            rowWrapper.fields.add(new LwcHelperDynamicRecordList.FieldWrapper('Notes__c', cf.Notes__c));
            rowWrapper.fields.add(new LwcHelperDynamicRecordList.FieldWrapper('LastModifiedDate', cf.LastModifiedDate.toString()));
            dataWrapper.rows.add(rowWrapper);
        }
        return dataWrapper;
    }
}
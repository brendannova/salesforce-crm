/*
 * This class exists for the sole purpose of creating a list of all available email templates with their related configuration.
 * It get all templates and their configuration data to display in a list on the Manage Email Templates tab
 */
public with sharing class LwcHelperEmailTemplateList {

    public static LwcHelperDynamicRecordList.DataWrapper getTemplateData(Id contextId) {
        LwcHelperDynamicRecordList.DataWrapper dataWrapper = new LwcHelperDynamicRecordList.DataWrapper();
        dataWrapper.config.keyFieldName = 'TemplateId';

        //Define columns
        LwcHelperDynamicRecordList.ColumnWrapper folderLinkColumn = new LwcHelperDynamicRecordList.ColumnWrapper('Folder', 'Folder.Id', 'url');
        folderLinkColumn.typeAttributes.label.put('fieldName', 'Folder.Name');

        LwcHelperDynamicRecordList.ColumnWrapper nameLinkColumn = new LwcHelperDynamicRecordList.ColumnWrapper('Template Name', 'TemplateId', 'url');
        nameLinkColumn.typeAttributes.label.put('fieldName', 'Name');

        LwcHelperDynamicRecordList.ColumnWrapper googleTemplateLinkColumn = new LwcHelperDynamicRecordList.ColumnWrapper('Google template URL', 'GoogleDriveTemplateUrl__c', 'url');
        googleTemplateLinkColumn.typeAttributes.label.put('fieldName', 'GoogleDriveTemplateUrl__c'); //May not need to define label

        dataWrapper.columns.add(folderLinkColumn);
        dataWrapper.columns.add(nameLinkColumn);
        dataWrapper.columns.add(new LwcHelperDynamicRecordList.ColumnWrapper('Description', 'Description', 'text'));
        dataWrapper.columns.add(googleTemplateLinkColumn);
        dataWrapper.columns.add(new LwcHelperDynamicRecordList.ColumnWrapper('Review at tax year end', 'ReviewAtTaxYearEnd__c', 'text'));
        dataWrapper.columns.add(new LwcHelperDynamicRecordList.ColumnWrapper('Close after send', 'AwaitReply__c', 'text'));
        dataWrapper.columns.add(new LwcHelperDynamicRecordList.ColumnWrapper('Has attachment', 'HasAttachment__c', 'text'));
        dataWrapper.columns.add(new LwcHelperDynamicRecordList.ColumnWrapper('Last modified date', 'LastModifiedDate', 'date'));

        // Define rows
        List<EmailTemplate> emailTemps = [SELECT Id, Name, FolderId, Folder.Name, Description, DeveloperName, LastModifiedDate FROM EmailTemplate ORDER BY Folder.Name];
        Map<String,EmailTemplate> emailTemplateMap = new Map<String,EmailTemplate>();
        for(EmailTemplate emailTempForMap : emailTemps) {
            emailTemplateMap.put(emailTempForMap.DeveloperName, emailTempForMap);
        }
        Map<String,EmailConfiguration__c> emailConfigMap = new Map<String,EmailConfiguration__c>();
        for(EmailConfiguration__c econfig : [SELECT Id, Name, DeveloperName__c, GoogleDriveTemplateUrl__c, AwaitReply__c, ReviewAtTaxYearEnd__c, HasAttachment__c FROM EmailConfiguration__c]) {
            emailConfigMap.put(econfig.DeveloperName__c, econfig);
        }
        String urlPrefix = URL.getOrgDomainURL().toExternalForm() + '/';
        Map<String,String> picklistApiToLabelMapCloseAfterSend = getPicklistApiLabelMapCloseAfterSend();
        Map<String,String> picklistApiToLabelMapTye = getPicklistApiLabelMapTyeDates();
        Map<String,String> picklistApiToLabelMapAttachments = getPicklistApiLabelMapAttachments();

        for(String emailTempDevNames : emailTemplateMap.keySet()) {
            if(emailConfigMap.containsKey(emailTempDevNames)){
                LwcHelperDynamicRecordList.RowWrapper rowWrapper = new LwcHelperDynamicRecordList.RowWrapper();
                rowWrapper.fields.add(new LwcHelperDynamicRecordList.FieldWrapper('Folder.Id', urlPrefix+emailTemplateMap.get(emailTempDevNames).FolderId));
                rowWrapper.fields.add(new LwcHelperDynamicRecordList.FieldWrapper('Folder.Name', emailTemplateMap.get(emailTempDevNames).Folder.Name));
                rowWrapper.fields.add(new LwcHelperDynamicRecordList.FieldWrapper('TemplateId', urlPrefix+emailTemplateMap.get(emailTempDevNames).Id));
                rowWrapper.fields.add(new LwcHelperDynamicRecordList.FieldWrapper('Name', emailTemplateMap.get(emailTempDevNames).Name));
                rowWrapper.fields.add(new LwcHelperDynamicRecordList.FieldWrapper('Description', emailTemplateMap.get(emailTempDevNames).Description));
                rowWrapper.fields.add(new LwcHelperDynamicRecordList.FieldWrapper('GoogleDriveTemplateUrl__c', emailConfigMap.get(emailTempDevNames).GoogleDriveTemplateUrl__c));
                rowWrapper.fields.add(new LwcHelperDynamicRecordList.FieldWrapper('ReviewAtTaxYearEnd__c', picklistApiToLabelMapTye.get(emailConfigMap.get(emailTempDevNames).ReviewAtTaxYearEnd__c)));
                rowWrapper.fields.add(new LwcHelperDynamicRecordList.FieldWrapper('AwaitReply__c', picklistApiToLabelMapCloseAfterSend.get(emailConfigMap.get(emailTempDevNames).AwaitReply__c)));
                rowWrapper.fields.add(new LwcHelperDynamicRecordList.FieldWrapper('HasAttachment__c', picklistApiToLabelMapAttachments.get(emailConfigMap.get(emailTempDevNames).HasAttachment__c)));
                rowWrapper.fields.add(new LwcHelperDynamicRecordList.FieldWrapper('LastModifiedDate', emailTemplateMap.get(emailTempDevNames).LastModifiedDate.toString()));

                    dataWrapper.rows.add(rowWrapper);
            }
        }
        return dataWrapper;
    }

    // Get a map of picklist values to labels so that we can display the labels in the list
    private static Map<String,String> getPicklistApiLabelMapCloseAfterSend(){
        List<Schema.PicklistEntry> picklistItems = EmailConfiguration__c.AwaitReply__c.getDescribe().getPicklistValues();
        Map<String,String> picklistApiLabelMap = new Map<String,String>();
        For(Schema.PicklistEntry picklistItem : picklistItems){
            String label;
            if(picklistItem.getValue() == 'Await a reply'){
                label = 'No';
            } else if(picklistItem.getValue() == 'No reply expected'){
                label = 'Yes';
            }
            picklistApiLabelMap.put(picklistItem.getValue(), label);
        }
        return picklistApiLabelMap; 
    }
    private static Map<String,String> getPicklistApiLabelMapTyeDates(){
        List<Schema.PicklistEntry> picklistItems = EmailConfiguration__c.ReviewAtTaxYearEnd__c.getDescribe().getPicklistValues();
        Map<String,String> picklistApiLabelMap = new Map<String,String>();
        For(Schema.PicklistEntry picklistItem : picklistItems){
            picklistApiLabelMap.put(picklistItem.getValue(), picklistItem.getLabel());
        }
        return picklistApiLabelMap; 
    }
    private static Map<String,String> getPicklistApiLabelMapAttachments(){
        List<Schema.PicklistEntry> picklistItems = EmailConfiguration__c.HasAttachment__c.getDescribe().getPicklistValues();
        Map<String,String> picklistApiLabelMap = new Map<String,String>();
        For(Schema.PicklistEntry picklistItem : picklistItems){
            picklistApiLabelMap.put(picklistItem.getValue(), picklistItem.getLabel());
        }
        return picklistApiLabelMap; 
    }
}
/**
 * This class exists exclusively to provide testing coverage for the Email Template List LWC.
 * It should not be used in any other contexts.
 * It generates a creates an email template and email configuration record to display in a table 
 */
@isTest
public with sharing class LwcHelperEmailTemplateListTest {
    
    @isTest
    static void createTemplates() {
        Folder tempFolder = [SELECT Id, Name, Type, DeveloperName FROM Folder WHERE DeveloperName = 'FreeFormEmails' LIMIT 1];
        System.debug(tempFolder);
        
        User currentUser = [ SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        
            EmailTemplate emailTemp = new EmailTemplate();
            emailTemp.Name = 'Test';
            emailTemp.FolderId = UserInfo.getUserId();
            emailTemp.Description = 'This is test template';
            //emailTemp.UiType = 'SFX';
        	emailTemp.TemplateType = 'custom';
        	emailTemp.Encoding = 'UTF-8';
        	emailTemp.IsActive = true;
            emailTemp.DeveloperName = 'unique_Test12345';
            emailTemp.TemplateType = 'text';
            System.runAs(currentUser) {
            insert emailTemp;

            EmailConfiguration__c emailConfig = new EmailConfiguration__c();
            emailConfig.Name = 'unique_Test12345';
            emailConfig.DeveloperName__c = 'unique_Test12345';
            emailConfig.ClientsAddressed__c = 'All';
            emailConfig.CustomPermission__c = 'TestPermission';
            emailConfig.Description__c = 'Test';
            emailConfig.ReviewAtTaxYearEnd__c = 'Yes';
            emailConfig.GoogleDriveTemplateUrl__c = 'https://drive.google.com';
            emailConfig.Necessity__c = 'Optional';
            emailConfig.Type__c = 'Service';
            emailConfig.From__c = 'amy@novawm.com';

            insert emailConfig;
        }
        
        EmailTemplate et = [SELECT Id FROM EmailTemplate WHERE DeveloperName = 'unique_Test12345' LIMIT 1];
        LwcHelperDynamicRecordList.DataWrapper data = LwcHelperEmailTemplateList.getTemplateData(et.Id);     
        System.AssertEquals(1, data.rows.size());
    }
}
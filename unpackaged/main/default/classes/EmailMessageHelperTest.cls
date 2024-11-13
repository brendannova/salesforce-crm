@isTest
private class EmailMessageHelperTest {
   
    @testSetup
    static void setup() {

        // set up user and permissions
        User currentUser = [ SELECT Id FROM User WHERE Id = :UserInfo.getUserId() ];
        PermissionSet ps = new PermissionSet(
            Name = 'Test', 
            Label = 'Test'
        );
        System.runAs ( currentUser ) {
            insert ps;
        }
        CustomPermission cp = [SELECT Id, DeveloperName FROM CustomPermission WHERE IsLicensed = false AND IsProtected = false AND NamespacePrefix = null LIMIT 1];
        SetupEntityAccess sea = new SetupEntityAccess(
            ParentId = ps.Id, 
            SetupEntityId = cp.Id
        );
        System.runAs ( currentUser ) {
            insert sea;
        }
        
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = currentUser.Id,
            PermissionSetId = ps.Id
        );
        System.runAs ( currentUser ) {
            insert psa;
        }

        // Create email templates and email configuration records
        OrgWideEmailAddress fromEmail = [SELECT Id, Address FROM OrgWideEmailAddress ORDER BY Address ASC LIMIT 1];
        List<EmailTemplate> testEmailTemplates = new List<EmailTemplate>();
        List<EmailConfiguration__c> emailConfigRecords = new List<EmailConfiguration__c>();
        List<Account> accs = new List<Account>();
        testEmailTemplates.add(new EmailTemplate(
            isActive = true, 
            Name = 'STARTER_EMAIL', 
            DeveloperName = 'STARTER_EMAIL', 
            TemplateType = 'text', 
            FolderId = UserInfo.getUserId() // fix this line, not right
        )); 
        emailConfigRecords.add(new EmailConfiguration__c(
            Name = 'STARTER_EMAIL', 
            DeveloperName__c = 'STARTER_EMAIL',
            ClientsAddressed__c = 'All', 
            CustomPermission__c = cp.DeveloperName,
            Description__c = 'Test',
            From__c = fromEmail.Address,
            PartnerCopied__c = 'Always',
            Type__c = 'Service',
            Necessity__c = 'Required'
        ));
        testEmailTemplates.add(new EmailTemplate(
            isActive = true, 
            Name = 'WRONG_PERMISSION', 
            DeveloperName = 'WRONG_PERMISSION', 
            TemplateType = 'text', 
            FolderId = UserInfo.getUserId() // fix this line, not right
        )); 
        emailConfigRecords.add(new EmailConfiguration__c(
            Name = 'WRONG_PERMISSION', 
            DeveloperName__c = 'WRONG_PERMISSION',
            ClientsAddressed__c = 'All', 
            CustomPermission__c = 'NonExistentPermission',
            Description__c = 'Test',
            From__c = fromEmail.Address,
            PartnerCopied__c = 'Always',
            Type__c = 'Service',
            Necessity__c = 'Required'
        ));
        testEmailTemplates.add(new EmailTemplate(
            isActive = true, 
            Name = 'TEMPLATE_NO_EMAIL_CONFIG', 
            DeveloperName = 'TEMPLATE_NO_EMAIL_CONFIG', 
            TemplateType = 'text', 
            FolderId = UserInfo.getUserId() // fix this line, not right
        )); 
        testEmailTemplates.add(new EmailTemplate(
            isActive = true, 
            Name = 'CC_PARTNER_NEVER', 
            DeveloperName = 'CC_PARTNER_NEVER', 
            TemplateType = 'text', 
            FolderId = UserInfo.getUserId() // fix this line, not right
        )); 
        emailConfigRecords.add(new EmailConfiguration__c(
            Name = 'CC_PARTNER_NEVER', 
            DeveloperName__c = 'CC_PARTNER_NEVER',
            ClientsAddressed__c = 'All', 
            CustomPermission__c = cp.DeveloperName,
            Description__c = 'Test',
            From__c = fromEmail.Address,
            PartnerCopied__c = 'NEVER',
            Type__c = 'Service',
            Necessity__c = 'Required'
        ));
        testEmailTemplates.add(new EmailTemplate(
            isActive = true, 
            Name = 'CC_PARTNER_OPTIONAL', 
            DeveloperName = 'CC_PARTNER_OPTIONAL', 
            TemplateType = 'text', 
            FolderId = UserInfo.getUserId() // fix this line, not right
        )); 
        emailConfigRecords.add(new EmailConfiguration__c(
            Name = 'CC_PARTNER_OPTIONAL', 
            DeveloperName__c = 'CC_PARTNER_OPTIONAL',
            ClientsAddressed__c = 'All', 
            CustomPermission__c = cp.DeveloperName,
            Description__c = 'Test',
            From__c = fromEmail.Address,
            PartnerCopied__c = 'Optional',
            Type__c = 'Service',
            Necessity__c = 'Required'
        ));
        DataFactoryAccountHousehold dfah = new DataFactoryAccountHousehold();
        dfah.createHousehold('EmailMessageHelperTestHousehold', 1, 0, 'Active', 'Full');
        // EmailRecipientValidationBypass__c = true
        // accs.add(new Account(FirstName = 'EmailMessageHelperTestPerson', LastName = 'EmailMessageHelperTest', PersonEmail = 'urmum@urmum.com', RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId()));
        System.runAs ( currentUser ) {
            insert testEmailTemplates;
            insert emailConfigRecords;
        }
    }

    @isTest
    static void sendEmail_noTemplate_blocked(){
        Account acc = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailMessageHelperTestHousehold'];
        EmailMessage message = new EmailMessage(
            FromAddress = 'test@test.com',
            ToAddress = 'test@test.com',
            Subject = 'Test',
            TextBody = 'Testing',
            Incoming = false,
            RelatedToId = acc.Id
        );
        try{
            insert message;
        }  catch (DmlException e) {
            System.Assert.isTrue(e.getMessage().contains(System.Label.EmailTriggerNoTemplate), 'Allowed to insert email without a template');
        }
    }

    @isTest
    static void sendEmail_noEmailConfiguration_blocked(){
        String devName = 'TEMPLATE_NO_EMAIL_CONFIG';
        Id emailTemplateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :devName].Id;
        Account acc = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailMessageHelperTestHousehold'];
        EmailMessage message = new EmailMessage(
            FromAddress = 'test@test.com',
            ToAddress = 'test@test.com',
            Subject = 'Test',
            TextBody = 'Testing',
            Incoming = false,
            RelatedToId = acc.Id,
            EmailTemplateId = emailTemplateId
        );
        try{
            insert message;
        }  catch (DmlException e) {
            System.Assert.isTrue(e.getMessage().contains(System.Label.EmailTriggerNoConfig), 'Allowed to insert email with template that has no associated email configuration record');
        }
    }

    @isTest
    static void sendEmail_invalidPermission_blocked(){
        String devName = 'WRONG_PERMISSION';
        Id emailTemplateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :devName].Id;
        OrgWideEmailAddress fromEmail = [SELECT Id, Address FROM OrgWideEmailAddress ORDER BY Address ASC LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailMessageHelperTestHousehold'];
        EmailMessage message = new EmailMessage(
            FromAddress = fromEmail.Address,
            ToAddress = 'test@test.com',
            Subject = 'Test',
            TextBody = 'Testing',
            Incoming = false,
            RelatedToId = acc.Id,
            EmailTemplateId = emailTemplateId
        );
        try{
            insert message;
        }  catch (DmlException e) {
            System.Assert.isTrue(e.getMessage().contains(System.Label.EmailTriggerNoPermission), 'Permission not restricted');
        }
    }

    //sendEmail_validPermission_allowed

    @isTest
    static void sendEmail_correctFromAddress_permitted(){
        String devName = 'STARTER_EMAIL';
        Id emailTemplateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :devName].Id;
        OrgWideEmailAddress fromEmail = [SELECT Id, Address FROM OrgWideEmailAddress ORDER BY Address ASC LIMIT 1];
        Account acc = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailMessageHelperTestHousehold'];
        EmailMessage message = new EmailMessage(
            FromAddress = fromEmail.Address,
            ToAddress = 'test@test.com',
            Subject = 'Test',
            TextBody = 'Testing',
            Incoming = false,
            RelatedToId = acc.Id,
            EmailTemplateId = emailTemplateId
        );
        try{
            insert message;
            System.assertEquals(Schema.EmailMessage.SObjectType, message.Id.getSobjectType(), 'Message failed to insert');
        }  catch (DmlException e) {
            System.debug(e);
        }
    }

    @isTest
    static void sendEmail_incorrectFromAddress_blocked(){
        String devName = 'STARTER_EMAIL';
        Id emailTemplateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :devName].Id;
        Account acc = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailMessageHelperTestHousehold'];
        OrgWideEmailAddress fromEmail = [SELECT Id, Address FROM OrgWideEmailAddress ORDER BY Address ASC LIMIT 1];
        EmailMessage message = new EmailMessage(
            FromAddress = 'test@test.com',
            ToAddress = 'test@test.com',
            Subject = 'Test',
            TextBody = 'Testing',
            Incoming = false,
            RelatedToId = acc.Id,
            EmailTemplateId = emailTemplateId
        );
        try{
            insert message;
        }  catch (DmlException e) {
            System.Assert.isTrue(e.getMessage().contains(System.Label.EmailTriggerFrom + ' ' + fromEmail.Address));
        }
    }

    @isTest
    static void sendEmail_bccIncluded_blocked(){
        String devName = 'STARTER_EMAIL';
        Id emailTemplateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :devName].Id;
        Account acc = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailMessageHelperTestHousehold'];
        OrgWideEmailAddress fromEmail = [SELECT Id, Address FROM OrgWideEmailAddress ORDER BY Address ASC LIMIT 1];
        EmailMessage message = new EmailMessage(
            FromAddress = 'test@test.com',
            ToAddress = 'test@test.com',
            Subject = 'Test',
            TextBody = 'Testing',
            Incoming = false,
            RelatedToId = acc.Id,
            BccAddress = 'test@test.com',
            EmailTemplateId = emailTemplateId
        );
        try{
            insert message;
        }  catch (DmlException e) {
            System.Assert.isTrue(e.getMessage().contains(System.Label.EmailTriggerNoBcc));
        }
    }

    @isTest
    static void sendEmail_ccNonPartner_blocked(){
        String devName = 'STARTER_EMAIL';
        Id emailTemplateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :devName].Id;
        Account acc = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailMessageHelperTestHousehold'];
        OrgWideEmailAddress fromEmail = [SELECT Id, Address FROM OrgWideEmailAddress ORDER BY Address ASC LIMIT 1];
        EmailMessage message = new EmailMessage(
            FromAddress = 'test@test.com',
            ToAddress = 'test@test.com',
            Subject = 'Test',
            TextBody = 'Testing',
            Incoming = false,
            RelatedToId = acc.Id,
            CcAddress = 'test@test.com',
            EmailTemplateId = emailTemplateId
        );
        try{
            insert message;
        }  catch (DmlException e) {
            System.Assert.isTrue(e.getMessage().contains(System.Label.EmailTriggerCcPartnerOnly));
        }
    }   

    @isTest
    static void sendEmail_ccDoesNotIncludePartner_blocked(){
        String devName = 'STARTER_EMAIL';
        Id emailTemplateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :devName].Id;
        Account acc = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailMessageHelperTestHousehold'];
        OrgWideEmailAddress fromEmail = [SELECT Id, Address FROM OrgWideEmailAddress ORDER BY Address ASC LIMIT 1];
        EmailMessage message = new EmailMessage(
            FromAddress = 'test@test.com',
            ToAddress = 'test@test.com',
            Subject = 'Test',
            TextBody = 'Testing',
            Incoming = false,
            RelatedToId = acc.Id,
            EmailTemplateId = emailTemplateId
        );
        try{
            insert message;
        }  catch (DmlException e) {
            System.Assert.isTrue(e.getMessage().contains(System.Label.EmailTriggerCcPartner));
        }
    }   

    @isTest
    static void sendEmail_ccPartnerNeverButIncluded_blocked(){
        String devName = 'CC_PARTNER_NEVER';
        Id emailTemplateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :devName].Id;
        Account acc = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailMessageHelperTestHousehold'];
        OrgWideEmailAddress fromEmail = [SELECT Id, Address FROM OrgWideEmailAddress ORDER BY Address ASC LIMIT 1];
        EmailMessage message = new EmailMessage(
            FromAddress = 'test@test.com',
            ToAddress = 'test@test.com',
            Subject = 'Test',
            TextBody = 'Testing',
            Incoming = false,
            RelatedToId = acc.Id,
            CcAddress = UserInfo.getUserEmail(),
            EmailTemplateId = emailTemplateId
        );
        try{
            insert message;
        }  catch (DmlException e) {
            System.Assert.isTrue(e.getMessage().contains(System.Label.EmailTriggerCcMustBeBlank));
        }
    }   

    @isTest
    static void sendEmail_ccPartnerOptionalExtraIncluded_blocked(){
        String devName = 'CC_PARTNER_OPTIONAL';
        Id emailTemplateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :devName].Id;
        Account acc = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailMessageHelperTestHousehold'];
        OrgWideEmailAddress fromEmail = [SELECT Id, Address FROM OrgWideEmailAddress ORDER BY Address ASC LIMIT 1];
        EmailMessage message = new EmailMessage(
            FromAddress = 'test@test.com',
            ToAddress = 'test@test.com',
            Subject = 'Test',
            TextBody = 'Testing',
            Incoming = false,
            RelatedToId = acc.Id,
            CcAddress = UserInfo.getUserEmail() + ',test@test.com',
            EmailTemplateId = emailTemplateId
        );
        try{
            insert message;
        }  catch (DmlException e) {
            System.Assert.isTrue(e.getMessage().contains(System.Label.EmailTriggerCcPartnerOnly));
        }
    }

    @isTest
    static void sendEmail_bypassValidation_passed(){
        String devName = 'STARTER_EMAIL';
        Id emailTemplateId = [SELECT Id FROM EmailTemplate WHERE DeveloperName = :devName].Id;
        Account acc = [SELECT Id FROM Account WHERE OW_admin_notes__c = 'EmailMessageHelperTestHousehold'];
        acc.EmailRecipientValidationBypass__c = true;
        update acc;
        OrgWideEmailAddress fromEmail = [SELECT Id, Address FROM OrgWideEmailAddress ORDER BY Address ASC LIMIT 1];
        EmailMessage message = new EmailMessage(
            FromAddress = fromEmail.Address,
            ToAddress = 'test@test.com,test2@test.com',
            BccAddress = 'test@test.com',
            Subject = 'Test',
            TextBody = 'Testing',
            Incoming = false,
            RelatedToId = acc.Id,
            CcAddress = UserInfo.getUserEmail() + ',test@test.com',
            EmailTemplateId = emailTemplateId
        );
        try{
            insert message;
        }  catch (DmlException e) {
            System.debug(e);
        }
        System.assertEquals(Schema.EmailMessage.SObjectType, message.Id.getSobjectType(), 'Message failed to insert');
        acc = [SELECT Id, EmailRecipientValidationBypass__c FROM Account WHERE OW_admin_notes__c = 'EmailMessageHelperTestHousehold'];
        System.assertEquals(acc.EmailRecipientValidationBypass__c, false, 'Bypass not reset to false');
    }   
}
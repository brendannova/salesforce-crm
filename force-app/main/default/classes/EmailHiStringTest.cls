@isTest
public class EmailHiStringTest {

    @istest
    static void hiString_generate_successful(){
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
        EmailTemplate et = new EmailTemplate(
            isActive = true, 
            Name = 'STARTER_EMAIL', 
            DeveloperName = 'STARTER_EMAIL', 
            TemplateType = 'text', 
            FolderId = UserInfo.getUserId() // fix this line, not right
        ); 
        EmailConfiguration__c ec = new EmailConfiguration__c(
            Name = 'STARTER_EMAIL', 
            DeveloperName__c = 'STARTER_EMAIL',
            ClientsAddressed__c = 'All', 
            CustomPermission__c = cp.DeveloperName,
            Description__c = 'Test',
            From__c = fromEmail.Address,
            PartnerCopied__c = 'Always',
            Type__c = 'Service',
            Necessity__c = 'Required'
        );
        String identifier = 'EmailMessageHelperTestHousehold';
        Account household = DataFactoryAccountHousehold.createHousehold(identifier, 2, 0, 'Active', 'Full');
        System.runAs ( currentUser ) {
            insert et;
            insert ec;
        }
        EmailHiString hi = new EmailHiString();
        hi.emailTemplateDevName = et.DeveloperName;
        hi.objectIdString = household.Id;
        String output = hi.getHiString();
        List<AccountContactRelation> acrs = [SELECT Contact.FirstName, Contact.FinServ__PreferredName__c FROM AccountContactRelation WHERE AccountId = :household.Id];
        System.debug(acrs.size());
        for(AccountContactRelation acr : acrs){
            if(!String.isBlank(acr.Contact.FinServ__PreferredName__c)){
                System.Assert.isTrue(output.contains(acr.Contact.FinServ__PreferredName__c));
            } else {
                System.Assert.isTrue(output.contains(acr.Contact.FirstName));
            }
        }
        System.assertEquals(true, output.contains(',')); 
    }
}

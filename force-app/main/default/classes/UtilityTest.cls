@isTest
public class UtilityTest {

    @isTest
    static void getObjectLabel_success(){
        FactCategory__c fc = new FactCategory__c(
            Name = 'Test'
        );
        insert fc;
        String objectLabel = Utility.getObjectLabelById(fc.Id);
        System.Assert.areEqual(objectLabel, 'Fact Category', 'Label Task was expected but not returned');
    }

    @isTest
    static void getObjectName_success(){
        FactCategory__c fc = new FactCategory__c(
            Name = 'Test'
        );
        insert fc;
        String objectLabel = Utility.getObjectNameById(fc.Id);
        System.Assert.areEqual(objectLabel, 'FactCategory__c', 'Label Task was expected but not returned');
    }

    @isTest
    static void getRecordTypeId_success(){
        RecordType rt = [SELECT Id, DeveloperName, SObjectType FROM RecordType LIMIT 1];
        Id recordTypeId = Utility.getRecordTypeId(rt.SObjectType, rt.DeveloperName);
        System.Assert.areEqual(recordTypeId, rt.Id, 'Record type ID returned did not match');
    }

    @isTest
    static void getDomain_success(){
        String baseUrl = UrlUtility.getBaseUrl();
        System.assertEquals(baseUrl, System.URL.getOrgDomainURL().toExternalForm());
    }

    @isTest
    static void checkSandbox_success(){
        Boolean isSandbox = Utility.isSandbox;
        System.assert(isSandbox != null, 'Did not determine if this is a sandbox or not');
    }
    
    @isTest
    static void checkSandboxName_success(){
        String sandboxName = Utility.sandboxName;
        if(Utility.isSandbox){
            System.assert(!String.isBlank(sandboxName), 'Expected a sandbox name but blank string returned');
        } else {
            System.assertEquals(null, sandboxName, 'Expected null sandbox name but a value was returned');
        }
        
    }
@IsTest
    static void getOffsetBusinessDate_success(){
        Date startDate = Date.newInstance(2024, 12, 31);
        Integer daysOffset = 3; //over a bank holiday and a weekend
        Date offsetDate = Utility.getOffsetBusinessDate(startDate, daysOffset);
        Date expectedOffsetDate = Date.newInstance(2025, 1, 6);
        Assert.areEqual(expectedOffsetDate, offsetDate , 'Incorrect number of business days offset');
    }
    
    @isTest
    static void getPicklistValues_success(){
        Map<String, String> picklistMap = Utility.getPicklistApiLabelMap('AdviceType__c','ProfileUpdate__c');
        List<Schema.PicklistEntry> picklistItems = AdviceType__c.ProfileUpdate__c.getDescribe().getPicklistValues();
        System.Assert.areEqual(picklistItems.size(), picklistMap.size(), 'Number of ites in the picklist map does not match the number of picklist options.');
    }
    
    @isTest
    static void tagSubstituter_success(){
        String message = '{addressedname}';
        DataFactory df = new DataFactory();
        Id household = df.createHousehold('OW001 Test',2,2,'Onboarding','Full');
        List<AccountContactRelation> acrs = [SELECT 
                                       		 Contact.AccountId, 
                                       		 AccountId, 
                                       		 Roles, 
                                       		 isActive 
                                       		 FROM 
                                       		 AccountContactRelation
                                       		 WHERE 
                                       		 AccountId =: household
                                            ];
        
        List<Id> clients = new List<Id>();
        List<Id> children = new List<Id>();
        
        for(AccountContactRelation acr : acrs) {
            if(acr.Roles.split(';').contains('Client')){
                clients.add(acr.Contact.AccountId);
            } else if(acr.Roles.split(';').contains('Child')) {
                children.add(acr.Contact.AccountId);
            }
        }
        
        Account child = [SELECT Id, AddressedName__pc FROM Account WHERE Id =: children[0]];
        System.debug(message);
        System.debug(child.Id);
        message = Utility.tagSubstituter(message, child.Id, 'Account', 'Account');
        System.Assert.areEqual(child.AddressedName__pc, message, 'Tags have not been processed correctly');
    }

}
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

@IsTest
    static void getOffsetBusinessDate_success(){
        Date startDate = Date.newInstance(2024, 12, 31);
        Integer daysOffset = 3; //over a bank holiday and a weekend
        Date offsetDate = Utility.getOffsetBusinessDate(startDate, daysOffset);
        Date expectedOffsetDate = Date.newInstance(2025, 1, 6);
        Assert.areEqual(expectedOffsetDate, offsetDate , 'Incorrect number of business days offset');
    }

    @isTest
    static void checkSandbox_success(){
        Boolean isSandbox;
        isSandbox = Utility.checkSandbox();
        System.assert(isSandbox != null, 'No sandbox check returned');
    }
    
    public static Boolean checkSandbox() {
        return [SELECT IsSandbox FROM Organization LIMIT 1].IsSandbox;
    }
}
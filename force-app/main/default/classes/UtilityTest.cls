@isTest
public class UtilityTest {

    @istest
    static void getObjectLabel_success(){
        FactCategory__c fc = new FactCategory__c(
            Name = 'Test'
        );
        insert fc;
        String objectLabel = Utility.getObjectLabelById(fc.Id);
        System.Assert.areEqual(objectLabel, 'Fact Category', 'Label Task was expected but not returned');
    }

    @istest
    static void getObjectName_success(){
        FactCategory__c fc = new FactCategory__c(
            Name = 'Test'
        );
        insert fc;
        String objectLabel = Utility.getObjectNameById(fc.Id);
        System.Assert.areEqual(objectLabel, 'FactCategory__c', 'Label Task was expected but not returned');
    }

    @istest
    static void getRecordTypeId_success(){
        RecordType rt = [SELECT Id, DeveloperName, SObjectType FROM RecordType LIMIT 1];
        Id recordTypeId = Utility.getRecordTypeId(rt.SObjectType, rt.DeveloperName);
        System.Assert.areEqual(recordTypeId, rt.Id, 'Record type ID returned did not match');
    }

    @istest
    static void getDomain_success(){
        String baseUrl = UrlUtility.getBaseUrl();
        System.assertEquals(baseUrl, System.URL.getOrgDomainURL().toExternalForm());
    }
}
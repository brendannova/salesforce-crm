@isTest
public with sharing class AuditLogEntryTest {

    // Create an account whose access will be audited
    @testSetup static void setup() {
        TestDataFactory.createHousehold(1, 0, 'AUDIT_LOG_TEST');
    }

    // Run test with expectation of creating audit log
    @istest
    static void testCreateAudit() {
        List<Account> accs = [SELECT Id FROM Account WHERE AccountNumber = 'AUDIT_LOG_TEST'];
        AuditLogEntry.createAuditLogEntry(accs[0].Id, 'Account', false);
        List<AuditLogEntry__c> ales = [SELECT Id, RecordId__c, RecordObject__c, UserId__c FROM AuditLogEntry__c WHERE RecordId__c = :accs[0].Id];
        System.assertEquals(ales.size(), 1);
        System.assertEquals(ales[0].RecordObject__c, 'Account');
        System.assertEquals(ales[0].UserId__c, UserInfo.getUserId());
    }

    // Run test with expectation of skipping audit log creation
    @istest
    static void testSkipAudit() {
        List<Account> accs = [SELECT Id FROM Account WHERE AccountNumber = 'AUDIT_LOG_TEST'];
        AuditLogEntry.createAuditLogEntry(accs[0].Id, 'Account', true);
        List<AuditLogEntry__c> ales = [SELECT Id, RecordId__c, RecordObject__c, UserId__c FROM AuditLogEntry__c WHERE RecordId__c = :accs[0].Id];
        System.assertEquals(ales.size(), 0);
    }

    // Run test with expectation of failure due to no record ID or object name
    @istest
    static void testAuditError() {
        List<Account> accs = [SELECT Id FROM Account WHERE AccountNumber = 'AUDIT_LOG_TEST'];
        AuditLogEntry.createAuditLogEntry('', '', false);
        List<AuditLogEntry__c> ales = [SELECT Id, RecordId__c, RecordObject__c, UserId__c FROM AuditLogEntry__c WHERE RecordId__c = :accs[0].Id];
        System.assertEquals(ales.size(), 0);
    }
}
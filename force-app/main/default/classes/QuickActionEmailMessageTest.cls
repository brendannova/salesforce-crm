/*
 * Test method for QuickActionEmailMessage class
 * Test setup will create an account with 2 household and a new case record
 * Test methods will instantiate the custom case quick action and ensure the correct To recipients are returned.
 * Test methods test a household with 2 clients, and a case with no linked household
 */
@isTest
public class QuickActionEmailMessageTest {
    
    @testSetup
    static void setup () {
        List<Account> testAccounts = TestDataFactory.createHousehold(2,0,'1237');
        Id householdRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('IndustriesHousehold').getRecordTypeId();
        Id personRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Account household = [SELECT Id FROM Account WHERE RecordTypeId =: householdRT AND AccountNumber = '1237'];
        List<Account> people = [SELECT Id, PersonEmail FROM Account WHERE AccountNumber = '1237' AND RecordTypeId =: personRT];
        for(Integer i=0; i < people.size(); i++) {
            Account p = people.get(i);
            p.PersonEmail = 'owemailtest2108+' + i + '@gmail.com';
        }
        update people;
        Id emailRT = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Email').getRecordTypeId();
        Case testCase = new Case();
        testCase.Subject = 'Test Case';
        testCase.RecordTypeId = emailRT;
        testCase.AccountId = household.Id;
        Insert testCase;
    }
    
    @isTest
    static void quickAction_TwoPersonHousehold () {
        
        Id personRT = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId();
        Case c = [SELECT Id FROM Case WHERE Subject = 'Test Case'];    
        List<Map<String, Object>> defaultSettingString = new List<Map<String, Object>> { //Create a map of SendEmailQuickAction properties to execute the correct quick action
  			new Map<String, Object> {
        		'targetSObject' => new EmailMessage(),
        		'contextId' => c.Id,
        		'actionType' => 'SendEmail',
        		'actionName' => 'Case.SendEmailBeta'
  			}
		};
        List<QuickAction.SendEmailQuickActionDefaults> defaultsSettings = (List<QuickAction.SendEmailQuickActionDefaults>)JSON.deserialize(JSON.serialize(defaultSettingString), List<QuickAction.SendEmailQuickActionDefaults>.class);
    	Test.startTest();
		(new QuickActionEmailMessage()).onInitDefaults(defaultsSettings); 
    	Test.stopTest();

        EmailMessage emailMessageRecord = (EmailMessage)defaultsSettings.get(0).getTargetSObject();
        
        List<Account> people = [SELECT Id, PersonEmail FROM Account WHERE AccountNumber = '1237' AND RecordTypeId =: personRT];
        String ToAddresses;
        for(Integer i = 0; i < people.size(); i++) {
            if(i == 0) {
                ToAddresses = people.get(i).PersonEmail;
            } else {
                ToAddresses = ToAddresses + ';' + people.get(i).PersonEmail;
            } 
        }
        System.AssertEquals(ToAddresses, emailMessageRecord.ToAddress);
    }
    
    @isTest    
    static void quickAction_NoHousehold () {
        
        Case c = [SELECT Id FROM Case WHERE Subject = 'Test Case'];
        c.AccountId = null;
        update c;
        List<Map<String, Object>> defaultSettingString = new List<Map<String, Object>> { //Create a map of SendEmailQuickAction properties to execute the correct quick action
  			new Map<String, Object> {
        		'targetSObject' => new EmailMessage(),
        		'contextId' => c.Id,
        		'actionType' => 'SendEmail',
        		'actionName' => 'Case.SendEmailBeta'
  			}
		};
        List<QuickAction.SendEmailQuickActionDefaults> defaultsSettings = (List<QuickAction.SendEmailQuickActionDefaults>)JSON.deserialize(JSON.serialize(defaultSettingString), List<QuickAction.SendEmailQuickActionDefaults>.class);
    	Test.startTest();
		(new QuickActionEmailMessage()).onInitDefaults(defaultsSettings); 
    	Test.stopTest();

        EmailMessage emailMessageRecord = (EmailMessage)defaultsSettings.get(0).getTargetSObject();
        System.AssertEquals(null, emailMessageRecord.ToAddress);
    }
}
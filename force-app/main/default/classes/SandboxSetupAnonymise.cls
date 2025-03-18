public with sharing class SandboxSetupAnonymise implements Database.Batchable<sObject> {

    final private static String NATIONAL_INSURANCE_NUMBER = 'QQ123456A';

    private Boolean isSandbox;

    public SandboxSetupAnonymise(){
        isSandbox = Utility.checkSandbox();        
        if(isSandbox){
            this.isSandbox = true;
        } else {
            throw new SandboxSetupException('Cannot be run in production'); 
        }
    }
    
    // Query all person accounts in the system
    public Database.QueryLocator start(Database.BatchableContext bc) {
        return Database.getQueryLocator('SELECT Id FROM Account WHERE IsPersonAccount = true');
    }

    // Anonymise then update the person accounts
    public void execute(Database.BatchableContext bc, List<Account> people) {
        for(Account person : people) {
            person.PersonEmail = null;
            person.Phone = null;
            person.PersonMobilePhone = null;
            person.Secondary_Email__pc = null;
            person.National_Insurance_Number__pc = NATIONAL_INSURANCE_NUMBER;
            DataFactoryNameGenerator fakeNameClass = new DataFactoryNameGenerator();
            DataFactoryNameGenerator.RandomName fakeName = fakeNameClass.generateName(true, true, true);
            person.FirstName = fakeName.firstName;
            person.LastName = fakeName.lastName;
            person.FinServ__PreferredName__pc = fakeName.preferredName;
            person.OW_portal_activated__c = null;
            person.PortalAccountStatus__c = null;
        }
        update people;
    }
    
    public void finish(Database.BatchableContext bc) {
    }

    public class SandboxSetupException extends Exception {
    }
}
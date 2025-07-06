@isTest
public with sharing class DataFactoryAccountHouseholdTest {

    @isTest
    static void createHousehold(){
        String reference = 'TEST_CLASS';
        Integer NUM_CLIENTS = 2;
        Integer NUM_CHILDREN = 3;
        String RecordTypeDevNameHousehold = 'IndustriesHousehold';
        String RecordTypeDevNamePerson = 'PersonAccount';
        String CLIENT_STATUS = 'Active';
        String FACT_FIND_TYPE = 'Full';
        Account household = DataFactoryAccountHousehold.createHousehold(reference, NUM_CLIENTS, NUM_CHILDREN, CLIENT_STATUS, FACT_FIND_TYPE);
        List<Account> accounts = [SELECT Id, FinServ__Status__c, Fact_Find_Type__c, OW_admin_notes__c, RecordType.DeveloperName FROM Account ORDER BY OW_admin_notes__c];
        System.debug(accounts.size());
        System.debug(accounts);
        List<Account> households = new List<Account>();
        List<Account> clients = new List<Account>();
        List<Account> children = new List<Account>();
        
        for(Account acc : accounts){
            if (acc.OW_admin_notes__c.contains('-client-')) {
                clients.add(acc);
            } else if (acc.OW_admin_notes__c.contains('-child-')) {
                children.add(acc);
            } else if (acc.RecordType.DeveloperName == RecordTypeDevNameHousehold){
                households.add(acc);
            }
        }
        List<AccountContactRelation> acrs = [SELECT Id, Roles FROM AccountContactRelation WHERE AccountId = :household.Id];
        List<AccountContactRelation> acrsClients = new List<AccountContactRelation>();
        List<AccountContactRelation> acrsChildren = new List<AccountContactRelation>();
        for(AccountContactRelation acr : acrs){
            if (acr.Roles == 'Client'){
                acrsClients.add(acr);
            } else if (acr.Roles == 'Child'){
                acrsChildren.add(acr);
            }
        }
        System.assertEquals(1, households.size(), 'No household found');
        System.assertEquals(CLIENT_STATUS, households[0].FinServ__Status__c, 'Status incorrect');
        System.assertEquals(FACT_FIND_TYPE, households[0].Fact_Find_Type__c,  'Fact find type incorrect');
        System.assertEquals(NUM_CLIENTS, clients.size(),  'Incorrect number of clients');
        System.assertEquals(NUM_CHILDREN, children.size(), 'Incorrect number of children');
        System.assertEquals(NUM_CLIENTS + NUM_CHILDREN, acrs.size(), 'Incorrect number of relationships');
        System.assertEquals(NUM_CLIENTS, acrsClients.size(), 'Incorrect number of client relationships');
        System.assertEquals(NUM_CHILDREN, acrsChildren.size(), 'Incorrect number of children relationships');
    }
}
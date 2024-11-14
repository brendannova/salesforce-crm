@isTest(SeeAllData=true)
public class fake_data_factory_v2_test {
    
	/**
	* TITLE:	Create test household test class
	* GOAL:		Test the creation of a test household
	* NOTES: 	SeeAllData is true so that task information records are visible
	**/
    
    @istest
    static void test_household_creation(){
        Integer num_clients = 2;
        Integer num_children = 3;
        String status = 'Active';
        String identifier = 'cth_test_run';
        String profile_type = 'Full'; 
        fake_data_factory_v2 cth = new fake_data_factory_v2();
        String household_id = cth.create_household(identifier, num_clients, num_children, status, profile_type);
        
        Account[] accounts = [SELECT Id FROM Account WHERE FinServ__Status__c =: status and utm_medium__c =: identifier];
        AccountContactRelation[] acrs = [SELECT Id, Roles FROM AccountContactRelation WHERE FinServ__SourceSystemId__c =: identifier];
        
        System.assert(num_clients + num_children + 1 == accounts.size()); // Check that there is an account for the household and each client and child. 
        
        // Check that there is a relationship for each client and child.
        Integer num_child_relationships = 0;
        Integer num_client_relationships = 0;      
        for(AccountContactRelation acr : acrs){
            if(acr.Roles == 'Client'){
                num_client_relationships++;
            } else if(acr.Roles == 'Child'){
                num_child_relationships++;
            }
        }
        System.assert(num_child_relationships == num_children); 
        System.assert(num_client_relationships == num_clients);
    }
    
    @istest
    static void test_advice_creation(){
        Integer num_clients = 2;
        Integer num_products = 1;
        Integer num_children = 0;
        String status = 'Active';
        String identifier = 'cth_test_run_advice';
        String profile_type = 'Full'; 
        fake_data_factory_v2 cth = new fake_data_factory_v2();
        Id household_id = cth.create_household(identifier, num_clients, num_children, status, profile_type);
        Advice__c advice = cth.create_advice(identifier, num_products, household_id);
        
        // Get the financial products and LOAs back
        FinServ__FinancialAccount__c[] financial_products = [SELECT Id FROM FinServ__FinancialAccount__c WHERE Household__c =: household_id];
        LOA__c[] loas = [SELECT Id FROM LOA__c WHERE Household_Lookup__c =: household_id];
        
        //System.assert(num_clients * num_products + 1 == financial_products.size()); // Check that there is a financial product for each client plus a joint product
        System.assert(num_clients * num_products + 1 == loas.size()); // Check that there is an LOA for each client plus a joint product
    }
}
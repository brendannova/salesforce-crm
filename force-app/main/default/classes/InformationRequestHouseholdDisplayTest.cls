@isTest
public class InformationRequestHouseholdDisplayTest {
    @istest
    static void test_household_creation(){
        Integer num_clients = 1;
        Integer num_products = 1;
        Integer num_children = 0;
        String status = 'Active';
        String identifier = 'cth_test_run_advice';
        String profile_type = 'Full'; 
        fake_data_factory_v2 cth = new fake_data_factory_v2();
        Id household_id = cth.create_household(identifier, num_clients, num_children, status, profile_type);
        Advice__c advice = cth.create_advice(identifier, num_products, household_id);

        InformationRequestHouseholdDisplay irhd = new InformationRequestHouseholdDisplay();
       	List<Map<String, String>> outputs = irhd.getOutputs(household_id);
        System.assert(outputs.size() == 1);
    }

}
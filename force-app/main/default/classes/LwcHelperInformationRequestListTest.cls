/**
 * This class exists exclusively to provide testing coverage for the Information Request Related List for households LWC.
 * It should not be used in any other contexts.
 * It generates a household with some information requests and compares the outputted formatted data from those information requests. 
 */
@isTest
public class LwcHelperInformationRequestListTest {
	 
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

       	List<Map<String, String>> data = LwcHelperInformationRequestList.getData(household_id);
        System.Assert.areEqual(1, data.size(), 'Expected 1 row');
    }
}
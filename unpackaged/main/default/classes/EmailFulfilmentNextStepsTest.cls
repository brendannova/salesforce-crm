@isTest(SeeAllData=true)
global class EmailFulfilmentNextStepsTest{
    
    @istest
    static void test_table_data(){
        // Define and create test data for 2 clients and 2 children
        Integer numClients = 2;
        Integer numChildren = 2;
        String household_status = 'Active';
        String household_identifier = '2clients2child'; 
        String profile_type = 'Full'; 
        FakeDataGenerata fdg = new FakeDataGenerata();
        Id household_id = fdg.createHousehold(household_identifier, numClients, numChildren, household_status, profile_type);
        Id adviceId = fdg.createAdvice(household_identifier, household_id, 'Deck complete');
        Map<String, String> productTypes = new Map<String, String>();
        productTypes.put('Stocks & Shares ISA', 'FP_Stocks_Shares_ISA');
        productTypes.put('General Investment Account', 'FP_General_Investment_Account_GIA');
        productTypes.put('Defined Contribution', 'FP_SIPP');
        fdg.createProducts(household_id, productTypes);
        Map<String, String> recTypes = new Map<String, String>();
        recTypes.put('LUMP_SUM', 'Client');
        recTypes.put('CANCEL_EXISTING_REGULAR', 'Client');
        recTypes.put('UPDATE_EOW', 'Client');
        recTypes.put('CLIENT_ACTION', 'Client');
        recTypes.put('REGULAR', 'Employer');
        recTypes.put('EXTERNAL_TRANSFER_IN', '');
        List<String> products = new List<String>();
        products.add('SIPP_HUBWISE');
        products.add('SSISA_HUBWISE');
        fdg.createRecommendations(recTypes, products, adviceId, household_id);
        
        // Call the classes to run the code and ensure everything generates
        system.currentPageReference().getParameters().put('objectId', adviceId); 
		EmailFulfilmentNextSteps ns = new EmailFulfilmentNextSteps();
        ns.EmailFulfilmentNextStepsTableGroupedConstructor();
        ns.getEmailCategories();
        ns.getCategoryActionMap();
        ns.getBankDetails();
        ns.getTransfers();
        ns.getnewProds();
        ns.getLumpSum();
        ns.getcashIsaTransfers();
        ns.getSipps();
        ns.getemployerReg();
        ns.getemployerBank();
        ns.getcancelReg();
        ns.geteow();
        ns.getOthers();
        ns.getAcceptanceString();
        System.assertEquals(ns.objectId, adviceId); 
    } 

}
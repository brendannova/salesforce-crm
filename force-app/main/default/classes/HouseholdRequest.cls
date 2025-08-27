public class HouseholdRequest {
        @AuraEnabled public String id;
        @AuraEnabled public String name;
        @AuraEnabled public String status;

        //display only - contains values from formula or relationships
        @AuraEnabled public String specialistName; // This will hold the flattened lookup value (User's Name)
}
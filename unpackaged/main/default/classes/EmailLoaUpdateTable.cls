public class EmailLoaUpdateTable {
    
    // Create the variables that are needed throughout this flow or returned to the Visualforce component
    String EMAIL_TYPE = 'LOA';
    public List<owner> owner_list = new List<owner>(); 
    public map<String, List<loa_update>> owner_loa_map = new map<String, List<loa_update>>();
    public String adviceId{get;set;} 
    
    // Method for the visualforce component to call to get a list of the owners
    public List<owner> getOwners() {
        if(String.isBlank(adviceId)){
            adviceId = ApexPages.currentPage().getParameters().get('adviceId');                
        }
        if(String.isNotBlank(adviceId)){
            
            // Get details of the advice, primarily to identify the household
            Advice__c adv = [SELECT Advice_Household__c FROM Advice__c WHERE Id =: adviceId];
            
            // Create list of excluded statuses and maps of the email content for different LOA statuses
            List<OW_email_update_setting__mdt> settings = [SELECT OW_display_status__c, OW_record_status__c, OW_message__c, OW_action__c FROM OW_email_update_setting__mdt WHERE OW_email_type__c =: EMAIL_TYPE];
            Map<String, String> status_map = new Map<String, String>();
            Map<String, String> message_map = new Map<String, String>();
            List<String> excluded_statuses = new List<String>();
            for(OW_email_update_setting__mdt setting : settings){
                if( setting.OW_action__c == 'Include' ){
                    status_map.put(setting.OW_record_status__c, setting.OW_display_status__c);
                    message_map.put(setting.OW_record_status__c, setting.OW_message__c);
                } else if ( setting.OW_action__c == 'Exclude' ){
                    excluded_statuses.add(setting.OW_record_status__c);
                }
            }
            
            // Get list of fields to return with the LOA query and any substitution tags.
            List<OW_query_field__mdt > query_settings = [SELECT OW_tag__c, OW_field__c FROM OW_query_field__mdt WHERE EmailType__c =:  EMAIL_TYPE];
            Map<String, String> substitution_map = new Map<String, String>();
            Set<String> query_fields_set = new Set<String>(); // Use a set initially to ensure there are no duplicate values
            for(OW_query_field__mdt  query_setting : query_settings){
                query_fields_set.add(query_setting.OW_field__c);
                if( !String.isBlank(query_setting.OW_tag__c)){
                    substitution_map.put(query_setting.OW_tag__c, query_setting.OW_field__c);
                }
            }
            List<String> query_fields_list = new List<String>(query_fields_set); // Convert from set to list to allow String.join method to be used
            String query_fields_string = String.join(query_fields_list, ',');
            
            // Return a list of the LOAs requiring an update
            List<LOA_to_Advice__c> loas  = Database.query('SELECT ' + query_fields_string + ' FROM LOA_to_Advice__c WHERE Advice__c =: adviceId AND LOA__r.Exclude_from_LOA_Updates__c = false AND LOA__r.MainLOAStatus__c NOT IN: excluded_statuses ORDER BY LOA__r.LOA_Financial_Account__r.Public_Provider_Name__r.Name ASC');                        
            
            // Generate the email updates for each LOA
            List<loa_update> loa_updates = new List<loa_update>();
            String owner_id;
            String status;
            String provider;
            String product_type; 
            String message;   
            String substitute_tag;
            String substitute_value;            
            Boolean includes_joint_products = false;
            Map<String, Object> fieldValues = new Map<String, Object>();
            for(LOA_to_Advice__c loa: loas ){
                status = status_map.get(loa.LOA__r.MainLOAStatus__c);
                provider = loa.LOA__r.LOA_Financial_Account__r.Public_Provider_Name__r.Name;
                product_type = loa.LOA__r.LOA_Financial_Account__r.Subtype__c;
                if(loa.LOA__r.LOA_Financial_Account__r.FinServ__Ownership__c == 'Individual'){
                    owner_id = loa.LOA__r.LOA_Financial_Account__r.FinServ__PrimaryOwner__c;
                } else if( loa.LOA__r.LOA_Financial_Account__r.FinServ__Ownership__c == 'Joint' ){
                    owner_id = 'Joint';
                    includes_joint_products = true;
                }
                
                // Construct the LOA update message and substitute {} tags for actual values
                message = message_map.get(loa.LOA__r.MainLOAStatus__c);
                fieldValues = genFieldValueMap(loa.getPopulatedFieldsAsMap(), '');
                Matcher tag_matcher = Pattern.compile('\\{(.*?)\\}').matcher(message);
                while(tag_matcher.find()){
                    substitute_tag = tag_matcher.group();
                    if( fieldValues.get(substitution_map.get(substitute_tag)) instanceOf Date ){  // Format string if a date
                        DateTime date_output = Date.valueOf(fieldValues.get(substitution_map.get(substitute_tag)));
                        substitute_value = date_output.format('d MMMMM yyyy');
                    } else {
                        substitute_value = String.valueOf(fieldValues.get(substitution_map.get(substitute_tag)));
                    }
                    message = message.replace(substitute_tag, substitute_value);
                }
                loa_updates.add(new loa_update(owner_id, status, provider, product_type, message));
            }
            
            // Generate a list of the people in the household using their first or preferred name appropriately and sort
            List<AccountContactRelation> household_members = [SELECT Roles, Contact.AccountId, Contact.Account.FirstName, Contact.Account.FinServ__PreferredName__pc FROM AccountContactRelation WHERE AccountId =: adv.Advice_Household__c];
            String account_id;
            String name;
            String role;
            for( AccountContactRelation household_member : household_members ){
                account_id = household_member.Contact.AccountId;
                role = household_member.Roles;
                if( String.isBlank(household_member.Contact.Account.FinServ__PreferredName__pc) ){
                    name = household_member.Contact.Account.FirstName;
                } else {
                    name = household_member.Contact.Account.FinServ__PreferredName__pc;
                }
                owner_list.add(new owner(account_id, name, role));
            }
            if( includes_joint_products == true ){
                owner_list.add(new owner('Joint', 'Joint', 'Joint'));
            }
            owner_list.sort(); // Uses custom sorting algorithm from comparable owner class
            
            // Loop through household members and LOAs to create a map of owners to LOAs
            Integer j = 0;
            Integer k;
            List<loa_update> loa_updates_temp = new List<loa_update>();            
            while(j < owner_list.size() ){
                k = 0;
                while(k < loa_updates.size() ){
                    if( loa_updates[k].owner_id == owner_list[j].account_id){
                        loa_updates_temp.add(loa_updates[k]);
                        loa_updates.remove(k);
                    } else {
                        k++;
                    }
                }
                if( loa_updates_temp.size() > 0 ){
                    owner_loa_map.put(owner_list[j].account_id, loa_updates_temp);
                    loa_updates_temp = new List<loa_update>();
                    j++;
                } else {
                    owner_list.remove(j);
                }
            }
        }
        return owner_list;
    }
    
    // Method for the visualforce component to call to get the owner to LOA map
    public map<String, List<loa_update>> getOwner_loa_map() {
        return owner_loa_map;
    }
    
    // Owner class implementing comparable so a custom sort order can be used
    public class owner implements Comparable {
        public String account_id {get;set;}
        public String name {get;set;}
        public String role {get;set;}
        
        public owner (String i, String n, String r){
            account_id = i;
            name = n;
            role = r;
        }
        
        // Custom sorting to promote clients above joint and joint above other roles. Alphabetically sorted within that ordering. 
        public Integer compareTo(Object compareTo){
            owner compareToOwn = (Owner)compareTo;
            if(role == compareToOwn.role){
                if(role == compareToOwn.role){
                    if(name == compareToOwn.name){
                        return 0;
                    } else if(name < compareToOwn.name){
                        return -1;
                    } else {
                        return 1;
                    }
                } else if( role == 'Joint' && compareToOwn.role != 'Joint' ){
                    return -1;
                } else {
                    return 1;
                }
            } else if(role == 'Client' && compareToOwn.role != 'Client'){
                return -1;
            } else {
                return 1;
            }
        }
    }
    
    // LOA update class to take key values needed in the email output
    public class loa_update{
        public String owner_id {get;set;}
        public String status {get;set;}
        public String provider {get;set;}
        public String product_type {get;set;}
        public String message {get;set;}
        
        public loa_update(String i, String s, String p, String pt, String m){
            owner_id = i;
            status = s;
            provider = p;
            product_type = pt;
            message = m;
        }
    }
    
    // Generate a map of field names (as defined in the SOQL query) to field values with all parent relationships and fields included
    public Map<String, Object> genFieldValueMap(Map<String, Object> fieldValues, String prefix) {
        Map<String, Object> field_values_temp = new Map<String, Object>();
        for (String fieldName : fieldValues.keySet()) {
            if (fieldValues.get(fieldName) instanceof sObject) { // If an sObject, this class is called again (nested) to get field values from parent relationships
                prefix = prefix + fieldName + '.' ;
                sObject obj = (sObject) fieldValues.get(fieldName);
                field_values_temp.putAll(genFieldValueMap(obj.getPopulatedFieldsAsMap(), prefix));
            } else {
                field_values_temp.put(prefix + fieldName, fieldValues.get(fieldName));
            }
        }
        return field_values_temp;
    }
}
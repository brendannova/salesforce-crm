public class EmailFulfilmentUpdate {
    public String objectId{get;set;}
    public String hiString;
    public String adviceId;             //@harriet this can be deleted as no longer needed. 
    public String householdId;
    public String introCopyRegular;
    public String introCopyFinal;
    String  EMAIL_TYPE = 'Fulfilment';
    public List<owner> ownerList = new List<owner>();
    public map<String, List<fulfilmentUpdate>> ownerFulfilmentMap = new map<String, List<fulfilmentUpdate>>();
    
    // Method to retrieve the object ID from the page
    /*private Id retrieveObjectId(){
        Id objectId = ApexPages.currentPage().getParameters().get('objectId');
        return objectId;
    }*/

    // Method for the visualforce component to call to get a list of the owners
    public String getHiString() {
        if(String.isBlank(objectId)){
            //objectId = retrieveObjectId();
            objectId = ApexPages.currentPage().getParameters().get('objectId');
        }
        householdId = objectId;
        
        // Generate a list of the people in the household using their first or preferred name appropriately and sort
        List<AccountContactRelation> household_members = [SELECT Contact.Account.FirstName, Contact.Account.FinServ__PreferredName__pc FROM AccountContactRelation WHERE AccountId =: householdId AND Roles = 'Client' AND Contact.Email != null];
        List<String> recipients = new List<String>();
        String name;
        for( AccountContactRelation household_member : household_members ){
            if( String.isBlank(household_member.Contact.Account.FinServ__PreferredName__pc) ){
                name = household_member.Contact.Account.FirstName;
            } else {
                name = household_member.Contact.Account.FinServ__PreferredName__pc;
            }
            recipients.add(name);
        }
        recipients.sort();
        
        // Loop through the recipients to produce the recipient details to be displayed in the email
        Integer n = recipients.size();
        Integer i = 0;
        hiString = 'Hi ';
        
        if ( n == 1 ) {
            hiString = hiString + recipients[0] + ',';
        } else {
            i = 0;
            for(String recipient : recipients){
                if ( i < n - 2 ) {
                    hiString = hiString + recipients[i] + ', ';
                } else if ( i == n - 2 ) {
                    hiString = hiString + recipients[i] + ' & ';
                } else {
                    hiString = hiString + recipients[i] + ',';
                }
                i = i + 1;
            }
        }
        return hiString;
    }

    // Method for the visualforce component to get introductory copy for a non final email
    public String getIntroCopyRegular() {
        
        if(String.isBlank(objectId)){
            //objectId = retrieveObjectId();
            objectId = ApexPages.currentPage().getParameters().get('objectId');
        }
        householdId = objectId;
        
        String updateStatus = 'Receiving updates';
        getExcludedStatuses excludedCall = new getExcludedStatuses();
        List<String> excludedStatuses = excludedCall.getExcludedStatuses('Fulfilment');
        
        List<Fulfilment__c> fulfilments;
        fulfilments  = [SELECT Recommendation__r.RecommendationType__r.ReferenceName__c FROM Fulfilment__c WHERE Household__c =: objectId AND Advice__r.FulfilmentUpdateStatus__c =: updateStatus AND ExcludeFromUpdate__c = False AND Status__c NOT IN: excludedStatuses AND FulfilmentType__r.ExcludeFromUpdate__c = False ORDER BY Recommendation__r.DestinationLegacy__r.Public_Provider_Name__r.Name ASC];
        
        // Loop through the recipients to produce the recipient details to be displayed in the email
        Integer n = fulfilments.size();
        Integer i = 0;
        Boolean transfers = false;
        Boolean investments = false;
        
        for (Fulfilment__c fulfilment : fulfilments) {
            if (fulfilment.Recommendation__r.RecommendationType__r.ReferenceName__c == 'EXTERNAL_TRANSFER_IN') {
                transfers = True;
            } else if (fulfilment.Recommendation__r.RecommendationType__r.ReferenceName__c == 'LUMP_SUM' || fulfilment.Recommendation__r.RecommendationType__r.ReferenceName__c == 'INTERNAL_TRANSFER' || fulfilment.Recommendation__r.RecommendationType__r.ReferenceName__c == 'REGULAR') {
                investments = True;
            } 
        }
        
        if ( transfers && investments ) {
            introCopyRegular = System.Label.EmailFulfilmentUpdateIntroCopyCashTransfer;
        } else if ( transfers && !investments) {
            introCopyRegular = System.Label.EmailFulfilmentUpdateIntroCopyTransfers;
        } else if (!transfers && investments) {
            introCopyRegular = System.Label.EmailFulfilmentUpdateIntroCopyCash;
        } else {
            introCopyRegular = System.Label.EmailFulfilmentUpdateIntroCopyGeneric;
        }
        return introCopyRegular; 
        
    } 
    
    // Method for the visualforce component to get introductory copy for a final email
    public String getIntroCopyFinal() {
        
        if(String.isBlank(objectId)){
            //objectId = retrieveObjectId();
            objectId = ApexPages.currentPage().getParameters().get('objectId');
        }
        
        String updateStatus = 'Receiving updates';
        getExcludedStatuses excludedCall = new getExcludedStatuses();
        List<String> excludedStatuses = excludedCall.getExcludedStatuses('Fulfilment');
        
        householdId = objectId;
        
        List<Fulfilment__c> fulfilments;
        fulfilments  = [SELECT Recommendation__r.RecommendationType__r.ReferenceName__c FROM Fulfilment__c WHERE Household__c =: objectId AND Advice__r.FulfilmentUpdateStatus__c =: updateStatus AND ExcludeFromUpdate__c = False AND Status__c NOT IN: excludedStatuses AND FulfilmentType__r.ExcludeFromUpdate__c = False ORDER BY Recommendation__r.DestinationLegacy__r.Public_Provider_Name__r.Name ASC];
        
        

        // Loop through the fulfilment to produce the details to be displayed in the email
        Integer n = fulfilments.size();
        Integer i = 0;
        Boolean transfers = false;
        Boolean investments = false;
        
        for (Fulfilment__c fulfilment : fulfilments) {
            if (fulfilment.Recommendation__r.RecommendationType__r.ReferenceName__c == 'EXTERNAL_TRANSFER_IN') {
                transfers = True;
            } else if (fulfilment.Recommendation__r.RecommendationType__r.ReferenceName__c == 'LUMP_SUM' || fulfilment.Recommendation__r.RecommendationType__r.ReferenceName__c == 'INTERNAL_TRANSFER' || fulfilment.Recommendation__r.RecommendationType__r.ReferenceName__c == 'REGULAR') {
                investments = True;
            } 
        }
        
        if ( transfers && investments ) {
            introCopyFinal = System.Label.EmailFulfilmentUpdateIntroCopyCashTransferFinal;
        } else if ( transfers && !investments) {
            introCopyFinal = System.Label.EmailFulfilmentUpdateIntroCopyTransferFinal;
        } else if (!transfers && investments) {
            introCopyFinal = System.Label.EmailFulfilmentUpdateIntroCopyCashFinal;
        } else {
            introCopyFinal = System.Label.EmailFulfilmentUpdateIntroCopyGenericFinal;
        }
        
        return introCopyFinal; 
        
    } 
    
    public class getExcludedStatuses {
        public List<String> getExcludedStatuses(String emailType) {
            List<OW_email_update_setting__mdt> settings = [SELECT SubStatus__c, OW_display_status__c, OW_record_status__c, OW_message__c, OW_action__c FROM OW_email_update_setting__mdt WHERE OW_email_type__c =:  emailType];
            List<String> excluded_statuses = new List<String>();
            for(OW_email_update_setting__mdt setting : settings){
                if ( setting.OW_action__c == 'Exclude' ){
                    excluded_statuses.add(setting.OW_record_status__c);
                }
            }
            return excluded_statuses;
        }
    }
    
    public class getMaps {
        public Map<String, String> getStatusMap(String emailType) {
            List<OW_email_update_setting__mdt> settings = [SELECT SubStatus__c, OW_display_status__c, OW_record_status__c, OW_message__c, OW_action__c FROM OW_email_update_setting__mdt WHERE OW_email_type__c =:  emailType];
            Map<String, String> statusMap = new Map<String, String>();
            for(OW_email_update_setting__mdt setting : settings){
                String statusKey;
                if( setting.OW_action__c == 'Include' ){
                    if ( String.isEmpty(setting.SubStatus__c) ) {
                        statusKey = setting.OW_record_status__c;
                    } else {
                        statusKey = setting.OW_record_status__c + setting.SubStatus__c;
                    }
                    statusMap.put(statusKey, setting.OW_display_status__c);
                }
            }
            return statusMap;
        }
        
        public Map<String, String> getMessageMap(String emailType) {
            List<OW_email_update_setting__mdt> settings = [SELECT SubStatus__c, OW_display_status__c, OW_record_status__c, OW_message__c, OW_action__c FROM OW_email_update_setting__mdt WHERE OW_email_type__c =:  emailType];
            Map<String, String> messageMap = new Map<String, String>();
            for(OW_email_update_setting__mdt setting : settings){
                String statusKey;
                if( setting.OW_action__c == 'Include' ){
                    if ( String.isEmpty(setting.SubStatus__c) ) {
                        statusKey = setting.OW_record_status__c;
                    } else {
                        statusKey = setting.OW_record_status__c + setting.SubStatus__c;
                    }
                    messageMap.put(statusKey, setting.OW_message__c);
                }
            }
            return messageMap;
        }
    }
    
    // Method for the visualforce component to call to get a list of the owners
    public List<owner> getOwners() {
        
        if(String.isBlank(objectId)){
            //objectId = retrieveObjectId();
            objectId = ApexPages.currentPage().getParameters().get('objectId');
        }
        householdId = objectId;
        
        if(String.isNotBlank(objectId)){
            // Create list of excluded statuses and maps of the email content for different fulfilment statuses
            List<OW_email_update_setting__mdt> settings = [SELECT SubStatus__c, OW_display_status__c, OW_record_status__c, OW_message__c, OW_action__c FROM OW_email_update_setting__mdt WHERE OW_email_type__c =:  EMAIL_TYPE];
            getMaps newMap = new getMaps();
            Map<String, String> statusMap = newMap.getStatusMap('Fulfilment');
            Map<String, String> messageMap = newMap.getMessageMap('Fulfilment');
            String EMAIL_TYPE = 'Fulfilment';

            // Get list of fields to return with the Fulfilment query and any substitution tags.
            List<OW_query_field__mdt > query_settings = [SELECT OW_tag__c, OW_field__c FROM OW_query_field__mdt WHERE EmailType__c =:  EMAIL_TYPE];
            Map<String, String> substitution_map = new Map<String, String>();
            Set<String> query_fields_set = new Set<String>(); // Use a set initially to ensure there are no duplicate values
            for(OW_query_field__mdt  query_setting : query_settings){
                query_fields_set.add(query_setting.OW_field__c);
                if( !String.isBlank(query_setting.OW_tag__c)){
                    substitution_map.put(query_setting.OW_tag__c, query_setting.OW_field__c);
                }
            }
            List<String> queryFieldsList = new List<String>(query_fields_set); // Convert from set to list to allow String.join method to be used
            String queryFieldsString = String.join(queryFieldsList, ',');
            String updateStatus = 'Receiving updates';
            getExcludedStatuses excludedCall = new getExcludedStatuses();
            List<String> excludedStatuses = excludedCall.getExcludedStatuses('Fulfilment');
            // Return a list of the fulfilments requiring an update
            List<Fulfilment__c> fulfilments  = Database.query('SELECT ' + queryFieldsString + ' FROM Fulfilment__c WHERE Household__c =: objectId AND Advice__r.FulfilmentUpdateStatus__c =: updateStatus AND FulfilmentType__r.ExcludeFromUpdate__c = False AND Status__c NOT IN: excludedStatuses AND ExcludeFromUpdate__c = False ORDER BY Recommendation__r.DestinationLegacy__r.Public_Provider_Name__r.Name ASC');
            System.debug(fulfilments);
            System.debug(objectId);
            // Generate the email updates for each Fulfilment
            List<fulfilmentUpdate> fulfilmentUpdates = new List<fulfilmentUpdate>();
            String ownerId;
            String status;
            String cedingProvider;
            String productType;
            String fulfilmentType;
            String title;
            String message;
            String substituteTag;
            String substitute_value;
            Boolean includesJointProducts = false;
            Map<String, Object> fieldValues = new Map<String, Object>();
            for(Fulfilment__c fulfilment: fulfilments ){
                String statusKey;
                if ( String.isBlank(fulfilment.PaymentStatus__c) ) {
                    statusKey = fulfilment.Status__c;
                } else {
                    statusKey = fulfilment.Status__c + fulfilment.PaymentStatus__c;
                }
                status = statusMap.get(statusKey);
                if(fulfilment.Recommendation__r.DestinationLegacy__r.FinServ__Ownership__c == 'Individual' || fulfilment.Recommendation__r.DestinationLegacy__c == null ){
                    ownerId = fulfilment.Recommendation__r.PrimaryOwner__c;
                } else if( fulfilment.Recommendation__r.DestinationLegacy__r.FinServ__Ownership__c == 'Joint' ){
                    ownerId = 'Joint';
                    includesJointProducts = true;
                }
                // Construct the fulfilment update message and substitute {} tags for actual values
                message = messageMap.get(statusKey);
                System.debug(status);
                fieldValues = genFieldValueMap(fulfilment.getPopulatedFieldsAsMap(), '');
                Matcher tagMatcherMessage = Pattern.compile('\\{(.*?)\\}').matcher(message);
                while(tagMatcherMessage.find()){
                    substituteTag = tagMatcherMessage.group();
                    System.debug(substituteTag);
                    if( fieldValues.get(substitution_map.get(substituteTag)) instanceOf Date ){  // Format string if a date
                        DateTime date_output = Date.valueOf(fieldValues.get(substitution_map.get(substituteTag)));
                        substitute_value = date_output.format('d MMMMM yyyy');
                    } else {
                        substitute_value = String.valueOf(fieldValues.get(substitution_map.get(substituteTag)));
                    }
                    message = message.replace(substituteTag, substitute_value);
                }
                title = fulfilment.FulfilmentType__r.UpdateEmailHeadline__c;
                Matcher tagMatcherTitle = Pattern.compile('\\{(.*?)\\}').matcher(title);
                while(tagMatcherTitle.find()){
                    substituteTag = tagMatcherTitle.group();
                    System.debug('Substitue tag: '+ substituteTag);
                    System.debug('Sub map: ' + substitution_map.get(substituteTag));
                    System.debug('Field values.get: ' + fieldValues.get(substitution_map.get(substituteTag)));
                    System.debug('Subvalue should = ' + String.valueOf(fieldValues.get(substitution_map.get(substituteTag))));
                    substitute_value = String.valueOf(fieldValues.get(substitution_map.get(substituteTag)));
                    title = title.replace(substituteTag, substitute_value);
                }
                fulfilmentUpdates.add(new fulfilmentUpdate(ownerId, status, message, title));
            }
            // Generate a list of the people in the household using their first or preferred name appropriately and sort
            List<AccountContactRelation> householdMembers = [SELECT Roles, Contact.AccountId, Contact.Account.FirstName, Contact.Account.FinServ__PreferredName__pc FROM AccountContactRelation WHERE AccountId =: householdId];
            String accountId;
            String name;
            String role;
            for( AccountContactRelation householdMember : householdMembers ){
                accountId = householdMember.Contact.AccountId;
                role = householdMember.Roles;
                if( String.isBlank(householdMember.Contact.Account.FinServ__PreferredName__pc) ){
                    name = householdMember.Contact.Account.FirstName;
                } else {
                    name = householdMember.Contact.Account.FinServ__PreferredName__pc;
                }
                ownerList.add(new owner(accountId, name, role));
            }
            if( includesJointProducts == true ){
                ownerList.add(new owner('Joint', 'Joint', 'Joint'));
            }
            ownerList.sort(); // Uses custom sorting algorithm from comparable owner class
            // Loop through household members and LOAs to create a map of owners to LOAs
            Integer j = 0;
            Integer k;
            List<fulfilmentUpdate> fulfilmentUpdates_temp = new List<fulfilmentUpdate>();
            while(j < ownerList.size() ){
                k = 0;
                while(k < fulfilmentUpdates.size() ){
                    if( fulfilmentUpdates[k].ownerId == ownerList[j].accountId){
                        fulfilmentUpdates_temp.add(fulfilmentUpdates[k]);
                        fulfilmentUpdates.remove(k);
                    } else {
                        k++;
                    }
                }
                if( fulfilmentUpdates_temp.size() > 0 ){
                    ownerFulfilmentMap.put(ownerList[j].accountId, fulfilmentUpdates_temp);
                    fulfilmentUpdates_temp = new List<fulfilmentUpdate>();
                    j++;
                } else {
                    ownerList.remove(j);
                }
            }
        }
        return ownerList;
    }
    
    // Method for the visualforce component to call to get the owner to Fulfilment map
    public map<String, List<fulfilmentUpdate>> getOwnerFulfilmentMap() {
        return ownerFulfilmentMap;
    }
    
    // Owner class implementing comparable so a custom sort order can be used
    public class owner implements Comparable {
        public String accountId {get;set;}
        public String name {get;set;}
        public String role {get;set;}
        public owner (String i, String n, String r){
            accountId = i;
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
    
    // Fulfilment update class to take key values needed in the email output
    public class fulfilmentUpdate {
        public String ownerId {get;set;}
        public String status {get;set;}
        public String message {get;set;}
        public String title {get;set;}
        public fulfilmentUpdate(String i, String s, String m, String t){
            ownerId = i;
            status = s;
            message = m;
            title = t;
        }
    }
    
    // Generate a map of field names (as defined in the SOQL query) to field values with all parent relationships and fields included
    public Map<String, Object> genFieldValueMap(Map<String, Object> fieldValues, String prefix) {
        Map<String, Object> fieldValuesTemp = new Map<String, Object>();
        String prefixUpdated;
        for (String fieldName : fieldValues.keySet()) {
            if (fieldValues.get(fieldName) instanceof sObject) { // If an sObject, this class is called again (nested) to get field values from parent relationships
                sObject obj = (sObject) fieldValues.get(fieldName);
                fieldValuesTemp.putAll(genFieldValueMap(obj.getPopulatedFieldsAsMap(), prefix + fieldName + '.'));
            } else {
                fieldValuesTemp.put(prefix + fieldName, fieldValues.get(fieldName));                
            }
        }
        return fieldValuesTemp;
    }
}
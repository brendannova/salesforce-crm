/**
 * This class handles logic for returning users who are licensed. 
 * It should be expanded in time to handle other scenarios and support licensing use cases, like finding unlicensed users, adding and removing licences etc. 
 */
public without sharing class Licence {

    // Get all users for a single licence
    public static List<User> getLicensedUsers(String licenceDeveloperName){
        Set<String> licenceDeveloperNames = new Set<String>{licenceDeveloperName};
        Map<String, List<User>> usersByLicence = getLicensedUsers(licenceDeveloperNames);
        return usersByLicence.get(licenceDeveloperName);
    }

    // Get all users for a collection of licences
    public static Map<String, List<User>> getLicensedUsers(Set<String> licenceDeveloperNames){
        Map<String, List<User>> usersByLicence = new Map<String, List<User>>();
        for(String licenceDeveloperName : licenceDeveloperNames){
            usersByLicence.put(licenceDeveloperName, new List<User>());
        }
        List<User> users = [SELECT Id, FirstName, LastName, Name, Email, UserName, (SELECT Licence__r.DeveloperName__c FROM UserLicences__r WHERE IsActive__c = true AND Licence__r.DeveloperName__c IN :licenceDeveloperNames) FROM User WHERE IsActive = true AND Id IN (SELECT User__c FROM UserLicence__c WHERE Licence__r.DeveloperName__c IN :licenceDeveloperNames AND IsActive__c = true) ORDER BY FirstName ASC];
        for(User user : users){
            for(UserLicence__c userLicence : user.UserLicences__r){
                usersByLicence.get(userLicence.Licence__r.DeveloperName__c).add(user);
            }
        }
        return usersByLicence;
    }
}
public without sharing class Licence {

    public static List<User> getLicensedUsers(String licenceDeveloperName){
        Set<String> licenceDeveloperNames = new Set<String>{licenceDeveloperName};
        Map<String, List<User>> usersByLicence = getLicensedUsers(licenceDeveloperNames);
        return usersByLicence.get(licenceDeveloperName);
    }

    public static Map<String, List<User>> getLicensedUsers(Set<String> licenceDeveloperNames){
        Map<String, List<User>> usersByLicence = new Map<String, List<User>>();
        for(String licenceDeveloperName : licenceDeveloperNames){
            usersByLicence.put(licenceDeveloperName, new List<User>());
        }
        List<User> users = [SELECT Id, FirstName, LastName, Name, Email, UserName, (SELECT Licence__r.DeveloperName__c FROM UserLicences__r WHERE IsActive__c = true) FROM User WHERE IsActive = true];
        for(User user : users){
            for(UserLicence__c userLicence : user.UserLicences__r){
                usersByLicence.get(userLicence.Licence__r.DeveloperName__c).add(user);
            }
        }
        return usersByLicence;
    }
}
/**
    * @description This class is used for operations on groups and group membership. 
*/
public with sharing class Groups {
    
    /**
    * @description Returns a set of user IDs containing all users that are members via:
        *   1. Direct membership
        *   2. Role membership
        *   3. Role and subordinate membership
        *   4. Sub-group membership 
        * @param groupIds
        * @return groupMemberUserIds
    */
    public static Set<Id> getGroupMemberUsers(Set<Id> groupIds){
        List<GroupMember> groupMembers = [
            SELECT UserOrGroupId 
            FROM GroupMember 
            WHERE GroupId IN :groupIds
            WITH SECURITY_ENFORCED];                // Get all members of the groups provided
        Set<Id> groupMemberUserIds = new Set<Id>();     // Stores the IDs of users in the group
        Set<Id> groupMemberGroupIds = new Set<Id>();    // Stores the IDs of groups that are members of the group
        
        // Loop the members of the group to sort them into separate lists of users and sub-groups
        for(GroupMember groupMemberLoop : groupMembers){
            String userOrGroupId = groupMemberLoop.UserOrGroupId;
            if(userOrGroupId.left(3) == '005'){
                groupMemberUserIds.add(groupMemberLoop.UserOrGroupId);
            } else {
                groupMemberGroupIds.add(groupMemberLoop.UserOrGroupId);
            }
        }

        // If there are sub-groups, we need to iterate through them
        // We may need to go down multiple layers as those groups may themselves be made up of other groups
        // The action required also depends on the group type - i.e. role vs role and subordinates vs group
        if(groupMemberGroupIds.size() > 0){
            Set<Id> groupMemberSubGroupIds = new Set<Id>();
            Set<Id> groupMemberRoleIds = new Set<Id>();
            Set<Id> groupMemberRoleAndSubIds = new Set<Id>();
            
            // Sort into 3 separate sets of roles, role and subordinates, and groups
            for(Group groupLoop : [SELECT Id, Type, relatedId FROM Group WHERE Id = :groupMemberGroupIds WITH SECURITY_ENFORCED]){
                if(groupLoop.Type == 'Role'){
                    groupMemberRoleIds.add(groupLoop.relatedId);    
                } else if(groupLoop.Type == 'RoleAndSubordinates'){
                    groupMemberRoleAndSubIds.add(groupLoop.relatedId);    
                } else if(groupLoop.Type == 'Regular'){
                    groupMemberSubGroupIds.add(groupLoop.Id);    
                }
            }
            // If any roles and subordinates, add the role then get the subordinate roles
            if(groupMemberRoleAndSubIds.size() > 0){
                groupMemberRoleIds.addAll(groupMemberRoleAndSubIds);
                groupMemberRoleIds.addAll(getAllSubRoleIds(groupMemberRoleAndSubIds));
            }
            // If any roles, get the users in those roles and add them to the list
            if(groupMemberRoleIds.size() > 0){
                List<User> userList= [SELECT Id FROM User WHERE UserRoleId IN :groupMemberRoleIds WITH SECURITY_ENFORCED];
                for(User userLoop: userList){
                    groupMemberUserIds.add(userLoop.Id);
                }
            }
            // If any sub groups, these need to be run recursively through this method
            if(groupMemberSubGroupIds.size() > 0){
                groupMemberUserIds.addAll(getGroupMemberUsers(groupMemberSubGroupIds));
            }
        }
        return groupMemberUserIds;
    }
    
    /**
    * @description This method gets the child roles where there are role and subordinate group members
    * @param roleIds
    * @return currentRoleIds
    */ 
    public static Set<Id> getAllSubRoleIds(Set<Id> roleIds){
        Set<Id> currentRoleIds = new Set<Id>();
        for(UserRole userRole :[SELECT Id FROM UserRole WHERE ParentRoleId IN :roleIds WITH SECURITY_ENFORCED]){
            currentRoleIds.add(userRole.Id);
        }
        if(currentRoleIds.size() > 0){
            currentRoleIds.addAll(getAllSubRoleIds(currentRoleIds));
        }
        return currentRoleIds;
    }

    /**
    * @description The method is invocable to ensure this can be called from a flow, allowing us to use this within declarative automation. 
    * @param requests
    * @return results
    */ 
    @InvocableMethod(label = 'Group | Get unique user list' description = 'Pass in a list of public group IDs and get back a list of users in those groups.' category = 'Utilities')
    public static List<FlowOutputs> invokeThisMethod(List<FlowInputs> requests){
        List<FlowOutputs> results = new List<FlowOutputs>();
        for (FlowInputs request : requests) {
            results.add(invokeLocalMethod(request));
        }
        return results;
    }

    /**
    * @description This method is called from the invocable one and will call the primary method of this class
    * @param request
    * @return returnDetails
    */ 
    public static FlowOutputs invokeLocalMethod(FlowInputs request){        
        FlowOutputs returnDetails = new FlowOutputs();
        Set<Id> groupIds = new Set<Id>();
        for(Group groupLoop : request.groups){
            groupIds.add(groupLoop.Id);
        }
        Set<Id> userIds =  Groups.getGroupMemberUsers(groupIds);
        List<Id> userIdsList = new List<Id>();
        userIdsList.addAll(userIds);
        returnDetails.userIds = userIdsList;
        return returnDetails;  
    }

    /**
    * @description The inputs accepted when invoked from a flow
    */ 
    public class FlowInputs{
        @InvocableVariable
        public List<Group> groups;
    }
    
    /**
    * @description The outputs returned when invoked from a flow
    */ 
    public class FlowOutputs{
        @InvocableVariable
        public List<Id> userIds;
    }
}
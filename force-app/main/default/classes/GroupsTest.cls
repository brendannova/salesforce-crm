@isTest
public with sharing class GroupsTest {
    @testSetup static void setup() {
        // Create the test group we are searching for members of
        Group testGroup = new Group(
            Name = 'Test group',
            DeveloperName = 'TEST_GROUP',
            Type = 'Regular'
        );
        insert testGroup;

        // Create a test sub-group that will be a member of the group above
        Group testSubGroup = new Group(
            Name = 'Test subgroup',
            DeveloperName = 'TEST_SUB_GROUP',
            Type = 'Regular'
        );
        insert testSubGroup;
        
        // Create a test role
        UserRole userRole = new UserRole(DeveloperName = 'MyTestRole', Name = 'My Test Role');
        insert userRole;

        // The newly created userRole will have 2 related groups for role and role and subordinate groups that we need
        List<Group> roleGroups = [SELECT Id FROM Group WHERE RelatedId = :userRole.Id];
        
        // Create a test role that is a child of the one just created
        UserRole userRoleSub = new UserRole(DeveloperName = 'MyTestRoleSub', Name = 'My Test Role Sub', ParentRoleId = userRole.Id);
        insert userRoleSub;
        
        // Insert a new user in the test role
        User testUser = DataFactoryUser.createColleague('testuser.fake@novawm.com.testuser');
        
        // Create group membership for the user, sub-group, role, and role and subordinate
        List<GroupMember> groupMembers = new List<GroupMember>();
        GroupMember groupMemberUser = new GroupMember(
            UserOrGroupId = testUser.Id,
            GroupId = testGroup.Id
        );
        groupMembers.add(groupMemberUser);
        GroupMember groupMemberGroup = new GroupMember(
            UserOrGroupId = testSubGroup.Id,
            GroupId = testGroup.Id
        );
        groupMembers.add(groupMemberGroup);
        for(Group groupLoop : roleGroups){
            GroupMember groupMemberRole = new GroupMember(
                UserOrGroupId = groupLoop.Id,
                GroupId = testGroup.Id
            );
            groupMembers.add(groupMemberRole);
        }
        insert groupMembers;        
    }
    
    @istest
    static void testGetUsers() {
        Group testGroup = [SELECT Id FROM Group WHERE DeveloperName = 'TEST_GROUP'];
        Set<Id> groupIds = new Set<Id>();
        groupIds.add(testGroup.Id);
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser.fake@novawm.com.testuser'];
        Set<Id> userIds = Groups.getGroupMemberUsers(groupIds);
        List<Id> userIdsList = new List<Id>();
        userIdsList.addAll(userIds);
        System.assertEquals(userIdsList[0], testUser.Id);
        System.assertEquals(userIdsList.size(), 1);
    }

    @istest
    static void testGetUsersInvoked() {
        Group testGroup = [SELECT Id FROM Group WHERE DeveloperName = 'TEST_GROUP'];
        List<Group> groupsTest = new List<Group>();
        groupsTest.add(testGroup);
        User testUser = [SELECT Id FROM User WHERE Email = 'testuser.fake@novawm.com.testuser'];
        List<Groups.FlowInputs> requests = new List<Groups.FlowInputs>();
        Groups.FlowInputs request = new Groups.FlowInputs();
        request.groups = groupsTest;
        requests.add(request);
        List<Groups.FlowOutputs> results = new List<Groups.FlowOutputs>();
        results = Groups.invokeThisMethod(requests);
        for (Groups.FlowOutputs result : results) {
            System.assertEquals(result.userIds[0], testUser.Id);
        }
    }
}
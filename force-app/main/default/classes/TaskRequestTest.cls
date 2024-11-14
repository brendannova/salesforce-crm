@istest
public class TaskRequestTest {
    @istest
    static void testTaskRequestObject(){
        Id userId = System.UserInfo.getUserId();
        TaskRequest tr = new TaskRequest();
        tr.householdId = userId;
        tr.mode = 'Create';
        tr.relatedAdviceId = userId;
        tr.relatedAmlKycId = userId;
        tr.relatedAnnualReviewId = userId;
        tr.relatedLoaId = userId;
        tr.relatedMortgageApplicationId = userId;
        tr.relatedOpportunityId = userId;
        tr.relatedProviderId = userId;
        tr.targetStartDate = Date.today();
        tr.dueDate = Date.today();
        tr.originalTaskId = userId;
        tr.taskType = 'TEST_TASK_TYPE';
        tr.whatId = userId;
        tr.whoId = userId;
        System.assertEquals(tr.householdId, userId);
        System.assertEquals(tr.mode, 'Create');
        System.assertEquals(tr.taskType, 'TEST_TASK_TYPE');
    }
}
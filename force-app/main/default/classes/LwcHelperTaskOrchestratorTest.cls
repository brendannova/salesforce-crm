@isTest
public class LwcHelperTaskOrchestratorTest {

    private static final String TASK_TYPE = 'test_type';

    @IsTest
    public static void testGetTaskInfoByTaskName() {
        OW_task_information__c taskInfo = new OW_task_information__c();
        taskInfo.OW_task_type__c = TASK_TYPE;
        taskInfo.OW_record_type_developer_name__c = TASK_TYPE;
        taskInfo.OW_task_description_google_doc_link__c = 'https://google.com';
        insert taskInfo;

        test.startTest();
        OW_task_information__c fetchedTaskInfo = LwcHelperTaskOrchestrator.getTaskInfoByTaskName(TASK_TYPE);
        Assert.areEqual(taskInfo.Id, fetchedTaskInfo.Id);
        test.stopTest();
    }

}
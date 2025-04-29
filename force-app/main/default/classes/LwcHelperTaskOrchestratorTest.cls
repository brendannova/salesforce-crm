@isTest
public class LwcHelperTaskOrchestratorTest {

    private static final String TASK_TYPE = 'test_type';

    @IsTest
    public static void testGetTaskInfoByTaskName() {
        DataFactoryTaskInformation dataFactory = new DataFactoryTaskInformation();
        OW_task_information__c ti = dataFactory.generateTaskInformation(TASK_TYPE);

        test.startTest();
        OW_task_information__c fetchedTaskInfo = LwcHelperTaskOrchestrator.getTaskInfoByTaskName(TASK_TYPE);
        Assert.areEqual(taskInfo.Id, fetchedTaskInfo.Id);
        test.stopTest();
    }

}

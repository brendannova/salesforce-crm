@isTest
public class TaskHelperTest {

    @istest
    static void deleteTask_notOrchestrated_allowed(){
        Task t = new Task(
            Subject = 'Test'
        );
        insert t;
        delete t;
        t = [SELECT Id, IsDeleted FROM Task WHERE Id = :t.Id ALL ROWS];
        System.Assert.areEqual(t.IsDeleted, true, 'Task not deleted');
    }

    @istest
    static void deleteTask_orchestrated_blocked(){
        Task t = new Task(
            Subject = 'Test',
            OrchestrationTaskStatus__c = 'Incomplete'
        );
        insert t;
        try{
            delete t;
        }  catch (DmlException e) {
            System.Assert.isTrue(e.getMessage().contains('Error'), 'Task deletion was permitted and should not have been');
        }
    }
}
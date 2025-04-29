public class UserTriggerHandler extends TriggerHandler{

    //recase tigger variables from SObjects
    private List<User> newUserList = (List<User>) Trigger.new;


    public override void beforeInsert(){
        UserTriggerHelper helper = new UserTriggerHelper(this.newUserList); //would refactor UserTriggerHelper to pull logic out of constructor so it can be initialised once in this class and then funcitons called when need
    }

    public override void beforeUpdate(){
        UserTriggerHelper helper = new UserTriggerHelper(this.newUserList);
    }
}
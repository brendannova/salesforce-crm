public class UserTriggerHandler extends TriggerHandler{

    //recase tigger variables from SObjects
    private List<User> newUserList = (List<User>) Trigger.new;

    public override void beforeInsert(){
        UserTriggerHelper helper = new UserTriggerHelper();
        helper.checkFederationIdentifier(this.newUserList);
    }

    public override void beforeUpdate(){
        UserTriggerHelper helper = new UserTriggerHelper();
        helper.checkFederationIdentifier(this.newUserList);
    }
    
    public override void afterInsert(){
        UserTriggerHelper helper = new UserTriggerHelper();
        helper.checkColleagueAccount(this.newUserList);
    }

    public override void afterUpdate(){
        UserTriggerHelper helper = new UserTriggerHelper();
        helper.checkColleagueAccount(this.newUserList);
    }
}
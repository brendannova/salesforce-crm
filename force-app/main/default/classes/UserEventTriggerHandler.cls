public class UserEventTriggerHandler extends TriggerHandler{

    //recase tigger variables from SObjects
    private List<UserEvent__e> newUserEventList = (List<UserEvent__e>) Trigger.new;

    public override void afterInsert(){
        UserEventTriggerHelper helper = new UserEventTriggerHelper();
        helper.processUserEvents(this.newUserEventList);
    }
}
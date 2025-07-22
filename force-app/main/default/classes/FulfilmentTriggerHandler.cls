public class FulfilmentTriggerHandler extends TriggerHandler {   
    public override void afterUpdate() {
		FulfilmentTriggerHelper fth = new FulfilmentTriggerHelper();
        fth.sendNotices(Trigger.newMap, Trigger.oldMap);
    }
}
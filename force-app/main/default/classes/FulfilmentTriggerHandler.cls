public class FulfilmentTriggerHandler extends TriggerHandler {
    
    public override void afterUpdate() {
		FulfilmentTriggerHelper fth = new FulfilmentTriggerHelper();
        fth.sendAutomaticNotices(Trigger.new);
    }
}
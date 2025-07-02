public class FulfilmentTriggerHandler extends TriggerHandler {
    
    public override void afterUpdate() {
		FulfilmentTriggerHelper fth = new FulfilmentTriggerHelper();
        fth.sendCancellationNotices(Trigger.new);
        fth.sendTransferCompleteEmails(Trigger.new);
    }
}
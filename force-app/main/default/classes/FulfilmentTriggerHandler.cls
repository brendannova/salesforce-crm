public class FulfilmentTriggerHandler extends TriggerHandler {
    
    public override void afterUpdate() {
        System.debug('In the handler function');
		FulfilmentTriggerHelper fth = new FulfilmentTriggerHelper();
        fth.sendCancellationNotices(Trigger.new);
        fth.sendTransferCompleteEmails(Trigger.new);
    }
}
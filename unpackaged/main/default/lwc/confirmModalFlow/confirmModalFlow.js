import { LightningElement, api } from "lwc";
import { FlowNavigationNextEvent, FlowNavigationFinishEvent, FlowNavigationBackEvent } from "lightning/flowSupport";
import LightningConfirm from "lightning/confirm";

export default class ConfirmModalFlow extends LightningElement {
    hasRendered = false;
    @api message;
    @api variant;
    @api label;
    @api theme;
    @api availableActions = [];
    @api navigateForwardOnConfirm;
    @api navigateBackOnCancel;
    
    renderedCallback() {
        if (!this.hasRendered) {
            this.hasRendered = true;
            this.showModal();
        }
    }

    async showModal() {
        console.log('modal about to go up')
        const result = await LightningConfirm.open({
            message: this.message,
            variant: this.variant,
            label: this.label,
            theme: this.theme
        });
        console.log('modal actioned?')
        console.log('modal result: ' + result)
        if(result && this.navigateForwardOnConfirm){
            if (this.availableActions.find(action => action === 'NEXT')) {
                const navigateNextEvent = new FlowNavigationNextEvent();
                this.dispatchEvent(navigateNextEvent);
            } else if (this.availableActions.find(action => action === 'FINISH')) {
                const navigateFinishEvent = new FlowNavigationFinishEvent();
                this.dispatchEvent(navigateFinishEvent);
            }
        } else if (!result && this.navigateBackOnCancel){
            if (this.availableActions.find(action => action === 'BACK')) {
                const navigateBackEvent = new FlowNavigationBackEvent();
                this.dispatchEvent(navigateBackEvent);
            }
        }
    }
}
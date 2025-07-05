import { api } from 'lwc';
import LightningModal from 'lightning/modal';

export default class ModalFlow extends LightningModal {
    @api modalHeader;
    @api flowInputs = [];
    @api flowApiName;
    @api refreshScreen = false;

    handleFlowStatusChange(event) {
        if(event.detail.status === 'FINISHED'){
            this.close();
            if(this.refreshScreen){
                window.location.reload();
            }
        }
    }
}
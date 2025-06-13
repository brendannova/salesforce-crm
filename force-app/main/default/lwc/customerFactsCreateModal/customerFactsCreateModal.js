import LightningModal from 'lightning/modal';
import { api } from 'lwc';

export default class FactsCreateModal extends LightningModal {
    @api recordId;

    get inputVariables() {
        return [
            {
                name: 'recordId',
                type: 'String',
                value: this.recordId
            }
        ];
    }

    handleFlowStatusChange(event) {
        if(event.detail.status === 'FINISHED'){
            this.close();
            window.location.reload();
        }
    }
}
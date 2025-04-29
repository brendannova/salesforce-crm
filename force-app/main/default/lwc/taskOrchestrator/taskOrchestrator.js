import { LightningElement, api } from 'lwc';
//import { RefreshEvent } from 'lightning/refresh';

export default class TaskOrchestrator extends LightningElement {

    @api recordId;
    @api objectApiName;
    @api cardTitle = "Manage Task"
    @api cardIcon = "standard:task";
    @api flowApiName;
    

    get inputVariables() {
        return [
          {
            name: "recordId",
            type: "String",
            value: this.recordId
          }
        ];
      }

    handleStatusChange(event) {
        if(event.detail.status === 'FINISHED') {
            //Refresh just the record view and the LWC
            //this.dispatchEvent(new RefreshEvent());
            //Reload the entire page
            window.location.reload();
        }
    }
}
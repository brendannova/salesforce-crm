import { LightningElement, api } from 'lwc';
import getTaskInfo from '@salesforce/apex/LwcHelperTaskOrchestrator.getTaskInfoByTaskName';

export default class polaris extends LightningElement {


  @api recordId;
  @api objectApiName;
  @api cardTitle = "Manage Task"
  @api cardIcon = "standard:task";
  @api flowApiName;

  showTaskSelectionFlow = true;
  showOrchestatorFlow = false;
  showHelpButton = false;
  

  get taskSelectionInputVariables() {
    return [
      {
        name: "recordId",
        type: "String",
        value: this.recordId
      }
    ];
  }

  get orchestrationInputVariables(){
    return [
      {
        name: "recordId",
        type: "String",
        value: this.recordId
      },
      {
        name: "task",
        type: "SObject",
        value: this.selectedTask
      }
    ];
  }

  _selectedTask
  @api
  get selectedTask(){
    return this._selectedTask;
  }
  set selectedTask(value){
    this._selectedTask = value;
    this.getTaskInfo();
  }
  
  @api taskInformation;

  async getTaskInfo(){
    try{
      if(this.selectedTask && this.selectedTask.OW_task_information_name__c){
        this.taskInformation = await getTaskInfo({taskTypeName: this.selectedTask.OW_task_information_name__c});

        if(this.taskInformation && this.taskInformation.OW_task_description_google_doc_link__c){
          this.showHelpButton = true;
        }
      }
    } catch(error){
      console.log('error:', error);
    }
  }

  handleHelpClick() {
    window.open(this.taskInformation.OW_task_description_google_doc_link__c, '_blank');
  }

  handleTaskSelectionStatusChange(event){

    if(event.detail.status === 'FINISHED_SCREEN' || event.detail.status === 'FINISHED') {

      this.showTaskSelectionFlow = false;
      this.showOrchestatorFlow = true;

      const outputVariables = event.detail.outputVariables;


      for (let i = 0; i < outputVariables.length; i++) {
        const outputVar = outputVariables[i];

        if (outputVar.name === "selectedTask") {
          this.selectedTask = outputVar.value;
        }
      }
    }
  }  

  handleOrchestrationStatusChange(event) {
    if(event.detail.status === 'FINISHED') {
        //Refresh just the record view and the LWC
        //this.dispatchEvent(new RefreshEvent());
        //Reload the entire page
        window.location.reload();
    }
  }
}
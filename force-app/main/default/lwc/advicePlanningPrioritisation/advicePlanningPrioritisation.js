/*********************************************************
LWC Name           : advicePlanningPrioritisation
Created Date       : 2024-09-10
@description       : This LWC retrieves advice data and displays it to planners so they can understand priority and add notes and prioritisation flags. 
@author            : Cian Morrissey
Modification Log:
Date         Author                               Modification
2024-09-10   Cian Morrissey                       Initial Version
*********************************************************/
import { LightningElement, wire } from "lwc";
import getAdvice from "@salesforce/apex/AdvicePlanningPioritisationHelper.getAdvice";
import { updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from "@salesforce/apex";

// The columns to be displayed in the table for new business
const columnsNew = [
    { label: "Stage", fieldName: "Stage"},
    { label: 'Name',fieldName: 'RecordLink', type: 'url', typeAttributes: {label: { fieldName: 'Name' }, target: '_blank'}},
    { label: "Status", fieldName: "Status"},
    { label: "Retirement call", fieldName: "RetirementCallStatus"},
    { label: "Partner", fieldName: "Partner"},
    { label: "Planner", fieldName: "Planner"},
    { label: "Specialist", fieldName: "Specialist"},
    { label: "Risk call", fieldName: "RiskCallDate", type: "date"},
    { label: "Priority", fieldName: "IsPriority__c", type: "boolean", editable: true},
    { label: "Notes", fieldName: "PlanningNotes__c", editable: true},
];

// The columns to be displayed in the table for existing customer advice
const columnsExisting = [
    { label: "Stage", fieldName: "Stage"},
    { label: 'Name',fieldName: 'RecordLink', type: 'url', typeAttributes: {label: { fieldName: 'Name' }, target: '_blank'}},
    { label: "Advice type", fieldName: "AdviceType"},
    { label: "Status", fieldName: "Status"},
    { label: "Retirement call", fieldName: "RetirementCallStatus"},
    { label: "Partner", fieldName: "Partner"},
    { label: "Planner", fieldName: "Planner"},
    { label: "Specialist", fieldName: "Specialist"},
    { label: "Annual review", fieldName: "AnnualReviewDate", type: "date"},
    { label: "Priority", fieldName: "IsPriority__c", type: "boolean", editable: true},
    { label: "Notes", fieldName: "PlanningNotes__c", editable: true},
];

const columnsSimplified = [
    { label: "Stage", fieldName: "Stage"},
    { label: 'Name',fieldName: 'RecordLink', type: 'url', typeAttributes: {label: { fieldName: 'Name' }, target: '_blank'}},
    { label: "Advice type", fieldName: "AdviceType"},
    { label: "Status", fieldName: "Status"},
    { label: "Partner", fieldName: "Partner"},
    { label: "Planner", fieldName: "Planner"},
    { label: "Specialist", fieldName: "Specialist"},
    { label: "Priority", fieldName: "IsPriority__c", type: "boolean", editable: true},
    { label: "Notes", fieldName: "PlanningNotes__c", editable: true},
];

export default class AdvicePlanningPrioritisation extends LightningElement {
    recordsRaw;
    recordsAll;
    recordsNew;
    recordsExisting;
    recordsDisplay;
    error;
    dataLoaded = false;
    draftValues = [];
    adviceRefresh;
    onboardingdisabled = false;
    existingdisabled = false;
    
    // Retrieve and process the advice data
    @wire(getAdvice)  
    getAdviceOutput(result) {
        this.adviceRefresh = result;
        if (result.data) {
            this.recordsRaw = result.data;
            console.log('this.recordsRaw', this.recordsRaw);
            let recordsTemp = JSON.parse(JSON.stringify(result.data));
            recordsTemp = recordsTemp.map(row => {
                return {...row, 
                    //Stage: this.getStageValue(row),
                    /*
                    Planner: this.plannerValue(row), 
                    Household: row.Advice_Household__r.Name, 
                    Partner: row.Partner__r.Name,
                    AdviceType: this.adviceTypeValue(row),
                    RiskCallDate: this.riskCallDateValue(row),
                    NewOrExisting: this.getOnboardingOrExisting(row),
                    AnnualReviewDate: this.getAnnualReviewDate(row),*/
                };
            })
            this.recordsAll = recordsTemp;
            this.recordsNew = this.recordsAll.filter((row) => row.NewOrExisting == 'NEW');;
            this.recordsExisting = this.recordsAll.filter((row) => row.NewOrExisting == 'EXISTING');;
            this.recordsTopUp = this.recordsAll.filter((row) => row.NewOrExisting == 'TOP_UP');;
            this.recordsWithdrawal = this.recordsAll.filter((row) => row.NewOrExisting == 'WITHDRAWAL');;
            if(this.showOnboardingAdvice){
                this.recordsDisplay = this.recordsNew;
            } else if(this.showExistingCustomerAdvice){
                this.recordsDisplay = this.recordsExisting;
            }
            this.error = undefined;
            this.dataLoaded = true;
        } else if (result.error) {
            console.log('Error getting advice');
            console.log(result.error);
            this.error = result.error;
            this.recordsAll = undefined;
        }
    }

    // Process clicks of the buttons, switching which data is diplayed
    handleClick(event) {
        this.dataLoaded = false;
        if(event.target.name == 'onboardingAdvice'){
            this.onboardingdisabled = true;
            this.existingdisabled = false;
            this.topupdisabled = false;
            this.withdrawaldisabled = false;
            this.columns = columnsNew;
            this.recordsDisplay = this.recordsNew;
        } else if(event.target.name == 'existingCustomerAdvice'){
            this.existingdisabled = true;
            this.onboardingdisabled = false;
            this.topupdisabled = false;
            this.withdrawaldisabled = false;
            this.columns = columnsExisting;
            this.recordsDisplay = this.recordsExisting;
        } else if(event.target.name == 'topUpAdvice'){
            this.existingdisabled = false;
            this.onboardingdisabled = false;
            this.topupdisabled = true;
            this.withdrawaldisabled = false;
            this.columns = columnsSimplified;
            this.recordsDisplay = this.recordsTopUp;
        } else if(event.target.name == 'withdrawalAdvice'){
            this.existingdisabled = false;
            this.onboardingdisabled = false;
            this.topupdisabled = false;
            this.withdrawaldisabled = true;
            this.columns = columnsSimplified;
            this.recordsDisplay = this.recordsWithdrawal;
        }
        this.dataLoaded = true;
    }

    // Process a save to notes or priority flags, presenting a toast and refreshing the data
    async handleSave(event) {
        console.log(event.detail.draftValues);
        let recordsUpdated = event.detail.draftValues;
        let recordsUpdatedArray = recordsUpdated.map((currItem) => {
            let fieldInput = {...currItem};
            return {
                fields : fieldInput
            };
        });

        this.draftValues = [];
        let recordsUpdatedArrayPromise = recordsUpdatedArray.map((currItem) => 
            updateRecord(currItem)
        );
        
        await Promise.all(recordsUpdatedArrayPromise);

        const toastEvent = new ShowToastEvent({
            title: "Success",
            message: "Updates saved",
            variant: "success"
        });
        this.dispatchEvent(toastEvent);

        await refreshApex (this.adviceRefresh);
    }
}
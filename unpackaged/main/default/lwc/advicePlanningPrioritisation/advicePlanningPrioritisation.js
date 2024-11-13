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
    { label: "Name", fieldName: "Name"},
    { label: "Status", fieldName: "Advice_Status__c"},
    { label: "Retirement call", fieldName: "RetirementCallStatus__c"},
    { label: "Partner", fieldName: "Partner"},
    { label: "Planner", fieldName: "Planner"},
    { label: "Risk call", fieldName: "RiskCallDate"},
    { label: "Priority", fieldName: "IsPriority__c", type: "boolean", editable: true},
    { label: "Notes", fieldName: "PlanningNotes__c", editable: true},
];

// The columns to be displayed in the table for existing customer advice
const columnsExisting = [
    { label: "Stage", fieldName: "Stage"},
    { label: "Name", fieldName: "Name"},
    { label: "Advice type", fieldName: "AdviceType"},
    { label: "Status", fieldName: "Advice_Status__c"},
    { label: "Retirement call", fieldName: "RetirementCallStatus__c"},
    { label: "Partner", fieldName: "Partner"},
    { label: "Planner", fieldName: "Planner"},
    { label: "Annual review", fieldName: "AnnualReviewDate"},
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
    showOnboardingAdvice = false;
    showExistingCustomerAdvice = false;
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
                    Planner: this.plannerValue(row), 
                    Household: row.Advice_Household__r.Name, 
                    Partner: row.Partner__r.Name,
                    AdviceType: this.adviceTypeValue(row),
                    RiskCallDate: this.riskCallDateValue(row),
                    NewOrExisting: this.getOnboardingOrExisting(row),
                    Stage: this.getStageValue(row),
                    AnnualReviewDate: this.getAnnualReviewDate(row),
                };
            })
            this.recordsAll = recordsTemp;
            this.recordsNew = this.recordsAll.filter((row) => row.NewOrExisting == 'NEW');;
            this.recordsExisting = this.recordsAll.filter((row) => row.NewOrExisting == 'EXISTING');;
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
            this.columns = columnsNew;
            this.showExistingCustomerAdvice = false;
            this.recordsDisplay = this.recordsNew;
            this.showOnboardingAdvice = true;
        } else if(event.target.name == 'existingCustomerAdvice'){
            this.existingdisabled = true;
            this.onboardingdisabled = false;
            this.columns = columnsExisting;
            this.showOnboardingAdvice = false;
            this.recordsDisplay = this.recordsExisting;
            this.showExistingCustomerAdvice = true;
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

    // Return the planner name if there's a planner and a blank string otherwise. Prevents that will occur otherwise. 
    plannerValue(row) {
        if(row.Assigned_planner__c == null){
            return '';
        } else {
            return row.Assigned_planner__r.Name;
        }
    }
    
    // Return the advice type name if there's an advice type and a blank string otherwise. Prevents that will occur otherwise. 
    adviceTypeValue(row) {
        if(row.AdviceType__c == null){
            return '';
        } else {
            return row.AdviceType__r.Name;
        }
    }

    // Format and return the risk call date
    riskCallDateValue(row) {
        if(row.RiskCallDate__c == null){
            return '';
        } else {
            return new Date(row.RiskCallDate__c).toLocaleDateString("en-GB");
        }
    }
    
    getOnboardingOrExisting(row) {
        if(row.New_or_existing_client__c == 'New'){
            return 'NEW';
        } else {
            return 'EXISTING';
        }
    }

    // Format and return the annual review month
    getAnnualReviewDate(row) {
        if(row.OW_review__c == null){
            return '-';
        } else {
            return new Date(row.OW_review__r.OW_due_date__c).toLocaleString('default', { month: 'long' });;
        }
    }
    
    // Format and return a stage description value
    getStageValue(row){
        const narrativeStatus = row.NarrativeStatus__c;
        const deckStatus = row.DeckStatus__c;
        const status = row.Advice_Status__c;
        if(status == 'Data gathering'){
            return 'Data gathering';
        } else if(status == 'Risk Call'){
            if(row.RiskCallStatus__c == 'Ready'){
                return 'Risk call | Ready';
            } else if(row.RiskCallStatus__c == 'Booked'){
                return 'Risk call | Booked';
            } else if(row.RiskCallStatus__c == 'Complete'){
                return 'Risk call | Complete';
            }
        } else if (status == 'Suitability in progress'){
            if (narrativeStatus == 'Not started'){
                return 'Narrative | Ready to start';
            } else if (narrativeStatus == 'In progress') {
                return 'Narrative | In progress';
            } else if (narrativeStatus == 'Planner review') {
                return 'Narrative | Planner review';
            } else if (narrativeStatus == 'Resolve planner comments') {
                return 'Narrative | Resolve planner comments';
            } else if (narrativeStatus == 'Partner review') {
                return 'Narrative | Partner review';
            } else if (narrativeStatus == 'Resolve partner comments') {
                return 'Narrative | Resolve partner comments';
            } else if (narrativeStatus == 'Complete') {
                if(deckStatus == 'Not started'){
                    return 'Deck | Ready to start';
                } else if(deckStatus == 'In progress'){
                    return 'Deck | In progress';
                } else if(deckStatus == 'Planner review'){
                    return 'Deck | Planner review';
                } else if(deckStatus == 'Resolve planner comments'){
                    return 'Deck | Resolve planner comments';
                } else if(deckStatus == 'Partner review'){
                    return 'Deck | Partner review';
                } else if(deckStatus == 'Resolve partner comments'){
                    return 'Deck | Resolve partner comments';
                } else if(deckStatus == 'Complete'){
                    return 'Deck | Complete';
                }
            }
        }
    }
}
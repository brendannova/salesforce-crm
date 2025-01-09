import { LightningElement, wire } from "lwc";
import getAdviceTypes from './adviceTypes';
import getAdvice from "@salesforce/apex/LwcHelperAdviceManager.getAdvice";
import { updateRecord } from "lightning/uiRecordApi";
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from "@salesforce/apex";

export default class AdviceManager extends LightningElement {
    adviceTypeRequested;                // The advice type that the user has requested to see
    tableData = [];                     // The data to be displayed in the data table
    wiredAdvice;                        // Wired variable to allow us to refresh
    showTable;                          // Displays the data table if true
    showSpinner;                        // Displays a spinner if true
    columns;                            // The table columns to be displayed
    adviceTypes = getAdviceTypes();     // The advice types for which buttons should be displayed, plus other info
    
    // Retrieve and process the advice data for the specified advice type
    @wire(getAdvice, { adviceTypeRequested: '$adviceTypeRequested' })
    getAdviceOutput(result) {
        this.wiredAdvice = result;
        if (result.data) {
            this.tableData = result.data;
            if(this.tableData.length > 0){
                this.showTable = true;
            }
        } else if (result.error) {
            console.log('Error getting advice', result.error);
        }
    }

    // Process button clicks to display different subsets of advice data
    async handleClick(event) {
        const adviceType = event.target.value;
        if(this.adviceTypeRequested != adviceType){
            this.showTable = false;
            this.showSpinner = true;
            this.tableData = [];
            this.adviceTypeRequested = adviceType;
            await refreshApex (this.wiredAdvice);
            this.columns = this.adviceTypes.find(at => at.value == adviceType).columns;
            this.showSpinner = false;
        }
    }

    // Process a save to notes or priority flags, presenting a toast and refreshing the data
    async handleSave(event) {
        let recordsUpdated = event.detail.draftValues;
        let recordsUpdatedArray = recordsUpdated.map((currItem) => {
            let fieldInput = {...currItem};
            return {
                fields : fieldInput
            };
        });
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
        await refreshApex (this.wiredAdvice);
    }
}
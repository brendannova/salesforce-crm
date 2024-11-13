import { LightningElement, api, wire } from "lwc";
import { getObjectInfos } from "lightning/uiObjectInfoApi";

export default class AuditHistoryList extends LightningElement {
    // Input variables
    @api auditRows = [];
    @api objectApiName;

    // Output variables
    @api selectedAuditRow;
    @api selectAuditRowObject;

    // Other variables
    objectDataLoaded; // Ensures the function that produces the table data doesn't run until the object data has been loaded and maps produced
    tableDataLoaded; // Ensures the table is not displayed until the data output is ready
    lowerDevNameToLabelMap = new Map(); // Map of lower case {objectName.fieldName} to Salesforce field label - e.g. asset__c.value__c | Value
    lowerDevNameToLabelMapObject = new Map(); // Map of lower case {objectName} to Salesforce object label - e.g. asset__c | Asset
    lowerDevNameToApiNameObject = new Map(); // Map of lower case {objectName} to Salesforce object name in correct case - e.g. asset__c | Asset__c
    objectApiNames; // Will store an array of object API names whose information are being displayed by this component

    // The field columns to be displayed on the history list table
    @api fieldColumns = [
        { label: "Who", fieldName: "updateMadeBy", initialWidth: 200 },
        {
            label: "When",
            fieldName: "updateMadeAt",
            type: "date",
            initialWidth: 160,
            typeAttributes: {
                day: "numeric",
                month: "short",
                year: "numeric",
                hour: "2-digit",
                minute: "2-digit",
                hour12: false,
            },
        },
        { label: "Object", fieldName: "object", initialWidth: 200 },
        { label: "Fields Changed", fieldName: "fieldsEdited", wrapText: true },
    ];

    connectedCallback() {
        this.objectApiNames = this.objectApiName.split(",");
    };

    /*// This function splits the comma separated list of object API names inputted into an array
    get objectApiNames(){
        objectApiNames = this.objectApiName.split(",");
        return objectApiNames;  
    }*/

    // Gets object information and creates maps of API object and field names to their respective labels and original API names
    @wire(getObjectInfos, { objectApiNames: "$objectApiNames" })
    _getObjectInfos({ error, data }) {
        if (error) {
            console.log(error);
            throw new Error(
                `Object data not retrieved. Please check that the object API name is correct: ${this.objectApiName}`);
        } else if (data) {
            const resultsData = data.results;
            Object.keys(resultsData).forEach(resultNumber => {
                this.lowerDevNameToLabelMapObject.set(resultsData[resultNumber].result.apiName.toLowerCase(), resultsData[resultNumber].result.label);
                this.lowerDevNameToApiNameObject.set(resultsData[resultNumber].result.apiName.toLowerCase(), resultsData[resultNumber].result.apiName);
                const fieldData = resultsData[resultNumber].result.fields;
                Object.keys(fieldData).forEach(field => {
                    this.lowerDevNameToLabelMap.set(resultsData[resultNumber].result.apiName.toLowerCase() + '.' + fieldData[field].apiName.toLowerCase(), fieldData[field].label);
                });
            });
            this.objectDataLoaded = true;
        }
    }

    // Constructs the list of audit rows to be displayed to the user, including a comma separated list of labels of fields changed
    get formattedAuditRows(){
        if(this.objectDataLoaded){
            var formattedAuditRows = [];
            formattedAuditRows = JSON.parse(JSON.stringify(this.auditRows));
            formattedAuditRows.forEach(auditRow => {
                let fieldsChangedLabels = [];
                auditRow.fieldsChanged.forEach(changedField => {
                    let fieldLabel = "";
                    try {
                        fieldLabel = this.lowerDevNameToLabelMap.get(auditRow.tableName + '.' + changedField);
                    }
                    catch(err) {
                        fieldLabel = "Error: map field";
                        console.log("Map field: " + changedField)
                    }
                    fieldsChangedLabels.push(fieldLabel);
                });
                auditRow["fieldsEdited"] = fieldsChangedLabels.join(", ");
                auditRow["object"] = this.lowerDevNameToLabelMapObject.get(auditRow.tableName);
            });
            this.tableDataLoaded = true; 
            return formattedAuditRows;
        }
    }
    
    // Handles row selection event and assigns the selected row and object to output variables
    handleRowSelection(event) {
        this.selectAuditRowObject = this.lowerDevNameToApiNameObject.get(event.detail.selectedRows[0].tableName);
        this.selectedAuditRow = this.auditRows.filter(
            (auditRow) => auditRow.id === event.detail.selectedRows[0].id
        );
    }
}
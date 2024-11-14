import { LightningElement, api, wire } from "lwc";
import { getObjectInfo } from "lightning/uiObjectInfoApi";

export default class AuditHistoryList extends LightningElement {
    @api auditRowsAccount = [];
    @api selectedAuditRowAccount;
    objectApiName = 'Account';
    objectDataLoaded;
    lowerDevNameToLabelMap = new Map();
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
        { label: "Fields Changed", fieldName: "fieldsEdited", wrapText: true },
    ];

    // Gets object information and creates a map of lowercase field API names to labels 
    @wire(getObjectInfo, { objectApiName: "$objectApiName" })
    _getObjectInfo({ error, data }) {
        if (error) {
            console.log(error);
            throw new Error(
                `Object data not retrieved. Please check that the object API name is correct: ${this.objectApiName}`);
        } else if (data) {
            const fieldData = data.fields;
            Object.keys(fieldData).forEach(field => {
                this.lowerDevNameToLabelMap.set(fieldData[field].apiName.toLowerCase(), fieldData[field].label);
            });
            this.objectDataLoaded = true;
        }
    }

    // Constructs the list of audit rows to be displayed to the user, including a comma separated list of labels of fields changed
    get formattedAuditRows(){
        if(this.objectDataLoaded){
            var formattedAuditRows = [];
            formattedAuditRows = JSON.parse(JSON.stringify(this.auditRowsAccount));
            formattedAuditRows.forEach(auditRow => {
                let fieldsChangedLabels = [];
                auditRow.fieldsChanged.forEach(changedField => {
                    let fieldLabel = "";
                    try {
                        fieldLabel = this.lowerDevNameToLabelMap.get(changedField);
                    }
                    catch(err) {
                        fieldLabel = "Error: map field";
                        console.log("Map field: " + changedField)
                    }
                    fieldsChangedLabels.push(fieldLabel);
                });
                auditRow["fieldsEdited"] = fieldsChangedLabels.join(", ");
            });
            return formattedAuditRows;
        }
    }
    
    // Handles row selection event and assigns the selected row to an output selected row variable
    handleRowSelection(event) {
        this.selectedAuditRowAccount = this.auditRowsAccount.filter(
            (auditRow) => auditRow.id === event.detail.selectedRows[0].id
        );
    }
}
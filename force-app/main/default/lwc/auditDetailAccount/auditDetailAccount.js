import { LightningElement, api, wire } from "lwc";
import { getObjectInfo } from "lightning/uiObjectInfoApi";

export default class AuditHistoryList extends LightningElement {
    @api auditRecordResponseAccount;
    @api objectApiName;
    objectDataLoaded;
    lowerDevNameToLabelMap = new Map();
    @api fieldColumns = [
        { label: "Field", fieldName: "fieldEdited", initialWidth: 200 },
        { label: "Before", fieldName: "beforeValue" },
        { label: "After", fieldName: "afterValue" },
    ];
    ignoredFields = [
        'createdbyid',
        'createddate',
        'lastmodifiedbyid',
        'lastmodifieddate',
        'lastreferenceddate',
        'lastvieweddate',
        'systemmodstamp',
        'platformidx5fx5fc',
        'platformcreatedbyx5fx5fc',
        'platformcreateddatetimex5fx5fc',
        'platformlastmodifiedbyx5fx5fc',
        'platformlastmodifieddatetimex5fx5fc'
    ];

    // Gets object information and creates a map of lowercase field API names to labels 
    @wire(getObjectInfo, { objectApiName: "$objectApiName" })
    _getObjectInfo({ error, data }) {
        if (error) {
            console.log(error.body[0].message);
            throw new Error(
                `Object data not retrieved. Please check that the object API name is correct: ${this.objectApiName}`);
        } else if (data) {
            const fieldData = data.fields;
            Object.keys(fieldData).forEach(field => {
                this.lowerDevNameToLabelMap.set(fieldData[field].apiName.toLowerCase().replaceAll('_', 'x5f'), fieldData[field].label);
            });
            this.objectDataLoaded = true;
        }
    }    

    // Constructs the list of audit rows to be displayed to the user, including a comma separated list of labels of fields changed
    get auditDetailDisplay(){
        if(this.objectDataLoaded){
            var auditDetail = [];
            var auditDetailDisplay = [];
            if (this.objectApiName === "Account") {
                auditDetail = JSON.parse(JSON.stringify(this.auditRecordResponseAccount));
            }
            Object.keys(auditDetail.changes).forEach(changedField => {
                if(auditDetail.changes[changedField] !== null && !this.ignoredFields.includes(changedField)){
                    var auditDetailRow = [];
                    auditDetailRow["fieldEdited"] = this.lowerDevNameToLabelMap.get(changedField);
                    auditDetailRow["beforeValue"] = auditDetail.previous[changedField];
                    auditDetailRow["afterValue"] = auditDetail.current[changedField];
                    auditDetailDisplay.push(auditDetailRow);
                }
            });
        }
        return auditDetailDisplay;
    }
}
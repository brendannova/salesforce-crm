import { LightningElement, api, wire } from "lwc";
import { getObjectInfo } from "lightning/uiObjectInfoApi";

export default class AuditHistoryList extends LightningElement {
    // Input variables
    @api objectApiName; // The object API name, passed in by the flow
    @api selectedAuditRow;
    @api auditRecordResponseAccount;
    @api auditRecordResponseAsset;
    @api auditRecordResponseIncome;
    @api auditRecordResponseRole;
    @api auditRecordResponseLiability;
    @api auditRecordResponseFinancialProduct;
    
    // Other variables 
    objectDataLoaded;  // Keeps the table from dispalying until the data is ready
    lowerDevNameToLabelMap = new Map(); // A map to store the mapping of API field names from the API to field labels
    @api fieldColumns = [
        { label: "Field", fieldName: "fieldEdited", initialWidth: 200 },
        { label: "Before", fieldName: "beforeValue" },
        { label: "After", fieldName: "afterValue" },
    ];

    // These ignored fields will not be displayed on the detailed set of changes
    ignoredFields = [
        'createdbyid',
        'createddate',
        'lastmodifiedbyid',
        'lastmodifieddate',
        'lastreferenceddate',
        'lastvieweddate',
        'systemmodstamp',
        'platformid__c',
        'platformcreatedby__c',
        'platformcreateddatetime__c',
        'platformlastmodifiedby__c',
        'platformlastmodifieddatetime__c'
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
                this.lowerDevNameToLabelMap.set(fieldData[field].apiName.toLowerCase(), fieldData[field].label);
            });
            this.objectDataLoaded = true;
        }
    }

    // Constructs the list of audit rows to be displayed to the user, including a comma separated list of labels of fields changed
    get auditDetailDisplay(){
        if(this.objectDataLoaded){
            var auditDetail = [];
            var auditDetailDisplay = [];
            console.log(this.objectApiName);
            if (this.objectApiName === "Account") {
                auditDetail = JSON.parse(JSON.stringify(this.auditRecordResponseAccount));
            } else if (this.objectApiName === "Asset__c"){
                auditDetail = JSON.parse(JSON.stringify(this.auditRecordResponseAsset));
            } else if(this.objectApiName === "Role__c") {
                auditDetail = JSON.parse(JSON.stringify(this.auditRecordResponseRole));
            } else if(this.objectApiName === "Income__c") {
                auditDetail = JSON.parse(JSON.stringify(this.auditRecordResponseIncome));
            } else if(this.objectApiName === "Liability__c") {
                auditDetail = JSON.parse(JSON.stringify(this.auditRecordResponseLiability));
            } else if(this.objectApiName === "FinancialProduct__c") {
                auditDetail = JSON.parse(JSON.stringify(this.auditRecordResponseFinancialProduct));
            }
            Object.keys(auditDetail.changes).forEach(changedField => {
                console.log(changedField)
                var changedFieldSf = changedField.replaceAll('x5f','_');
                //console.log(changedField)
                //console.log(this.ignoredFields)
                //console.log(this.fieldsChanged)
                //if(auditDetail.changes[changedField] !== null && !this.ignoredFields.includes(changedField)){ // looks at null values in the changed object
                //if(!this.ignoredFields.includes(changedField)){   // show all values except the ignored fields
                if(!this.ignoredFields.includes(changedFieldSf) && this.selectedAuditRow.fieldsChanged.includes(changedFieldSf)){    
                    var auditDetailRow = [];
                    auditDetailRow["fieldEdited"] = this.lowerDevNameToLabelMap.get(changedFieldSf);
                    auditDetailRow["beforeValue"] = auditDetail.previous[changedField];
                    auditDetailRow["afterValue"] = auditDetail.current[changedField];
                    auditDetailDisplay.push(auditDetailRow);
                }
            });
        }
        return auditDetailDisplay;
    }

    // Options
    // 4 - use the fields changed comma separated strings of API names
    // 1 - see if variable was set, even if null - beyond our knowledge
    // 2 - loop all the data and compare ourselves
    // 3 - the chagnes schema is altered to return boolean values, e.g. true if changes
}
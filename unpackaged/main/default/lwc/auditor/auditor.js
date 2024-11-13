import { LightningElement, wire, api } from "lwc";
import createAuditLogEntry from "@salesforce/apex/AuditLogEntry.createAuditLogEntry";

export default class Auditor extends LightningElement {
    @api recordId;
    @api objectApiName;
    audited = false;

    async connectedCallback() {
        createAuditLogEntry({recordId: this.recordId, objectApiName: this.objectApiName, audited: this.audited})
        .then((result) => {
            this.audited = true;
          })
          .catch((error) => {
            console.log('Error:', JSON.parse(JSON.stringify(error)));
          });
    }
}
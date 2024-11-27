import { LightningElement, wire, api } from 'lwc';
import formattedData from '@salesforce/apex/InformationRequestHouseholdDisplay.formattedData';


export default class irDisplay extends LightningElement {
    @api flexipageRegionWidth;

    @api recordId;

    @wire(formattedData,{recordId: '$recordId'}) 
        records;

    get records() {
        return this.records;
    }

}
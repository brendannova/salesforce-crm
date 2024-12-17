import { LightningElement, wire, api } from 'lwc';
import formattedData from '@salesforce/apex/InformationRequestHouseholdDisplay.formattedData';

// The columns to be displayed in the table
const columnsFixed = [
    { label: 'Name',fieldName: 'Link', type: 'url', typeAttributes: {label: { fieldName: 'Name' }, target: '_blank'}
    },
    { label: "Type", fieldName: "Type"},
    { label: "Product", fieldName: "FinancialProductName"},
    { label: "Status", fieldName: "Status"},
];

export default class InformationRequestRelatedList extends LightningElement {
    @api recordId;
    records = [];
    error;
    cardIcon = 'standard:account';
    cardTitle = 'Information Requests';

    @wire(formattedData,{recordId: '$recordId'})  
    setRecords(result) {
        if(result.data){
            console.log('got it');
            console.log(result.data);
            this.records = result.data;
            this.columns = columnsFixed;
        } else if  (result.error) {
            console.log('Error getting advice');
            console.log(result.error);
            this.error = result.error;
        }
    }
}
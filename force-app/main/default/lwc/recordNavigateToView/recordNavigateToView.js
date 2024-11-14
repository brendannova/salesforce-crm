import { LightningElement, api } from 'lwc';
import { NavigationMixin } from 'lightning/navigation';

export default class NavigateToRecord  extends NavigationMixin(LightningElement) {
    @api recordId;
    
    renderedCallback() {
        const recordPageRef = {
            type: 'standard__recordPage',
            attributes: {
                recordId: this.recordId ,
                actionName: 'view'
            }
        };

        this[NavigationMixin.GenerateUrl](recordPageRef).then(url => this.url = url);
        this[NavigationMixin.Navigate](recordPageRef);
    }
}
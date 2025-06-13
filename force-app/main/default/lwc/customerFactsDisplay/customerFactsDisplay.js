import { LightningElement, wire } from 'lwc';
import customerFactsCreateModal from 'c/customerFactsCreateModal';
import { CurrentPageReference } from "lightning/navigation";

export default class LwcWrapperDisplayFacts extends LightningElement {
    recordId;

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference){
        if(currentPageReference && currentPageReference.state.c__recordId){
            this.recordId = currentPageReference.state.c__recordId;
        }
    }
    
    newFactClick() {
         customerFactsCreateModal.open({
            label: 'Create new fact',
            size: 'large',
            description: 'Create new facts',
            recordId: this.recordId
        }).then((result) => {
            console.log(result);
        });

    }
}
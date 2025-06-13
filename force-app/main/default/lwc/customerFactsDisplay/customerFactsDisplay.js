import { LightningElement, wire } from 'lwc';
import { CurrentPageReference } from "lightning/navigation";
import modalFlow from 'c/modalFlow';

export default class LwcWrapperDisplayFacts extends LightningElement {
    recordId;

    @wire(CurrentPageReference)
    setCurrentPageReference(currentPageReference){
        if(currentPageReference && currentPageReference.state.c__recordId){
            this.recordId = currentPageReference.state.c__recordId;
        }
    }
    
    newFactClick() {
         modalFlow.open({
            modalHeader: 'Create new fact',
            refreshScreen: true,
            flowApiName: 'Facts_Create_Household',
            size: 'large',
            flowInputs: [{
                name: 'recordId',
                type: 'String',
                value: this.recordId
            }],
        }).then((result) => {
            console.log(result);
        });
    }
}
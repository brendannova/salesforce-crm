import { LightningElement, api } from 'lwc';

export default class NavigateToUrl extends LightningElement {
    @api url;

    renderedCallback() {
        window.open(this.url, "_blank");
    }
}
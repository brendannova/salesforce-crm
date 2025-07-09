import { LightningElement, api } from 'lwc';

export default class NavigateToUrl extends LightningElement {
    @api url;
    @api target;

    renderedCallback() {
        window.open(this.url, this.target);
    }
}
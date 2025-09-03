import { LightningElement, track, api, wire } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import { FlowAttributeChangeEvent } from 'lightning/flowSupport';
//import { CurrentPageReference } from "lightning/navigation"; \\Currently unused. This gives an option to access key value pairs defined in a page's URL
import getDynamicData from "@salesforce/apex/LwcHelperDynamicRecordList.getDynamicData";

export default class dynamicRecordList extends NavigationMixin(LightningElement) {

    @track dataReturn;
    @track state = {};
    @api recordId;
    @api pageSpecifiedColumnNames;
    @api rowActionHandler;
    @api customActions = [];
    @api title;
    @api iconName;
    @api contextId;
    @api logicReference;
    @api whereClause;
    @api maxRowSelection;
    @api maxHeight;

    // --- Flow Screen Properties ---
    // Remove the custom getters and setters
    @api isFlowMode = false; // Set a JS default
    @api keyField;
    @api tableDataString;
    @api columnsString;
    @api outputSelectedRowsString;
    @api outputSelectedIds;

    /**
     * @description This lifecycle hook fires when the component is inserted into the DOM.
     * It's the ideal place for initialization because all @api properties have been set.
     */
    connectedCallback() {
        // We now call init() here, once, ensuring all properties are available.
        this.init();
    }

    get isFlowModeEnabled() { //flows cannot set a boolean correclty consitently
        // This reliably checks the string value passed from the Flow.
        return this.isFlowMode === 'true';
    }

    get hideCheckboxColumn(){
        return !this.isFlowMode;
    }

    get maxRowSelectionValue() {
        // Only apply max row selection if specified
        return this.maxRowSelection ? parseInt(this.maxRowSelection) : undefined;
    }

    get heightStyle() {
        // If maxHeight is specified, apply it; otherwise allow natural height
        return this.maxHeight ? `height: ${this.maxHeight}px;` : '';
    }

    get hasRows() {
        return this.state.rows != null && this.state.rows.length && this.state.keyField != null;
    }

    get numberOfRows(){
        if(this.state.rows != null){
            return this.state.rows.length;
        } else {
            return 0;
        }
    }

    async handleFetchData(){
        this.dataReturn = await this.fetchData(this.logicReference, this.contextId, this.whereClause);
        if(this.dataReturn !== null && this.dataReturn.errorMessage !== null ){
            this.state.error = this.dataReturn.errorMessage;
        }
        this.setColumns();
        this.setKeyField();
        this.setRows();
        // Update title after data is loaded to ensure correct count
        this.setTitle();
    }

    async init(){
        console.log('init called');
        this.state.title = this.title;
        this.state.iconName = this.iconName;
        this.state.showRelatedList = true;
        this.state.error = null; // Reset error on init

        //this.isFlowMode = true;

        console.log('FlowMdde:', this.isFlowMode);
        console.log('isFlowModeEnabled:', this.isFlowModeEnabled);

        if (this.isFlowModeEnabled) {
            // Logic for Flow Mode ---
            console.log('In Flow Mode');
            this.handleFlowData();
            // Update title after flow data is processed
            this.setTitle();
        } else {
            // --- Logic on page ---
            if(this.recordId && !this.contextId){
                this.contextId = this.recordId;
            }

            console.log('Context ID:', this.contextId);
            console.log('Logic Reference:', this.logicReference);
            if(this.contextId != null && this.contextId !== '' && this.logicReference != null && this.logicReference !== ''){
                await this.handleFetchData();
            } else {
                // Set initial title even when no data is available
                this.setTitle();
            }
        }
    }

    handleFlowData() {
        try {
            if(this.logicReference != null && this.logicReference !== '') {
                //query dynamically
                this.handleFetchData();
            }else{
                //otherwise expect it to be passed in variables
                if (this.tableDataString) {
                    this.state.rows = JSON.parse(this.tableDataString);
                    
                } else {
                    this.state.rows = [];
                }
                console.log('rows:',this.state.rows);


                if (this.columnsString) {
                    this.state.columns = JSON.parse(this.columnsString);
                } else {
                    this.state.columns = [];
                }
                console.log('columns:',this.state.columns);
                
                // In Flow mode, the keyField is passed directly
                this.state.keyField = this.keyField; 
                console.log('keyField:', this.state.keyField)
            }

            if (!this.state.keyField) {
                 this.state.error = 'Error: You must specify a Key Field when using this component in a Flow.';
            }

        } catch(e) {
            this.state.error = 'Error parsing data or columns. Please ensure they are valid JSON strings. Details: ' + e.message;
            this.state.rows = [];
            this.state.columns = [];
            console.log(this.state.error);
        }
    }

    setColumns() {
        //if none specified ignore and load all
        let tempColumns = [];
        if(this.pageSpecifiedColumnNames == null) {
            tempColumns = this.dataReturn.columns;
        } else {
            //check columns exist and add in order
            let specifiedColumnNames = this.pageSpecifiedColumnNames.split(',');
            for(let columnName of specifiedColumnNames) {
                for(let returnedColumn of this.dataReturn.columns){
                    if(returnedColumn.fieldName == columnName) {
                        tempColumns.push(returnedColumn);
                    }
                }
            }
        }

        this.state.columns  = tempColumns
    }

    setRows(){
        this.state.rows = [];
        for(let returnedRow of this.dataReturn.rows) {
            let row = {};
            for(let field of returnedRow.fields){
                row[field.fieldName] = field.value;
            }
            this.state.rows.push(row);
        }
    }

    setKeyField(){
        if(this.dataReturn.config.keyFieldName){
            this.state.keyField = this.dataReturn.config.keyFieldName;
        } else {
            this.state.error += ' No key field specified in the configuration';
        }
    }

    setTitle(){
        this.state.title = 'Dynamic Related List';
        if(this.title){
            this.state.title = this.title;
        }
        this.state.title += ' (' + this.numberOfRows + ')';
    }

    async fetchData(logicReference, contextId, whereClause){
        try{
            let data = await getDynamicData({logicReference: logicReference, contextId: contextId, whereClause: whereClause});
            return data;
        } catch (error) {
            console.log('error in fetchData');
            console.log(error);
            this.state.error = 'Error: ' + error;
        }
    }

    async handleRefreshData() {
        await this.init();
    }

    /**
     * @description NEW: Handles the row selection event from the datatable.
     */
    handleRowSelection(event) {
        const selectedRows = event.detail.selectedRows;

        //get selected rows id field value and add to list of string
        let selectedIds = [];
        for (let row of selectedRows) {
            selectedIds.push(row[this.state.keyField]);
        }
        console.log('selected Ids: ' + selectedIds);
        
        // Convert the selected rows back to a JSON string for the Flow
        const selectedRowsJson = JSON.stringify(selectedRows);
        
        
        // Notify the Flow that the output attribute has changed
        //this.outputSelectedRowsString = selectedRowsJson;
        const attributeChangeEvent = new FlowAttributeChangeEvent('outputSelectedRowsString', selectedRowsJson);
        this.dispatchEvent(attributeChangeEvent);

        //this.outputSelectedIds = selectedIds;
        const selectedRowsIdsChangeEvent = new FlowAttributeChangeEvent('outputSelectedIds', selectedIds);
        this.dispatchEvent(selectedRowsIdsChangeEvent);
    }

    /**
     * @description Handles row action events from the datatable.
     */
    handleRowAction(event) {
        const { action, row } = event.detail;
        
        if (this.rowActionHandler) {
            // If a custom action handler is provided, dispatch a custom event
            const customEvent = new CustomEvent('rowaction', {
                detail: {
                    action: action,
                    row: row,
                    keyField: this.state.keyField
                }
            });
            this.dispatchEvent(customEvent);
        } else {
            // Default navigation behavior
            if (action.name === 'view' || action.name === 'edit') {
                this[NavigationMixin.Navigate]({
                    type: 'standard__recordPage',
                    attributes: {
                        recordId: row[this.state.keyField],
                        actionName: action.name === 'view' ? 'view' : 'edit'
                    }
                });
            }
        }
    }

}
import { LightningElement, track, api } from "lwc";
import { NavigationMixin } from "lightning/navigation";
import getDynamicData from "@salesforce/apex/LwcHelperDynamicRecordList.getDynamicData";

export default class dynamicRecordList extends NavigationMixin(LightningElement) {

    @track dataReturn;
    @track state = {}
    @api recordId;
    @api pageSpecifiedColumnNames; //comma seperated list of columns to display
    @api rowActionHandler;
    @api customActions = [];

    @api title;
    @api iconName;

    _contextId;
    @api
    get contextId() {
        return this._contextId;
    }
    set contextId(value) {
        this._contextId = value;
        this.init();
    }

    _logicReference;
    @api
    get logicReference() {
        return this._logicReference;
    }
    set logicReference(value) {
        this._logicReference = value;
        this.init();
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

    async init(){
        this.state.title = this.title;
        this.state.iconName = this.iconName;
        this.state.showRelatedList = true;

        if(this.recordId && !this.contextId){ //set context id as record id if not overwritten
            this.contextId = this.recordId;
        }

        console.log(this.contextId);
        console.log(this.logicReference);
        if(this.contextId != null && !this.contextId.isEmpty() && this.logicReference != null && !this.logicReference.isEmpty()){

            this.dataReturn = await this.fetchData(this.logicReference, this.contextId);
            this.state.error = this.dataReturn.errorMessage;
            this.setColumns();
            this.setKeyField();
            this.setRows();
        }
        this.setTitle();
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

    async fetchData(logicReference, contextId){
        try{
            let data = await getDynamicData({logicReference: logicReference, contextId: contextId});
            return data;
        } catch (error) {
            console.log('error in fetchData');
            console.log(error);
            this.state.error = 'Error: ' + error;
        }
    }

    handleRefreshData() {
        this.init();
    }
}
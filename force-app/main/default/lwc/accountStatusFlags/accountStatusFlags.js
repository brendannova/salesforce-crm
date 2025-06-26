import { LightningElement, api, wire, track } from 'lwc';
import { getRecord, getFieldValue } from "lightning/uiRecordApi";
import { getSObjectValue } from "@salesforce/apex";

import getAccountsByHouseholdId from '@salesforce/apex/LwcHelperAccountStatusFlags.getAccountsByHouseholdId';
import getWrapperFromRecord from '@salesforce/apex/LwcHelperAccountStatusFlags.getWrapperFromRecord';

//fields
import STATUS_FIELD from "@salesforce/schema/Account.FinServ__Status__c";
import RTQ_STATUS_FIELD from "@salesforce/schema/Account.OW_rtq_status__c";
import TOB_STATUS_FIELD from "@salesforce/schema/Account.OW_terms_of_Business_Status__c";
import AML_STATUS_FIELD from "@salesforce/schema/Account.OW_aml_check_account__c";
import VULNERABLE_FIELD from "@salesforce/schema/Account.Vulnerable_Client__c";
import CONFLICT_OF_INTEREST_FIELD from "@salesforce/schema/Account.ConflictOfInterest__c";
import CUSTOMER_FLAG_FIELD from "@salesforce/schema/Account.OW_customer_flag__c";
import CUSTOMER_TYPE_FIELD from "@salesforce/schema/Account.Type";
import FACT_FIND_VALIDATIONS_FIELD from "@salesforce/schema/Account.Fact_Find_Validations_Outstanding__c";
import RECORD_TYPE_DEVELOPER_NAME_FIELD from "@salesforce/schema/Account.RecordType.DeveloperName";
import TEMP_BANK_DETAILS_ISSUE_FIELD from "@salesforce/schema/Account.TempBankDetailIssues__c";

//custom labels for tooltips
import TOOLTIP_STATUS_DECEASED from "@salesforce/label/c.CustomerFlagStatusDeceasedTooltip";
import TOOLTIP_STATUS_REPORTED_DECEASED from "@salesforce/label/c.CustomerFlagStatusReportedDeceasedTooltip";
import TOOLTIP_STATUS_WITHDRAWN from "@salesforce/label/c.CustomerFlagStatusWithdrawnTooltip";
import TOOLTIP_STATUS_OFFBOARDING from "@salesforce/label/c.CustomerFlagStatusOffboardingTooltip";
import TOOLTIP_STATUS_FORMER from "@salesforce/label/c.CustomerFlagStatusFormerTooltip";
import TOOLTIP_STATUS_SPLIT from "@salesforce/label/c.CustomerFlagStatusSplitTooltip";
import TOOLTIP_STATUS_FORGOTTEN from "@salesforce/label/c.CustomerFlagStatusForgottenTooltip";
import TOOLTIP_RTQ_EXPIRED from "@salesforce/label/c.CustomerFlagRtqExpiredTooltip";
import TOOLTIP_RTQ_PENDING from "@salesforce/label/c.CustomerFlagRtqPendingTooltip";
import TOOLTIP_RTQ_INCOMPLETE from "@salesforce/label/c.CustomerFlagRtqIncompleteTooltip";
import TOOLTIP_TOB_NOT_ACCEPTED from "@salesforce/label/c.CustomerFlagTobNotAcceptedTooltip";
import TOOLTIP_TOB_AWAITING_ACCEPTACE from "@salesforce/label/c.CustomerFlagTobAwaitingAcceptanceTooltip";
import TOOLTIP_AML_INCOMPLETE from "@salesforce/label/c.CustomerFlagAmlIncompleteTooltip";
import TOOLTIP_VULNERABLE from "@salesforce/label/c.CustomerFlagVulnerableTooltip";
import TOOLTIP_COI from "@salesforce/label/c.CustomerFlagCoiTooltip";
import TOOLTIP_PEP from "@salesforce/label/c.CustomerFlagPepTooltip";
import TOOLTIP_FACT_FIND_VALIDATIONS from "@salesforce/label/c.CustomerFlagFactFindValidationTooltip";
import TOOLTIP_BANK_DETAILS_ISSUE from "@salesforce/label/c.CustomerFlagBankIssuesTooltip"
import TOOLTIP_CUSTOMER_EMPLOYEE from "@salesforce/label/c.CustomerFlagCustomerEmployeeTooltip";
import TOOLTIP_CUSTOMER_FAMILY from "@salesforce/label/c.CustomerFlagCustomerFamilyTooltip";
import TOOLTIP_CUSTOMER_VIP from "@salesforce/label/c.CustomerFlagCustomerVipTooltip";
import TOOLTIP_CUSTOMER_TRUST from "@salesforce/label/c.CustomerFlagCustomerTrustTooltip";
import TOOLTIP_TYPE_MORTGAGE from "@salesforce/label/c.CustomerFlagTypeMortgageTooltip";
import TOOLTIP_TYPE_WEALTH from "@salesforce/label/c.CustomerFlagTypeWealthTooltip";
import TOOLTIP_TYPE_TRUST from "@salesforce/label/c.CustomerFlagTypeTrustTooltip";
import TOOLTIP_FULFILMENT_PHASING from "@salesforce/label/c.CustomerFlagFulfilmentPhasing";
import TOOLTIP_FULFILMENT_RINGFENCE from "@salesforce/label/c.CustomerFlagFulfilmentRingfence";
import TOOLTIP_FULFILMENT_TRADING_RESTRICTIONS_EMPLOYER from "@salesforce/label/c.CustomerFlagFulfilmentTradingRestrictionsEmployer";
import TOOLTIP_FULFILMENT_TRADING_SUSPENDED from "@salesforce/label/c.CustomerFlagFulfilmentTradingSuspended";
import TOOLTIP_FULFILMENT_ADDITIONAL_AML from "@salesforce/label/c.CustomerFlagFulfilmentAdditionalAml";

const FIELDS = [STATUS_FIELD, RTQ_STATUS_FIELD, TOB_STATUS_FIELD, AML_STATUS_FIELD, VULNERABLE_FIELD, CONFLICT_OF_INTEREST_FIELD, CUSTOMER_FLAG_FIELD, CUSTOMER_TYPE_FIELD, RECORD_TYPE_DEVELOPER_NAME_FIELD, FACT_FIND_VALIDATIONS_FIELD, TEMP_BANK_DETAILS_ISSUE_FIELD];

const HOUSEHOLD_RECORD_TYPE_DEVELOPER_NAME = 'IndustriesHousehold';

//card titles
const CARD_TITLE_HOUSEHOLD = 'Household Flags';
const CARD_TITLE_INDIVIDUAL = 'Person Flags';

//Field labels for display / field reference
const PROFILE_STATUS_LABEL = 'Profile Status';
const RTQ_STATUS_LABEL = 'RTQ';
const TOB_STATUS_LABEL = 'TOB';
const AML_STATUS_LABEL = 'AML';
const VULNERABLE_LABEL = 'Vulnerable';
const COI_LABEL = 'Conflict of Interest';
const CUSTOMER_FLAG_LABEL = 'Customer Flag';
const CUSTOMER_TYPE_LABEL = 'Customer Type';
const PEP_LABEL = 'Politically Exposed';
const FACT_FIND_VALIDATIONS_LABEL = 'Validations Outstanding';
const TEMP_BANK_DETAILS_ISSUE_LABEL = 'Bank Details Issue';

//css sytling references
const BADGE_RED = 'badgeRed';
const BADGE_AMBER = 'badgeAmber';
const BADGE_GREEN = 'badgeGreen';
const BADGE_PINK = 'badgePink';

//icons
let iconMap = new Map();
iconMap.set(PROFILE_STATUS_LABEL, 'utility:warning');
iconMap.set(RTQ_STATUS_LABEL, 'custom:custom90');
iconMap.set(TOB_STATUS_LABEL, 'utility:signature');
iconMap.set(AML_STATUS_LABEL, 'utility:identity');
iconMap.set(VULNERABLE_LABEL, 'utility:shield');
iconMap.set(COI_LABEL, 'utility:contract_alt');
iconMap.set(PEP_LABEL, 'utility:advertising')

//Individual field values
const DECEASED_VALUE = 'Deceased';
const REPORTED_DECEASED_VALUE = 'Reported Deceased';

const JUNIOR_VALUE = 'Junior';
const JUNTIOR_POLICY_HOLDER_VALUE = 'Junior Policy Holder';

const WITHDRAWN_VALUE = 'Withdrawn';
const OFFBOARDING_VALUE = 'Offboarding';
const FORMER_VALUE = 'Former';
const SPLIT_VALUE = 'Split';
const FORGOTTEN_VALUE = 'Forgotten';

const RTQ_EXPIRED_VALUE = 'Expired';
const RTQ_PENDING_VALUE = 'Pending';
const RTQ_INCOMPLETE_VALUE = 'Incomplete';

const TOB_NOT_ACCEPTED_VALUE = 'Not Accepted';
const TOB_AWAITING_ACCEPTANCE_VALUE = 'Awaiting acceptance';

const AML_INCOMPLETE_VALUE = 'Incomplete';

const VULNERABLE_VALUE = 'Vulnerable';

const COI_YES_VALUE = 'Yes'

const CUSTOMER_FLAG_EMPLOYEE = 'Employee';
const CUSTOMER_FLAG_FAMILY = 'Family';
const CUSTOMER_FLAG_TRUST = 'Trust';
const CUSTOMER_FLAG_VIP = 'VIP';

const CUSTOMER_TYPE_MORTGAGE_VALUE = 'Mortgage only';
const CUSTOMER_TYPE_TRUST_VALUE = 'Trust';
const CUSTOMER_TYPE_WEALTH_VALUE = 'Wealth';
const CUSTOMER_TYPE_CORPORATE_VALUE = 'Corporate';

//badge references
const REF_STATUS_DECEASED = 'REF_STATUS_DECEASED';
const REF_STATUS_REPORTED_DECEASED = 'REF_STATUS_REPORTED_DECEASED';
const REF_STATUS_WITHDRAWN = 'REF_STATUS_WITHDRAWN';
const REF_STATUS_OFFBOARDING = 'REF_STATUS_OFFBOARDING';
const REF_STATUS_FORMER = 'REF_STATUS_FORMER';
const REF_STATUS_SPLIT = 'REF_STATUS_SPLIT';
const REF_STATUS_FORGOTTEN = 'REF_STATUS_FORGOTTEN';
const REF_RTQ_EXPIRED = 'REF_RTQ_EXPIRED';
const REF_RTQ_PENDING = 'REF_RTQ_PENDING';
const REF_RTQ_INCOMPLETE = 'REF_RTQ_INCOMPLETE';
const REF_TOB_NOT_ACCPETED = 'REF_TOB_NOT_ACCPETED';
const REF_TOB_AWAITING_ACCEPTANCE = 'REF_TOB_AWAITING_ACCEPTANCE';
const REF_AML_INCOMPLETE = 'REF_AML_INCOMPLETE';
const REF_VULNERABLE = 'REF_VULNERABLE';
const REF_COI = 'REF_COI';
const REF_CUSTOMER_FLAG_EMPLOYEE = 'REF_CUSTOMER_FLAG_EMPLOYEE';
const REF_CUSTOMER_FLAG_FAMILY = 'REF_CUSTOMER_FLAG_FAMILY';
const REF_CUSTOMER_FLAG_TRUST = 'REF_CUSTOMER_FLAG_TRUST';
const REF_CUSTOMER_FLAG_VIP = 'REF_CUSTOMER_FLAG_VIP';
const REF_CUSTOMER_TYPE_MORTGAGE = 'REF_CUSTOMER_TYPE_MORTGAGE';
const REF_CUSTOMER_TYPE_TRUST = 'REF_CUSTOMER_TYPE_TRUST';
const REF_CUSTOMER_TYPE_WEALTH = 'REF_CUSTOMER_TYPE_WEALTH';
const REF_CUSTOMER_TYPE_CORPORATE = 'REF_CUSTOMER_TYPE_CORPORATE';
const REF_PEP = 'REF_PEP';
const REF_FACT_FIND_VALIDATIONS = 'REF_FACT_FIND_VALIDATIONS';
const REF_TEMP_BANK_DETAILS_ISSUE = 'REF_TEMP_BANK_DETAILS_ISSUE';
const REF_FULFILMENT_PHASING = 'REF_FULFILMENT_PHASING';
const REF_FULFILMENT_RINGFENCE = 'REF_FULFILMENT_RINGFENCE'
const REF_TRADING_RESTRICTIONS_EMPLOYER = 'REF_TRADING_RESTRICTIONS_EMPLOYER';
const REF_TRADING_SUSPENDED = 'REF_TRADING_SUSPENDED';
const REF_ADDITIONAL_AML = 'REF_ADDITIONAL_AML';

const SUPPORTED_OBJECTS = [
    'Account',
    'Advice__c',
    'AdviceChecklist__c',
    'Asset__c',
    'BankAccount__c',
    'Case',
    'CustomerFact__c',
    'Fee__c',
    'FinServ__FinancialAccount__c',
    'FinServ__Employment__c',
    'Fulfilment__c',
    'InformationRequest__c',
    'Liability__c',
    'Opportunity',
    'OW_review__c',
    'OW_rtq__c',
    'PersonAccount',
    'Recommendation__c'
];


export default class accountStatusFlags extends LightningElement {
    
    badgeRefs = {
        REF_STATUS_DECEASED:                {show: false, badge: {Id: REF_STATUS_DECEASED, text: DECEASED_VALUE, icon: iconMap.get(PROFILE_STATUS_LABEL), badgeClass: BADGE_RED, order: 1.0, tooltip: TOOLTIP_STATUS_DECEASED}},
        REF_STATUS_REPORTED_DECEASED:       {show: false, badge: {Id: REF_STATUS_REPORTED_DECEASED, text: REPORTED_DECEASED_VALUE, icon: iconMap.get(PROFILE_STATUS_LABEL), badgeClass: BADGE_RED, order: 1.0, tooltip: TOOLTIP_STATUS_REPORTED_DECEASED}},
        REF_STATUS_WITHDRAWN:               {show: false, badge: {Id: REF_STATUS_WITHDRAWN, text: WITHDRAWN_VALUE, icon: 'utility:undo', badgeClass: BADGE_RED, order: 1.0, tooltip: TOOLTIP_STATUS_WITHDRAWN}},
        REF_STATUS_OFFBOARDING:             {show: false, badge: {Id: REF_STATUS_OFFBOARDING, text: OFFBOARDING_VALUE, icon: 'utility:leave_conference', badgeClass: BADGE_RED, order: 1.0, tooltip: TOOLTIP_STATUS_OFFBOARDING}},
        REF_STATUS_FORMER:                  {show: false, badge: {Id: REF_STATUS_FORMER, text: FORMER_VALUE, icon: 'utility:leave_conference', badgeClass: BADGE_RED, order: 1.0, tooltip: TOOLTIP_STATUS_FORMER}},
        REF_STATUS_SPLIT:                   {show: false, badge: {Id: REF_STATUS_SPLIT, text: SPLIT_VALUE, icon: 'utility:rules', badgeClass: BADGE_RED, order: 1.0, tooltip: TOOLTIP_STATUS_SPLIT}},
        REF_STATUS_FORGOTTEN:               {show: false, badge: {Id: REF_STATUS_FORGOTTEN, text: FORGOTTEN_VALUE, icon: 'utility:delete', badgeClass: BADGE_RED, order: 1.0, tooltip: TOOLTIP_STATUS_FORGOTTEN}},
        REF_RTQ_EXPIRED:                    {show: false, badge: {Id: REF_RTQ_EXPIRED, text: RTQ_STATUS_LABEL + ' ' + RTQ_EXPIRED_VALUE, icon: iconMap.get(RTQ_STATUS_LABEL), badgeClass: BADGE_AMBER, order: 2.1, tooltip: TOOLTIP_RTQ_EXPIRED}},
        REF_RTQ_PENDING:                    {show: false, badge: {Id: REF_RTQ_PENDING, text: RTQ_STATUS_LABEL + ' ' + RTQ_PENDING_VALUE, icon: iconMap.get(RTQ_STATUS_LABEL), badgeClass: BADGE_AMBER, order: 2.1, tooltip: TOOLTIP_RTQ_PENDING}},
        REF_RTQ_INCOMPLETE:                 {show: false, badge: {Id: REF_RTQ_INCOMPLETE, text: RTQ_STATUS_LABEL + ' Incomplete', icon: iconMap.get(RTQ_STATUS_LABEL), badgeClass: BADGE_AMBER, order: 2.1, tooltip: TOOLTIP_RTQ_INCOMPLETE}},
        REF_TOB_NOT_ACCPETED:               {show: false, badge: {Id: REF_TOB_NOT_ACCPETED, text: TOB_STATUS_LABEL + ' Not Accepted', icon: iconMap.get(TOB_STATUS_LABEL), badgeClass: BADGE_AMBER, order: 2.2, tooltip: TOOLTIP_TOB_NOT_ACCEPTED}},
        REF_TOB_AWAITING_ACCEPTANCE:        {show: false, badge: {Id: REF_TOB_AWAITING_ACCEPTANCE, text: TOB_STATUS_LABEL + ' Awaiting Acceptance', icon: iconMap.get(TOB_STATUS_LABEL), badgeClass: BADGE_AMBER, order: 2.2, tooltip: TOOLTIP_TOB_AWAITING_ACCEPTACE}},
        REF_AML_INCOMPLETE:                 {show: false, badge: {Id: REF_AML_INCOMPLETE, text: AML_STATUS_LABEL + ' ' + AML_INCOMPLETE_VALUE, icon: iconMap.get(AML_STATUS_LABEL), badgeClass: BADGE_AMBER, order: 2.3, tooltip: TOOLTIP_AML_INCOMPLETE}},
        REF_VULNERABLE:                     {show: false, badge: {Id: REF_VULNERABLE, text: VULNERABLE_VALUE, icon: iconMap.get(VULNERABLE_LABEL), badgeClass: BADGE_AMBER, order: 2.4, tooltip: TOOLTIP_VULNERABLE}},
        REF_COI:                            {show: false, badge: {Id: REF_COI, text: COI_LABEL, icon: iconMap.get(COI_LABEL), badgeClass: BADGE_AMBER, order: 2.5, tooltip: TOOLTIP_COI}},
        REF_FACT_FIND_VALIDATIONS:          {show: false, badge: {Id: REF_FACT_FIND_VALIDATIONS, text: FACT_FIND_VALIDATIONS_LABEL, icon: 'utility:task', badgeClass: BADGE_AMBER, order: 2.6, tooltip: TOOLTIP_FACT_FIND_VALIDATIONS}},
        REF_TEMP_BANK_DETAILS_ISSUE:        {show: false, badge: {Id: REF_TEMP_BANK_DETAILS_ISSUE, text: TEMP_BANK_DETAILS_ISSUE_LABEL, icon: 'custom:custom16', badgeClass: BADGE_AMBER, order: 2.7, tooltip: TOOLTIP_BANK_DETAILS_ISSUE}},
        REF_CUSTOMER_FLAG_EMPLOYEE:         {show: false, badge: {Id: REF_CUSTOMER_FLAG_EMPLOYEE, text: CUSTOMER_FLAG_EMPLOYEE, icon: 'utility:privately_shared', badgeClass: BADGE_AMBER, order: 2.8, tooltip: TOOLTIP_CUSTOMER_EMPLOYEE}},
        REF_CUSTOMER_FLAG_FAMILY:           {show: false, badge: {Id: REF_CUSTOMER_FLAG_FAMILY, text: CUSTOMER_FLAG_FAMILY, icon: 'utility:privately_shared', badgeClass: BADGE_AMBER, order: 2.8, tooltip: TOOLTIP_CUSTOMER_FAMILY}},
        REF_CUSTOMER_FLAG_TRUST:            {show: false, badge: {Id: REF_CUSTOMER_FLAG_TRUST, text: CUSTOMER_FLAG_TRUST, icon: 'utility:privately_shared', badgeClass: BADGE_AMBER, order: 2.8, tooltip: TOOLTIP_CUSTOMER_TRUST}},
        REF_CUSTOMER_FLAG_VIP:              {show: false, badge: {Id: REF_CUSTOMER_FLAG_VIP, text: CUSTOMER_FLAG_VIP, icon: 'utility:privately_shared', badgeClass: BADGE_AMBER, order: 2.8, tooltip: TOOLTIP_CUSTOMER_VIP}},
        REF_CUSTOMER_TYPE_MORTGAGE:         {show: false, badge: {Id: REF_CUSTOMER_TYPE_MORTGAGE, text: CUSTOMER_TYPE_MORTGAGE_VALUE, icon: 'utility:home', badgeClass: BADGE_PINK, order: 3.7, tooltip: TOOLTIP_TYPE_MORTGAGE}},
        REF_CUSTOMER_TYPE_TRUST:            {show: false, badge: {Id: REF_CUSTOMER_TYPE_TRUST, text: CUSTOMER_TYPE_TRUST_VALUE, icon: 'utility:contract_payment', badgeClass: BADGE_PINK, order: 3.7, tooltip: TOOLTIP_TYPE_TRUST}},
        REF_CUSTOMER_TYPE_WEALTH:           {show: false, badge: {Id: REF_CUSTOMER_TYPE_WEALTH, text: CUSTOMER_TYPE_WEALTH_VALUE, icon: 'utility:trending', badgeClass: BADGE_PINK, order: 3.7, tooltip: TOOLTIP_TYPE_WEALTH}},
        REF_CUSTOMER_TYPE_CORPORATE:        {show: false, badge: {Id: REF_CUSTOMER_TYPE_CORPORATE, text: CUSTOMER_TYPE_CORPORATE_VALUE, icon: 'utility:company', badgeClass: BADGE_PINK, order: 3.7, tooltip: ''}},
        REF_FULFILMENT_PHASING:             {show: false, badge: {Id: REF_FULFILMENT_PHASING, text: 'Phasing', icon: 'utility:page_structure', badgeClass: BADGE_RED, order: 1.1, tooltip: TOOLTIP_FULFILMENT_PHASING}},
        REF_FULFILMENT_RINGFENCE:           {show: false, badge: {Id: REF_FULFILMENT_RINGFENCE, text: 'Ringfence', icon: 'utility:steps', badgeClass: BADGE_AMBER, order: 2.9, tooltip: TOOLTIP_FULFILMENT_RINGFENCE}},
        REF_TRADING_RESTRICTIONS_EMPLOYER:  {show: false, badge: {Id: REF_TRADING_RESTRICTIONS_EMPLOYER, text: 'Employer trading restictions', icon: 'utility:incident', badgeClass: BADGE_RED, order: 1.1, tooltip: TOOLTIP_FULFILMENT_TRADING_RESTRICTIONS_EMPLOYER}},
        REF_TRADING_SUSPENDED:              {show: false, badge: {Id: REF_TRADING_SUSPENDED, text: 'Trading suspended', icon: 'utility:clear', badgeClass: BADGE_RED, order: 1.1, tooltip: TOOLTIP_FULFILMENT_TRADING_SUSPENDED}},
        REF_ADDITIONAL_AML:                 {show: false, badge: {Id: REF_ADDITIONAL_AML, text: 'Additional AML', icon: 'utility:clear', badgeClass: BADGE_RED, order: 1.1, tooltip: TOOLTIP_FULFILMENT_ADDITIONAL_AML}}
    };

    _isHousehold
    get isHousehold(){
        return this._isHousehold;
    }
    set isHousehold(value){
        this._isHousehold = value;
        this.setCardTitle();
    }


    @api recordId;
    @api objectApiName;
    @api badgeItems = [];
    @api isIconTest;
    @track accountId;
    errorMessage;
    account;
    personAccounts;
    cardTitle;

    @wire(getRecord, { recordId: '$accountId', fields: FIELDS })
    wiredAccount({error, data}){
        if(error){
            console.log('error: ' + JSON.stringify(error));
        }else if(data){
            this.account = data;
            this.isHousehold = getFieldValue(this.account, RECORD_TYPE_DEVELOPER_NAME_FIELD) === HOUSEHOLD_RECORD_TYPE_DEVELOPER_NAME;

            this.generateItems();
        }
    }

    @wire(getAccountsByHouseholdId, { householdId: '$accountId' })
    wiredAccounts({ error, data }) {
        if (data) {
            this.personAccounts = data;
            this.generateItems();
        } else if (error) {
            console.error('Error fetching accounts:', error);
        }
    }

    setCardTitle() {
        this.cardTitle = this.isHousehold ? CARD_TITLE_HOUSEHOLD : CARD_TITLE_INDIVIDUAL;
    }

    generateItems() {
        //clear what is already there to avoid any duplicates
        this.badgeItems = [];

        if(this.isIconTest){
            this.testIcons();
        } else {
            this.setFlags();
        }
        
        for(var key of Object.keys(this.badgeRefs)){
            let badgeRef = this.badgeRefs[key];

            if(badgeRef.show){
                this.addBadge(badgeRef.badge.Id, badgeRef.badge.text, badgeRef.badge.icon, badgeRef.badge.badgeClass, badgeRef.badge.order, badgeRef.badge.tooltip);
            }
        }

        this.sortBadges();
    }
    
    setFlags(){
        let accounts = [this.account];

        if(this.isHousehold){
            //holdhold only flags
            if(this.getValue(this.account, CONFLICT_OF_INTEREST_FIELD) === COI_YES_VALUE){
                this.badgeRefs[REF_COI].show = true;
            }

            let customerFlag = this.getValue(this.account, CUSTOMER_FLAG_FIELD);
            if(customerFlag === CUSTOMER_FLAG_EMPLOYEE){
                this.badgeRefs[REF_CUSTOMER_FLAG_EMPLOYEE].show = true;
            }
            if(customerFlag === CUSTOMER_FLAG_FAMILY){
                this.badgeRefs[REF_CUSTOMER_FLAG_FAMILY].show = true;
            }
            if(customerFlag === CUSTOMER_FLAG_TRUST){
                this.badgeRefs[REF_CUSTOMER_FLAG_TRUST].show = true;
            }
            if(customerFlag === CUSTOMER_FLAG_VIP){
                this.badgeRefs[REF_CUSTOMER_FLAG_VIP].show = true;
            }

            let customerType = this.getValue(this.account, CUSTOMER_TYPE_FIELD);
            if(customerType === CUSTOMER_TYPE_MORTGAGE_VALUE){
                this.badgeRefs[REF_CUSTOMER_TYPE_MORTGAGE].show = true;
            } else if(customerType === CUSTOMER_TYPE_TRUST_VALUE){
                this.badgeRefs[REF_CUSTOMER_TYPE_TRUST].show = true;
            } else {
                this.badgeRefs[REF_CUSTOMER_TYPE_WEALTH].show = true;
            }

            if(this.getValue(this.account, FACT_FIND_VALIDATIONS_FIELD)){
                this.badgeRefs[REF_FACT_FIND_VALIDATIONS].show = true;
            }

            accounts = accounts.concat(this.personAccounts);
        }

        //set at person level - could have different persons in the houseold in different states for each field
        if(accounts){
            accounts.forEach(account => {
                let status = this.getValue(account, STATUS_FIELD)
                if (status === DECEASED_VALUE) {
                    this.badgeRefs[REF_STATUS_DECEASED].show = true;
                } else if (status === REPORTED_DECEASED_VALUE) {
                    this.badgeRefs[REF_STATUS_REPORTED_DECEASED].show = true;
                } else if (status === WITHDRAWN_VALUE) {
                    this.badgeRefs[REF_STATUS_WITHDRAWN].show = true;
                } else if (status === OFFBOARDING_VALUE) {
                    this.badgeRefs[REF_STATUS_OFFBOARDING].show = true;
                } else if (status === FORGOTTEN_VALUE) {
                    this.badgeRefs[REF_STATUS_FORGOTTEN].show = true;
                } else if (status === SPLIT_VALUE) {
                    this.badgeRefs[REF_STATUS_SPLIT].show = true;
                } else if (status === FORMER_VALUE) {
                    this.badgeRefs[REF_STATUS_FORMER].show = true;
                }

                //only display if not a Junior or Junior Policy Holder
                if(status !== JUNIOR_VALUE && status !== JUNTIOR_POLICY_HOLDER_VALUE){
                    let termsOfBusiness = this.getValue(account, TOB_STATUS_FIELD);
                    if (termsOfBusiness === TOB_NOT_ACCEPTED_VALUE) {
                        this.badgeRefs[REF_TOB_NOT_ACCPETED].show = true;
                    }else if (termsOfBusiness === TOB_AWAITING_ACCEPTANCE_VALUE) {
                        this.badgeRefs[REF_TOB_AWAITING_ACCEPTANCE].show = true;
                    }

                    if (this.getValue(account, AML_STATUS_FIELD) === AML_INCOMPLETE_VALUE) {
                        this.badgeRefs[REF_AML_INCOMPLETE].show = true;
                    }

                    let riskToleranceQuestionaire = this.getValue(account, RTQ_STATUS_FIELD);
                    if(riskToleranceQuestionaire === RTQ_EXPIRED_VALUE){
                        this.badgeRefs[REF_RTQ_EXPIRED].show = true;
                    } else if(riskToleranceQuestionaire === RTQ_INCOMPLETE_VALUE){
                        this.badgeRefs[REF_RTQ_INCOMPLETE].show = true;
                    } else if(riskToleranceQuestionaire === RTQ_PENDING_VALUE){
                        this.badgeRefs[REF_RTQ_PENDING].show = true;
                    }
                }

                if(this.getValue(account, VULNERABLE_FIELD) === VULNERABLE_VALUE){
                    this.badgeRefs[REF_VULNERABLE].show = true;
                }
                console.log('temp bank details issue');
                console.log(this.getValue(account, TEMP_BANK_DETAILS_ISSUE_FIELD))
                if(this.getValue(account, TEMP_BANK_DETAILS_ISSUE_FIELD) === true){
                    this.badgeRefs[REF_TEMP_BANK_DETAILS_ISSUE].show = true;
                }
            });
        }
    }

    getValue(data, field){ //data in different formats and different methods needed to retrive it if wired or apex
        let value = getSObjectValue(data, field)
        if(!value && value !== false){
            value = getFieldValue(data, field);
        }
        return (value ? value : '');
    }

    addBadge(Id, label, icon, badgeClass, order, tooltip) {
        this.badgeItems.push({Id: Id, label: label, icon: icon, badgeClass: badgeClass, order: order, tooltip: tooltip});
    }

    sortBadges(){
        this.badgeItems.sort((a, b) => a.order - b.order);
    }

    testIcons(){
         //display all
         for(var key of Object.keys(this.badgeRefs)){
            let badgeRef = this.badgeRefs[key];
            this.addBadge(badgeRef.badge.Id, badgeRef.badge.text, badgeRef.badge.icon, badgeRef.badge.badgeClass, badgeRef.badge.order, badgeRef.badge.tooltip);
        }

    }

    connectedCallback(){
        if(this.objectApiName == 'Account'){
            this.accountId = this.recordId;
        }else if(SUPPORTED_OBJECTS.includes(this.objectApiName)){
            this.getDataFromOtherObject();
        }else{
            this.errorMessage = 'Logic to get the householdId for this Object has not yet been defined'
        }
    }

    async getDataFromOtherObject(){
        console.log('getDataFromOtherObject');
        let wrapperData = await getWrapperFromRecord({recordId: this.recordId, objectName: this.objectApiName});
        this.accountId = wrapperData.householdId;
    }
    
}

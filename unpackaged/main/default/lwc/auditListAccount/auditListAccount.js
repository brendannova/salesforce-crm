import { api, LightningElement, track, wire } from 'lwc';
import { getObjectInfo } from "lightning/uiObjectInfoApi";

// Build a map of API field names to Salesforce field names
const mapFields = new Map();
// Personal Details
mapFields.set('firstname', 'FirstName');
mapFields.set('middlename', 'MiddleName');
mapFields.set('lastname', 'LastName');
mapFields.set('name', 'Name');
mapFields.set('maiden_name__c', 'Maiden_Name__c');
mapFields.set('finserv__preferredname__pc','FinServ__PreferredName__pc')
mapFields.set('personbirthdate', 'PersonBirthdate');
mapFields.set('national_insurance_number__pc', 'National_Insurance_Number__pc');
// Contact
mapFields.set('personmobilephone', 'PersonMobilePhone');
mapFields.set('personemail', 'PersonEmail');
mapFields.set('phone', 'Phone');
mapFields.set('shippingstreet', 'ShippingStreet');
mapFields.set('shippingstate', 'ShippingState');
mapFields.set('shippingpostalcode', 'ShippingPostalCode');
mapFields.set('shippingcity', 'ShippingCity');
mapFields.set('shippingcountry', 'ShippingCountry');
mapFields.set('prefered_contact_method__c', 'Prefered_contact_method__c');
mapFields.set('wealth_marketing_opt_in__pc', 'Wealth_Marketing_Opt_In__pc');
// Family and relationships
mapFields.set('what_are_your_plans_re_more_children__c', 'What_are_your_plans_re_more_children__c');
mapFields.set('planning_to_have_more_children__c', 'Planning_to_have_more_children__c');
mapFields.set('finserv__maritalstatus__pc', 'FinServ__MaritalStatus__pc');
// Work and income
mapFields.set('retirement_target__c', 'Retirement_Target__c');
mapFields.set('working_situation__c', 'Working_Situation__c');
mapFields.set('do_you_anticioate_any_changes_to_income__c', 'Do_you_anticioate_any_changes_to_income__c');
mapFields.set('anticipated_changes_to_income__c', 'Anticipated_Changes_to_Income__c');
mapFields.set('expected_windfalls__c', 'Expected_Windfalls__c');
mapFields.set('recent_windfalls_inheritance__c', 'Recent_Windfalls_Inheritance__c');
// Eligibility
mapFields.set('country_of_domicile__c', 'Country_of_Domicile__c');
mapFields.set('country_of_residence__c', 'Country_of_Residence__c');
mapFields.set('finserv__countryofbirth__pc', 'FinServ__CountryOfBirth__pc');
mapFields.set('nationality__pc', 'Nationality__pc');
mapFields.set('dual_nationality__c', 'Dual_Nationality__c');
mapFields.set('ow_third_nationality__c', 'OW_third_nationality__c');
mapFields.set('do_you_have_any_connections_with_the_usa__c', 'Do_you_have_any_connections_with_the_USA__c');
// Health
mapFields.set('smoked_in_last_12_months__pc', 'Smoked_in_Last_12_Months__pc');
mapFields.set('smoker__pc', 'Smoker__pc');
mapFields.set('in_good_health__pc', 'In_Good_Health__pc');
mapFields.set('medical_conditions__pc', 'Medical_conditions__pc');
// Legals
mapFields.set('power_of_attorney_in_place__c', 'Power_of_Attorney_in_Place__c');
mapFields.set('power_of_attorney_types__c', 'Power_of_Attorney_Types__c');
mapFields.set('lta_protection__c', 'LTA_Protection__c');
mapFields.set('lta_protection_type__c', 'LTA_Protection_Type__c');
mapFields.set('certificate_number__c', 'Certificate_Number__c');
mapFields.set('is_will_up_to_date__c', 'Is_Will_Up_to_Date__c');
mapFields.set('valid_will_in_place__c', 'Valid_Will_in_Place__c');
// Spending and Savings
mapFields.set('rent__c', 'Rent__c');
mapFields.set('rent_frequency__c', 'Rent_Frequency__c');
mapFields.set('cash__c', 'Cash__c');
mapFields.set('cash_frequency__c', 'Cash_Frequency__c');
mapFields.set('ow_essential_spending__c', 'OW_essential_spending__c');
mapFields.set('ow_essential_spending_frequency__c', 'OW_essential_spending_frequency__c');
mapFields.set('ow_non_essential_spending__c', 'OW_non_essential_spending__c');
mapFields.set('ow_non_essential_spending_frequency__c', 'OW_non_essential_spending_frequency__c');
mapFields.set('pensions__c', 'Pensions__c');
mapFields.set('pensions_frequency__c', 'Pensions_Frequency__c');
mapFields.set('other_investments__c', 'Other_Investments__c');
mapFields.set('other_investments_frequency__c', 'Other_Investments_Frequency__c');
mapFields.set('isas__c', 'ISAs__c');
mapFields.set('isas_frequency__c', 'ISAs_Frequency__c');
mapFields.set('cost_of_childcare__c', 'Cost_of_Childcare__c');
mapFields.set('cost_of_childcare_frequency__c', 'Cost_of_Childcare_Frequency__c');
mapFields.set('costs_of_education__c', 'Costs_of_Education__c');
mapFields.set('cost_of_education_frequency__c', 'Cost_of_Education_Frequency__c');
mapFields.set('giving__c', 'Giving__c');
// Bank
mapFields.set('bank_account_name__c', 'Bank_Account_Name__c');
mapFields.set('bank_name__c', 'Bank_Name__c');
mapFields.set('bank_account_number__c', 'Bank_Account_Number__c');
mapFields.set('bank_sort_code__c', 'Bank_sort_code__c');
// System information
mapFields.set('intelligent_office_id__c', 'Intelligent_Office_ID__c');
mapFields.set('platformlastmodifieddatetime__c', 'PlatformLastModifiedDateTime__c');
mapFields.set('platformlastmodifiedby__c', 'PlatformLastModifiedBy__c');
mapFields.set('portalaccountstatus__c', 'PortalAccountStatus__c');
mapFields.set('profile_status__c', 'Profile_Status__c');
mapFields.set('dashboard_visibility__c', 'Dashboard_Visibility__c');
mapFields.set('fact_find_type__c', 'Fact_Find_Type__c');
mapFields.set('household_lookup__c', 'Household_Lookup__c');
mapFields.set('ow_role_in_primary_household__c', 'OW_role_in_primary_household__c');
mapFields.set('ow_queue__c', 'OW_queue__c');
mapFields.set('ownerid', 'OwnerId');
mapFields.set('hasclienttablerow__c', 'HasClientTableRow__c');
// Other information
mapFields.set('ow_total_value_of_contents__c', 'OW_total_value_of_contents__c');
mapFields.set('finserv__investmentexperience__c', 'FinServ__InvestmentExperience__c');
mapFields.set('discovery_level_of_risk__c', 'Discovery_Level_of_Risk__c');
mapFields.set('finserv__notes__c', 'FinServ__Notes__c');
mapFields.set('finserv__status__c', 'FinServ__Status__c');
mapFields.set('ow_aml_check_account__c', 'OW_aml_check_account__c');

export default class auditList extends LightningElement {
    @api auditList = [];
    objectApiName = 'Account';
    @track objectData;
    @api auditRow;
    @api fieldColumns = [
        { label: 'Who', fieldName: 'updateMadeBy', initialWidth: 200},
        { label: 'When', fieldName: 'updateMadeAt', type: 'date', initialWidth: 160,
            typeAttributes: {
                day: 'numeric',
                month: 'short',
                year: 'numeric',
                hour: '2-digit',
                minute: '2-digit',
                hour12: false
            }
        },
        {label: 'Fields Changed', fieldName: 'fieldsEdited', wrapText: true}
    ];
    
    // Gets the account object information so that field labels can be retrieved
    @wire(getObjectInfo, {objectApiName: '$objectApiName'})
    _getObjectInfo({error, data}) {
        if (error) {
            console.log(error.body[0].message);
        } else if (data) {
            this.objectData = data;
        }
    }
    
    // Constructs the audit list to be displayed to the user. Makes a copy of the input audit list as this can't be edited then produces the additional column as a comma separated string
    @api
    get auditListMod(){
        let auditListMod = JSON.parse(JSON.stringify(this.auditList));
        auditListMod.forEach(auditRow => {
            let fieldsChangedLabels = [];
            auditRow.fieldsChanged.forEach(changedField => {
                if(this.objectData){
                    let fieldLabel = '';
                    try {
                        fieldLabel = this.objectData.fields[mapFields.get(changedField)].label;
                    }
                    catch(err) {
                        fieldLabel = 'Error: mapping required';
                        console.log('Map field: ' + changedField)}
                    fieldsChangedLabels.push(fieldLabel);
                }
            });
            auditRow['fieldsEdited'] = fieldsChangedLabels.join(', ');
        });
        return auditListMod;
    }

    // Handles row selection event so that the audit row and ID can be passed back to the flow
    handleRowSelection(event) {
        this.auditRow = this.auditList.filter(auditRow => auditRow.id === event.detail.selectedRows[0].id);
    }
}
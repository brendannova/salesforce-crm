/**
 * This file defines static advice type information that is used in the LWC to render buttons and determine which table columns appear. 
 * There are 3 sets of table columns defined for different scenarios. 
 * As new advice types are added to the LWC, they should be added here. 
 */
export default function getAdviceTypes() {
    return [{
        label: 'Onboarding',
        value: 'ONBOARDING',
        title: "Click to display onboarding advice",
        columns: columnsNew,
    },
    {
        label: 'Existing',
        value: 'EXISTING',
        title: "Click to display existing advice",
        columns: columnsExisting,
    },
    {
        label: 'Top up',
        value: 'TOP_UP',
        title: "Click to display top up advice",
        columns: columnsSimplified,
    },
    {
        label: 'Withdrawal',
        value: 'WITHDRAWAL',
        title: "Click to display withdrawal advice",
        columns: columnsSimplified,
    },
    {
        label: 'Protection',
        value: 'PROTECTION',
        title: "Click to display protection advice",
        columns: columnsSimplified,
    },
    {
        label: 'Regular amendment',
        value: 'REGULAR_AMENDMENT',
        title: "Click to display Regular amendment advice",
        columns: columnsSimplified,
    }];
}

// The columns to be displayed in the table for onboarding advice.
const columnsNew = [
    { label: "Stage", fieldName: "Stage"},
    { label: 'Name',fieldName: 'RecordLink', type: 'url', typeAttributes: {label: { fieldName: 'Name' }, target: '_blank'}},
    { label: "Status", fieldName: "Status"},
    { label: "Retirement call", fieldName: "RetirementCallStatus"},
    { label: "Partner", fieldName: "Partner"},
    { label: "Planner", fieldName: "Planner"},
    { label: "Specialist", fieldName: "Specialist"},
    { label: "Risk call", fieldName: "RiskCallDate", type: "date"},
    { 
        label: "Priority",
        fieldName: "IsPriority__c",
        type: "boolean",
        editable: true
    },
    { label: "Notes", fieldName: "PlanningNotes__c", editable: true},
];

// The columns to be displayed in the table for existing customer advice.
const columnsExisting = [
    { label: "Stage", fieldName: "Stage"},
    { label: 'Name',fieldName: 'RecordLink', type: 'url', typeAttributes: {label: { fieldName: 'Name' }, target: '_blank'}},
    { label: "Advice type", fieldName: "AdviceType"},
    { label: "Status", fieldName: "Status"},
    { label: "Retirement call", fieldName: "RetirementCallStatus"},
    { label: "Partner", fieldName: "Partner"},
    { label: "Planner", fieldName: "Planner"},
    { label: "Specialist", fieldName: "Specialist"},
    { label: "Annual review", fieldName: "AnnualReviewDate", type: "date"},
    { label: "Prepare advice date", fieldName: "PrepareAdviceDate", type: "date"},
    { 
        label: "Priority",
        fieldName: "IsPriority__c",
        type: "boolean",
        editable: true
    },
    { label: "Notes", fieldName: "PlanningNotes__c", editable: true},
];

// A simplified set of columns for streamlined advice.
const columnsSimplified = [
    { label: "Stage", fieldName: "Stage"},
    { label: 'Name',fieldName: 'RecordLink', type: 'url', typeAttributes: {label: { fieldName: 'Name' }, target: '_blank'}},
    { label: "Advice type", fieldName: "AdviceType"},
    { label: "Status", fieldName: "Status"},
    { label: "Partner", fieldName: "Partner"},
    { label: "Planner", fieldName: "Planner"},
    { label: "Specialist", fieldName: "Specialist"},
    { 
        label: "Priority",
        fieldName: "IsPriority__c",
        type: "boolean",
        editable: true
    },
    { label: "Notes", fieldName: "PlanningNotes__c", editable: true},
];
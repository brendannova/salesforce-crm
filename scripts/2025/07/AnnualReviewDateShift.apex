List<Account> accounts = [SELECT Id, FinServ__Status__c, FinServ__NextReview__c, OW_annual_review_month__c FROM Account WHERE FinServ__NextReview__c != null AND RecordType.DeveloperName = 'IndustriesHousehold' AND FinServ__Status__c NOT IN ('Prospect','Withdrawn','Split','Former','Offboarding') ORDER BY FinServ__NextReview__c ASC];

// Move Jan reviews to October and Feb to November
for(Account acc : accounts){
    if(acc.FinServ__NextReview__c.month() == 1 || acc.FinServ__NextReview__c.month() == 2){
        Date newDate = acc.FinServ__NextReview__c.addMonths(-3);
        if(acc.FinServ__NextReview__c.month() == 1){
            acc.OW_annual_review_month__c = '10';
        } else {
            acc.OW_annual_review_month__c = '11';
        }
        System.debug(acc.OW_annual_review_month__c + ' | ' + acc.FinServ__NextReview__c + ' | ' + newDate);
        acc.FinServ__NextReview__c = newDate;
    }
}

// Move next review dates to the last day of the month
for(Account acc : accounts){
    Date newDate = Date.newInstance(acc.FinServ__NextReview__c.year(), acc.FinServ__NextReview__c.month() + 1, 1).addDays(-1);
    System.debug(acc.FinServ__NextReview__c + ' | ' + newDate);
    acc.FinServ__NextReview__c = newDate;
}
update accounts;

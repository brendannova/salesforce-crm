public class MilestoneTimeCalculator implements Support.MilestoneTriggerTimeCalculator {
    public Integer calculateMilestoneTriggerTime(String caseId, String milestoneTypeId) {
        Integer sla;
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        DateTime nextWorkingDay = BusinessHours.nextStartDate(bh.Id, DateTime.now());
        DateTime eod = DateTime.newInstance(nextWorkingDay.year(), nextWorkingDay.month(), nextWorkingDay.day(), 18, 0, 0);
        case c = [SELECT id, EmailStatus__c FROM Case WHERE id =: caseId];
        //check if the next business time is before 3pm
        if(nextWorkingDay.hour() < 15 && c.EmailStatus__c != 'Holding email sent') {
            //calculate the difference in business hours between now and 6pm
           sla  = Integer.valueOf(BusinessHours.diff(bh.Id, nextWorkingDay, eod)/60000);
        } else if(nextWorkingDay.hour() >= 15 || c.EmailStatus__c == 'Holding email sent') {
            DateTime eodTom = eod.addDays(1);
            sla = Integer.valueOf(BusinessHours.diff(bh.Id, nextWorkingDay, eodTom)/60000);
        }
        return sla;
    }
}
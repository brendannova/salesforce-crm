public class MilestoneTimeCalculator implements Support.MilestoneTriggerTimeCalculator {
    public Integer calculateMilestoneTriggerTime(String caseId, String milestoneTypeId) {
        Integer sla;
        BusinessHours bh = [SELECT Id FROM BusinessHours WHERE IsDefault = true LIMIT 1];
        //DateTime now = DateTime.now();
        DateTime nextWorkingDay = BusinessHours.nextStartDate(bh.Id, DateTime.now());
        DateTime eod = DateTime.newInstance(nextWorkingDay.year(), nextWorkingDay.month(), nextWorkingDay.day(), 18, 0, 0);
        case c = [SELECT id, EmailStatus__c FROM Case WHERE id =: caseId];
        //check if current time is before 3pm
        if(nextWorkingDay.hour() < 15 && c.EmailStatus__c != 'Holding email sent') {
            //calculate the difference between now and 6pm
            sla = Integer.valueOf((eod.getTime() - nextWorkingDay.getTime()) / 60000);
        } else if(nextWorkingDay.hour() >= 15 || c.EmailStatus__c == 'Holding email sent') {
            DateTime eodTom = eod.addDays(1);
            sla = Integer.valueOf((eodTom.getTime() - nextWorkingDay.getTime()) / 60000);
        }
        return sla;
    }
}
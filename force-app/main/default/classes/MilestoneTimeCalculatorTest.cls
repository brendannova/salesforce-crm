@isTest
private class MilestoneTimeCalculatorTest {
    static testMethod void testMilestoneTimeCalculator() {
        
        MilestoneType[] mtLst = [SELECT Id, Name FROM MilestoneType LIMIT 1];      
        MilestoneType mt = mtLst[0];
        
        Case c = new Case();
        c.Subject = 'new Email';
        c.EmailStatus__c = 'N/A';
        Insert c;
        
        MilestoneTimeCalculator calc = new MilestoneTimeCalculator();
        Integer timeMins = calc.calculateMilestoneTriggerTime(c.Id, mt.Id);
        
        Case c2 = new Case();
        c2.Subject = 'new Email';
        c2.EmailStatus__c = 'Holding email sent';
        Insert c2;
        
        MilestoneTimeCalculator calc2 = new MilestoneTimeCalculator();
        Integer timeMins2 = calc.calculateMilestoneTriggerTime(c2.Id, mt.Id);
        
    }
    

}
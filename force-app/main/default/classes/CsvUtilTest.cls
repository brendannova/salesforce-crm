@isTest
global class CsvUtilTest {
    
    @TestSetup
    static void testDataSetup() {
        List<Account> testAccounts = new List<Account>();
        Integer numAccounts = 5;
        for(Integer i = 0; i < numAccounts; i++){
            testAccounts.add(new Account(
                Name = 'Test Account ' + i
            ));
        }
        insert testAccounts;
    }

    @istest
    static void testCsvCreation(){
        CsvUtil cu = new CsvUtil();
        String fileName = 'TestFile';
        List<String> csvFieldApiNames = new List<String>{'Id','Name'};
        List<Account> testAccounts = [SELECT Id, Name FROM Account];
        Id fileId = cu.createFromsObjectList(fileName, csvFieldApiNames, testAccounts);
        ContentVersion cv = [SELECT Title, VersionData FROM ContentVersion WHERE Id = :fileId];
        System.assertEquals(fileName, cv.Title);
        List<String> csvRows = cv.VersionData.toString().split('\n');
        Integer rowCount = csvRows.size();
        System.assertEquals(testAccounts.size() + 1, rowCount);
    }
}
@isTest
public with sharing class UtilityCsvTest {
    
    final private static String BLANK_STRING            = '';
    final private static String CSV_CONTENT_TYPE        = 'text/csv';
    final private static String CSV_DELIMITER           = ',';
    final private static String CSV_FILE_BODY           = 'Header 1, Header 2\nValue1-1,Value1-2\nValue2-1,Value2-2\n';
    final private static String CSV_FILE_EXTENSION      = '.csv';
    final private static String CSV_FILE_TITLE          = 'TestFile_UtilityCsvTest';
    final private static String CSV_NEW_LINE            = '\n';
    final private static String QUOTE_MARK              = '\"';

    @TestSetup
    static void testDataSetup() {

        // Insert test accounts
        List<Account> testAccounts = new List<Account>();
        Integer numAccounts = 5;
        for(Integer i = 0; i < numAccounts; i++){
            testAccounts.add(new Account(
                Name = 'Test Account ' + i
            ));
        }
        insert testAccounts;

        // Create test CSV file to parse later 
        ContentVersion csvFile = new ContentVersion();
        csvFile.Title = CSV_FILE_TITLE;
        csvFile.VersionData = Blob.valueOf(CSV_FILE_BODY);
        csvFile.PathOnClient = csvFile.title + CSV_FILE_EXTENSION;
        insert csvFile;
    }

    @istest
    static void testCsvCreation_success(){
        UtilityCsv csvProcessor = new UtilityCsv();
        String fileName = 'TestFile';
        List<String> csvFieldApiNames = new List<String>{'Id','Name'};
        List<Account> testAccounts = [SELECT Id, Name FROM Account];
        ContentVersion csvFile = csvProcessor.createCsvFromsObjectList(fileName, csvFieldApiNames, testAccounts);
        System.assertEquals(fileName, csvFile.Title, 'Expected a file called ' + fileName + '.');
        List<String> csvRows = csvFile.VersionData.toString().split('\n');
        System.assertEquals(testAccounts.size() + 1, csvRows.size(), 'Expected ' + testAccounts.size() + ' rows but got ' + csvRows.size() + '.');
    }

    @istest
    static void testParseCsvString_success(){
        UtilityCsv csvProcessor = new UtilityCsv();
        Map<Integer, Map<String, String>> csvMap = csvProcessor.parseCsv(CSV_FILE_BODY);
        System.assertEquals(2, csvMap.size(), 'Expected 2 rows but got ' + csvMap.size() + '.');
    }

    @istest
    static void testParseCsvString_noBody_error(){
        UtilityCsv csvProcessor = new UtilityCsv();
        try{
            Map<Integer, Map<String, String>> csvMap = csvProcessor.parseCsv('');
        } catch (Exception e){
            System.assertEquals(UtilityCsv.ERROR_NO_CSV_BODY, e.getMessage(), 'Expected error due to empty csvFileBody.');
        }
    }

    @istest
    static void testParseCsvStaticResource_success(){
        UtilityCsv csvProcessor = new UtilityCsv();
        Map<Integer, Map<String, String>> csvMap = csvProcessor.parseCsvStaticResource('DataFactoryRecognisableNames');
        System.assert(csvMap.size() > 0, 'Expected rows to the map.');
    }

    @istest
    static void testParseCsvStaticResource_noStaticResourceFound_error(){
        UtilityCsv csvProcessor = new UtilityCsv();
        try{
            Map<Integer, Map<String, String>> csvMap = csvProcessor.parseCsvStaticResource('file name that will not exist');
        } catch(Exception e){
            System.assertEquals(UtilityCsv.ERROR_NO_STATIC_RESOURCE_FOUND, e.getMessage(), 'Unexpected error message returned');
        }
    }

    @istest
    static void testParseCsvStaticResource_blankStaticResourceName_error(){
        UtilityCsv csvProcessor = new UtilityCsv();
        try{
            Map<Integer, Map<String, String>> csvMap = csvProcessor.parseCsvStaticResource('');
        } catch(Exception e){
            System.assertEquals(UtilityCsv.ERROR_NO_STATIC_RESOURCE_NAME, e.getMessage(), 'Unexpected error message returned');
        }
    }

    @istest
    static void testParseCsvStaticResource_notCsv_error(){
        UtilityCsv csvProcessor = new UtilityCsv();
        String staticResourceName = [SELECT Id, Name FROM StaticResource WHERE ContentType != :CSV_FILE_EXTENSION LIMIT 1].Name;
        try{
            Map<Integer, Map<String, String>> csvMap = csvProcessor.parseCsvStaticResource(staticResourceName);
        } catch(Exception e){
            System.assertEquals(UtilityCsv.ERROR_INCORRECT_FILE_TYPE, e.getMessage(), 'Unexpected error message returned');
        }
    }

    @istest
    static void testParseCsvContentVersion_success(){
        ContentVersion csvContentVersion = [SELECT Id, VersionData FROM ContentVersion WHERE Title = :CSV_FILE_TITLE];
        UtilityCsv csvProcessor = new UtilityCsv();
        Map<Integer, Map<String, String>> csvMap = csvProcessor.parseCsvContentVersion(csvContentVersion);
        System.assertEquals(2, csvMap.size(), 'Expected 2 rows but got ' + csvMap.size() + '.');
    }
}
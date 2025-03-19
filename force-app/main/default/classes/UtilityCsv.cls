/**
 * This class contains a selection of CSV utilities that are used to process or produce CSV data. 
 */

public with sharing class UtilityCsv {
    
    final private static String CSV_DELIMITER = ',';
    final private static String CSV_CONTENT_TYPE = 'text/csv';
    final private static String CSV_FILE_EXTENSION = '.csv';
    final private static String CSV_NEW_LINE = '\n';
    final private static String QUOTE_MARK = '\"';
    final private static String BLANK_STRING = '';
    
    final public static String ERROR_NO_CSV_BODY = 'csvFileBody input required';
    final public static String ERROR_INCORRECT_FILE_TYPE = 'File type must be ' + CSV_CONTENT_TYPE;
    final public static String ERROR_NO_STATIC_RESOURCE_NAME = 'csvStaticResourceName input required';
    final public static String ERROR_NO_STATIC_RESOURCE_FOUND = 'No static resource found for csvStaticResourceName provided';

    // Parse a CSV that is input as a string and return a map of the headers to the data. CSV input must have a header row for this to work. We may want to create a headerless supported version in the future. 
    public Map<Integer, Map<String, String>> parseCsv(String csvFileBody){

        Map<Integer, Map<String, String>> mapData = new Map<Integer, Map<String, String>>();
        if(String.isBlank(csvFileBody)){
            throw new UtilityCsvException(ERROR_NO_CSV_BODY);
        } else {
            List<String> csvRows = csvFileBody.split(CSV_NEW_LINE);
            List<String> csvHeaders = csvRows[0].split(CSV_DELIMITER); 
            
            for (Integer i = 1; i < csvRows.size(); i++) {
                List<String> csvColumns = csvRows[i].split(CSV_DELIMITER);
                Integer columnCount = csvColumns.size();
                Map<String, String> mapDataItem = new Map<String, String>();
                for(Integer j = 0; j < columnCount; j++) {
                    mapDataItem.put(csvHeaders[j], csvColumns[j].removeStart(QUOTE_MARK).removeEnd(QUOTE_MARK));
                }
                mapData.put(i, mapDataItem);
            }
        }
        return mapData;
    }

    // Parse a CSV that exists as a file in Salesforce and return a map of the headers to the data. Must pass in required fields. 
    public Map<Integer, Map<String, String>> parseCsvContentVersion(ContentVersion csvContentVersion){
        return parseCsv(csvContentVersion.VersionData.toString());
    }

    // Parse a CSV that exists as a static resource in Salesforce and return a map of the headers to the data.
    public Map<Integer, Map<String, String>> parseCsvStaticResource(String csvStaticResourceName){
        if(String.isBlank(csvStaticResourceName)){
            throw new UtilityCsvException(ERROR_NO_STATIC_RESOURCE_NAME);
        } else {
            List<StaticResource> staticResources = [SELECT Id, Name, Body, ContentType FROM StaticResource WHERE Name = :csvStaticResourceName];
            if(staticResources.isEmpty()){
                throw new UtilityCsvException(ERROR_NO_STATIC_RESOURCE_FOUND);
            }
            StaticResource staticResourceCsv = staticResources[0];
            if (staticResourceCsv.ContentType != CSV_CONTENT_TYPE) {
                throw new UtilityCsvException(ERROR_INCORRECT_FILE_TYPE);
            } else {
                String csvFileBody = staticResourceCsv.Body.toString();
                return parseCsv(csvFileBody);
            }
        }
    }
    
    // Given a list of sObjects, generate a CSV file with the columns in the first row and the data in the following rows.
    public ContentVersion createCsvFromsObjectList(String fileName, List<String> csvFieldApiNames, List<sObject> csvRowList){
        Integer i = 0;
        Integer rowListSize = csvRowList.size();
        Integer headerSize = csvFieldAPINames.size();
        String headerRow = String.join(csvFieldApiNames, CSV_DELIMITER) + CSV_NEW_LINE;
        String concantenatedStr = headerRow;
        for(sObject row : csvRowList){
            // Assuming the rowList is in the correct format and each string in the list is a new record
            Map<String, Object> objFieldMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(row));
            Integer j = 0;
            for(String objField : csvFieldAPINames){
                concantenatedStr += objFieldMap.get(objField) != null ? String.valueOf(objFieldMap.get(objField)) : BLANK_STRING;
                j++;
                concantenatedStr += j != headerSize ? CSV_DELIMITER : BLANK_STRING; // Add comma separator
            }
            i++;
            if(i != rowListSize) concantenatedStr += CSV_NEW_LINE; // Add new line
        }
        return createCsvFile(fileName, concantenatedStr);
    }

    // Create a CSV as a file in Salesforce
    private ContentVersion createCsvFile(String fileName, String csvFileBody){
        ContentVersion csvFile = new ContentVersion();
        csvFile.Title = fileName;
        csvFile.VersionData = Blob.valueOf(csvFileBody);
        csvFile.PathOnClient = csvFile.title + CSV_FILE_EXTENSION;
        insert csvFile;
        return csvFile;
    }

    // Handle errors within this class
    public class UtilityCsvException extends Exception {
    }
}
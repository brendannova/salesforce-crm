public without sharing class CsvUtil {
    public Id createFromsObjectList(String fileName, List<String> csvFieldApiNames, List<sObject> csvRowList){
        Integer i = 0;
        Integer rowListSize = csvRowList.size();
        Integer headerSize = csvFieldAPINames.size();
        String headerRow = String.join(csvFieldApiNames,',') + '\n';
        String concantenatedStr = headerRow;
        for(sObject row : csvRowList){
            //assuming the rowList is in the correct format and each string in the list is a new record
            Map<String, Object> objFieldMap = (Map<String, Object>)JSON.deserializeUntyped(JSON.serialize(row));
            Integer j = 0;
            for(String objField : csvFieldAPINames){
                concantenatedStr += objFieldMap.get(objField) != null ? String.valueOf(objFieldMap.get(objField)) : '';
                j++;
                concantenatedStr += j != headerSize ? ',' : '';//add comma separator
            }
            i++;
            if(i != rowListSize) concantenatedStr += '\n';//add new line
        }
        return createCsvFile(fileName, concantenatedStr);
    }

    private Id createCsvFile(String fileName, String csvContentString){
        ContentVersion csvFile = new ContentVersion();
        csvFile.Title = fileName;
        csvFile.VersionData = Blob.valueOf(csvContentString);
        csvFile.PathOnClient = csvFile.title +'.csv';
        insert csvFile;
        return csvFile.Id;
    }
}
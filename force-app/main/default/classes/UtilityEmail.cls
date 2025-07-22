public with sharing class UtilityEmail {
    
    public static String tagSubstituter(Map<String, String> parameterMap, String text){
        for(String parameter : parameterMap.keySet()){
            text = text.replace(parameter, parameterMap.get(parameter));
        }
        return text;
    }
}
/*********************************************************
Apex Class Name    : UtilityString
Created Date       : 2024-12-02
@description       : This class is a collection of string utilities that can be used to do things like convert string formats.
@author            : Cian Morrissey
Modification Log:
Date         Author                               Modification
2024-12-02   Cian Morrissey                       Initial Version
*********************************************************/
public with sharing class UtilityString {
    /*
    *	@methodName = convertCaseUpperSnakeToSentence
    *	@return = Sentence case string
    *	@params = A string in UPPER_SNAKE_CASE
    *	@description = Method takes a string in upper snake case and converts it to sentence case
    */
    public static String convertCaseUpperSnakeToSentence(String inputString){
        String returnString = inputString.replace('_', ' ');
        returnString = returnString.toLowerCase();
        returnString = returnString.capitalize();
        return returnString;
    }
    
    /*
    *	@methodName = formatDateForNovaEmail
    *	@return = Formatted date in the format eg 3 July 2025
    *	@params = A date time instance
    *	@description = Method takes a datetime instance and returns a string of the formatted date
    */
    public String formatDateForNovaEmail(Datetime dateToFormat){
   		return dateToFormat.format('d MMMMMMMMMM yyyy');
	}
}
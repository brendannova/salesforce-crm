/**
 * A collection of utilities that work with strings and we want to reuse around the place.
 * In all cases, here the outputs should be a string unless discussed and changed.
 */
public with sharing class UtilityString {
    
    // Converts UPPER_SNAKE_CASE string to sentence case (Upper snake case)
    public static String convertCaseUpperSnakeToSentence(String inputString){
        String returnString = inputString.replace('_', ' ');
        returnString = returnString.toLowerCase();
        returnString = returnString.capitalize();
        return returnString;
    }
    
    // Takes a datetime instance and returns a string of the formatted date, for use in emails, in 3 July 2025 format. 
    public String formatDateForNovaEmail(Datetime dateToFormat){
   		return dateToFormat.format('d MMMMMMMMMM yyyy');
	}
}
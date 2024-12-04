@isTest
public class UtilityStringTest {

    @istest
    static void convertStringUpperSnakeToSentence_success(){
        String inputString = 'UPPER_SNAKE_CASE_STRING';
        String convertedString = UtilityString.convertCaseUpperSnakeToSentence(inputString);
        System.Assert.areEqual(convertedString, 'Upper snake case string', 'String was not converted correctly');
    }
}
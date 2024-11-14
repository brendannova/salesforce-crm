@isTest(SeeAllData=true)
public class StringListDeduplicateTest {
    
    @istest
    static void testDeDupeString(){
        List<String> stringToUnique = new List<String>{'1','2','3','4','4'};
        List<StringListDeduplicate.FlowInputs> FlowInputs = new List<StringListDeduplicate.FlowInputs>();
        StringListDeduplicate.FlowInputs FlowInput = new StringListDeduplicate.FlowInputs();
        FlowInput.inputString = stringToUnique;      
        FlowInputs.add(FlowInput);
        List<StringListDeduplicate.FlowOutputs> FlowOutputs = new List<StringListDeduplicate.FlowOutputs>();
		FlowOutputs = StringListDeduplicate.invokeThisMethod(FlowInputs);
        System.assertEquals(FlowOutputs[0].outputString.size(), 4);
    }
}
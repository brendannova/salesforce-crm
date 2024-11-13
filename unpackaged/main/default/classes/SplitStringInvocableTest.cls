@isTest(SeeAllData=true)
public class SplitStringInvocableTest {
    
    @istest
    static void testSplitString(){
        String stringToSplit = 'string1;string2;string3';
        List<SplitStringInvocable.FlowInputs> FlowInputs = new List<SplitStringInvocable.FlowInputs>();
        SplitStringInvocable.FlowInputs FlowInput = new SplitStringInvocable.FlowInputs();
        FlowInput.stringToSplit = stringToSplit;      
        FlowInputs.add(FlowInput);
        List<SplitStringInvocable.FlowOutputs> FlowOutputs = new List<SplitStringInvocable.FlowOutputs>();
		FlowOutputs = SplitStringInvocable.invokeThisMethod(FlowInputs);
        System.assertEquals(FlowOutputs[0].tasksToCreate.size(), 3);
    }
}
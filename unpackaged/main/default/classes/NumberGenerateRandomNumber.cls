/** 
 * @description Generates a random number
 */
public class NumberGenerateRandomNumber {
    /** @description Taking odds as an input, this class generates a random number between 0 and the odds, inclusive. Invocable so it can be called from a flow. 
     * @param odds The max number that should be returned
     * @return The random number
	*/
    @InvocableMethod (label='Generate random number') 
    public static List<Integer> generate(List<Integer> odds){
        Integer randomNumber = Integer.valueof((Math.random() * odds[0]));
        List<Integer> randomNumbers = new List<Integer>{randomNumber};
        return randomNumbers;
    }
}
@isTest
private class NumberGenerateRandomNumberTest {
    @isTest static void testRandomNumber(){
        Integer odds = 1000;
        //List<Integer> oddsList = ;
        //GenerateRandomNumber grn = new GenerateRandomNumber();
        List<Integer> randomNumbers = NumberGenerateRandomNumber.generate(new List<Integer>{odds});
        system.assert(randomNumbers.size() == 1);
        system.assert(randomNumbers[0] >= 0);
        system.assert(randomNumbers[0] <= odds);
    }
}
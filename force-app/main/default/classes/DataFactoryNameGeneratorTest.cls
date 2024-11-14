@isTest
class DataFactoryNameGeneratorTest {
    @isTest
    static void createHousehold(){
        DataFactoryNameGenerator dfng = new DataFactoryNameGenerator();
        DataFactoryNameGenerator.RandomName name = new DataFactoryNameGenerator.RandomName();
        name = dfng.generateName(true, true, true);
        System.assert(!String.isBlank(name.firstName), 'No first name generated');
        System.assert(!String.isBlank(name.lastName), 'No last name generated');
        System.assert(!String.isBlank(name.preferredName), 'No preferred name generated');
    }
}
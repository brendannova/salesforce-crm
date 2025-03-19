@isTest
class DataFactoryNameGeneratorTest {
    
    @isTest
    static void generateName_success(){
        DataFactoryNameGenerator nameGenerator = new DataFactoryNameGenerator();
        DataFactoryNameGenerator.RandomName name = nameGenerator.generateName(true, true, true);
        System.assert(!String.isBlank(name.firstName), 'No first name generated');
        System.assert(!String.isBlank(name.lastName), 'No last name generated');
        System.assert(!String.isBlank(name.preferredName), 'No preferred name generated');
    }

    @isTest
    static void generateRecongisableName_success(){
        DataFactoryNameGenerator nameGenerator = new DataFactoryNameGenerator();
        DataFactoryNameGenerator.RandomName name = nameGenerator.getRecognisableName();
        System.assert(!String.isBlank(name.firstName), 'No first name generated');
        System.assert(!String.isBlank(name.lastName), 'No last name generated');
    }
}
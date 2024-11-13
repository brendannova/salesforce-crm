@istest
public class random_name_generator_test {
    
    /**
	* TITLE:	Random name generator test class
	* GOAL:		Test the generation of random first and last names. 
	**/
    
    @istest
    static void test_name_generator(){
        // Generate random first and last names
        random_name_generator rng = new random_name_generator();
        String first_name = rng.generate_name('first_name');
        String last_name = rng.generate_name('last_name'); 
        
        // Check that the length of the first and last names is greater than 0 to ensure a value was returned
        System.assert(first_name.length() > 0);
        System.assert(last_name.length() > 0);    
    }
}
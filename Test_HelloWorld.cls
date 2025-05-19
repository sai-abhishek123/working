@isTest
private class Test_HelloWorld {
    @isTest
    static void testSayHello() {
        // Call the method
        String result = HelloWorld.sayHello();

        // Verify the result
        System.assertEquals('Hello, World!', result, 'The greeting should be "Hello, World!"');
    }
}

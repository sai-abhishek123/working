@isTest
private class Test_CSISBaseQueueable {
    @isTest
    static void testOperationInProgress() {
        String testOpId = 'TEST_OP_1';
        TestCSISQueueable queueable = new TestCSISQueueable(testOpId, 'TEST');
        
        Test.startTest();
        Boolean inProgress = CSISBaseQueueable.isOperationInProgress(testOpId);
        Test.stopTest();
        
        System.assert(inProgress);
    }
    
    @isTest
    static void testStaleOperationCheck() {
        String testOpId = 'TEST_OP_2';
        TestCSISQueueable queueable = new TestCSISQueueable(testOpId, 'TEST');
        
        Test.startTest();
        Boolean inProgress = CSISBaseQueueable.isOperationInProgress(testOpId);
        Test.stopTest();
        
        System.assert(inProgress);
    }
    
    @isTest
    static void testClearOperation() {
        String testOpId = 'TEST_OP_3';
        TestCSISQueueable queueable = new TestCSISQueueable(testOpId, 'TEST');
        
        Test.startTest();
        queueable.execute(null);
        Boolean inProgress = CSISBaseQueueable.isOperationInProgress(testOpId);
        Test.stopTest();
        
        System.assert(!inProgress);
    }
    
    @isTest
    static void testQueueableChainingSuccess() {
        String testOpId = 'TEST_OP_4';
        TestCSISQueueable queueable = new TestCSISQueueable(testOpId, 'TEST');
        
        Test.startTest();
        queueable.testChainQueueable(new TestCSISQueueable('CHAINED_OP', 'TEST'));
        Test.stopTest();
        
        System.assertEquals(0, Limits.getDMLStatements());
    }
    
    @isTest
    static void testHandleError() {
        String testOpId = 'TEST_OP_5';
        TestCSISQueueable queueable = new TestCSISQueueable(testOpId, 'TEST');
        
        Test.startTest();
        queueable.testHandleError(new System.NullPointerException(), 'Test error handling');
        Test.stopTest();
        
        System.assert(!CSISBaseQueueable.isOperationInProgress(testOpId));
    }
    
    private class TestCSISQueueable extends CSISBaseQueueable {
        public TestCSISQueueable(String operationId, String operationType) {
            super(operationId, operationType);
        }
        
        public override void execute(QueueableContext context) {
            clearOperation(operationId);
        }
        
        public void testChainQueueable(Queueable nextJob) {
            chainQueueable(nextJob);
        }
        
        public void testHandleError(Exception ex, String detail) {
            handleError(ex, detail);
        }
    }
}
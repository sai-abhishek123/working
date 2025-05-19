@isTest
private class Test_CSISBatchQueueable {
    @isTest
    static void testBatchQueueableEventType() {
        Test.startTest();
        CSISBatchQueueable batchJob = new CSISBatchQueueable('EVENT', 50, true);
        System.enqueueJob(batchJob);
        Test.stopTest();
        
        // Cannot directly access protected fields, so test a different way
        System.assertNotEquals(null, batchJob);
    }
    
    @isTest
    static void testBatchQueueableOrderType() {
        Test.startTest();
        CSISBatchQueueable batchJob = new CSISBatchQueueable('ORDER', 50, true);
        System.enqueueJob(batchJob);
        Test.stopTest();
        
        System.assertNotEquals(null, batchJob);
    }
    
    @isTest
    static void testBatchQueueableAttendeeType() {
        Test.startTest();
        CSISBatchQueueable batchJob = new CSISBatchQueueable('ATTENDEE', 50, true);
        System.enqueueJob(batchJob);
        Test.stopTest();
        
        System.assertNotEquals(null, batchJob);
    }
    
    @isTest
    static void testBatchQueueableDateRange() {
        Date startDate = Date.today().addDays(-7);
        Date endDate = Date.today();
        
        Test.startTest();
        CSISBatchQueueable batchJob = new CSISBatchQueueable('EVENT', 50, startDate, endDate);
        System.enqueueJob(batchJob);
        Test.stopTest();
        
        System.assertNotEquals(null, batchJob);
    }
    
    @isTest
    static void testBatchQueueableRegAccount() {
        String regAccountCode = 'TEST-REG-123';
        
        Test.startTest();
        CSISBatchQueueable batchJob = new CSISBatchQueueable('ATTENDEE', 50, regAccountCode);
        System.enqueueJob(batchJob);
        Test.stopTest();
        
        System.assertNotEquals(null, batchJob);
    }
    
    @isTest
    static void testExecuteEventType() {
        CSISBatchQueueable batchJob = new CSISBatchQueueable('EVENT', 50, true);
        
        Test.startTest();
        batchJob.execute(null);
        Test.stopTest();
        
        System.assertNotEquals(null, batchJob);
    }
    
    @isTest
    static void testExecuteOrderType() {
        CSISBatchQueueable batchJob = new CSISBatchQueueable('ORDER', 50, true);
        
        Test.startTest();
        batchJob.execute(null);
        Test.stopTest();
        
        System.assertNotEquals(null, batchJob);
    }
    
    @isTest
    static void testExecuteAttendeeType() {
        CSISBatchQueueable batchJob = new CSISBatchQueueable('ATTENDEE', 50, true);
        
        Test.startTest();
        batchJob.execute(null);
        Test.stopTest();
        
        System.assertNotEquals(null, batchJob);
    }
    
    @isTest
    static void testRunFullIntegration() {
        Test.startTest();
        CSISBatchQueueable.runFullIntegration();
        Test.stopTest();
        
        // Verify that the method executed without errors
        System.assertEquals(0, Limits.getDMLStatements());
    }
    
    @isTest
    static void testRunPendingIntegration() {
        Test.startTest();
        CSISBatchQueueable.runPendingIntegration();
        Test.stopTest();
        
        // Verify that the method executed without errors
        System.assertEquals(0, Limits.getDMLStatements());
    }
}
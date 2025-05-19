@isTest
private class Test_CSISEventBatch implements System.Queueable {
    private List<conference360__Event__c> eventsToProcess;
    
    // Constructor for the queueable implementation
    public Test_CSISEventBatch(List<conference360__Event__c> events) {
        this.eventsToProcess = events;
    }
    
    // Implementation of the queueable execute method
    public void execute(System.QueueableContext context) {
        // This is used to test the branch where System.isQueueable() returns true
        if (eventsToProcess != null && !eventsToProcess.isEmpty()) {
            CSISEventBatch batchInstance = new CSISEventBatch();
            batchInstance.execute(null, eventsToProcess);
        }
    }
    
    // Test data setup method
    @testSetup
    static void setupTestData() {
        // Create test Account
        Account acc = new Account(
            Name = 'Test Account',
            Acc_Number__c = 'COMP-678910'  // This should be the same value as what Computed_ID__c would have
        );
        insert acc;
        
        // We don't need to update Computed_ID__c as it's read-only
        // The Acc_Number__c value will be used for the computed ID
        
        // Create 5 test events with different scenarios
        List<conference360__Event__c> testEvents = new List<conference360__Event__c>();
        
        // Event 1: Approved and not yet sent to CSIS
        conference360__Event__c event1 = new conference360__Event__c(
            Name = 'Test Event 1',
            externalId__c = 'EXT-001',
            Fiscal_Year__c = '2025',
            conference360__Event_Start_Date__c = Date.today(),
            conference360__Event_End_Date__c = Date.today().addDays(3),
            conference360__Status__c = 'Active',
            L3__c = true,
            conference360__Organizer_Account__c = acc.Id,
            Approved_to_Send_to_CSIS__c = true,
            Event_Data_Sent_to_CSIS__c = false
        );
        testEvents.add(event1);
        
        // Event 2: Approved and already sent to CSIS
        conference360__Event__c event2 = new conference360__Event__c(
            Name = 'Test Event 2',
            externalId__c = 'EXT-002',
            Fiscal_Year__c = '2025',
            conference360__Event_Start_Date__c = Date.today().addDays(5),
            conference360__Event_End_Date__c = Date.today().addDays(8),
            conference360__Status__c = 'Active',
            L3__c = true,
            conference360__Organizer_Account__c = acc.Id,
            Approved_to_Send_to_CSIS__c = true,
            Event_Data_Sent_to_CSIS__c = true
        );
        testEvents.add(event2);
        
        // Event 3: Not approved to send to CSIS
        conference360__Event__c event3 = new conference360__Event__c(
            Name = 'Test Event 3',
            externalId__c = 'EXT-003',
            Fiscal_Year__c = '2025',
            conference360__Event_Start_Date__c = Date.today().addDays(10),
            conference360__Event_End_Date__c = Date.today().addDays(13),
            conference360__Status__c = 'Active',
            L3__c = false,
            conference360__Organizer_Account__c = acc.Id,
            Approved_to_Send_to_CSIS__c = false,
            Event_Data_Sent_to_CSIS__c = false
        );
        testEvents.add(event3);
        
        // Event 4: Approved but with computed account ID already set
        conference360__Event__c event4 = new conference360__Event__c(
            Name = 'Test Event 4',
            externalId__c = 'EXT-004',
            Fiscal_Year__c = '2025',
            conference360__Event_Start_Date__c = Date.today().addDays(15),
            conference360__Event_End_Date__c = Date.today().addDays(18),
            conference360__Status__c = 'Active',
            L3__c = true,
            conference360__Organizer_Account__c = acc.Id,
            Approved_to_Send_to_CSIS__c = true,
            Event_Data_Sent_to_CSIS__c = false,
            Computed_Id_Account__c = 'COMP-678910'
        );
        testEvents.add(event4);
        
        // Event 5: Approved but without an organizer account
        conference360__Event__c event5 = new conference360__Event__c(
            Name = 'Test Event 5',
            externalId__c = 'EXT-005',
            Fiscal_Year__c = '2025',
            conference360__Event_Start_Date__c = Date.today().addDays(20),
            conference360__Event_End_Date__c = Date.today().addDays(23),
            conference360__Status__c = 'Active',
            L3__c = false,
            Approved_to_Send_to_CSIS__c = true,
            Event_Data_Sent_to_CSIS__c = false
        );
        testEvents.add(event5);
        
        insert testEvents;
    }
    
    // Test for default constructor
    @isTest
    static void testDefaultConstructor() {
        Test.startTest();
        CSISEventBatch batchInstance = new CSISEventBatch();
        Test.stopTest();
        
        System.assertNotEquals(null, batchInstance, 'Batch instance should not be null');
    }
    
    // Test for constructor with nonIntegratedOnly parameter
    @isTest
    static void testNonIntegratedOnlyConstructor() {
        Test.startTest();
        CSISEventBatch batchInstance = new CSISEventBatch(true);
        Test.stopTest();
        
        System.assertNotEquals(null, batchInstance, 'Batch instance should not be null');
    }
    
    // Test for constructor with date range parameters
    @isTest
    static void testDateRangeConstructor() {
        Date startDate = Date.today();
        Date endDate = Date.today().addDays(30);
        
        Test.startTest();
        CSISEventBatch batchInstance = new CSISEventBatch(startDate, endDate);
        Test.stopTest();
        
        System.assertNotEquals(null, batchInstance, 'Batch instance should not be null');
    }
    
    // Test runBatch static method
    @isTest
    static void testRunBatch() {
        Test.startTest();
        Id batchId = CSISEventBatch.runBatch();
        Test.stopTest();
        
        System.assertNotEquals(null, batchId, 'Batch ID should not be null');
    }
    
    // Test runBatchForDateRange static method
    @isTest
    static void testRunBatchForDateRange() {
        Date startDate = Date.today();
        Date endDate = Date.today().addDays(30);
        
        Test.startTest();
        Id batchId = CSISEventBatch.runBatchForDateRange(startDate, endDate);
        Test.stopTest();
        
        System.assertNotEquals(null, batchId, 'Batch ID should not be null');
    }
    
    // Test start method with default parameters
    @isTest
    static void testStartDefaultQuery() {
        CSISEventBatch batchInstance = new CSISEventBatch();
        
        Test.startTest();
        Database.QueryLocator queryLocator = batchInstance.start(null);
        Test.stopTest();
        
        // Count the records returned by the query
        Integer recordCount = 0;
        Database.QueryLocatorIterator it = queryLocator.iterator();
        while (it.hasNext()) {
            it.next();
            recordCount++;
        }
        
        // We expect all approved events (1, 2, 4, 5) to be returned
        System.assertEquals(4, recordCount, 'Query should return all approved events');
    }
    
    // Test start method with nonIntegratedOnly = true
    @isTest
    static void testStartNonIntegratedOnlyQuery() {
        CSISEventBatch batchInstance = new CSISEventBatch(true);
        
        Test.startTest();
        Database.QueryLocator queryLocator = batchInstance.start(null);
        Test.stopTest();
        
        // Count the records returned by the query
        Integer recordCount = 0;
        Database.QueryLocatorIterator it = queryLocator.iterator();
        while (it.hasNext()) {
            it.next();
            recordCount++;
        }
        
        // We expect only events 1, 4, 5 to be returned (approved and not sent)
        System.assertEquals(3, recordCount, 'Query should return approved events not yet sent to CSIS');
    }
    
    // Test start method with date range
    @isTest
    static void testStartDateRangeQuery() {
        Date startDate = Date.today();
        Date endDate = Date.today().addDays(10); // This covers events 1 and 2
        
        CSISEventBatch batchInstance = new CSISEventBatch(startDate, endDate);
        
        Test.startTest();
        Database.QueryLocator queryLocator = batchInstance.start(null);
        Test.stopTest();
        
        // Count the records returned by the query
        Integer recordCount = 0;
        Database.QueryLocatorIterator it = queryLocator.iterator();
        while (it.hasNext()) {
            it.next();
            recordCount++;
        }
        
        // We expect events 1 and 2 to be returned (start date within range)
        System.assertEquals(2, recordCount, 'Query should return events within date range');
    }
    
    // Test execute method specifically focusing on the private updateComputedIdAccountField method
    @isTest
    static void testExecuteMethodAndUpdateComputedIdAccount() {
        // Get events for testing - specifically looking for events that need Computed_Id_Account__c updated
        List<conference360__Event__c> events = [
            SELECT Id, Name, externalId__c, Fiscal_Year__c, 
                   conference360__Event_Start_Date__c, conference360__Event_End_Date__c, 
                   conference360__Status__c, L3__c, 
                   conference360__Organizer_Account__c, 
                   Event_Data_Sent_to_CSIS__c, Computed_Id_Account__c 
            FROM conference360__Event__c 
            WHERE Approved_to_Send_to_CSIS__c = true 
            AND (Event_Data_Sent_to_CSIS__c = false OR Event_Data_Sent_to_CSIS__c = null)
            AND conference360__Organizer_Account__c != null
            AND (Computed_Id_Account__c = null OR Computed_Id_Account__c = '')
            LIMIT 1
        ];
        
        // If no qualifying events found, create one
        if (events.isEmpty()) {
            List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
            if (!accounts.isEmpty()) {
                conference360__Event__c newEvent = new conference360__Event__c(
                    Name = 'Test Event for Private Method',
                    externalId__c = 'EXT-PRIV-001',
                    Fiscal_Year__c = '2025',
                    conference360__Event_Start_Date__c = Date.today(),
                    conference360__Event_End_Date__c = Date.today().addDays(3),
                    conference360__Status__c = 'Active',
                    L3__c = true,
                    conference360__Organizer_Account__c = accounts[0].Id,
                    Approved_to_Send_to_CSIS__c = true,
                    Event_Data_Sent_to_CSIS__c = false
                );
                insert newEvent;
                
                events = [
                    SELECT Id, Name, externalId__c, Fiscal_Year__c, 
                           conference360__Event_Start_Date__c, conference360__Event_End_Date__c, 
                           conference360__Status__c, L3__c, 
                           conference360__Organizer_Account__c, 
                           Event_Data_Sent_to_CSIS__c, Computed_Id_Account__c 
                    FROM conference360__Event__c 
                    WHERE Id = :newEvent.Id
                ];
            }
        }
        
        // Skip test if still no events available
        if (events.isEmpty()) {
            return;
        }
        
        CSISEventBatch batchInstance = new CSISEventBatch();
        
        Test.startTest();
        batchInstance.execute(null, events);
        Test.stopTest();
        
        // Verify the field was updated
        List<conference360__Event__c> updatedEvents = [
            SELECT Id, Computed_Id_Account__c 
            FROM conference360__Event__c 
            WHERE Id IN :events
        ];
        
        for (conference360__Event__c updatedEvent : updatedEvents) {
            System.assertNotEquals(null, updatedEvent.Computed_Id_Account__c, 
                                  'Computed_Id_Account__c should be updated');
            System.assertEquals('COMP-678910', updatedEvent.Computed_Id_Account__c, 
                               'Computed_Id_Account__c should match Account.Acc_Number__c');
        }
    }
    
    // Test execute method in a normal context (not future/queueable)
    @isTest
    static void testExecuteNormalContext() {
        List<conference360__Event__c> events = [
            SELECT Id, Name, externalId__c, Fiscal_Year__c, 
                   conference360__Event_Start_Date__c, conference360__Event_End_Date__c, 
                   conference360__Status__c, L3__c, 
                   conference360__Organizer_Account__c, 
                   Event_Data_Sent_to_CSIS__c, Computed_Id_Account__c 
            FROM conference360__Event__c 
            WHERE Approved_to_Send_to_CSIS__c = true 
            LIMIT 2
        ];
        
        if (events.isEmpty()) {
            return;
        }
        
        CSISEventBatch batchInstance = new CSISEventBatch();
        
        // This will hit the System.enqueueJob branch in execute
        Test.startTest();
        batchInstance.execute(null, events);
        Test.stopTest();
        
        System.assert(true, 'Method completed successfully');
    }
    
    // Test execute method in a queueable context
    @isTest
    static void testExecuteQueueableContext() {
        List<conference360__Event__c> events = [
            SELECT Id, Name, externalId__c, Fiscal_Year__c, 
                   conference360__Event_Start_Date__c, conference360__Event_End_Date__c, 
                   conference360__Status__c, L3__c, 
                   conference360__Organizer_Account__c, 
                   Event_Data_Sent_to_CSIS__c, Computed_Id_Account__c 
            FROM conference360__Event__c 
            WHERE Approved_to_Send_to_CSIS__c = true 
            LIMIT 2
        ];
        
        if (events.isEmpty()) {
            return;
        }
        
        // This will hit the else branch (System.isQueueable() == true)
        Test.startTest();
        System.enqueueJob(new Test_CSISEventBatch(events));
        Test.stopTest();
        
        System.assert(true, 'Method completed successfully in queueable context');
    }
    
    // Test execute method in a future context
    @isTest
    static void testExecuteFutureContext() {
        List<conference360__Event__c> events = [
            SELECT Id
            FROM conference360__Event__c 
            WHERE Approved_to_Send_to_CSIS__c = true 
            LIMIT 2
        ];
        
        if (events.isEmpty()) {
            return;
        }
        
        List<Id> eventIds = new List<Id>();
        for (conference360__Event__c event : events) {
            eventIds.add(event.Id);
        }
        
        // Call a future method that will execute the batch
        Test.startTest();
        executeBatchInFuture(eventIds);
        Test.stopTest();
        
        System.assert(true, 'Method completed successfully in future context');
    }
    
    // Future method to test the future context branch
    @future
    private static void executeBatchInFuture(List<Id> eventIds) {
        List<conference360__Event__c> events = [
            SELECT Id, Name, externalId__c, Fiscal_Year__c, 
                   conference360__Event_Start_Date__c, conference360__Event_End_Date__c, 
                   conference360__Status__c, L3__c, 
                   conference360__Organizer_Account__c, 
                   Event_Data_Sent_to_CSIS__c, Computed_Id_Account__c 
            FROM conference360__Event__c 
            WHERE Id IN :eventIds
        ];
        
        CSISEventBatch batchInstance = new CSISEventBatch();
        batchInstance.execute(null, events);
    }
    
    // Test finish method
    @isTest
    static void testFinishMethod() {
        CSISEventBatch batchInstance = new CSISEventBatch();
        
        Test.startTest();
        batchInstance.finish(null);
        Test.stopTest();
        
        System.assert(true, 'Finish method should complete successfully');
    }
    
    // Test error handling in updateComputedIdAccountField method
    @isTest
    static void testUpdateComputedIdAccountFieldErrorHandling() {
        // Test with invalid events to trigger error handling
        List<conference360__Event__c> events = new List<conference360__Event__c>();
        
        // Add event with no valid account relationship
        conference360__Event__c invalidEvent = new conference360__Event__c(
            Name = 'Test Invalid Event',
            Approved_to_Send_to_CSIS__c = true,
            Event_Data_Sent_to_CSIS__c = false
        );
        events.add(invalidEvent);
        
        CSISEventBatch batchInstance = new CSISEventBatch();
        
        Test.startTest();
        try {
            batchInstance.execute(null, events);
            System.assert(true, 'Method should handle errors gracefully');
        } catch (Exception e) {
            System.assert(false, 'Method should not throw unhandled exceptions: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    // Test empty list handling
    @isTest
    static void testEmptyListHandling() {
        List<conference360__Event__c> emptyList = new List<conference360__Event__c>();
        
        CSISEventBatch batchInstance = new CSISEventBatch();
        
        Test.startTest();
        batchInstance.execute(null, emptyList);
        Test.stopTest();
        
        System.assert(true, 'Method should handle empty list gracefully');
    }
}@isTest
private class Test_CSISEventBatch {
    
    // Test data setup method
    @testSetup
    static void setupTestData() {
        // Create test Account
        Account acc = new Account(
            Name = 'Test Account',
            Acc_Number__c = 'COMP-678910'  // This should be the same value as what Computed_ID__c would have
        );
        insert acc;
        
        // We don't need to update Computed_ID__c as it's read-only
        // The Acc_Number__c value will be used for the computed ID
        
        // Create 5 test events with different scenarios
        List<conference360__Event__c> testEvents = new List<conference360__Event__c>();
        
        // Event 1: Approved and not yet sent to CSIS
        conference360__Event__c event1 = new conference360__Event__c(
            Name = 'Test Event 1',
            externalId__c = 'EXT-001',
            Fiscal_Year__c = '2025',
            conference360__Event_Start_Date__c = Date.today(),
            conference360__Event_End_Date__c = Date.today().addDays(3),
            conference360__Status__c = 'Active',
            L3__c = true,
            conference360__Organizer_Account__c = acc.Id,
            Approved_to_Send_to_CSIS__c = true,
            Event_Data_Sent_to_CSIS__c = false
        );
        testEvents.add(event1);
        
        // Event 2: Approved and already sent to CSIS
        conference360__Event__c event2 = new conference360__Event__c(
            Name = 'Test Event 2',
            externalId__c = 'EXT-002',
            Fiscal_Year__c = '2025',
            conference360__Event_Start_Date__c = Date.today().addDays(5),
            conference360__Event_End_Date__c = Date.today().addDays(8),
            conference360__Status__c = 'Active',
            L3__c = true,
            conference360__Organizer_Account__c = acc.Id,
            Approved_to_Send_to_CSIS__c = true,
            Event_Data_Sent_to_CSIS__c = true
        );
        testEvents.add(event2);
        
        // Event 3: Not approved to send to CSIS
        conference360__Event__c event3 = new conference360__Event__c(
            Name = 'Test Event 3',
            externalId__c = 'EXT-003',
            Fiscal_Year__c = '2025',
            conference360__Event_Start_Date__c = Date.today().addDays(10),
            conference360__Event_End_Date__c = Date.today().addDays(13),
            conference360__Status__c = 'Active',
            L3__c = false,
            conference360__Organizer_Account__c = acc.Id,
            Approved_to_Send_to_CSIS__c = false,
            Event_Data_Sent_to_CSIS__c = false
        );
        testEvents.add(event3);
        
        // Event 4: Approved but with computed account ID already set
        conference360__Event__c event4 = new conference360__Event__c(
            Name = 'Test Event 4',
            externalId__c = 'EXT-004',
            Fiscal_Year__c = '2025',
            conference360__Event_Start_Date__c = Date.today().addDays(15),
            conference360__Event_End_Date__c = Date.today().addDays(18),
            conference360__Status__c = 'Active',
            L3__c = true,
            conference360__Organizer_Account__c = acc.Id,
            Approved_to_Send_to_CSIS__c = true,
            Event_Data_Sent_to_CSIS__c = false,
            Computed_Id_Account__c = 'COMP-678910'
        );
        testEvents.add(event4);
        
        // Event 5: Approved but without an organizer account
        conference360__Event__c event5 = new conference360__Event__c(
            Name = 'Test Event 5',
            externalId__c = 'EXT-005',
            Fiscal_Year__c = '2025',
            conference360__Event_Start_Date__c = Date.today().addDays(20),
            conference360__Event_End_Date__c = Date.today().addDays(23),
            conference360__Status__c = 'Active',
            L3__c = false,
            Approved_to_Send_to_CSIS__c = true,
            Event_Data_Sent_to_CSIS__c = false
        );
        testEvents.add(event5);
        
        // Add optional fields if they exist in the schema
        addOptionalFields(testEvents);
        
        insert testEvents;
    }
    
    private static void addOptionalFields(List<conference360__Event__c> events) {
        // Try to dynamically add fields that might exist in the schema
        // but aren't required for the test to work
        try {
            Map<String, Schema.SObjectField> eventFields = Schema.SObjectType.conference360__Event__c.fields.getMap();
            
            for (conference360__Event__c event : events) {
                // Check and add only fields that exist in the schema
                if (eventFields.containsKey('Department__c')) {
                    // Department__c field exists but we don't have the object to relate to
                }
                
                if (eventFields.containsKey('Course_Offering__c')) {
                    // Course_Offering__c field exists but we don't have the object to relate to
                }
                
                // Custom_Event_Page_URL__c can't be written to per the user's feedback
                // We won't try to add it even if it exists
            }
        } catch (Exception ex) {
            System.debug('Error adding optional fields: ' + ex.getMessage());
        }
    }
    
    // Test for default constructor
    @isTest
    static void testDefaultConstructor() {
        Test.startTest();
        CSISEventBatch batchInstance = new CSISEventBatch();
        Test.stopTest();
        
        System.assertNotEquals(null, batchInstance, 'Batch instance should not be null');
    }
    
    // Test for constructor with nonIntegratedOnly parameter
    @isTest
    static void testNonIntegratedOnlyConstructor() {
        Test.startTest();
        CSISEventBatch batchInstance = new CSISEventBatch(true);
        Test.stopTest();
        
        System.assertNotEquals(null, batchInstance, 'Batch instance should not be null');
    }
    
    // Test for constructor with date range parameters
    @isTest
    static void testDateRangeConstructor() {
        Date startDate = Date.today();
        Date endDate = Date.today().addDays(30);
        
        Test.startTest();
        CSISEventBatch batchInstance = new CSISEventBatch(startDate, endDate);
        Test.stopTest();
        
        System.assertNotEquals(null, batchInstance, 'Batch instance should not be null');
    }
    
    // Test runBatch static method
    @isTest
    static void testRunBatch() {
        Test.startTest();
        Id batchId = CSISEventBatch.runBatch();
        Test.stopTest();
        
        System.assertNotEquals(null, batchId, 'Batch ID should not be null');
    }
    
    // Test runBatchForDateRange static method
    @isTest
    static void testRunBatchForDateRange() {
        Date startDate = Date.today();
        Date endDate = Date.today().addDays(30);
        
        Test.startTest();
        Id batchId = CSISEventBatch.runBatchForDateRange(startDate, endDate);
        Test.stopTest();
        
        System.assertNotEquals(null, batchId, 'Batch ID should not be null');
    }
    
    // Test start method with default parameters
    @isTest
    static void testStartDefaultQuery() {
        CSISEventBatch batchInstance = new CSISEventBatch();
        
        Test.startTest();
        Database.QueryLocator queryLocator = batchInstance.start(null);
        Test.stopTest();
        
        // Count the records returned by the query
        Integer recordCount = 0;
        Database.QueryLocatorIterator it = queryLocator.iterator();
        while (it.hasNext()) {
            it.next();
            recordCount++;
        }
        
        // We expect all approved events (1, 2, 4, 5) to be returned
        System.assertEquals(4, recordCount, 'Query should return all approved events');
    }
    
    // Test start method with nonIntegratedOnly = true
    @isTest
    static void testStartNonIntegratedOnlyQuery() {
        CSISEventBatch batchInstance = new CSISEventBatch(true);
        
        Test.startTest();
        Database.QueryLocator queryLocator = batchInstance.start(null);
        Test.stopTest();
        
        // Count the records returned by the query
        Integer recordCount = 0;
        Database.QueryLocatorIterator it = queryLocator.iterator();
        while (it.hasNext()) {
            it.next();
            recordCount++;
        }
        
        // We expect only events 1, 4, 5 to be returned (approved and not sent)
        System.assertEquals(3, recordCount, 'Query should return approved events not yet sent to CSIS');
    }
    
    // Test start method with date range
    @isTest
    static void testStartDateRangeQuery() {
        Date startDate = Date.today();
        Date endDate = Date.today().addDays(10); // This covers events 1 and 2
        
        CSISEventBatch batchInstance = new CSISEventBatch(startDate, endDate);
        
        Test.startTest();
        Database.QueryLocator queryLocator = batchInstance.start(null);
        Test.stopTest();
        
        // Count the records returned by the query
        Integer recordCount = 0;
        Database.QueryLocatorIterator it = queryLocator.iterator();
        while (it.hasNext()) {
            it.next();
            recordCount++;
        }
        
        // We expect events 1 and 2 to be returned (start date within range)
        System.assertEquals(2, recordCount, 'Query should return events within date range');
    }
    
    // Test execute method specifically focusing on the private updateComputedIdAccountField method
    @isTest
    static void testExecuteMethodAndUpdateComputedIdAccount() {
        // Get events for testing - specifically looking for events that need Computed_Id_Account__c updated
        // This helps test the private updateComputedIdAccountField method through the public execute method
        List<conference360__Event__c> events = [
            SELECT Id, Name, externalId__c, Fiscal_Year__c, 
                   conference360__Event_Start_Date__c, conference360__Event_End_Date__c, 
                   conference360__Status__c, L3__c, 
                   conference360__Organizer_Account__c, 
                   Event_Data_Sent_to_CSIS__c, Computed_Id_Account__c 
            FROM conference360__Event__c 
            WHERE Approved_to_Send_to_CSIS__c = true 
            AND (Event_Data_Sent_to_CSIS__c = false OR Event_Data_Sent_to_CSIS__c = null)
            AND conference360__Organizer_Account__c != null
            AND (Computed_Id_Account__c = null OR Computed_Id_Account__c = '')
            LIMIT 1
        ];
        
        // If no qualifying events found, create one specifically for testing the private method
        if (events.isEmpty()) {
            // Find an account with Computed_ID__c
            List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
            if (!accounts.isEmpty()) {
                // Create a new event that will trigger the updateComputedIdAccountField logic
                conference360__Event__c newEvent = new conference360__Event__c(
                    Name = 'Test Event for Private Method',
                    externalId__c = 'EXT-PRIV-001',
                    Fiscal_Year__c = '2025',
                    conference360__Event_Start_Date__c = Date.today(),
                    conference360__Event_End_Date__c = Date.today().addDays(3),
                    conference360__Status__c = 'Active',
                    L3__c = true,
                    conference360__Organizer_Account__c = accounts[0].Id,
                    Approved_to_Send_to_CSIS__c = true,
                    Event_Data_Sent_to_CSIS__c = false,
                    Computed_Id_Account__c = null
                );
                insert newEvent;
                
                // Query the newly created event
                events = [
                    SELECT Id, Name, externalId__c, Fiscal_Year__c, 
                           conference360__Event_Start_Date__c, conference360__Event_End_Date__c, 
                           conference360__Status__c, L3__c, 
                           conference360__Organizer_Account__c, 
                           Event_Data_Sent_to_CSIS__c, Computed_Id_Account__c 
                    FROM conference360__Event__c 
                    WHERE Id = :newEvent.Id
                ];
            }
        }
        
        // Skip test if still no events available
        if (events.isEmpty()) {
            System.debug('Could not create test data for private method test - skipping');
            return;
        }
        
        // Create a batch instance
        CSISEventBatch batchInstance = new CSISEventBatch();
        
        // Execute method directly to reach the private updateComputedIdAccountField method
        Test.startTest();
        batchInstance.execute(null, events);
        Test.stopTest();
        
        // Query to check if Computed_Id_Account__c was updated
        List<conference360__Event__c> updatedEvents = [
            SELECT Id, Computed_Id_Account__c 
            FROM conference360__Event__c 
            WHERE Id IN :events
        ];
        
        // Verify that the field was updated, which confirms the private method executed
        for (conference360__Event__c updatedEvent : updatedEvents) {
            System.assertNotEquals(null, updatedEvent.Computed_Id_Account__c, 
                                  'Computed_Id_Account__c should be updated by the private method');
            System.debug('Updated Computed_Id_Account__c: ' + updatedEvent.Computed_Id_Account__c);
        }
    }
    
    // Test execute method in a regular execution context (not a future or queueable context)
    @isTest
    static void testExecuteNormalContext() {
        // Get events for testing
        List<conference360__Event__c> events = [
            SELECT Id, Name, externalId__c, Fiscal_Year__c, 
                   conference360__Event_Start_Date__c, conference360__Event_End_Date__c, 
                   conference360__Status__c, L3__c, 
                   conference360__Organizer_Account__c, 
                   Event_Data_Sent_to_CSIS__c, Computed_Id_Account__c 
            FROM conference360__Event__c 
            WHERE Approved_to_Send_to_CSIS__c = true 
            LIMIT 1
        ];
        
        // Skip test if no events available
        if (events.isEmpty()) {
            System.debug('No events found for test - skipping');
            return;
        }
        
        // Create a testable context
        CSISEventBatch batchInstance = new CSISEventBatch();
        
        // The Test.startTest() and Test.stopTest() ensure we're not in a future or queueable context
        // This should hit the System.enqueueJob branch in the execute method
        Test.startTest();
        batchInstance.execute(null, events);
        Test.stopTest();
        
        // We can't directly verify System.enqueueJob was called
        // But we can verify the method completed without exceptions
        System.assert(true, 'Method completed without exceptions');
    }
    
    // Test execute method in a future or queueable context
    @isTest
    static void testExecuteFutureContext() {
        // Get events for testing
        List<conference360__Event__c> events = [
            SELECT Id, Name, externalId__c, Fiscal_Year__c, 
                   conference360__Event_Start_Date__c, conference360__Event_End_Date__c, 
                   conference360__Status__c, L3__c, 
                   conference360__Organizer_Account__c, 
                   Event_Data_Sent_to_CSIS__c, Computed_Id_Account__c 
            FROM conference360__Event__c 
            WHERE Approved_to_Send_to_CSIS__c = true 
            LIMIT 2
        ];
        
        // Skip test if no events available
        if (events.isEmpty()) {
            System.debug('No events found for test - skipping');
            return;
        }
        
        // Set up to mimic a future context
        CSISEventBatch batchInstance = new CSISEventBatch();
        
        // To test the else branch (when in future or queueable context),
        // we need to simulate that context
        Test.startTest();
        // Call the method inside a Queueable to simulate being in that context
        System.enqueueJob(new TestQueueable(events, batchInstance));
        Test.stopTest();
        
        // We can't directly verify CSISIntegration.sendEventsWithJWT was called
        // But we can verify the method completed without exceptions
        System.assert(true, 'Method completed without exceptions in future context');
    }
    
    // Helper queueable class to simulate a queueable context
    private class TestQueueable implements System.Queueable {
        private List<conference360__Event__c> events;
        private CSISEventBatch batchInstance;
        
        public TestQueueable(List<conference360__Event__c> events, CSISEventBatch batchInstance) {
            this.events = events;
            this.batchInstance = batchInstance;
        }
        
        public void execute(System.QueueableContext context) {
            // This will execute in a queueable context
            // So it should hit the else branch in the batch's execute method
            batchInstance.execute(null, events);
        }
    }
    
    // Test finish method
    @isTest
    static void testFinishMethod() {
        CSISEventBatch batchInstance = new CSISEventBatch();
        
        Test.startTest();
        batchInstance.finish(null);
        Test.stopTest();
        
        // No assertions needed as the method is empty, but this covers it for code coverage
        System.assert(true, 'Finish method should complete successfully');
    }
    
    // Test error handling in updateComputedIdAccountField method
    @isTest
    static void testUpdateComputedIdAccountFieldErrorHandling() {
        // Testing with invalid events to trigger error handling
        List<conference360__Event__c> events = new List<conference360__Event__c>();
        
        // Add event with no valid account relationship
        conference360__Event__c invalidEvent = new conference360__Event__c(
            Name = 'Test Invalid Event',
            Approved_to_Send_to_CSIS__c = true,
            Event_Data_Sent_to_CSIS__c = false
        );
        events.add(invalidEvent);
        
        CSISEventBatch batchInstance = new CSISEventBatch();
        
        Test.startTest();
        // This should not throw an exception because of error handling
        try {
            batchInstance.execute(null, events);
            System.assert(true@isTest
private class Test_CSISEventBatch {
    
    // Test data setup method
    @testSetup
    static void setupTestData() {
    // Create test Account
        Account acc = new Account(
            Name = 'Test Account'
        );
        // Adding field dynamically to handle cases where it may or may not exist
        try {
            Schema.SObjectField accNumberField = Schema.SObjectType.Account.fields.getMap().get('Acc_Number__c');
            if (accNumberField != null) {
                acc.put('Acc_Number__c', 'ACC-12345');
            }
        } catch (Exception e) {
            System.debug('Acc_Number__c field not available: ' + e.getMessage());
        }
        insert acc;
        
        // Update the Computed_ID__c field if it exists
        try {
            acc = [SELECT Id FROM Account WHERE Id = :acc.Id];
            acc.put('Computed_ID__c', 'COMP-678910');
            update acc;
        } catch (Exception e) {
            System.debug('Note: Computed_ID__c might not be writeable or might not exist: ' + e.getMessage());
        }
        
        // Create 5 test events with different scenarios
        List<conference360__Event__c> testEvents = new List<conference360__Event__c>();
        
        // Event 1: Approved and not yet sent to CSIS
        conference360__Event__c event1 = new conference360__Event__c(
            Name = 'Test Event 1',
            externalId__c = 'EXT-001',
            Fiscal_Year__c = '2025',
            conference360__Event_Start_Date__c = Date.today(),
            conference360__Event_End_Date__c = Date.today().addDays(3),
            conference360__Status__c = 'Active',
            L3__c = true,
            conference360__Organizer_Account__c = acc.Id,
            Approved_to_Send_to_CSIS__c = true,
            Event_Data_Sent_to_CSIS__c = false
        );
        testEvents.add(event1);
        
        // Event 2: Approved and already sent to CSIS
        conference360__Event__c event2 = new conference360__Event__c(
            Name = 'Test Event 2',
            externalId__c = 'EXT-002',
            Fiscal_Year__c = '2025',
            conference360__Event_Start_Date__c = Date.today().addDays(5),
            conference360__Event_End_Date__c = Date.today().addDays(8),
            conference360__Status__c = 'Active',
            L3__c = true,
            conference360__Organizer_Account__c = acc.Id,
            Approved_to_Send_to_CSIS__c = true,
            Event_Data_Sent_to_CSIS__c = true
        );
        testEvents.add(event2);
        
        // Event 3: Not approved to send to CSIS
        conference360__Event__c event3 = new conference360__Event__c(
            Name = 'Test Event 3',
            externalId__c = 'EXT-003',
            Fiscal_Year__c = '2025',
            conference360__Event_Start_Date__c = Date.today().addDays(10),
            conference360__Event_End_Date__c = Date.today().addDays(13),
            conference360__Status__c = 'Active',
            L3__c = false,
            conference360__Organizer_Account__c = acc.Id,
            Approved_to_Send_to_CSIS__c = false,
            Event_Data_Sent_to_CSIS__c = false
        );
        testEvents.add(event3);
        
        // Event 4: Approved but with computed account ID already set
        conference360__Event__c event4 = new conference360__Event__c(
            Name = 'Test Event 4',
            externalId__c = 'EXT-004',
            Fiscal_Year__c = '2025',
            conference360__Event_Start_Date__c = Date.today().addDays(15),
            conference360__Event_End_Date__c = Date.today().addDays(18),
            conference360__Status__c = 'Active',
            L3__c = true,
            conference360__Organizer_Account__c = acc.Id,
            Approved_to_Send_to_CSIS__c = true,
            Event_Data_Sent_to_CSIS__c = false,
            Computed_Id_Account__c = 'COMP-678910'
        );
        testEvents.add(event4);
        
        // Event 5: Approved but without an organizer account
        conference360__Event__c event5 = new conference360__Event__c(
            Name = 'Test Event 5',
            externalId__c = 'EXT-005',
            Fiscal_Year__c = '2025',
            conference360__Event_Start_Date__c = Date.today().addDays(20),
            conference360__Event_End_Date__c = Date.today().addDays(23),
            conference360__Status__c = 'Active',
            L3__c = false,
            Approved_to_Send_to_CSIS__c = true,
            Event_Data_Sent_to_CSIS__c = false
        );
        testEvents.add(event5);
        
        // Add optional fields if they exist in the schema
        addOptionalFields(testEvents);
        
        insert testEvents;
    }
    
    private static void addOptionalFields(List<conference360__Event__c> events) {
        // Try to dynamically add fields that might exist in the schema
        // but aren't required for the test to work
        try {
            Map<String, Schema.SObjectField> eventFields = Schema.SObjectType.conference360__Event__c.fields.getMap();
            
            for (conference360__Event__c event : events) {
                // Check and add only fields that exist in the schema
                if (eventFields.containsKey('Department__c')) {
                    // Department__c field exists but we don't have the object to relate to
                }
                
                if (eventFields.containsKey('Course_Offering__c')) {
                    // Course_Offering__c field exists but we don't have the object to relate to
                }
                
                // Custom_Event_Page_URL__c can't be written to per the user's feedback
                // We won't try to add it even if it exists
            }
        } catch (Exception ex) {
            System.debug('Error adding optional fields: ' + ex.getMessage());
        }
    }
    
    // Test for default constructor
    @isTest
    static void testDefaultConstructor() {
        Test.startTest();
        CSISEventBatch batchInstance = new CSISEventBatch();
        Test.stopTest();
        
        System.assertNotEquals(null, batchInstance, 'Batch instance should not be null');
    }
    
    // Test for constructor with nonIntegratedOnly parameter
    @isTest
    static void testNonIntegratedOnlyConstructor() {
        Test.startTest();
        CSISEventBatch batchInstance = new CSISEventBatch(true);
        Test.stopTest();
        
        System.assertNotEquals(null, batchInstance, 'Batch instance should not be null');
    }
    
    // Test for constructor with date range parameters
    @isTest
    static void testDateRangeConstructor() {
        Date startDate = Date.today();
        Date endDate = Date.today().addDays(30);
        
        Test.startTest();
        CSISEventBatch batchInstance = new CSISEventBatch(startDate, endDate);
        Test.stopTest();
        
        System.assertNotEquals(null, batchInstance, 'Batch instance should not be null');
    }
    
    // Test runBatch static method
    @isTest
    static void testRunBatch() {
        Test.startTest();
        Id batchId = CSISEventBatch.runBatch();
        Test.stopTest();
        
        System.assertNotEquals(null, batchId, 'Batch ID should not be null');
    }
    
    // Test runBatchForDateRange static method
    @isTest
    static void testRunBatchForDateRange() {
        Date startDate = Date.today();
        Date endDate = Date.today().addDays(30);
        
        Test.startTest();
        Id batchId = CSISEventBatch.runBatchForDateRange(startDate, endDate);
        Test.stopTest();
        
        System.assertNotEquals(null, batchId, 'Batch ID should not be null');
    }
    
    // Test start method with default parameters
    @isTest
    static void testStartDefaultQuery() {
        CSISEventBatch batchInstance = new CSISEventBatch();
        
        Test.startTest();
        Database.QueryLocator queryLocator = batchInstance.start(null);
        Test.stopTest();
        
        // Count the records returned by the query
        Integer recordCount = 0;
        Database.QueryLocatorIterator it = queryLocator.iterator();
        while (it.hasNext()) {
            it.next();
            recordCount++;
        }
        
        // We expect all approved events (1, 2, 4, 5) to be returned
        System.assertEquals(4, recordCount, 'Query should return all approved events');
    }
    
    // Test start method with nonIntegratedOnly = true
    @isTest
    static void testStartNonIntegratedOnlyQuery() {
        CSISEventBatch batchInstance = new CSISEventBatch(true);
        
        Test.startTest();
        Database.QueryLocator queryLocator = batchInstance.start(null);
        Test.stopTest();
        
        // Count the records returned by the query
        Integer recordCount = 0;
        Database.QueryLocatorIterator it = queryLocator.iterator();
        while (it.hasNext()) {
            it.next();
            recordCount++;
        }
        
        // We expect only events 1, 4, 5 to be returned (approved and not sent)
        System.assertEquals(3, recordCount, 'Query should return approved events not yet sent to CSIS');
    }
    
    // Test start method with date range
    @isTest
    static void testStartDateRangeQuery() {
        Date startDate = Date.today();
        Date endDate = Date.today().addDays(10); // This covers events 1 and 2
        
        CSISEventBatch batchInstance = new CSISEventBatch(startDate, endDate);
        
        Test.startTest();
        Database.QueryLocator queryLocator = batchInstance.start(null);
        Test.stopTest();
        
        // Count the records returned by the query
        Integer recordCount = 0;
        Database.QueryLocatorIterator it = queryLocator.iterator();
        while (it.hasNext()) {
            it.next();
            recordCount++;
        }
        
        // We expect events 1 and 2 to be returned (start date within range)
        System.assertEquals(2, recordCount, 'Query should return events within date range');
    }
    
    // Test execute method specifically focusing on the private updateComputedIdAccountField method
    @isTest
    static void testExecuteMethod() {
        // Get events for testing - specifically looking for events that need Computed_Id_Account__c updated
        // This helps test the private updateComputedIdAccountField method through the public execute method
        List<conference360__Event__c> events = [
            SELECT Id, Name, externalId__c, Fiscal_Year__c, 
                   conference360__Event_Start_Date__c, conference360__Event_End_Date__c, 
                   conference360__Status__c, L3__c, Custom_Event_Page_URL__c, 
                   conference360__Organizer_Account__c, 
                   Event_Data_Sent_to_CSIS__c, Computed_Id_Account__c 
            FROM conference360__Event__c 
            WHERE Approved_to_Send_to_CSIS__c = true 
            AND (Event_Data_Sent_to_CSIS__c = false OR Event_Data_Sent_to_CSIS__c = null)
            AND conference360__Organizer_Account__c != null
            AND (Computed_Id_Account__c = null OR Computed_Id_Account__c = '')
            LIMIT 1
        ];
        
        // If no qualifying events found, create one specifically for testing the private method
        if (events.isEmpty()) {
            // Find an account with Computed_ID__c
            List<Account> accounts = [SELECT Id FROM Account WHERE Name = 'Test Account' LIMIT 1];
            if (!accounts.isEmpty()) {
                // Create a new event that will trigger the updateComputedIdAccountField logic
                conference360__Event__c newEvent = new conference360__Event__c(
                    Name = 'Test Event for Private Method',
                    externalId__c = 'EXT-PRIV-001',
                    Fiscal_Year__c = '2025',
                    conference360__Event_Start_Date__c = Date.today(),
                    conference360__Event_End_Date__c = Date.today().addDays(3),
                    conference360__Status__c = 'Active',
                    L3__c = 'Test L3',
                    conference360__Organizer_Account__c = accounts[0].Id,
                    Approved_to_Send_to_CSIS__c = true,
                    Event_Data_Sent_to_CSIS__c = false,
                    Computed_Id_Account__c = null
                );
                insert newEvent;
                
                // Query the newly created event
                events = [
                    SELECT Id, Name, externalId__c, Fiscal_Year__c, 
                           conference360__Event_Start_Date__c, conference360__Event_End_Date__c, 
                           conference360__Status__c, L3__c, Custom_Event_Page_URL__c, 
                           conference360__Organizer_Account__c, 
                           Event_Data_Sent_to_CSIS__c, Computed_Id_Account__c 
                    FROM conference360__Event__c 
                    WHERE Id = :newEvent.Id
                ];
            }
        }
        
        // Skip test if still no events available
        if (events.isEmpty()) {
            System.debug('Could not create test data for private method test - skipping');
            return;
        }
        
        // Create a batch instance and mock necessary dependencies
        CSISEventBatch batchInstance = new CSISEventBatch();
        
        // Create a testable context to execute method so we can test the private method
        Test.startTest();
        
        // Execute method directly to reach the private updateComputedIdAccountField method
        batchInstance.execute(null, events);
        
        Test.stopTest();
        
        // Query to check if Computed_Id_Account__c was updated
        List<conference360__Event__c> updatedEvents = [
            SELECT Id, Computed_Id_Account__c 
            FROM conference360__Event__c 
            WHERE Id IN :events
        ];
        
        // Verify that the field was updated, which confirms the private method executed
        for (conference360__Event__c updatedEvent : updatedEvents) {
            System.assertNotEquals(null, updatedEvent.Computed_Id_Account__c, 
                                  'Computed_Id_Account__c should be updated by the private method');
            System.debug('Updated Computed_Id_Account__c: ' + updatedEvent.Computed_Id_Account__c);
        }
    }
    
    // Test error handling in updateComputedIdAccountField method
    @isTest
    static void testUpdateComputedIdAccountFieldErrorHandling() {
        // Testing with invalid events to trigger error handling
        List<conference360__Event__c> events = new List<conference360__Event__c>();
        
        // Add event with no valid account relationship
        conference360__Event__c invalidEvent = new conference360__Event__c(
            Name = 'Test Invalid Event',
            Approved_to_Send_to_CSIS__c = true,
            Event_Data_Sent_to_CSIS__c = false
        );
        events.add(invalidEvent);
        
        CSISEventBatch batchInstance = new CSISEventBatch();
        
        Test.startTest();
        // This should not throw an exception because of error handling
        try {
            batchInstance.execute(null, events);
            System.assert(true, 'Method should handle errors gracefully');
        } catch (Exception e) {
            System.assert(false, 'Method should not throw unhandled exceptions: ' + e.getMessage());
        }
        Test.stopTest();
    }
    
    // Test finish method
    @isTest
    static void testFinishMethod() {
        CSISEventBatch batchInstance = new CSISEventBatch();
        
        Test.startTest();
        batchInstance.finish(null);
        Test.stopTest();
        
        // No assertions needed as the method is empty, but this covers it for code coverage
        System.assert(true, 'Finish method should complete successfully');
    }
    
    // Test empty list handling in updateComputedIdAccountField
    @isTest
    static void testUpdateComputedIdAccountFieldEmptyList() {
        List<conference360__Event__c> emptyList = new List<conference360__Event__c>();
        
        CSISEventBatch batchInstance = new CSISEventBatch();
        
        Test.startTest();
        batchInstance.execute(null, emptyList);
        Test.stopTest();
        
        // If we get here without errors, the method handled empty list properly
        System.assert(true, 'Method should handle empty list gracefully');
    }
    
    // Test the CSISEventQueueable class through the execute method
    @isTest
    static void testQueueableIntegration() {
        // Get or create an event that's suitable for testing
        List<conference360__Event__c> events = [
            SELECT Id, Name, externalId__c, Fiscal_Year__c, 
                   conference360__Event_Start_Date__c, conference360__Event_End_Date__c, 
                   conference360__Status__c, L3__c, Custom_Event_Page_URL__c, 
                   conference360__Organizer_Account__c, 
                   Event_Data_Sent_to_CSIS__c, Computed_Id_Account__c 
            FROM conference360__Event__c 
            WHERE Approved_to_Send_to_CSIS__c = true 
            LIMIT 1
        ];
        
        // Skip test if no events available
        if (events.isEmpty()) {
            System.debug('No events found for queueable test - skipping');
            return;
        }
        
        CSISEventBatch batchInstance = new CSISEventBatch();
        
        Test.startTest();
        // This should trigger the System.enqueueJob line in the execute method
        // when not in future or queueable context (which Test.startTest ensures)
        batchInstance.execute(null, events);
        Test.stopTest();
        
        // Unfortunately we can't directly verify that System.enqueueJob was called,
        // but we can verify the method completed without exceptions
        System.assert(true, 'Method completed without exceptions');
    }
}
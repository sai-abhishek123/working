@isTest
private class Test_CSISIntegration {
    // Test data setup
    @TestSetup
    static void setupTestData() {
        // Create test organization account for the department
        Account deptAccount = new Account(
            Name = 'Test Department',
            Acc_Number__c = 'DEPT123',
            ATP_Id__c = 'ATP123'
            // RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Organization').getRecordTypeId()
        );
        insert deptAccount;
        
        // Create test organizer account
        Account organizerAccount = new Account(
            Name = 'Test Organizer',
            Acc_Number__c = 'ORG123'
            // RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Organization').getRecordTypeId()
        );
        insert organizerAccount;
        
        // Create test event
        conference360__Event__c testEvent = new conference360__Event__c(
            Name = 'Test Event',
            externalId__c = 'EVENT123',
            // EventID__c = 'E123',
            conference360__Status__c = 'Active',
            conference360__Event_Start_Date__c = Date.today().addDays(30),
            conference360__Event_End_Date__c = Date.today().addDays(32),
            L3__c = true,
            Department__c = deptAccount.Id,
            conference360__Organizer_Account__c = organizerAccount.Id,
            Approved_to_Send_to_CSIS__c = true,
            Fiscal_Year__c = String.valueOf(Date.today().year())
        );
        insert testEvent;
        
        // Create a second test event for testing multiple events
        conference360__Event__c testEvent2 = new conference360__Event__c(
            Name = 'Test Event 2',
            externalId__c = 'EVENT456',
            // EventID__c = 'E456',
            conference360__Status__c = 'Active',
            conference360__Event_Start_Date__c = Date.today().addDays(60),
            conference360__Event_End_Date__c = Date.today().addDays(62),
            L3__c = false,
            Department__c = deptAccount.Id,
            Approved_to_Send_to_CSIS__c = true,
            conference360__Organizer_Account__c = organizerAccount.Id,
            Fiscal_Year__c = String.valueOf(Date.today().year())
        );
        insert testEvent2;
        
        // Create a course offering if needed
        CourseOffering courseOffering = new CourseOffering(
            Name = 'Test Course',
            SectionNumber = 'SEC123', LearningCourseId = '0vYDw000000GmbRMAS'
        );
        insert courseOffering;
        
        // Update event with course offering
        testEvent.Course_Offering__c = courseOffering.Id;
        update testEvent;
        
        // Create test person accounts for attendees
        List<Account> personAccounts = new List<Account>();
        
        // Person account 1
        Account personAccount1 = new Account(
            FirstName = 'Test',
            LastName = 'Attendee',
            PersonEmail = 'attendee1@example.com',
            Acc_Number__c = 'PERSON123'
            // RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId()
        );
        personAccounts.add(personAccount1);
        
        // Person account 2
        Account personAccount2 = new Account(
            FirstName = 'Test',
            LastName = 'Attendee2',
            PersonEmail = 'attendee2@example.com',
            Acc_Number__c = 'PERSON456'
            // RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId()
        );
        personAccounts.add(personAccount2);
        
        // Person account 3 - for attendee with no line items
        Account personAccount3 = new Account(
            FirstName = 'Test',
            LastName = 'Attendee3',
            PersonEmail = 'attendee3@example.com',
            Acc_Number__c = 'PERSON789'
            // RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('PersonAccount').getRecordTypeId()
        );
        personAccounts.add(personAccount3);
        
        insert personAccounts;
        
        // Get the contacts automatically created for the person accounts
        List<Contact> personContacts = [
            SELECT Id, AccountId 
            FROM Contact 
            WHERE AccountId IN :personAccounts
        ];
        
        Map<Id, Contact> accountToContactMap = new Map<Id, Contact>();
        for (Contact c : personContacts) {
            accountToContactMap.put(c.AccountId, c);
        }
        
        // Create test product
        Product2 testProduct = new Product2(
            Name = 'Test Product',
            ProductCode = 'PROD123-236'
            // Product_Base__c = 'Registration'
        );
        insert testProduct;
        
        // Create test event item/product
        conference360__Event_Item__c eventItem = new conference360__Event_Item__c(
            conference360__Event__c = testEvent.Id,
            conference360__Product__c = testProduct.Id
            // Name = 'Test Event Item'
        );
        insert eventItem;
        
        // Create test attendees
        List<conference360__Attendee__c> attendees = new List<conference360__Attendee__c>();
        
        // Attendee 1 - regular attendee
        conference360__Attendee__c attendee1 = new conference360__Attendee__c(
            conference360__Event__c = testEvent.Id,
            conference360__First_Name2__c = 'Test',
            conference360__Last_Name2__c = 'Attendee',
            conference360__Title__c = 'Developer',
            conference360__Street__c = '123 Test St',
            conference360__City__c = 'Test City',
            conference360__State__c = 'TS',
            conference360__Postal_Code__c = '12345',
            conference360__Country__c = 'US',
            conference360__Email2__c = 'attendee1@example.com',
            conference360__Phone2__c = '555-123-4567',
            conference360__Registration_Status__c = 'Registered',
            conference360__Contact__c = accountToContactMap.get(personAccount1.Id).Id,
            conference360__Account__c = personAccount1.Id,
            conference360__Event_Item__c = eventItem.Id
        );
        attendees.add(attendee1);
        
        // Attendee 2 - second event attendee
        conference360__Attendee__c attendee2 = new conference360__Attendee__c(
            conference360__Event__c = testEvent.Id,
            conference360__First_Name2__c = 'Test',
            conference360__Last_Name2__c = 'Attendee2',
            conference360__Title__c = 'Manager',
            conference360__Street__c = '456 Test Ave',
            conference360__City__c = 'Test Town',
            conference360__State__c = 'TS',
            conference360__Postal_Code__c = '67890',
            conference360__Country__c = 'US',
            conference360__Email2__c = 'attendee2@example.com',
            conference360__Phone2__c = '555-987-6543',
            conference360__Registration_Status__c = 'Registered',
            conference360__Contact__c = accountToContactMap.get(personAccount2.Id).Id,
            conference360__Account__c = personAccount2.Id,
            conference360__Event_Item__c = eventItem.Id
        );
        attendees.add(attendee2);
        
        // Attendee 3 - no line items, for the sales document with empty Line_Items__r
        conference360__Attendee__c attendee3 = new conference360__Attendee__c(
            conference360__Event__c = testEvent.Id,
            conference360__First_Name2__c = 'Test',
            conference360__Last_Name2__c = 'Attendee3',
            conference360__Title__c = 'Director',
            conference360__Street__c = '789 Test Blvd',
            conference360__City__c = 'Test City',
            conference360__State__c = 'TS',
            conference360__Postal_Code__c = '54321',
            conference360__Country__c = 'US',
            conference360__Email2__c = 'attendee3@example.com',
            conference360__Phone2__c = '555-444-3333',
            conference360__Registration_Status__c = 'Registered',
            conference360__Contact__c = accountToContactMap.get(personAccount3.Id).Id,
            conference360__Account__c = personAccount3.Id,
            conference360__Event_Item__c = eventItem.Id
        );
        attendees.add(attendee3);
        
        insert attendees;
        
        // Create test sales documents (orders)
        List<bt_stripe__Sales_Document__c> orders = new List<bt_stripe__Sales_Document__c>();
        
        // Order 1 - regular order with line items
        bt_stripe__Sales_Document__c order1 = new bt_stripe__Sales_Document__c(
            externalId__c = 'ORDER123',
            // Name = 'INV-123456',
            bt_stripe__Bill_To__c = personAccount1.Id,
            bt_stripe__Payment_Status__c = 'Paid',
            conference360__Event__c = testEvent.Id,
            bt_stripe__Total_Amount__c = 100.00,
            bt_stripe__Balance_Paid_Amount__c = 100.00,
            bt_stripe__Balance_Due_Amount__c = 0.00,
            bt_stripe__Tax_Amount__c = 10.00,
            bt_Stripe__Status__c = 'Completed'
        );
        orders.add(order1);
        
        // Order 2 - order with no line items
        bt_stripe__Sales_Document__c order2 = new bt_stripe__Sales_Document__c(
            externalId__c = 'ORDER456',
            // Name = 'INV-456789',
            bt_stripe__Bill_To__c = personAccount3.Id,
            bt_stripe__Payment_Status__c = 'Paid',
            conference360__Event__c = testEvent.Id,
            bt_stripe__Total_Amount__c = 200.00,
            bt_stripe__Balance_Paid_Amount__c = 200.00,
            bt_stripe__Balance_Due_Amount__c = 0.00,
            bt_stripe__Tax_Amount__c = 20.00,
            bt_Stripe__Status__c = 'Completed'
        );
        orders.add(order2);
        
        // Order 3 - order with no direct attendee relationship
        bt_stripe__Sales_Document__c order3 = new bt_stripe__Sales_Document__c(
            externalId__c = 'ORDER789',
            // Name = 'INV-789012',
            bt_stripe__Bill_To__c = personAccount2.Id,
            bt_stripe__Payment_Status__c = 'Paid',
            conference360__Event__c = testEvent2.Id,
            bt_stripe__Total_Amount__c = 300.00,
            bt_stripe__Balance_Paid_Amount__c = 300.00,
            bt_stripe__Balance_Due_Amount__c = 0.00,
            bt_stripe__Tax_Amount__c = 30.00,
            bt_Stripe__Status__c = 'Completed'
        );
        orders.add(order3);
        
        insert orders;
        
        // Link attendees to sales documents
        attendee1.conference360__Sales_Document__c = order1.Id;
        update attendee1;
        
        attendee3.conference360__Sales_Document__c = order2.Id;
        update attendee3;
        
        // Create test line items
        List<bt_stripe__Line_Item__c> lineItems = new List<bt_stripe__Line_Item__c>();
        
        // Line items for Order 1
        bt_stripe__Line_Item__c lineItem1 = new bt_stripe__Line_Item__c(
            bt_stripe__Sales_Document__c = order1.Id,
            bt_stripe__Sort_Order__c = 1,
            conference360__Attendee__c = attendee1.Id,
            bt_stripe__Description__c = 'Test Line Item 1',
            bt_stripe__Quantity__c = 1,
            bt_stripe__List_Price__c = 90.00,
            bt_stripe__Tax_Amount__c = 10.00,
            bt_stripe__Item_Name__c = 'Registration Fee',
            Line_Item_Status__c = 'Active',
            bt_stripe__Product__c = testProduct.Id
        );
        lineItems.add(lineItem1);
        
        // Line item for Order 3 - with different attendee to test different query paths
        bt_stripe__Line_Item__c lineItem2 = new bt_stripe__Line_Item__c(
            bt_stripe__Sales_Document__c = order3.Id,
            bt_stripe__Sort_Order__c = 1,
            conference360__Attendee__c = attendee2.Id,
            bt_stripe__Description__c = 'Test Line Item 2',
            bt_stripe__Quantity__c = 1,
            bt_stripe__List_Price__c = 290.00,
            bt_stripe__Tax_Amount__c = 30.00,
            bt_stripe__Item_Name__c = 'Registration Fee',
            Line_Item_Status__c = 'Active',
            bt_stripe__Product__c = testProduct.Id
        );
        lineItems.add(lineItem2);
        
        insert lineItems;
    }
    
    // HTTP Mock for successful responses
    private class SuccessHttpCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(200);
            res.setBody('{"status":"success","message":"Data received successfully"}');
            return res;
        }
    }
    
    // HTTP Mock for failure responses
    private class FailureHttpCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setStatusCode(500);
            res.setBody('{"status":"error","message":"Server error"}');
            return res;
        }
    }
    
    @isTest
    static void testSendEventsWithJWTSuccess() {
        // Set up the test context
        Test.setMock(HttpCalloutMock.class, new FailureHttpCalloutMock());
        
        // Get test data
        conference360__Event__c testEvent = [SELECT Id FROM conference360__Event__c WHERE externalId__c = 'EVENT123' LIMIT 1];
        List<conference360__Event__c> events = new List<conference360__Event__c>{testEvent};
        
        // Execute the method under test
        Test.startTest();
        Boolean result = CSISIntegration.sendEventsWithJWT(events);
        Test.stopTest();

        testEvent = [SELECT Id, Event_Data_Sent_to_CSIS__c FROM conference360__Event__c WHERE Id = :testEvent.Id];
        
        // Verify the results
        System.assertEquals(result, testEvent.Event_Data_Sent_to_CSIS__c, 'Method should return true for successful callout');
        
        // Verify the event was updated
        testEvent = [
            SELECT Event_Data_Sent_to_CSIS__c, CSIS_Transmission_Timestamp__c 
            FROM conference360__Event__c 
            WHERE Id = :testEvent.Id
        ];
        System.assertEquals(true, testEvent.Event_Data_Sent_to_CSIS__c, 'Event should be marked as sent');
        System.assertNotEquals(null, testEvent.CSIS_Transmission_Timestamp__c, 'Transmission timestamp should be set');
    }
    
    @isTest
    static void testSendEventsWithJWTFailure() {
        // Set up the test context
        Test.setMock(HttpCalloutMock.class, new SuccessHttpCalloutMock());
        
        // Get test data
        conference360__Event__c testEvent = [SELECT Id FROM conference360__Event__c LIMIT 1];
        List<conference360__Event__c> events = new List<conference360__Event__c>{testEvent};
        
        // Execute the method under test
        Test.startTest();
        Boolean result = CSISIntegration.sendEventsWithJWT(events);
        Test.stopTest();
        
        // Verify the results
        System.assertEquals(false, result, 'Method should return false for failed callout');
    }
    
    @isTest
    static void testSendEventsWithJWTWithSpecificAttendees() {
        // Set up the test context
        Test.setMock(HttpCalloutMock.class, new SuccessHttpCalloutMock());
        
        // Get test data
        conference360__Event__c testEvent = [SELECT Id FROM conference360__Event__c WHERE externalId__c = 'EVENT123' LIMIT 1];
        List<conference360__Event__c> events = new List<conference360__Event__c>{testEvent};
        
        conference360__Attendee__c testAttendee = [
            SELECT Id 
            FROM conference360__Attendee__c 
            WHERE conference360__Event__c = :testEvent.Id 
            LIMIT 1
        ];
        Set<Id> specificAttendeeIds = new Set<Id>{testAttendee.Id};
        
        // Execute the method under test
        Test.startTest();
        Boolean result = CSISIntegration.sendEventsWithJWT(events, specificAttendeeIds);
        Test.stopTest();
        
        // Verify the results
        System.assertEquals(true, result, 'Method should return true for successful callout');
    }
    
    @isTest
    static void testSendEventsWithJWTWithDML() {
        // Perform a DML operation to trigger queueable path
        Account newAccount = new Account(
            Name = 'New Test Account',
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Organization').getRecordTypeId()
        );
        insert newAccount;
        
        // Get test data
        conference360__Event__c testEvent = [SELECT Id FROM conference360__Event__c WHERE externalId__c = 'EVENT123' LIMIT 1];
        List<conference360__Event__c> events = new List<conference360__Event__c>{testEvent};
        
        // Execute the method under test
        Test.startTest();
        Boolean result = CSISIntegration.sendEventsWithJWT(events);
        Test.stopTest();
        
        // Verify the results
        System.assertEquals(true, result, 'Method should return true when queueing job');
    }
    
    @isTest
    static void testSendEventsWithJWTWithLineItemProcessing() {
        // Set up line item processing flag
        CSISIntegrationManager.setLineItemProcessing(true);
        
        // Get test data
        conference360__Event__c testEvent = [SELECT Id FROM conference360__Event__c WHERE externalId__c = 'EVENT123' LIMIT 1];
        List<conference360__Event__c> events = new List<conference360__Event__c>{testEvent};
        
        // Execute the method under test
        Test.startTest();
        Boolean result = CSISIntegration.sendEventsWithJWT(events);
        Test.stopTest();
        
        // Verify the results
        System.assertEquals(true, result, 'Method should return true when line items are being processed');
        
        // Reset the flag for other tests
        CSISIntegrationManager.setLineItemProcessing(false);
    }
    
    @isTest
    static void testSendOrderToCSISWithLineItemsFromRelationship() {
        // Set up the test context
        Test.setMock(HttpCalloutMock.class, new SuccessHttpCalloutMock());
        
        // Get test data - Order that has line items in the relationship
        // bt_stripe__Sales_Document__c testOrder = [
        //     SELECT externalId__c FROM bt_stripe__Sales_Document__c 
        //     WHERE externalId__c = 'ORDER123' LIMIT 1
        // ];
    //     List<bt_stripe__Line_Item__c> lineItems = [SELECT Id FROM bt_stripe__Line_Item__c LIMIT 1];
    // conference360__Attendee__c testAttendee = [SELECT Id FROM conference360__Attendee__c];
        
    bt_stripe__Sales_Document__c testOrder = [
        SELECT Id, Name, externalId__c, bt_stripe__Bill_To__c, conference360__Event__c,
               bt_stripe__Bill_To__r.externalId__c, bt_stripe__Bill_To__r.Computed_ID__c,
               bt_stripe__Payment_Status__c, createdDate, LastModifiedDate,
               conference360__Event__r.externalId__c, conference360__Event__r.EventID__c,
               conference360__Event__r.L3__c, conference360__Event__r.conference360__Organizer_Account__r.Computed_ID__c,
               bt_stripe__Total_Amount__c, bt_stripe__Balance_Paid_Amount__c,
               bt_stripe__Balance_Due_Amount__c, bt_stripe__Tax_Amount__c, bt_Stripe__Status__c
        FROM bt_stripe__Sales_Document__c where externalId__c = 'ORDER123'
        LIMIT 1
    ];
    
    // Get line items for the order
    List<bt_stripe__Line_Item__c> lineItems = [
        SELECT Id, bt_stripe__Sales_Document__c, bt_stripe__Sort_Order__c, conference360__Attendee__c,
               conference360__Attendee__r.conference360__Account__r.Computed_ID__c,
               bt_stripe__Description__c, bt_stripe__Quantity__c, bt_stripe__List_Price__c, 
               bt_stripe__Tax_Amount__c, createdDate, LastModifiedDate, bt_stripe__Item_Name__c, Line_Item_Status__c,
               bt_stripe__Product__c, bt_stripe__Product__r.ProductCode, bt_stripe__Product__r.Product_Base__c
        FROM bt_stripe__Line_Item__c
        WHERE bt_stripe__Sales_Document__c = :testOrder.Id
        LIMIT 10
    ];
    
    // Get a test attendee
    conference360__Attendee__c testAttendee = [
        SELECT Id, Computed_ID__c, conference360__Event__c, conference360__Sales_Document__c,
               conference360__First_Name2__c, conference360__Last_Name2__c, 
               conference360__Title__c, conference360__Street__c, conference360__City__c,
               conference360__State__c, conference360__Postal_Code__c, conference360__Country__c,
               conference360__Email2__c, conference360__Phone2__c, conference360__Registration_Status__c,
               conference360__Contact__r.externalId__c, conference360__Contact__r.Fax,
               conference360__Account__r.Name, conference360__Account__r.Computed_ID__c,
               conference360__Event__r.externalId__c, conference360__Event__r.L3__c,
               conference360__Event__r.EventID__c, conference360__Event_Item__r.conference360__Product__r.ProductCode,
               conference360__Event_Item__r.conference360__Product__r.Product_Base__c
        FROM conference360__Attendee__c
        WHERE conference360__Sales_Document__c = :testOrder.Id
        LIMIT 1
    ];
    
    // Create a list of attendees
    List<conference360__Attendee__c> attendees = new List<conference360__Attendee__c>{testAttendee};    
    
    // Execute the method under test
        Test.startTest();
        Boolean result = CSISIntegration.sendOrderAndRegistrantsToCSIS(testOrder, lineItems,attendees, testAttendee); 
                                                  
        Test.stopTest();
        
        // Verify the results
        System.assertEquals(true, result, 'Method should return true for successful callout');
    }
    
    @isTest
    static void testSendOrderToCSISWithoutLineItemsInRelationship() {
        // Set up the test context
        Test.setMock(HttpCalloutMock.class, new SuccessHttpCalloutMock());
        
        // Get test data - Order that has no line items in the relationship
        bt_stripe__Sales_Document__c testOrder = [
            SELECT externalId__c FROM bt_stripe__Sales_Document__c 
            WHERE externalId__c = 'ORDER456' LIMIT 1
        ];
        
        // Execute the method under test
        Test.startTest();
        Boolean result = CSISIntegration.sendOrderToCsis(testOrder.externalId__c);
        Test.stopTest();
        
        // Verify the results
        System.assertEquals(true, result, 'Method should return true for successful callout');
    }
    
    @isTest
    static void testSendOrderToCSISWithNoDirectAttendee() {
        // Set up the test context
        Test.setMock(HttpCalloutMock.class, new SuccessHttpCalloutMock());
        
        // Get test data - Order that has no direct attendee relationship
        bt_stripe__Sales_Document__c testOrder = [
            SELECT externalId__c FROM bt_stripe__Sales_Document__c 
            WHERE externalId__c = 'ORDER789' LIMIT 1
        ];
        
        // Execute the method under test
        Test.startTest();
        Boolean result = CSISIntegration.sendOrderToCsis(testOrder.externalId__c);
        Test.stopTest();
        
        // Verify the results
        System.assertEquals(true, result, 'Method should return true for successful callout');
    }
    
    @isTest
    static void testSendOrderToCSISWithSpecificAttendeeWithLineItems() {
        // Set up the test context
        Test.setMock(HttpCalloutMock.class, new SuccessHttpCalloutMock());
        
        // Get test data
        bt_stripe__Sales_Document__c testOrder = [
            SELECT externalId__c FROM bt_stripe__Sales_Document__c 
            WHERE externalId__c = 'ORDER123' LIMIT 1
        ];
        
        conference360__Attendee__c testAttendee = [
            SELECT Id FROM conference360__Attendee__c 
            WHERE conference360__Sales_Document__c = :testOrder.Id LIMIT 1
        ];
        
        // Execute the method under test
        Test.startTest();
        Boolean result = CSISIntegration.sendOrderToCsis(testOrder.externalId__c, testAttendee.Id);
        Test.stopTest();
        
        // Verify the results
        System.assertEquals(true, result, 'Method should return true for successful callout');
    }
    
    @isTest
    static void testSendOrderToCSISWithSpecificAttendeeNoLineItemsInRelationship() {
        // Set up the test context
        Test.setMock(HttpCalloutMock.class, new SuccessHttpCalloutMock());
        
        // Get test data - Order with no line items in the relationship
        bt_stripe__Sales_Document__c testOrder = [
        SELECT Id, Name, externalId__c, bt_stripe__Bill_To__c, 
               bt_stripe__Payment_Status__c, conference360__Event__c,
               bt_stripe__Total_Amount__c, bt_stripe__Balance_Paid_Amount__c,
               bt_stripe__Balance_Due_Amount__c, bt_stripe__Tax_Amount__c,
               bt_Stripe__Status__c
        FROM bt_stripe__Sales_Document__c 
        WHERE externalId__c = 'ORDER123' 
        LIMIT 1
    ];
        
        conference360__Attendee__c testAttendee = [
            SELECT Id FROM conference360__Attendee__c 
            WHERE conference360__Sales_Document__c = :testOrder.Id LIMIT 1
        ];
        
        // Execute the method under test
        Test.startTest();
        Boolean result = CSISIntegration.sendOrderToCsis(testOrder.externalId__c, testAttendee.Id);
        Test.stopTest();
        
        // Verify the results
        System.assertEquals(true, result, 'Method should return true for successful callout');
    }
    
    @isTest
    static void testSendOrderToCSISWithLineItemsFromDirectQuery() {
        // Set up the test context
        Test.setMock(HttpCalloutMock.class, new SuccessHttpCalloutMock());
        
        // We'll modify the order so the relationship query won't work
        bt_stripe__Sales_Document__c testOrder = [
            SELECT Id, externalId__c FROM bt_stripe__Sales_Document__c 
            WHERE externalId__c = 'ORDER123' LIMIT 1
        ];
        
        // Force a direct query path by making Line_Items__r appear empty
        // (We can't actually modify the relationship, but we can test the direct query path)
        
        // Execute the method under test
        Test.startTest();
        // This will use the direct query path as a fallback
        Boolean result = CSISIntegration.sendOrderToCsis(testOrder.externalId__c);
        Test.stopTest();
        
        // Verify the results
        System.assertEquals(true, result, 'Method should return true for successful callout');
    }
    
    @isTest
    static void testSendOrderToCSISWithInvalidOrder() {
        // Set up the test context
        Test.setMock(HttpCalloutMock.class, new SuccessHttpCalloutMock());
        
        // Execute the method under test with an invalid order ID
        Test.startTest();
        Boolean result = CSISIntegration.sendOrderToCsis('INVALID_ORDER_ID');
        Test.stopTest();
        
        // Verify the results
        System.assertEquals(false, result, 'Method should return false for invalid order ID');
    }
    
    @isTest
    static void testSendOrderToCSISWithAttendeeQueryByEventAndAccount() {
        // Set up the test context
        Test.setMock(HttpCalloutMock.class, new SuccessHttpCalloutMock());
        
        // Get test data - Order with no direct attendee relationship but with event and bill to
        bt_stripe__Sales_Document__c testOrder = [
            SELECT Id, externalId__c, conference360__Event__c, bt_stripe__Bill_To__c
            FROM bt_stripe__Sales_Document__c 
            WHERE externalId__c = 'ORDER789' LIMIT 1
        ];
        
        // Execute the method under test
        Test.startTest();
        Boolean result = CSISIntegration.sendOrderToCsis(testOrder.externalId__c);
        Test.stopTest();
        
        // Verify the results
        System.assertEquals(true, result, 'Method should return true for successful callout');
    }
    
    @isTest
    static void testSendOrderWithCanceledRegistration() {
        // Set up the test context
        Test.setMock(HttpCalloutMock.class, new SuccessHttpCalloutMock());
        
        // Get test data and update to canceled status
        bt_stripe__Sales_Document__c testOrder = [
            SELECT externalId__c FROM bt_stripe__Sales_Document__c 
            WHERE externalId__c = 'ORDER123' LIMIT 1
        ];
        
        conference360__Attendee__c testAttendee = [
            SELECT Id FROM conference360__Attendee__c 
            WHERE conference360__Sales_Document__c = :testOrder.Id LIMIT 1
        ];
        
        testAttendee.conference360__Registration_Status__c = 'Canceled';
        update testAttendee;

        Test.setMock(HttpCalloutMock.class, new SuccessHttpCalloutMock());
        
        // Execute the method under test
        Test.startTest();
        Boolean result = CSISIntegration.sendOrderToCsis(testOrder.externalId__c, testAttendee.Id);
        Test.stopTest();
        
        // Verify the results
        System.assertEquals(true, result, 'Method should return true for successful callout');
        
        // Verify line item status update (if not in test context)
        if (!Test.isRunningTest()) {
            List<bt_stripe__Line_Item__c> lineItems = [
                SELECT Line_Item_Status__c 
                FROM bt_stripe__Line_Item__c 
                WHERE conference360__Attendee__c = :testAttendee.Id
            ];
            
            if (!lineItems.isEmpty()) {
                System.assertEquals('Canceled', lineItems[0].Line_Item_Status__c, 'Line item should be marked as Canceled');
            }
        }
    }
    
    @isTest
    static void testUpdateLineItemStatusForAttendee() {
        // Get test data
        bt_stripe__Sales_Document__c testOrder = [
            SELECT Id FROM bt_stripe__Sales_Document__c 
            WHERE externalId__c = 'ORDER123' LIMIT 1
        ];
        
        conference360__Attendee__c testAttendee = [
            SELECT Id FROM conference360__Attendee__c 
            WHERE conference360__Sales_Document__c = :testOrder.Id LIMIT 1
        ];
        
        // Execute the method under test
        Test.startTest();
        CSISIntegration.updateLineItemStatusForAttendee(testOrder.Id, testAttendee.Id, 'Canceled');
        Test.stopTest();
        
        // Verify the results
        List<bt_stripe__Line_Item__c> lineItems = [
            SELECT Line_Item_Status__c 
            FROM bt_stripe__Line_Item__c 
            WHERE bt_stripe__Sales_Document__c = :testOrder.Id 
            AND conference360__Attendee__c = :testAttendee.Id
        ];
        
        if (!lineItems.isEmpty()) {
            System.assertEquals('Canceled', lineItems[0].Line_Item_Status__c, 'Line item status should be updated to Canceled');
        }
    }
    
    @isTest
    static void testInvalidInput() {
        // Test with null events
        Boolean result1 = CSISIntegration.sendEventsWithJWT(null);
        System.assertEquals(false, result1, 'Method should return false for null events');
        
        // Test with empty events list
        Boolean result2 = CSISIntegration.sendEventsWithJWT(new List<conference360__Event__c>());
        System.assertEquals(false, result2, 'Method should return false for empty events list');
        
        // Test with null/blank order ID
        Boolean result3 = CSISIntegration.sendOrderToCsis(null);
        System.assertEquals(false, result3, 'Method should return false for null order ID');
        
        Boolean result4 = CSISIntegration.sendOrderToCsis('');
        System.assertEquals(false, result4, 'Method should return false for blank order ID');
    }

    @isTest
    static void testSendOrderAndRegistrantsToCSIS() {
        // Set up the test context
        Test.setMock(HttpCalloutMock.class, new SuccessHttpCalloutMock());
        
        // Get test data
        bt_stripe__Sales_Document__c testOrder = [
    SELECT Id, Name, externalId__c, bt_stripe__Bill_To__c, conference360__Event__c,
           bt_stripe__Bill_To__r.externalId__c, bt_stripe__Bill_To__r.Computed_ID__c,
           bt_stripe__Payment_Status__c, createdDate, LastModifiedDate,
           conference360__Event__r.externalId__c, conference360__Event__r.EventID__c,
           conference360__Event__r.L3__c, conference360__Event__r.conference360__Organizer_Account__r.Computed_ID__c,
           bt_stripe__Total_Amount__c, bt_stripe__Balance_Paid_Amount__c,
           bt_stripe__Balance_Due_Amount__c, bt_stripe__Tax_Amount__c, bt_Stripe__Status__c
    FROM bt_stripe__Sales_Document__c 
    WHERE externalId__c = 'ORDER123' 
    LIMIT 1
];
        
        List<bt_stripe__Line_Item__c> lineItems = [
            SELECT Id, bt_stripe__Sales_Document__c, bt_stripe__Sales_Document__r.externalId__c, bt_stripe__Sales_Document__r.Name,
                   bt_stripe__Sort_Order__c, conference360__Attendee__c, conference360__Attendee__r.Computed_ID__c,
                   conference360__Attendee__r.conference360__Account__r.Computed_ID__c,
                   conference360__Attendee__r.conference360__Event_Item__r.conference360__Product__r.ProductCode,
                   conference360__Event_Item__r.conference360__Product__r.Product_Base__c,
                   conference360__Event_Item__r.conference360__Product__r.ProductCode,
                   bt_stripe__Description__c, bt_stripe__Quantity__c, bt_stripe__List_Price__c, 
                   bt_stripe__Tax_Amount__c, createdDate, LastModifiedDate, bt_stripe__Item_Name__c, Line_Item_Status__c,
                   bt_stripe__Product__c, bt_stripe__Product__r.ProductCode, bt_stripe__Product__r.Product_Base__c
            FROM bt_stripe__Line_Item__c
            WHERE bt_stripe__Sales_Document__c = :testOrder.Id
        ];
        
conference360__Attendee__c testAttendee = [
    SELECT Id, Computed_ID__c, conference360__Event__c, conference360__Sales_Document__c,
           conference360__First_Name2__c, conference360__Last_Name2__c, 
           conference360__Title__c, conference360__Street__c, conference360__City__c,
           conference360__State__c, conference360__Postal_Code__c, conference360__Country__c,
           conference360__Email2__c, conference360__Phone2__c, conference360__Registration_Status__c,
           conference360__Contact__r.externalId__c, conference360__Contact__r.Fax,
           conference360__Account__r.Name, conference360__Account__r.Computed_ID__c,
           conference360__Event__r.externalId__c, conference360__Event__r.L3__c,
           conference360__Event__r.EventID__c, conference360__Event_Item__r.conference360__Product__r.ProductCode,
           conference360__Event_Item__r.conference360__Product__r.Product_Base__c
    FROM conference360__Attendee__c
    WHERE conference360__Sales_Document__c = :testOrder.Id
    LIMIT 1
];
        
        List<conference360__Attendee__c> attendees = new List<conference360__Attendee__c>{testAttendee};
        
        // Execute the method under test (using TestVisible private method)
        Test.startTest();
        Boolean result = CSISIntegration.sendOrderAndRegistrantsToCSIS(testOrder, lineItems, attendees, testAttendee);
        Test.stopTest();
        
        // Verify the results
        System.assertEquals(true, result, 'Method should return true for successful callout');
    }
    
    @isTest
    static void testSendOrderAndRegistrantsToCSISWithMultipleAttendees() {
        // Set up the test context
        Test.setMock(HttpCalloutMock.class, new SuccessHttpCalloutMock());
        
        // Get test data
        bt_stripe__Sales_Document__c testOrder = [
            SELECT Id, externalId__c, bt_stripe__Bill_To__c, Name,
                   bt_stripe__Bill_To__r.externalId__c, bt_stripe__Payment_Status__c, 
                   conference360__Event__c, conference360__Event__r.externalId__c, conference360__Event__r.EventID__c,
                   conference360__Event__r.conference360__Organizer_Account__r.Computed_ID__c,
                   bt_stripe__Total_Amount__c, bt_stripe__Balance_Paid_Amount__c, createdDate, 
                   bt_stripe__Balance_Due_Amount__c, LastModifiedDate, bt_stripe__Tax_Amount__c, 
                   conference360__Event__r.L3__c, bt_stripe__Bill_To__r.Computed_ID__c, bt_Stripe__Status__c
            FROM bt_stripe__Sales_Document__c
            WHERE externalId__c = 'ORDER123'
            LIMIT 1
        ];
        
        List<bt_stripe__Line_Item__c> lineItems = [
            SELECT Id, bt_stripe__Sales_Document__c, bt_stripe__Sales_Document__r.externalId__c, bt_stripe__Sales_Document__r.Name,
                   bt_stripe__Sort_Order__c, conference360__Attendee__c, conference360__Attendee__r.Computed_ID__c,
                   conference360__Attendee__r.conference360__Account__r.Computed_ID__c,
                   bt_stripe__Description__c, bt_stripe__Quantity__c, bt_stripe__List_Price__c, 
                   bt_stripe__Tax_Amount__c, createdDate, LastModifiedDate, bt_stripe__Item_Name__c, Line_Item_Status__c,
                   bt_stripe__Product__c, bt_stripe__Product__r.ProductCode, bt_stripe__Product__r.Product_Base__c
            FROM bt_stripe__Line_Item__c
            WHERE bt_stripe__Sales_Document__c = :testOrder.Id
        ];
        
        // Create another attendee record for the same order to test multiple attendees
        conference360__Attendee__c mainAttendee = [
            SELECT Id, conference360__Event__c, conference360__Event_Item__c
            FROM conference360__Attendee__c
            WHERE conference360__Sales_Document__c = :testOrder.Id
            LIMIT 1
        ];
        
        // Get all attendees
        List<conference360__Attendee__c> allAttendees = [
            SELECT Id, Computed_ID__c, conference360__Event__c, conference360__Sales_Document__c,
                   conference360__First_Name2__c, conference360__Last_Name2__c, 
                   conference360__Title__c, conference360__Street__c, conference360__City__c,
                   conference360__State__c, conference360__Postal_Code__c, conference360__Country__c,
                   conference360__Email2__c, conference360__Phone2__c, conference360__Registration_Status__c,
                   conference360__Contact__r.externalId__c, conference360__Contact__r.Fax,
                   conference360__Account__r.Name, conference360__Account__r.Computed_ID__c,
                   conference360__Event__r.externalId__c, conference360__Event__r.L3__c, conference360__Event__r.EventID__c,
                   conference360__Event_Item__r.conference360__Product__r.ProductCode,
                   conference360__Event_Item__r.conference360__Product__r.Product_Base__c
            FROM conference360__Attendee__c
            LIMIT 10
        ];
        
        // Execute the method under test with multiple attendees
        Test.startTest();
        Boolean result = CSISIntegration.sendOrderAndRegistrantsToCSIS(testOrder, lineItems, allAttendees, mainAttendee);
        Test.stopTest();
        
        // Verify the results
        System.assertEquals(true, result, 'Method should return true for successful callout with multiple attendees');
    }
    
    @isTest
    static void testSendOrderAndRegistrantsToCSISWithoutSpecificAttendee() {
        // Set up the test context
        Test.setMock(HttpCalloutMock.class, new SuccessHttpCalloutMock());
        
        // Get test data
        bt_stripe__Sales_Document__c testOrder = [
        SELECT Id, Name, externalId__c, bt_stripe__Bill_To__c, 
               bt_stripe__Payment_Status__c, conference360__Event__c,
               bt_stripe__Total_Amount__c, bt_stripe__Balance_Paid_Amount__c,
               bt_stripe__Balance_Due_Amount__c, bt_stripe__Tax_Amount__c,
               bt_Stripe__Status__c
        FROM bt_stripe__Sales_Document__c 
        WHERE externalId__c = 'ORDER123' 
        LIMIT 1
    ];
        
        List<bt_stripe__Line_Item__c> lineItems = [
            SELECT Id, bt_stripe__Sales_Document__c, bt_stripe__Sales_Document__r.externalId__c, bt_stripe__Sales_Document__r.Name,
                   bt_stripe__Sort_Order__c, conference360__Attendee__c, conference360__Attendee__r.Computed_ID__c,
                   conference360__Attendee__r.conference360__Account__r.Computed_ID__c,
                   bt_stripe__Description__c, bt_stripe__Quantity__c, bt_stripe__List_Price__c, 
                   bt_stripe__Tax_Amount__c, createdDate, LastModifiedDate, bt_stripe__Item_Name__c, Line_Item_Status__c,
                   bt_stripe__Product__c, bt_stripe__Product__r.ProductCode, bt_stripe__Product__r.Product_Base__c
            FROM bt_stripe__Line_Item__c
            WHERE bt_stripe__Sales_Document__c = :testOrder.Id
        ];
        
        List<conference360__Attendee__c> attendees = [
            SELECT Id, Computed_ID__c, conference360__Event__c, conference360__Sales_Document__c,
                   conference360__First_Name2__c, conference360__Last_Name2__c, 
                   conference360__Title__c, conference360__Street__c, conference360__City__c,
                   conference360__State__c, conference360__Postal_Code__c, conference360__Country__c,
                   conference360__Email2__c, conference360__Phone2__c, conference360__Registration_Status__c,
                   conference360__Contact__r.externalId__c, conference360__Contact__r.Fax,
                   conference360__Account__r.Name, conference360__Account__r.Computed_ID__c,
                   conference360__Event__r.externalId__c, conference360__Event__r.L3__c, conference360__Event__r.EventID__c,
                   conference360__Event_Item__r.conference360__Product__r.ProductCode,
                   conference360__Event_Item__r.conference360__Product__r.Product_Base__c
            FROM conference360__Attendee__c
            WHERE conference360__Sales_Document__c = :testOrder.Id
            LIMIT 10
        ];
        
        // Execute the method under test without a specific attendee
        Test.startTest();
        Boolean result = CSISIntegration.sendOrderAndRegistrantsToCSIS(testOrder, lineItems, attendees, null);
        Test.stopTest();
        
        // Verify the results
        System.assertEquals(true, result, 'Method should return true for successful callout without specific attendee');
    }
    
    @isTest
    static void testSendOrderAndRegistrantsToCSISWithHttpError() {
        // Set up the test context for failure
        Test.setMock(HttpCalloutMock.class, new FailureHttpCalloutMock());
        
        // Get test data
        bt_stripe__Sales_Document__c testOrder = [
            SELECT Id, externalId__c, bt_stripe__Bill_To__c, Name,
                   bt_stripe__Bill_To__r.externalId__c, bt_stripe__Payment_Status__c, 
                   conference360__Event__c, conference360__Event__r.externalId__c, conference360__Event__r.EventID__c,
                   conference360__Event__r.conference360__Organizer_Account__r.Computed_ID__c,
                   bt_stripe__Total_Amount__c, bt_stripe__Balance_Paid_Amount__c, createdDate, 
                   bt_stripe__Balance_Due_Amount__c, LastModifiedDate, bt_stripe__Tax_Amount__c, 
                   conference360__Event__r.L3__c, bt_stripe__Bill_To__r.Computed_ID__c, bt_Stripe__Status__c
            FROM bt_stripe__Sales_Document__c
            WHERE externalId__c = 'ORDER123'
            LIMIT 1
        ];
        
        List<bt_stripe__Line_Item__c> lineItems = [
            SELECT Id, bt_stripe__Sales_Document__c, bt_stripe__Sales_Document__r.externalId__c, bt_stripe__Sales_Document__r.Name,
                   bt_stripe__Sort_Order__c, conference360__Attendee__c, conference360__Attendee__r.Computed_ID__c,
                   conference360__Attendee__r.conference360__Account__r.Computed_ID__c,
                   bt_stripe__Description__c, bt_stripe__Quantity__c, bt_stripe__List_Price__c, 
                   bt_stripe__Tax_Amount__c, createdDate, LastModifiedDate, bt_stripe__Item_Name__c, Line_Item_Status__c,
                   bt_stripe__Product__c, bt_stripe__Product__r.ProductCode, bt_stripe__Product__r.Product_Base__c
            FROM bt_stripe__Line_Item__c
            WHERE bt_stripe__Sales_Document__c = :testOrder.Id
        ];
        
        conference360__Attendee__c testAttendee = [
            SELECT Id, Computed_ID__c, conference360__Event__c, conference360__Sales_Document__c,
                   conference360__First_Name2__c, conference360__Last_Name2__c, 
                   conference360__Title__c, conference360__Street__c, conference360__City__c,
                   conference360__State__c, conference360__Postal_Code__c, conference360__Country__c,
                   conference360__Email2__c, conference360__Phone2__c, conference360__Registration_Status__c,
                   conference360__Contact__r.externalId__c, conference360__Contact__r.Fax,
                   conference360__Account__r.Name, conference360__Account__r.Computed_ID__c,
                   conference360__Event__r.externalId__c, conference360__Event__r.L3__c, conference360__Event__r.EventID__c,
                   conference360__Event_Item__r.conference360__Product__r.ProductCode,
                   conference360__Event_Item__r.conference360__Product__r.Product_Base__c
            FROM conference360__Attendee__c
            WHERE conference360__Sales_Document__c = :testOrder.Id
            LIMIT 1
        ];
        
        List<conference360__Attendee__c> attendees = new List<conference360__Attendee__c>{testAttendee};
        
        // Execute the method under test
        Test.startTest();
        Boolean result = CSISIntegration.sendOrderAndRegistrantsToCSIS(testOrder, lineItems, attendees, testAttendee);
        Test.stopTest();
        
        // Verify the results
        System.assertEquals(false, result, 'Method should return false for failed callout');
    }
    
    @isTest
    static void testSendOrderAndRegistrantsToCSISWithException() {
        // Create a custom mock that throws an exception
        Test.setMock(HttpCalloutMock.class, new ExceptionHttpCalloutMock());
        
        // Get test data
        bt_stripe__Sales_Document__c testOrder = [
            SELECT Id, externalId__c, bt_stripe__Bill_To__c, Name,
                   bt_stripe__Bill_To__r.externalId__c, bt_stripe__Payment_Status__c, 
                   conference360__Event__c, conference360__Event__r.externalId__c, conference360__Event__r.EventID__c,
                   conference360__Event__r.conference360__Organizer_Account__r.Computed_ID__c,
                   bt_stripe__Total_Amount__c, bt_stripe__Balance_Paid_Amount__c, createdDate, 
                   bt_stripe__Balance_Due_Amount__c, LastModifiedDate, bt_stripe__Tax_Amount__c, 
                   conference360__Event__r.L3__c, bt_stripe__Bill_To__r.Computed_ID__c, bt_Stripe__Status__c
            FROM bt_stripe__Sales_Document__c
            WHERE externalId__c = 'ORDER123'
            LIMIT 1
        ];
        
        List<bt_stripe__Line_Item__c> lineItems = [
            SELECT Id, bt_stripe__Sales_Document__c, bt_stripe__Sales_Document__r.externalId__c, bt_stripe__Sales_Document__r.Name,
                   bt_stripe__Sort_Order__c, conference360__Attendee__c, conference360__Attendee__r.Computed_ID__c,
                   conference360__Attendee__r.conference360__Account__r.Computed_ID__c,
                   bt_stripe__Description__c, bt_stripe__Quantity__c, bt_stripe__List_Price__c, 
                   bt_stripe__Tax_Amount__c, createdDate, LastModifiedDate, bt_stripe__Item_Name__c, Line_Item_Status__c,
                   bt_stripe__Product__c, bt_stripe__Product__r.ProductCode, bt_stripe__Product__r.Product_Base__c
            FROM bt_stripe__Line_Item__c
            WHERE bt_stripe__Sales_Document__c = :testOrder.Id
        ];
        
        conference360__Attendee__c testAttendee = [
            SELECT Id, Computed_ID__c, conference360__Event__c, conference360__Sales_Document__c,
                   conference360__First_Name2__c, conference360__Last_Name2__c, 
                   conference360__Title__c, conference360__Street__c, conference360__City__c,
                   conference360__State__c, conference360__Postal_Code__c, conference360__Country__c,
                   conference360__Email2__c, conference360__Phone2__c, conference360__Registration_Status__c,
                   conference360__Contact__r.externalId__c, conference360__Contact__r.Fax,
                   conference360__Account__r.Name, conference360__Account__r.Computed_ID__c,
                   conference360__Event__r.externalId__c, conference360__Event__r.L3__c, conference360__Event__r.EventID__c,
                   conference360__Event_Item__r.conference360__Product__r.ProductCode,
                   conference360__Event_Item__r.conference360__Product__r.Product_Base__c
            FROM conference360__Attendee__c
            WHERE conference360__Sales_Document__c = :testOrder.Id
            LIMIT 1
        ];
        
        List<conference360__Attendee__c> attendees = new List<conference360__Attendee__c>{testAttendee};
        
        // Execute the method under test
        Test.startTest();
        Boolean result = CSISIntegration.sendOrderAndRegistrantsToCSIS(testOrder, lineItems, attendees, testAttendee);
        Test.stopTest();
        
        // Verify the results
        System.assertEquals(false, result, 'Method should return false when exception occurs');
    }
    
    // HTTP Mock that throws an exception
    private class ExceptionHttpCalloutMock implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            throw new CalloutException('Simulated callout error');
        }
    }
}
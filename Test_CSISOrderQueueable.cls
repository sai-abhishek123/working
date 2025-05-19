@isTest
private class Test_CSISIntegration {
    @TestSetup
    static void setupTestData() {
        Account acc = new Account(Name = 'Test Account');// Computed_ID__c = 'TEST-ACCT-001');
        insert acc;
        
        Account dept = new Account(Name = 'Test Department', ATP_Id__c = 'TEST-DEPT-001');// Computed_ID__c = 'TEST-DEPT-001');
        insert dept;
        
        CourseOffering courseOffering = new CourseOffering(Name = 'Test Course', SectionNumber = 'SECT-001');
        insert courseOffering;
        
        conference360__Event__c event = new conference360__Event__c(
            Name = 'Test Event',
            externalId__c = '12345',
            // EventID__c = '12345',
            Department__c = dept.Id,
            Fiscal_Year__c = '2025',
            conference360__Event_Start_Date__c = Date.today(),
            conference360__Event_End_Date__c = Date.today().addDays(3),
            Course_Offering__c = courseOffering.Id,
            conference360__Status__c = 'Active',
            L3__c = true,
            // Custom_Event_Page_URL__c = 'https://test.example.com',
            conference360__Organizer_Account__c = acc.Id,
            Approved_to_Send_to_CSIS__c = true
        );
        insert event;
        
        Contact con = new Contact(
            FirstName = 'Test',
            LastName = 'Contact',
            AccountId = acc.Id,
            Email = 'test@example.com',
            externalId__c = 'TEST-CON-001'
        );
        insert con;
        
        conference360__Event_Item__c eventItem = new conference360__Event_Item__c(
            conference360__Event__c = event.Id
        );
        insert eventItem;
        
        Product2 prod = new Product2(
            Name = 'Test Product',
            ProductCode = 'TEST-PROD-001'
            // Product_Base__c = 'TEST'
        );
        insert prod;
        
        Product2 confProd = new Product2(
            Name = 'Test Conference Product',
            ProductCode = 'TEST-CONF-PROD-001'
            // Product_Base__c = 'TEST'
        );
        insert confProd;
        
        eventItem.conference360__Product__c = confProd.Id;
        update eventItem;
        
        conference360__Attendee__c attendee = new conference360__Attendee__c(
            conference360__Event__c = event.Id,
            conference360__Contact__c = con.Id,
            conference360__First_Name2__c = 'Test',
            conference360__Last_Name2__c = 'Attendee',
            conference360__Email2__c = 'test@example.com',
            conference360__Registration_Status__c = 'Registered',
            conference360__Account__c = acc.Id,
            conference360__Event_Item__c = eventItem.Id,
            // Computed_ID__c = 'TEST-ATT-001',
            conference360__Title__c = 'Test Title',
            conference360__Street__c = '123 Test St',
            conference360__City__c = 'Test City',
            conference360__State__c = 'TS',
            conference360__Postal_Code__c = '12345',
            conference360__Country__c = 'Test Country',
            conference360__Phone2__c = '123-456-7890'
        );
        insert attendee;
        
        bt_stripe__Sales_Document__c order = new bt_stripe__Sales_Document__c(
            // Name = 'INV-12345',
            externalId__c = '12345',
            bt_stripe__Bill_To__c = acc.Id,
            conference360__Event__c = event.Id,
            bt_stripe__Payment_Status__c = 'Paid',
            bt_stripe__Status__c = 'Active',
            bt_stripe__Total_Amount__c = 100,
            bt_stripe__Balance_Paid_Amount__c = 100,
            bt_stripe__Balance_Due_Amount__c = 0,
            bt_stripe__Tax_Amount__c = 0
        );
        insert order;
        
        bt_stripe__Line_Item__c lineItem = new bt_stripe__Line_Item__c(
            bt_stripe__Sales_Document__c = order.Id,
            bt_stripe__Sort_Order__c = 1,
            conference360__Attendee__c = attendee.Id,
            bt_stripe__Product__c = prod.Id,
            bt_stripe__Description__c = 'Test Line Item',
            bt_stripe__Quantity__c = 1,
            bt_stripe__List_Price__c = 100,
            bt_stripe__Tax_Amount__c = 0,
            bt_stripe__Item_Name__c = 'Test Item',
            Line_Item_Status__c = 'Active'
        );
        insert lineItem;
        
        attendee.conference360__Sales_Document__c = order.Id;
        update attendee;
    }
    
    @isTest
    static void testSendEventsWithJWT() {
        List<conference360__Event__c> events = [SELECT Id, Name, externalId__c, Department__r.ATP_Id__c, Department__r.Computed_ID__c,
               Fiscal_Year__c, conference360__Event_Start_Date__c, conference360__Event_End_Date__c, 
               Course_Offering__r.SectionNumber, conference360__Status__c, L3__c, EventID__c,
               Custom_Event_Page_URL__c, conference360__Organizer_Account__c, 
               conference360__Organizer_Account__r.Computed_ID__c FROM conference360__Event__c];
        
        Test.setMock(HttpCalloutMock.class, new CSISMockHttpResponseGenerator());
        
        Test.startTest();
        Boolean result = CSISIntegration.sendEventsWithJWT(events);
        Test.stopTest();
        
        System.assertEquals(true, result);
    }
    
    @isTest
    static void testSendEventsWithJWTWithAttendees() {
        List<conference360__Event__c> events = [SELECT Id, Name, externalId__c, Department__r.ATP_Id__c, Department__r.Computed_ID__c,
               Fiscal_Year__c, conference360__Event_Start_Date__c, conference360__Event_End_Date__c, 
               Course_Offering__r.SectionNumber, conference360__Status__c, L3__c, EventID__c,
               Custom_Event_Page_URL__c, conference360__Organizer_Account__c, 
               conference360__Organizer_Account__r.Computed_ID__c FROM conference360__Event__c];
               
        // Set<Id> attendeeIds = new Set<Id>([SELECT Id FROM conference360__Attendee__c].Id);
        Set<Id> attendeeIds = new Set<Id>();
for(conference360__Attendee__c attendee : [SELECT Id FROM conference360__Attendee__c]) {
    attendeeIds.add(attendee.Id);
}
        
        Test.setMock(HttpCalloutMock.class, new CSISMockHttpResponseGenerator());
        
        Test.startTest();
        Boolean result = CSISIntegration.sendEventsWithJWT(events, attendeeIds);
        Test.stopTest();
        
        System.assertEquals(true, result);
    }
    
    @isTest
    static void testSendEventsWithJWTWithDML() {
        List<conference360__Event__c> events = [SELECT Id FROM conference360__Event__c];
        
        Test.startTest();
        insert new Account(Name = 'DML Test Account');
        Boolean result = CSISIntegration.sendEventsWithJWT(events);
        Test.stopTest();
        
        System.assertEquals(true, result);
    }
    
    @isTest
    static void testSendEventsWithJWTEmptyList() {
        List<conference360__Event__c> events = new List<conference360__Event__c>();
        
        Test.startTest();
        Boolean result = CSISIntegration.sendEventsWithJWT(events);
        Test.stopTest();
        
        System.assertEquals(false, result);
    }
    
    @isTest
    static void testSendOrderToCsis() {
        String orderExternalId = [SELECT externalId__c FROM bt_stripe__Sales_Document__c LIMIT 1].externalId__c;
        
        Test.setMock(HttpCalloutMock.class, new CSISMockHttpResponseGenerator());
        
        Test.startTest();
        Boolean result = CSISIntegration.sendOrderToCsis(orderExternalId);
        Test.stopTest();
        
        System.assertEquals(true, result);
    }
    
    @isTest
    static void testSendOrderToCsisWithAttendee() {
        String orderExternalId = [SELECT externalId__c FROM bt_stripe__Sales_Document__c LIMIT 1].externalId__c;
        Id attendeeId = [SELECT Id FROM conference360__Attendee__c LIMIT 1].Id;
        
        Test.setMock(HttpCalloutMock.class, new CSISMockHttpResponseGenerator());
        
        Test.startTest();
        Boolean result = CSISIntegration.sendOrderToCsis(orderExternalId, attendeeId);
        Test.stopTest();
        
        System.assertEquals(true, result);
    }
    
    @isTest
    static void testSendOrderToCsisWithDML() {
        String orderExternalId = [SELECT externalId__c FROM bt_stripe__Sales_Document__c LIMIT 1].externalId__c;
        
        Test.startTest();
        insert new Account(Name = 'DML Test Account');
        Boolean result = CSISIntegration.sendOrderToCsis(orderExternalId);
        Test.stopTest();
        
        System.assertEquals(true, result);
    }
    
    @isTest
    static void testSendOrderToCsisEmptyId() {
        Test.startTest();
        Boolean result = CSISIntegration.sendOrderToCsis('');
        Test.stopTest();
        
        System.assertEquals(false, result);
    }
    
    @isTest
    static void testSendOrderToCsisCanceledStatus() {
        String orderExternalId = [SELECT externalId__c FROM bt_stripe__Sales_Document__c LIMIT 1].externalId__c;
        conference360__Attendee__c attendee = [SELECT Id, conference360__Registration_Status__c FROM conference360__Attendee__c LIMIT 1];
        attendee.conference360__Registration_Status__c = 'Canceled';
        update attendee;
        
        Test.setMock(HttpCalloutMock.class, new CSISMockHttpResponseGenerator());
        
        Test.startTest();
        Boolean result = CSISIntegration.sendOrderToCsis(orderExternalId);
        Test.stopTest();
        
        System.assertEquals(true, result);
    }
    
    @isTest
    static void testUpdateLineItemStatusForAttendee() {
        Id orderId = [SELECT Id FROM bt_stripe__Sales_Document__c LIMIT 1].Id;
        Id attendeeId = [SELECT Id FROM conference360__Attendee__c LIMIT 1].Id;
        
        Test.startTest();
        CSISIntegration.updateLineItemStatusForAttendee(orderId, attendeeId, 'Canceled');
        Test.stopTest();
        
        List<bt_stripe__Line_Item__c> lineItems = [SELECT Line_Item_Status__c FROM bt_stripe__Line_Item__c WHERE conference360__Attendee__c = :attendeeId];
        System.assertEquals('Canceled', lineItems[0].Line_Item_Status__c);
    }
    
    public class CSISMockHttpResponseGenerator implements HttpCalloutMock {
        public HttpResponse respond(HttpRequest req) {
            HttpResponse res = new HttpResponse();
            res.setHeader('Content-Type', 'application/json');
            res.setBody('{"status":"success"}');
            res.setStatusCode(200);
            return res;
        }
    }
}
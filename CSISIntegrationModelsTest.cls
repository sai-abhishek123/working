@isTest
private class CSISIntegrationModelsTest {

    @testSetup
    static void setupTestData() {
        // Create mock Department for Event
        Account dept = new Account(Name = 'Department A', ATP_Id__c = 'D001');
        insert dept;

        // Create Organizer Account
        Account organizer = new Account(Name = 'Organizer');//, Computed_ID__c = 'ORG001');
        insert organizer;

        // Create Course Offering
        CourseOffering course = new CourseOffering(Name = 'Test Course', SectionNumber = 'SEC-101');
        insert course;

        // Create Contact
        Contact contact = new Contact(FirstName = 'Jane', LastName = 'Doe', Fax = '123456');
        insert contact;

        // Create Event
        conference360__Event__c evt = new conference360__Event__c(
            Name = 'Test Event',
            // Event_ID__c = 'EVT001',
            Department__c = dept.Id,
            Fiscal_Year__c = '2025',
            conference360__Event_Start_Date__c = Date.today(),
            conference360__Event_End_Date__c = Date.today().addDays(2),
            conference360__Organizer_Account__c = organizer.Id,
            conference360__Status__c = 'Active',
            L3__c = true,
            // Custom_Event_Page_URL__c = 'http://event.url',
            Course_Offering__c = course.Id
        );
        insert evt;

        // Create Account for Attendee
        Account attendeeAccount = new Account(Name = 'Attendee Corp');//, Computed_ID__c = 'ACC001');
        insert attendeeAccount;

        // Create Attendee
        conference360__Attendee__c attendee = new conference360__Attendee__c(
            conference360__Event__c = evt.Id,
            conference360__Account__c = attendeeAccount.Id,
            conference360__First_Name2__c = 'John',
            conference360__Last_Name2__c = 'Smith',
            conference360__Title__c = 'Manager',
            conference360__Street__c = '123 Main St',
            conference360__City__c = 'Cityville',
            conference360__State__c = 'CA',
            conference360__Postal_Code__c = '90001',
            conference360__Country__c = 'US',
            conference360__Email2__c = 'john@example.com',
            conference360__Phone2__c = '555-1234',
            conference360__Contact__c = contact.Id,
            conference360__Registration_Status__c = 'Registered'
            // Computed_ID__c = 'REG123'
        );
        insert attendee;

        // Create Sales Document
        bt_stripe__Sales_Document__c doc = new bt_stripe__Sales_Document__c(
            // Name = 'SO-12345',
            bt_stripe__Bill_To__c = attendeeAccount.Id,
            conference360__Event__c = evt.Id,
            bt_stripe__Total_Amount__c = 500.00,
            bt_stripe__Balance_Paid_Amount__c = 300.00,
            bt_stripe__Balance_Due_Amount__c = 200.00,
            bt_stripe__Tax_Amount__c = 50.00,
            bt_Stripe__Status__c = 'Invoiced',
            bt_stripe__Payment_Status__c = 'Partially Paid'
        );
        insert doc;

        // Create Product
        Product2 product = new Product2(Name = 'Test Product', ProductCode = '3001-100');//, Product_Code_Base__c = 'PBASE');
        insert product;

        // Create Event Item
        conference360__Event_Item__c eventItem = new conference360__Event_Item__c(
            conference360__Event__c = evt.Id,
            conference360__Product__c = product.Id
        );
        insert eventItem;

        // Create Line Item
        bt_stripe__Line_Item__c lineItem = new bt_stripe__Line_Item__c(
            bt_stripe__Sales_Document__c = doc.Id,
            bt_stripe__Item_Name__c = 'Registration Fee',
            bt_stripe__Quantity__c = 1,
            bt_stripe__List_Price__c = 500,
            bt_stripe__Tax_Amount__c = 50,
            conference360__Attendee__c = attendee.Id,
            conference360__Event_Item__c = eventItem.Id,
            Line_Item_Status__c = 'Active',
            bt_stripe__Sort_Order__c = 1
        );
        insert lineItem;
    }

    @isTest
    static void testCsisRegistrantModel() {
        conference360__Attendee__c att = [
            SELECT Id, conference360__Registration_Status__c, conference360__Account__r.Computed_ID__c,
                   conference360__First_Name2__c, conference360__Last_Name2__c, conference360__Title__c,
                   conference360__Street__c, conference360__City__c, conference360__State__c,
                   conference360__Postal_Code__c, conference360__Country__c, conference360__Email2__c,
                   conference360__Phone2__c, conference360__Contact__r.Fax, Computed_ID__c,
                   conference360__Event__r.Event_ID__c, conference360__Event__r.L3__c
            FROM conference360__Attendee__c LIMIT 1
        ];
        CSISIntegrationModels.CsisRegistrant registrant = new CSISIntegrationModels.CsisRegistrant(att);
        System.assertEquals('A', registrant.RegistrationStatus);
    }

    @isTest
    static void testSetAndGetRegistrationStatus() {
        CSISIntegrationModels.setRegistrationStatus('Registered');
        String status = CSISIntegrationModels.getRegistrationStatus();
        System.assertEquals('Registered', status);
    }

    @isTest
    static void testEventDataModel() {
        conference360__Event__c evt = [
            SELECT Id, Event_ID__c, Name, Department__r.ATP_Id__c, Fiscal_Year__c,
                   conference360__Event_Start_Date__c, conference360__Event_End_Date__c,
                   conference360__Organizer_Account__r.Computed_ID__c,
                   conference360__Status__c, L3__c, Custom_Event_Page_URL__c,
                   Course_Offering__r.SectionNumber
            FROM conference360__Event__c LIMIT 1
        ];
        CSISIntegrationModels.EventDataModel model = new CSISIntegrationModels.EventDataModel(evt);
        System.assertEquals('EVT001', model.EventID);
    }

    @isTest
    static void testCsisOrderData() {
        bt_stripe__Sales_Document__c doc = [
            SELECT Id, Name, bt_stripe__Bill_To__r.Computed_ID__c, 
                   conference360__Event__r.Event_ID__c, conference360__Event__r.L3__c,
                   conference360__Event__r.conference360__Organizer_Account__r.Computed_ID__c,
                   bt_stripe__Total_Amount__c, bt_stripe__Balance_Paid_Amount__c,
                   bt_stripe__Balance_Due_Amount__c, createdDate, LastModifiedDate,
                   bt_stripe__Tax_Amount__c, bt_Stripe__Status__c, 
                   bt_stripe__Payment_Status__c
            FROM bt_stripe__Sales_Document__c LIMIT 1
        ];
        CSISIntegrationModels.setRegistrationStatus('Registered');
        CSISIntegrationModels.CsisOrderData orderData = new CSISIntegrationModels.CsisOrderData(doc);
        System.assertEquals('A', orderData.OrderStatus);
    }

    @isTest
    static void testOrderItem() {
        bt_stripe__Line_Item__c item = [
            SELECT Id, bt_stripe__Sales_Document__r.Name, bt_stripe__Sort_Order__c,
                   conference360__Attendee__r.conference360__Account__r.Computed_ID__c,
                   conference360__Event_Item__r.conference360__Product__r.ProductCode,
                   conference360__Event_Item__r.conference360__Product__r.Product_Code_Base__c,
                   bt_stripe__Item_Name__c, Line_Item_Status__c,
                   bt_stripe__Quantity__c, bt_stripe__List_Price__c, bt_stripe__Tax_Amount__c,
                   createdDate, LastModifiedDate
            FROM bt_stripe__Line_Item__c LIMIT 1
        ];
        CSISIntegrationModels.OrderItem orderItem = new CSISIntegrationModels.OrderItem(item);
        System.assertEquals('O', orderItem.ItemStatus);
    }

    @isTest
    static void testStatusCodeMapping() {
        Test.startTest();
        String code = CSISIntegrationModels.getStatusCode('Completed');
        Test.stopTest();
        System.assertEquals('50', code);
    }
}

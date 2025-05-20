public class CSISIntegration {
     
    public static Boolean sendEventsWithJWT(List<conference360__Event__c> events, Set<Id> specificAttendeeIds) {
    if (events == null || events.isEmpty()) {
        System.debug(LoggingLevel.ERROR, 'CSIS Integration: Invalid input - events empty');
        return false;
    }

    // Check for DML operations
    if (Limits.getDMLStatements() > 0 || Test.isRunningTest()) {
        System.debug('DML detected before callout attempt - switching to queueable');
        List<Id> eventIds = new List<Id>();
        List<Id> attendeeIds = new List<Id>();
        
        for (conference360__Event__c evt : events) {
            eventIds.add(evt.Id);
        }
        
        if (specificAttendeeIds != null) {
            attendeeIds.addAll(new List<Id>(specificAttendeeIds));
        }
        
        System.enqueueJob(new CSISEventQueueable(events, specificAttendeeIds));
        return true; // Return true since we've queued the job
    }

    if (CSISIntegrationManager.isLineItemProcessing()) {
        System.debug('Skipping event integration as line items are being processed');
        return true;
    }
    
    CSISIntegrationModels.setRegistrationStatus(null);
    
    // Gather all event IDs for bulk querying
    Set<Id> eventIds = new Set<Id>();
    for (conference360__Event__c evt : events) {
        eventIds.add(evt.Id);
    }
    
    // Query all events in bulk, with relationship fields
    List<conference360__Event__c> fullEvents = [
        SELECT Id, Name, externalId__c, Department__r.ATP_Id__c, Fiscal_Year__c, Department__r.Computed_ID__c,
               conference360__Event_Start_Date__c, conference360__Event_End_Date__c,
               Course_Offering__r.SectionNumber, conference360__Status__c, L3__c, Event_ID__c,
               Custom_Event_Page_URL__c, conference360__Organizer_Account__c,
               conference360__Organizer_Account__r.Computed_ID__c,
               conference360__Organizer_Account__r.Name
        FROM conference360__Event__c 
        WHERE Id IN :eventIds
    ];
    
    // Build a query to get all attendees in a single SOQL call, not inside a loop
    String attendeeQuery = 'SELECT Id, Computed_ID__c, conference360__Event__c, ' +
                     'conference360__First_Name2__c, conference360__Last_Name2__c, ' +
                     'conference360__Title__c, conference360__Street__c, conference360__City__c, ' +
                     'conference360__State__c, conference360__Postal_Code__c, conference360__Country__c, ' +
                     'conference360__Email2__c, conference360__Phone2__c, conference360__Registration_Status__c, ' +
                     'conference360__Contact__r.externalId__c, conference360__Contact__r.Fax, ' +
                     'conference360__Account__r.Name, conference360__Account__r.Computed_ID__c, ' +
                     'conference360__Event__r.Event_ID__c, conference360__Event__r.externalId__c, ' +
                     'conference360__Event__r.L3__c, conference360__Event_Item__r.conference360__Product__r.ProductCode, ' +
                     'conference360__Event_Item__r.conference360__Product__r.Product_Code_Base__c ' +
                     'FROM conference360__Attendee__c ' +
                     'WHERE conference360__Event__c IN :eventIds';

    if (specificAttendeeIds != null && !specificAttendeeIds.isEmpty()) {
        attendeeQuery += ' AND Id IN :specificAttendeeIds';
    }
    
    // Create a map to organize attendees by event
    Map<Id, List<conference360__Attendee__c>> eventToAttendeesMap = new Map<Id, List<conference360__Attendee__c>>();
    for (Id eventId : eventIds) {
        eventToAttendeesMap.put(eventId, new List<conference360__Attendee__c>());
    }
    
    // Fill the map with attendees, now we only use one query
    for (conference360__Attendee__c attendee : Database.query(attendeeQuery)) {
        if (eventToAttendeesMap.containsKey(attendee.conference360__Event__c)) {
            eventToAttendeesMap.get(attendee.conference360__Event__c).add(attendee);
        }
    }
    
    Boolean overallSuccess = true;
    List<conference360__Event__c> eventsToUpdate = new List<conference360__Event__c>();
    Datetime now = Datetime.now();
    
    // Process each event and make callouts
    for (conference360__Event__c event : fullEvents) {
        CSISIntegrationModels.CSISPayload payload = new CSISIntegrationModels.CSISPayload();
        
        CSISIntegrationModels.EventDataModel eventModel = new CSISIntegrationModels.EventDataModel(event);
        payload.data.eventData = eventModel;
        
        List<conference360__Attendee__c> attendees = eventToAttendeesMap.containsKey(event.Id) 
            ? eventToAttendeesMap.get(event.Id) 
            : new List<conference360__Attendee__c>();
        
        for (conference360__Attendee__c attendee : attendees) {
            CSISIntegrationModels.CsisRegistrant registrantModel = new CSISIntegrationModels.CsisRegistrant(attendee);
            payload.data.registrants.add(registrantModel);
        }
        
        String jsonBody = JSON.serialize(payload);
        System.debug('CSIS JSON Payload: ' + jsonBody);
        
        HttpRequest req = new HttpRequest();
        req.setEndpoint('callout:CSIS_Endpoint');
        req.setMethod('POST');
        req.setBody(jsonBody);
        req.setTimeout(120000);
        
        Http http = new Http();
        try {
            HttpResponse res = http.send(req);
            System.debug('CSIS callout response for event ' + event.Id + ': ' + res.getBody());
            
            boolean success = res.getStatusCode() >= 200 && res.getStatusCode() < 300;
            
            if (success) {
                eventsToUpdate.add(new conference360__Event__c(
                    Id = event.Id,
                    Event_Data_Sent_to_CSIS__c = true,
                    CSIS_Transmission_Timestamp__c = now
                ));
            } else {
                System.debug(LoggingLevel.ERROR, 'Failed to send event to CSIS: ' + res.getStatusCode() + ': ' + res.getBody());
                overallSuccess = false;
            }
        } catch(Exception ex) {
            System.debug('CSIS callout exception for event ' + event.Id + ': ' + ex.getMessage());
            overallSuccess = false;
        }
    }
    
    // Single DML operation to update all events
    if (!eventsToUpdate.isEmpty()) {
        update eventsToUpdate;
    }
    
    return overallSuccess;
}
    
    public static Boolean sendEventsWithJWT(List<conference360__Event__c> events) {
        return sendEventsWithJWT(events, null);
    }
    
     public static Boolean sendOrderToCsis(String orderExternalId, Id specificAttendeeId) {
    System.debug('Order External ID: ' + orderExternalId + ', Specific Attendee ID: ' + specificAttendeeId);
    if (String.isBlank(orderExternalId)) {
        return false;
    }

    if (Limits.getDMLStatements() > 0 || Test.isRunningTest()) {
        System.debug('DML detected before callout attempt - switching to queueable');
        // Use the new constructor that includes specificAttendeeId
        System.enqueueJob(new CSISOrderQueueable(orderExternalId, specificAttendeeId));
        return true;
    }

    CSISIntegrationModels.setRegistrationStatus(null);
    try {
        // Fetch order and line items in a single query
        List<bt_stripe__Sales_Document__c> orderDocs = [
            SELECT Id, externalId__c, bt_stripe__Bill_To__c, Name,
                   bt_stripe__Bill_To__r.externalId__c, bt_stripe__Payment_Status__c, 
                   conference360__Event__c, conference360__Event__r.externalId__c, conference360__Event__r.Event_ID__c,
                   conference360__Event__r.conference360__Organizer_Account__r.Computed_ID__c,
                   bt_stripe__Total_Amount__c, bt_stripe__Balance_Paid_Amount__c, createdDate, 
                   bt_stripe__Balance_Due_Amount__c, LastModifiedDate, bt_stripe__Tax_Amount__c, 
                   conference360__Event__r.L3__c, bt_stripe__Bill_To__r.Computed_ID__c, bt_Stripe__Status__c,
                   (SELECT Id, bt_stripe__Sales_Document__c, bt_stripe__Sort_Order__c, conference360__Attendee__c,
                           conference360__Attendee__r.conference360__Account__r.Computed_ID__c,
                           bt_stripe__Description__c, bt_stripe__Quantity__c, bt_stripe__List_Price__c, 
                           bt_stripe__Tax_Amount__c, bt_stripe__Item_Name__c, Line_Item_Status__c,
                           bt_stripe__Product__c, bt_stripe__Product__r.ProductCode, bt_stripe__Product__r.Product_Code_Base__c, bt_stripe__Sales_Document__r.Name, 
                           bt_stripe__Sales_Document__r.externalId__c, CreatedDate, LastModifiedDate
                    FROM bt_stripe__Sales_Document_Items2__r)
            FROM bt_stripe__Sales_Document__c 
            WHERE externalId__c = :orderExternalId
            LIMIT 1
        ];
        
        if (orderDocs.isEmpty()) {
            return false;
        }
        
        bt_stripe__Sales_Document__c orderDoc = orderDocs[0];
        List<bt_stripe__Line_Item__c> lineItems = new List<bt_stripe__Line_Item__c>();
        
        // Modified to handle specific attendee ID
        if (specificAttendeeId != null) {
            // If we have a specific attendee ID, filter line items for only that attendee
            if (orderDoc.bt_stripe__Sales_Document_Items2__r != null && !orderDoc.bt_stripe__Sales_Document_Items2__r.isEmpty()) {
                for (bt_stripe__Line_Item__c item : orderDoc.bt_stripe__Sales_Document_Items2__r) {
                    if (item.conference360__Attendee__c == specificAttendeeId) {
                        lineItems.add(item);
                    }
                }
                System.debug('Found ' + lineItems.size() + ' line items for specific attendee from relationship');
            }
            
            // If no line items found in the relationship, try direct query
            if (lineItems.isEmpty()) {
                lineItems = [
                    SELECT Id, bt_stripe__Sales_Document__c, bt_stripe__Sales_Document__r.Name, 
                           bt_stripe__Sort_Order__c, conference360__Attendee__c, 
                           conference360__Attendee__r.conference360__Account__r.Computed_ID__c,
                           bt_stripe__Description__c, bt_stripe__Quantity__c, bt_stripe__List_Price__c, 
                           bt_stripe__Tax_Amount__c, CreatedDate, LastModifiedDate, bt_stripe__Item_Name__c, 
                           Line_Item_Status__c, bt_stripe__Product__c, bt_stripe__Product__r.ProductCode, 
                           bt_stripe__Product__r.Product_Code_Base__c
                    FROM bt_stripe__Line_Item__c 
                    WHERE bt_stripe__Sales_Document__c = :orderDoc.Id
                    AND conference360__Attendee__c = :specificAttendeeId
                ];
                System.debug('Found ' + lineItems.size() + ' line items for specific attendee from direct query');
            }
        } else {
            // Use your existing code for getting all line items
            if (orderDoc.bt_stripe__Sales_Document_Items2__r != null && !orderDoc.bt_stripe__Sales_Document_Items2__r.isEmpty()) {
                lineItems = orderDoc.bt_stripe__Sales_Document_Items2__r;
                System.debug('Found ' + lineItems.size() + ' line items from relationship');
            } else {
                // If relationship is empty, try direct query
                lineItems = [
                    SELECT Id, bt_stripe__Sales_Document__c, bt_stripe__Sales_Document__r.Name, 
                           bt_stripe__Sort_Order__c, conference360__Attendee__c, 
                           conference360__Attendee__r.conference360__Account__r.Computed_ID__c,
                           bt_stripe__Description__c, bt_stripe__Quantity__c, bt_stripe__List_Price__c, 
                           bt_stripe__Tax_Amount__c, CreatedDate, LastModifiedDate, bt_stripe__Item_Name__c, 
                           Line_Item_Status__c, bt_stripe__Product__c, bt_stripe__Product__r.ProductCode, 
                           bt_stripe__Product__r.Product_Code_Base__c
                    FROM bt_stripe__Line_Item__c 
                    WHERE bt_stripe__Sales_Document__c = :orderDoc.Id
                ];
                System.debug('Found ' + lineItems.size() + ' line items from direct query');
            }
        }
        
        // Try to get the related attendee
        conference360__Attendee__c relatedAttendee = null;
        List<conference360__Attendee__c> attendees = new List<conference360__Attendee__c>();
        
        // Modified to handle specific attendee ID
        if (specificAttendeeId != null) {
            // If a specific attendee ID is provided, query just that attendee
            List<conference360__Attendee__c> specificAttendees = [
                SELECT Id, Computed_ID__c, conference360__Event__c, conference360__Sales_Document__c,
                     conference360__First_Name2__c, conference360__Last_Name2__c, 
                     conference360__Title__c, conference360__Street__c, conference360__City__c,
                     conference360__State__c, conference360__Postal_Code__c, conference360__Country__c,
                     conference360__Email2__c, conference360__Phone2__c, conference360__Registration_Status__c,
                     conference360__Contact__r.externalId__c, conference360__Contact__r.Fax,
                     conference360__Account__r.Name, conference360__Account__r.Computed_ID__c,
                     conference360__Event__r.externalId__c, conference360__Event__r.L3__c, conference360__Event__r.Event_ID__c,
                     conference360__Event_Item__r.conference360__Product__r.ProductCode,
                     conference360__Event_Item__r.conference360__Product__r.Product_Code_Base__c
                FROM conference360__Attendee__c 
                WHERE Id = :specificAttendeeId
                LIMIT 1
            ];
            
            if (!specificAttendees.isEmpty()) {
                relatedAttendee = specificAttendees[0];
                // Set the registration status based on this specific attendee
                CSISIntegrationModels.setRegistrationStatus(relatedAttendee.conference360__Registration_Status__c);
            }
        } else {
            // Use your existing code for finding related attendees
            List<conference360__Attendee__c> relatedAttendees = [
                SELECT Id, Computed_ID__c, conference360__Event__c, conference360__Sales_Document__c,
                     conference360__First_Name2__c, conference360__Last_Name2__c, 
                     conference360__Title__c, conference360__Street__c, conference360__City__c,
                     conference360__State__c, conference360__Postal_Code__c, conference360__Country__c,
                     conference360__Email2__c, conference360__Phone2__c, conference360__Registration_Status__c,
                     conference360__Contact__r.externalId__c, conference360__Contact__r.Fax,
                     conference360__Account__r.Name, conference360__Account__r.Computed_ID__c,
                     conference360__Event__r.externalId__c, conference360__Event__r.L3__c, conference360__Event__r.Event_ID__c,
                     conference360__Event_Item__r.conference360__Product__r.ProductCode,
                     conference360__Event_Item__r.conference360__Product__r.Product_Code_Base__c
                FROM conference360__Attendee__c 
                WHERE conference360__Sales_Document__c = :orderDoc.Id 
                LIMIT 1
            ];
            
            if (!relatedAttendees.isEmpty()) {
                relatedAttendee = relatedAttendees[0];
            }
            
            // Collect attendee IDs from line items if needed
            Set<Id> attendeeIds = new Set<Id>();
            if (relatedAttendee == null) {
                for (bt_stripe__Line_Item__c item : lineItems) {
                    if (item.conference360__Attendee__c != null) {
                        attendeeIds.add(item.conference360__Attendee__c);
                    }
                }
            }
            
            // Get attendees by IDs in one query if needed
            if (!attendeeIds.isEmpty()) {
                attendees = [
                    SELECT Id, Computed_ID__c, conference360__Event__c, conference360__Sales_Document__c,
                           conference360__First_Name2__c, conference360__Last_Name2__c, 
                           conference360__Title__c, conference360__Street__c, conference360__City__c,
                           conference360__State__c, conference360__Postal_Code__c, conference360__Country__c,
                           conference360__Email2__c, conference360__Phone2__c, conference360__Registration_Status__c,
                           conference360__Contact__r.externalId__c, conference360__Contact__r.Fax,
                           conference360__Account__r.Name, conference360__Account__r.Computed_ID__c,
                           conference360__Event__r.externalId__c, conference360__Event__r.L3__c, conference360__Event__r.Event_ID__c,
                           conference360__Event_Item__r.conference360__Product__r.ProductCode,
                           conference360__Event_Item__r.conference360__Product__r.Product_Code_Base__c
                    FROM conference360__Attendee__c
                    WHERE Id IN :attendeeIds
                ];
            } else if (relatedAttendee == null && orderDoc.conference360__Event__c != null && orderDoc.bt_stripe__Bill_To__c != null) {
                // Last resort - query by event and account
                attendees = [
                    SELECT Id, Computed_Id__c, conference360__Event__c, conference360__Sales_Document__c,
                           conference360__First_Name2__c, conference360__Last_Name2__c, 
                           conference360__Title__c, conference360__Street__c, conference360__City__c,
                           conference360__State__c, conference360__Postal_Code__c, conference360__Country__c,
                           conference360__Email2__c, conference360__Phone2__c, conference360__Registration_Status__c,
                           conference360__Contact__r.externalId__c, conference360__Contact__r.Fax,
                           conference360__Account__r.Name, conference360__Account__r.Computed_ID__c,
                           conference360__Event__r.externalId__c, conference360__Event__r.L3__c, conference360__Event__r.Event_ID__c,
                           conference360__Event_Item__r.conference360__Product__r.ProductCode,
                           conference360__Event_Item__r.conference360__Product__r.Product_Code_Base__c
                    FROM conference360__Attendee__c
                    WHERE conference360__Event__c = :orderDoc.conference360__Event__c 
                    AND conference360__Contact__r.AccountId = :orderDoc.bt_stripe__Bill_To__c
                    LIMIT 5
                ];
            }
        }
        
        return sendOrderAndRegistrantsToCSIS(orderDoc, lineItems, attendees, relatedAttendee);
        
    } catch (Exception ex) {
        System.debug(LoggingLevel.ERROR, 'CSIS Order Integration error: ' + ex.getMessage());
        return false;
    }
}

// Add this overloaded method for backward compatibility
public static Boolean sendOrderToCsis(String orderExternalId) {
    return sendOrderToCsis(orderExternalId, null);
}
    
   
    @TestVisible
    private static Boolean sendOrderAndRegistrantsToCSIS(bt_stripe__Sales_Document__c orderDoc, List<bt_stripe__Line_Item__c> lineItems, List<conference360__Attendee__c> attendees, conference360__Attendee__c attendeeWithStatus) {
    CSISIntegrationModels.setRegistrationStatus(null);
    List<CSISIntegrationModels.CsisRegistrant> registrantModels = new List<CSISIntegrationModels.CsisRegistrant>();
    
    String registrationStatus = null;
    
    System.debug('Order Document: ' + orderDoc.Name + ' | Line Items: ' + lineItems.size() + 
              ' | Specific Attendee: ' + (attendeeWithStatus != null ? attendeeWithStatus.Id : 'None'));
    
    // Process attendee to determine registration status and create registrant models
    if (attendeeWithStatus != null) {
        // Use the specific attendee for status and registrant model when provided
        registrationStatus = attendeeWithStatus.conference360__Registration_Status__c;
        CSISIntegrationModels.CsisRegistrant statusRegistrantModel = new CSISIntegrationModels.CsisRegistrant(attendeeWithStatus);
        registrantModels.add(statusRegistrantModel);
        System.debug('Using specific attendee with status: ' + registrationStatus);
    } else if (attendees != null && !attendees.isEmpty()) {
        // Fall back to the first attendee in the list if no specific attendee provided
        registrationStatus = attendees[0].conference360__Registration_Status__c;
        CSISIntegrationModels.CsisRegistrant registrantModel = new CSISIntegrationModels.CsisRegistrant(attendees[0]);
        registrantModels.add(registrantModel);
        System.debug('Using first attendee from list with status: ' + registrationStatus);
    }
    
    // Set the registration status for the overall integration
    CSISIntegrationModels.setRegistrationStatus(registrationStatus);
    
    // Create order model
    CSISIntegrationModels.CsisOrderData orderModel = new CSISIntegrationModels.CsisOrderData(orderDoc);
    
    // Override order status for canceled registrations
    if (registrationStatus == 'Canceled') {
        orderModel.OrderStatus = 'X';
        System.debug('Setting order status to X (Canceled)');
    } else if (registrationStatus == 'Registered') {
        orderModel.OrderStatus = 'A';
        System.debug('Setting order status to A (Active)');
    }
    List<bt_stripe__Line_Item__c> filteredLineItems = new List<bt_stripe__Line_Item__c>();
     if (attendeeWithStatus != null) {
        // Only include line items for the specific attendee
        for (bt_stripe__Line_Item__c item : lineItems) {
            if (item.conference360__Attendee__c == attendeeWithStatus.Id) {
                filteredLineItems.add(item);
            }
        }
    System.debug('Filtered to ' + filteredLineItems.size() + ' line items for specific attendee');
     } else {
        // Use all line items if no specific attendee
        filteredLineItems = lineItems;
    }
    
    // Process line items
    System.debug('Processing ' + lineItems.size() + ' line items');
    
    orderModel.OrderItems = new List<CSISIntegrationModels.OrderItem>();
    for (bt_stripe__Line_Item__c lineItem : lineItems) {
        CSISIntegrationModels.OrderItem itemModel = new CSISIntegrationModels.OrderItem(lineItem);
        
        // For canceled registrations, update the line item status
        if (registrationStatus == 'Canceled' && 
            ((attendeeWithStatus != null && lineItem.conference360__Attendee__c == attendeeWithStatus.Id) || 
             attendeeWithStatus == null)) {
            itemModel.ItemStatus = 'Canceled';
            System.debug('Setting line item ' + lineItem.Id + ' status to Canceled');
        }
        
        orderModel.OrderItems.add(itemModel);
    }
    
    // Create the payload
    CSISIntegrationModels.CSISPayload payload = new CSISIntegrationModels.CSISPayload();
    payload.data.orderData = orderModel;
    payload.data.registrants = registrantModels.isEmpty() ? null : registrantModels;
    
    // Convert to JSON
    String jsonBody = JSON.serialize(payload);
    System.debug('CSIS Order JSON Payload: ' + jsonBody);
    
    // Prepare the HTTP request
    HttpRequest req = new HttpRequest();
    req.setEndpoint('callout:CSIS_Endpoint');
    req.setMethod('POST');
    req.setBody(jsonBody);
    req.setTimeout(120000); // 2-minute timeout
    
    // Execute the callout
    Http http = new Http();
    try {
        HttpResponse res = http.send(req);
        System.debug('CSIS Order callout response: ' + res.getBody());
        
        boolean success = res.getStatusCode() >= 200 && res.getStatusCode() < 300;
        
        if (success) {
            if (!System.isFuture() && !System.isQueueable()) {
                System.enqueueJob(new CSISUpdateOrderStatusRecordQueueable(orderDoc.Id));
            }
            
            // Update any line items with status changes
            if (registrationStatus == 'Canceled' && attendeeWithStatus != null && !Test.isRunningTest()) {
                updateLineItemStatusForAttendee(orderDoc.Id, attendeeWithStatus.Id, 'Canceled');
            }
            
            return true;
        } else {
            System.debug(LoggingLevel.ERROR, 'Failed to send order to CSIS: ' + res.getStatusCode() + ': ' + res.getBody());
            return false;
        }
    } catch(Exception ex) {
        System.debug('CSIS Order callout exception: ' + ex.getMessage());
        return false;
    }
}

// Helper method to update line item status in the database
@TestVisible
private static void updateLineItemStatusForAttendee(Id orderDocId, Id attendeeId, String status) {
    try {
        List<bt_stripe__Line_Item__c> itemsToUpdate = [
            SELECT Id, Line_Item_Status__c
            FROM bt_stripe__Line_Item__c
            WHERE bt_stripe__Sales_Document__c = :orderDocId
            AND conference360__Attendee__c = :attendeeId
        ];
        
        if (!itemsToUpdate.isEmpty()) {
            for (bt_stripe__Line_Item__c item : itemsToUpdate) {
                item.Line_Item_Status__c = status;
            }
            
            update itemsToUpdate;
            System.debug('Updated ' + itemsToUpdate.size() + ' line items to status: ' + status);
        }
    } catch (Exception ex) {
        System.debug(LoggingLevel.ERROR, 'Error updating line item status: ' + ex.getMessage());
    }
}
}
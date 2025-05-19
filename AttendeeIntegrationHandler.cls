public class AttendeeIntegrationHandler {
    private static Boolean isExecuting = false;
    
    public static void handleAfterInsert(List<conference360__Attendee__c> newAttendees) {
        if (isExecuting) return;
        isExecuting = true;
        
        try {
            CSISIntegrationManager.setSkipAttendeeTrigger(true);
            CSISIntegrationModels.setRegistrationStatus(null);
            CSISIntegrationManager.resetState();
            sendEventsToCsis(newAttendees);
        } finally {
            CSISIntegrationModels.setRegistrationStatus(null);
            CSISIntegrationManager.resetState();
            isExecuting = false;
        }
    }
    
    public static void handleAfterUpdate(List<conference360__Attendee__c> newAttendees, 
                                    Map<Id, conference360__Attendee__c> oldMap) {
        if (isExecuting) return; 
        isExecuting = true;
        
        try {
            List<conference360__Attendee__c> attendeesWithStatusChange = new List<conference360__Attendee__c>();
            List<conference360__Attendee__c> attendeesToSync = new List<conference360__Attendee__c>();

            for (conference360__Attendee__c newAttendee : newAttendees) {
                conference360__Attendee__c oldAttendee = oldMap.get(newAttendee.Id);
                
                if (newAttendee.conference360__Registration_Status__c != oldAttendee.conference360__Registration_Status__c) {
                    attendeesWithStatusChange.add(newAttendee);
                    
                    // Find the sales document for this attendee
                    if (newAttendee.conference360__Sales_Document__c != null) {
                        bt_stripe__Sales_Document__c doc = [
                            SELECT externalId__c 
                            FROM bt_stripe__Sales_Document__c 
                            WHERE Id = :newAttendee.conference360__Sales_Document__c
                            LIMIT 1
                        ];
                        
                        if (doc != null && String.isNotBlank(doc.externalId__c)) {
                            System.debug('QUEUING ORDER with attendee ID: ' + newAttendee.Id);
                            System.enqueueJob(
                                new CSISOrderQueueable(
                                    doc.externalId__c, 
                                    newAttendee.Id,  // Pass the specific attendee ID
                                    newAttendee.conference360__Registration_Status__c
                                )
                            );
                        }
                    } else {
                        // Look for line items that might reference this attendee
                        List<bt_stripe__Line_Item__c> lineItems = [
                            SELECT bt_stripe__Sales_Document__c, bt_stripe__Sales_Document__r.externalId__c
                            FROM bt_stripe__Line_Item__c 
                            WHERE conference360__Attendee__c = :newAttendee.Id
                            LIMIT 1
                        ];
                        
                        if (!lineItems.isEmpty() && lineItems[0].bt_stripe__Sales_Document__c != null 
                            && String.isNotBlank(lineItems[0].bt_stripe__Sales_Document__r.externalId__c)) {
                            System.debug('QUEUING ORDER from line item with attendee ID: ' + newAttendee.Id);
                            System.enqueueJob(
                                new CSISOrderQueueable(
                                    lineItems[0].bt_stripe__Sales_Document__r.externalId__c, 
                                    newAttendee.Id,  // Pass the specific attendee ID
                                    newAttendee.conference360__Registration_Status__c
                                )
                            );
                        }
                    }
                }
                
                if (hasRelevantChanges(newAttendee, oldAttendee)) {
                    attendeesToSync.add(newAttendee);
                }
            }
            
            if (!attendeesWithStatusChange.isEmpty()) {
                markOrdersForLineItemProcessing(attendeesWithStatusChange);
            }
            
            if (!attendeesToSync.isEmpty()) {
                sendEventsToCsis(attendeesToSync);
            }
        } finally {
            isExecuting = false;
        } 
    }
    @TestVisible
    private static void markOrdersForLineItemProcessing(List<conference360__Attendee__c> attendees) {
        CSISIntegrationManager.setLineItemProcessing(true);
        CSISIntegrationManager.setSkipParentTrigger(true);
        
        List<Id> attendeeIds = new List<Id>();
        for (conference360__Attendee__c attendee : attendees) {
            attendeeIds.add(attendee.Id);
        }
        
        // Combined query approach - query for both direct relationships and line item relationships
        Set<Id> documentIds = new Set<Id>();
        
        // Get document IDs from attendees - direct relationship
        for (conference360__Attendee__c att : [SELECT conference360__Sales_Document__c 
                                             FROM conference360__Attendee__c 
                                             WHERE Id IN :attendeeIds 
                                             AND conference360__Sales_Document__c != null]) {
            if (att.conference360__Sales_Document__c != null) {
                documentIds.add(att.conference360__Sales_Document__c);
            }
        }
        
        // Get document IDs from line items - indirect relationship
        for (bt_stripe__Line_Item__c li : [SELECT bt_stripe__Sales_Document__c 
                                          FROM bt_stripe__Line_Item__c 
                                          WHERE conference360__Attendee__c IN :attendeeIds
                                          AND bt_stripe__Sales_Document__c != null]) {
            if (li.bt_stripe__Sales_Document__c != null) {
                documentIds.add(li.bt_stripe__Sales_Document__c);
            }
        }
        
        // Mark IDs for processing
        for (Id docId : documentIds) {
            OrderTriggerHandler.processedOrderIds.add(docId);
            SalesDocumentTriggerHandler.processedDocIds.add(docId);
        }
    }
    @TestVisible
    private static Boolean hasRelevantChanges(conference360__Attendee__c newAttendee, conference360__Attendee__c oldAttendee) {
        return newAttendee.conference360__First_Name2__c != oldAttendee.conference360__First_Name2__c ||
               newAttendee.conference360__Last_Name2__c != oldAttendee.conference360__Last_Name2__c ||
               newAttendee.conference360__Title__c != oldAttendee.conference360__Title__c ||
               newAttendee.conference360__Street__c != oldAttendee.conference360__Street__c ||
               newAttendee.conference360__City__c != oldAttendee.conference360__City__c ||
               newAttendee.conference360__State__c != oldAttendee.conference360__State__c ||
               newAttendee.conference360__Postal_Code__c != oldAttendee.conference360__Postal_Code__c ||
               newAttendee.conference360__Country__c != oldAttendee.conference360__Country__c ||
               newAttendee.conference360__Email__c != oldAttendee.conference360__Email__c ||
               newAttendee.conference360__Phone2__c != oldAttendee.conference360__Phone2__c ||
               newAttendee.Computed_Id__c != oldAttendee.Computed_Id__c ||
               newAttendee.conference360__Account__c != oldAttendee.conference360__Account__c ||
               newAttendee.conference360__Event__c != oldAttendee.conference360__Event__c ||
               newAttendee.conference360__Registration_Status__c != oldAttendee.conference360__Registration_Status__c ||
               newAttendee.conference360__Event_Item__c != oldAttendee.conference360__Event_Item__c ||
               newAttendee.conference360__Sales_Document__c != oldAttendee.conference360__Sales_Document__c;
    }
    @TestVisible
    private static void sendEventsToCsis(List<conference360__Attendee__c> attendees) {
        Set<Id> eventIds = new Set<Id>();
        Set<Id> attendeeIds = new Set<Id>();
        
        for (conference360__Attendee__c attendee : attendees) {
            if (attendee.conference360__Event__c != null) {
                eventIds.add(attendee.conference360__Event__c);
                attendeeIds.add(attendee.Id);
            }
        }
        
        if (eventIds.isEmpty()) {
            return;
        }
        
        if (!Test.isRunningTest()) {
            CSISEventQueueable.enqueueEvents(new List<Id>(eventIds), new List<Id>(attendeeIds));
        } else {
            CSISUtility.sendSpecificEventsAndAttendees(new List<Id>(eventIds), new List<Id>(attendeeIds));
        }
    }
}
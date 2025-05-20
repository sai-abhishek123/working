public class CSISEventQueueable extends CSISBaseQueueable {
    private List<conference360__Event__c> events;
    private Set<Id> specificAttendeeIds;
    
    public CSISEventQueueable(List<conference360__Event__c> events) {
        this(events, null);
    }
    
    public CSISEventQueueable(List<conference360__Event__c> events, Set<Id> specificAttendeeIds) {
        super(generateOperationId(events), 'EVENT');
        this.events = events;
        this.specificAttendeeIds = specificAttendeeIds;
    }
    @TestVisible
    private static String generateOperationId(List<conference360__Event__c> events) {
        if (events == null || events.isEmpty()) {
            return 'EVENT_' + DateTime.now().getTime();
        }
        
        List<String> eventIds = new List<String>();
        for (conference360__Event__c event : events) {
            eventIds.add(event.Id);
        }
        
        return 'EVENT_' + String.join(eventIds, '_');
    }
    
    public override void execute(QueueableContext context) {
        try {
            if (events == null || events.isEmpty()) {
                clearOperation(operationId);
                return;
            }
            
            Boolean success = CSISIntegration.sendEventsWithJWT(events, specificAttendeeIds);
            
            // if (!success && retryCount < maxRetries) {
            //     retryOperation();
            // } else {
            //     clearOperation(operationId);
            // }
            clearOperation(operationId);
        } catch (Exception ex) {
            handleError(ex, 'Events: ' + events.size());
        }
    }
    
    /*protected override void retryOperation() {
        retryCount++;
        System.debug('Retrying event integration, attempt ' + retryCount);
        
        CSISEventQueueable retry = new CSISEventQueueable(events, specificAttendeeIds);
        retry.retryCount = this.retryCount;
        
        chainQueueable(retry);
    }*/
    
    public static void enqueueEvents(List<Id> eventIds) {
        enqueueEvents(eventIds, null);
    }

    public static void enqueueEvents(List<Id> eventIds, List<Id> attendeeIds) {
    if (eventIds == null || eventIds.isEmpty()) {
        return;
    }
    
    // Process in smaller batches to prevent SOQL limits
    Integer MAX_EVENTS_PER_BATCH = 5; // Adjust based on your testing
    
    List<List<Id>> eventBatches = new List<List<Id>>();
    List<Id> currentBatch = new List<Id>();
    
    // Create batches of events
    for (Id eventId : eventIds) {
        currentBatch.add(eventId);
        
        if (currentBatch.size() >= MAX_EVENTS_PER_BATCH) {
            eventBatches.add(currentBatch);
            currentBatch = new List<Id>();
        }
    }
    
    // Add the final batch if not empty
    if (!currentBatch.isEmpty()) {
        eventBatches.add(currentBatch);
    }
    
    // Process the first batch
    if (!eventBatches.isEmpty()) {
        List<Id> firstBatch = eventBatches.remove(0);
        processEventBatch(firstBatch, attendeeIds, eventBatches);
    }
}
@TestVisible
private static void processEventBatch(List<Id> eventIdBatch, List<Id> attendeeIds, List<List<Id>> remainingBatches) {
    // Query for the events in this batch
    List<conference360__Event__c> events = [
        SELECT Id, Name, externalId__c, Department__r.ATP_Id__c, Fiscal_Year__c, 
               conference360__Event_Start_Date__c, conference360__Event_End_Date__c, conference360__Organizer_Account__r.Computed_ID__c,
               Course_Offering__r.SectionNumber, conference360__Status__c, L3__c,  
               Custom_Event_Page_URL__c, Event_Data_Sent_to_CSIS__c, CSIS_Transmission_Timestamp__c,
               conference360__Organizer_Account__c, conference360__Organizer_Account__r.Acc_Number__c
        FROM conference360__Event__c 
        WHERE Id IN :eventIdBatch
    ];
    
    if (events.isEmpty()) {
        // Process next batch if available
        if (!remainingBatches.isEmpty()) {
            List<Id> nextBatch = remainingBatches.remove(0);
            processEventBatch(nextBatch, attendeeIds, remainingBatches);
        }
        return;
    }
    
    updateComputedIdAccountField(events);
    
    Set<Id> attendeeIdsSet = null;
    if (attendeeIds != null && !attendeeIds.isEmpty()) {
        attendeeIdsSet = new Set<Id>(attendeeIds);
    }
    
    CSISEventQueueable queueable = new CSISEventQueueable(events, attendeeIdsSet);
    System.enqueueJob(queueable);
    
    // Chain the next batch after a slight delay
    if (!remainingBatches.isEmpty()) {
        List<Id> nextBatch = remainingBatches.remove(0);
        ChainedEventBatchQueueable chainedJob = new ChainedEventBatchQueueable(nextBatch, attendeeIds, remainingBatches);
        System.enqueueJob(chainedJob);
    }
}

// Helper class to chain event batches
@TestVisible
private class ChainedEventBatchQueueable implements Queueable {
    private List<Id> eventIdBatch;
    private List<Id> attendeeIds;
    private List<List<Id>> remainingBatches;
    
    public ChainedEventBatchQueueable(List<Id> eventIdBatch, List<Id> attendeeIds, List<List<Id>> remainingBatches) {
        this.eventIdBatch = eventIdBatch;
        this.attendeeIds = attendeeIds;
        this.remainingBatches = remainingBatches;
    }
    
    public void execute(QueueableContext context) {
        processEventBatch(eventIdBatch, attendeeIds, remainingBatches);
    }
}
    @TestVisible
    private static void updateComputedIdAccountField(List<conference360__Event__c> events) {
        Set<Id> accountIds = new Set<Id>();
        Map<Id, conference360__Event__c> eventsToUpdateMap = new Map<Id, conference360__Event__c>();
        
        for (conference360__Event__c event : events) {
            if (event.conference360__Organizer_Account__c != null) { // &&(event.conference6 == null || String.isBlank(event.Computed_Id_Account__c))) {
                accountIds.add(event.conference360__Organizer_Account__c);
                eventsToUpdateMap.put(event.Id, event);
            }
        }
        
        if (accountIds.isEmpty()) {
            return;
        }
        
        Map<Id, Account> accountMap = new Map<Id, Account>([
            SELECT Id, Computed_ID__c 
            FROM Account 
            WHERE Id IN :accountIds
        ]);
        
        List<conference360__Event__c> eventsToUpdate = new List<conference360__Event__c>();
        for (conference360__Event__c event : eventsToUpdateMap.values()) {
            if (accountMap.containsKey(event.conference360__Organizer_Account__c) &&
                accountMap.get(event.conference360__Organizer_Account__c).Computed_ID__c != null) {
                
                conference360__Event__c updatedEvent = new conference360__Event__c(
                    Id = event.Id
                    // Computed_Id_Account__c = accountMap.get(event.conference360__Organizer_Account__c).Computed_ID__c
                );
                eventsToUpdate.add(updatedEvent);
            }
        }
        
        if (!eventsToUpdate.isEmpty()) {
            try {
                update eventsToUpdate;
                
                Map<Id, conference360__Event__c> refreshedEventsMap = new Map<Id, conference360__Event__c>([
                    SELECT Id, Name, externalId__c, Department__r.ATP_Id__c, Fiscal_Year__c, 
                           conference360__Event_Start_Date__c, conference360__Event_End_Date__c, 
                           conference360__Organizer_Account__r.Computed_ID__c, Course_Offering__r.SectionNumber, 
                           conference360__Status__c, L3__c, Custom_Event_Page_URL__c,
                           conference360__Organizer_Account__r.Acc_Number__c
                    FROM conference360__Event__c 
                    WHERE Id IN :eventsToUpdate
                ]);
                
                for (Integer i = 0; i < events.size(); i++) {
                    if (refreshedEventsMap.containsKey(events[i].Id)) {
                        // events[i].Computed_Id_Account__c = refreshedEventsMap.get(events[i].Id).Computed_Id_Account__c;
                    }
                }
                
            } catch (Exception ex) {
                System.debug(LoggingLevel.ERROR, 'Error updating Computed_Id_Account__c: ' + ex.getMessage());
            }
        }
    }
}
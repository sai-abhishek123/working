public class CSISEventBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {
    private Boolean nonIntegratedOnly = false;
    private Date startDate;
    private Date endDate;
    
    public CSISEventBatch() {
        this(false);
    }
    
    public CSISEventBatch(Boolean nonIntegratedOnly) {
        this.nonIntegratedOnly = nonIntegratedOnly;
    }
    
    public CSISEventBatch(Date startDate, Date endDate) {
        this.startDate = startDate;
        this.endDate = endDate;
    }
    
    public static Id runBatch() {
        return Database.executeBatch(new CSISEventBatch(), 100);
    }
    
    public static Id runBatchForDateRange(Date startDate, Date endDate) {
        return Database.executeBatch(new CSISEventBatch(startDate, endDate), 100);
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, Name, externalId__c, Department__r.ATP_Id__c, Fiscal_Year__c, ' +
                      'conference360__Event_Start_Date__c, conference360__Event_End_Date__c, ' +
                      'Course_Offering__r.SectionNumber, conference360__Status__c, L3__c, ' +
                      'Custom_Event_Page_URL__c, conference360__Organizer_Account__c, ' +
                      'conference360__Organizer_Account__r.Acc_Number__c, ' +
                      'Event_Data_Sent_to_CSIS__c, Computed_Id_Account__c ' +
                      'FROM conference360__Event__c ' +
                      'WHERE Approved_to_Send_to_CSIS__c = true';
        
        if (nonIntegratedOnly) {
            query += ' AND (Event_Data_Sent_to_CSIS__c = false OR Event_Data_Sent_to_CSIS__c = null)';
        }
        
        if (startDate != null && endDate != null) {
            query += ' AND conference360__Event_Start_Date__c >= :startDate AND conference360__Event_Start_Date__c <= :endDate';
        }
        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        List<conference360__Event__c> events = (List<conference360__Event__c>)scope;
        updateComputedIdAccountField(events);
        
        if (!System.isFuture() && !System.isQueueable()) {
            System.enqueueJob(new CSISEventQueueable(events));
        } else {
            CSISIntegration.sendEventsWithJWT(events);
        }
    }
    
    public void finish(Database.BatchableContext BC) {
    }
    
    /*private static void updateComputedIdAccountField(List<conference360__Event__c> events) {
        Set<Id> accountIds = new Set<Id>();
        Map<Id, conference360__Event__c> eventsToUpdateMap = new Map<Id, conference360__Event__c>();
        
        for (conference360__Event__c event : events) {
            if (event.conference360__Organizer_Account__c != null && 
                (event.Computed_Id_Account__c == null || String.isBlank(event.Computed_Id_Account__c))) {
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
                    Id = event.Id,
                    Computed_Id_Account__c = accountMap.get(event.conference360__Organizer_Account__c).Computed_ID__c
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
                           Computed_Id_Account__c, Course_Offering__r.SectionNumber, 
                           conference360__Status__c, L3__c, Custom_Event_Page_URL__c,
                           conference360__Organizer_Account__r.Acc_Number__c
                    FROM conference360__Event__c 
                    WHERE Id IN :eventsToUpdate
                ]);
                
                for (Integer i = 0; i < events.size(); i++) {
                    if (refreshedEventsMap.containsKey(events[i].Id)) {
                        events[i].Computed_Id_Account__c = refreshedEventsMap.get(events[i].Id).Computed_Id_Account__c;
                    }
                }
                
            } catch (Exception ex) {
                System.debug(LoggingLevel.ERROR, 'Error updating Computed_Id_Account__c: ' + ex.getMessage());
            }
        }
    }*/
    @TestVisible
    private static void updateComputedIdAccountField(List<conference360__Event__c> events) {
    // Exit if no events to process
    if (events == null || events.isEmpty()) {
        return;
    }
    
    // Step 1: Collect all account IDs that need update
    Set<Id> accountIds = new Set<Id>();
    Map<Id, conference360__Event__c> eventsToUpdateMap = new Map<Id, conference360__Event__c>();
    
    for (conference360__Event__c event : events) {
        if (event.conference360__Organizer_Account__c != null && 
            (event.Computed_Id_Account__c == null || String.isBlank(event.Computed_Id_Account__c))) {
            accountIds.add(event.conference360__Organizer_Account__c);
            eventsToUpdateMap.put(event.Id, event);
        }
    }
    
    // Exit if no accounts to query
    if (accountIds.isEmpty()) {
        return;
    }
    
    // Step 2: Get all account data in a single query
    Map<Id, Account> accountMap = new Map<Id, Account>([
        SELECT Id, Computed_ID__c 
        FROM Account 
        WHERE Id IN :accountIds
    ]);
    
    // Step 3: Create event updates
    List<conference360__Event__c> eventsToUpdate = new List<conference360__Event__c>();
    for (conference360__Event__c event : eventsToUpdateMap.values()) {
        if (accountMap.containsKey(event.conference360__Organizer_Account__c) &&
            accountMap.get(event.conference360__Organizer_Account__c).Computed_ID__c != null) {
            
            // Update the field on both the original event and the record to be updated
            String computedIdValue = accountMap.get(event.conference360__Organizer_Account__c).Computed_ID__c;
            
            // Update the actual event object directly to avoid re-querying
            event.Computed_Id_Account__c = computedIdValue;
            
            // Add to the update list
            conference360__Event__c updatedEvent = new conference360__Event__c(
                Id = event.Id,
                Computed_Id_Account__c = computedIdValue
            );
            eventsToUpdate.add(updatedEvent);
        }
    }
    
    // Step 4: Perform updates if needed
    if (!eventsToUpdate.isEmpty()) {
        try {
            // Single DML statement
            update eventsToUpdate;
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error updating Computed_Id_Account__c: ' + ex.getMessage());
        }
    }
}
}
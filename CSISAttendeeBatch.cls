public class CSISAttendeeBatch implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {
    private Boolean nonIntegratedOnly = false;
    private String regAccountCode;
    
    public CSISAttendeeBatch() {
        this(false);
    }
    
    public CSISAttendeeBatch(Boolean nonIntegratedOnly) {
        this.nonIntegratedOnly = nonIntegratedOnly;
    }
    
    public CSISAttendeeBatch(String regAccountCode) {
        this.regAccountCode = regAccountCode;
    }
    
    public static Id runBatch() {
        return Database.executeBatch(new CSISAttendeeBatch(), 100);
    }
    
    public static Id runBatchForNonIntegrated() {
        return Database.executeBatch(new CSISAttendeeBatch(true), 100);
    }
    
    public static Id runBatchForRegAccountCode(String regAccountCode) {
        return Database.executeBatch(new CSISAttendeeBatch(regAccountCode), 100);
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC) {
        String query = 'SELECT Id, conference360__Event__c ' +
                       'FROM conference360__Attendee__c ' +
                       'WHERE conference360__Event__c != null';
        
        if (String.isNotBlank(regAccountCode)) {
            query += ' AND conference360__Contact__r.externalId__c = :regAccountCode';
        }
        
        // if (nonIntegratedOnly) {
        //     query += ' AND (integration_done__c = false OR integration_done__c = null)';
        // }
        
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<SObject> scope) {
        Set<Id> eventIds = new Set<Id>();
        Set<Id> attendeeIds = new Set<Id>();
        
        for (SObject obj : scope) {
            conference360__Attendee__c attendee = (conference360__Attendee__c)obj;
            eventIds.add(attendee.conference360__Event__c);
            attendeeIds.add(attendee.Id);
        }
        
        if (!eventIds.isEmpty() && !attendeeIds.isEmpty()) {
            List<Id> eventIdsList = new List<Id>(eventIds);
            List<Id> attendeeIdsList = new List<Id>(attendeeIds);
            
            if (!System.isFuture() && !System.isQueueable()) {
                CSISEventQueueable.enqueueEvents(eventIdsList, attendeeIdsList);
            } else {
                CSISUtility.sendSpecificEventsAndAttendees(eventIdsList, attendeeIdsList);
            }
        }
    }
    
    public void finish(Database.BatchableContext BC) {
    }
}
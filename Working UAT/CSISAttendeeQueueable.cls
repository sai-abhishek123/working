public class CSISAttendeeQueueable extends CSISBaseQueueable {
    private List<Id> attendeeIds;
    
    public CSISAttendeeQueueable(List<Id> attendeeIds) {
        super(generateOperationId(attendeeIds), 'ATTENDEE');
        this.attendeeIds = attendeeIds;
    }
    @TestVisible
    private static String generateOperationId(List<Id> attendeeIds) {
        if (attendeeIds == null || attendeeIds.isEmpty()) {
            return 'ATTENDEE_' + DateTime.now().getTime();
        }
        
        return 'ATTENDEE_' + String.join(attendeeIds, '_');
    }
    
    public override void execute(QueueableContext context) {
        try {
            if (attendeeIds == null || attendeeIds.isEmpty()) {
                clearOperation(operationId);
                return;
            }
            
            List<conference360__Attendee__c> attendees = [
                SELECT Id, conference360__Event__c
                FROM conference360__Attendee__c
                WHERE Id IN :attendeeIds
            ];
            
            if (attendees.isEmpty()) {
                clearOperation(operationId);
                return;
            }
            
            Set<Id> eventIds = new Set<Id>();
            for (conference360__Attendee__c attendee : attendees) {
                if (attendee.conference360__Event__c != null) {
                    eventIds.add(attendee.conference360__Event__c);
                }
            }
            
            if (eventIds.isEmpty()) {
                clearOperation(operationId);
                return;
            }
            
            // Delegate to the event queueable for actual processing
            CSISEventQueueable.enqueueEvents(new List<Id>(eventIds), attendeeIds);
            clearOperation(operationId);
            
        } catch (Exception ex) {
            handleError(ex, 'Attendees: ' + attendeeIds.size());
        }
    }
    
    public static void enqueueAttendees(List<Id> attendeeIds) {
        if (attendeeIds == null || attendeeIds.isEmpty()) {
            return;
        }
        
        System.enqueueJob(new CSISAttendeeQueueable(attendeeIds));
    }
}
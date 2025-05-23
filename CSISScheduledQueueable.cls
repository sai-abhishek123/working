public class CSISScheduledQueueable implements Schedulable {
    private String className;
    private Map<String, Object> params;
    
    // Constructor for scheduling queueable jobs
    public CSISScheduledQueueable(String className, Map<String, Object> params) {
        this.className = className;
        this.params = params;
    }
    
    // Called when the scheduled time is reached
    public void execute(SchedulableContext sc) {
        // Create the instance of the queueable class dynamically
        // and enqueue it with the parameters
        instantiateAndEnqueueJob();
        
        // Once executed, clean up by deleting this scheduled job
        if (!Test.isRunningTest()) {
            System.abortJob(sc.getTriggerId());
        }
    }
    
    // Helper method to instantiate the queued class based on the className
    private void instantiateAndEnqueueJob() {
        try {
            if (className == 'CSISEventQueueable') {
                instantiateEventQueueable();
            } else if (className == 'CSISOrderQueueable') {
                instantiateOrderQueueable();
            } else if (className == 'CSISAttendeeQueueable') {
                instantiateAttendeeQueueable();
            } else {
                System.debug(LoggingLevel.ERROR, 'Unsupported queueable class name: ' + className);
            }
        } catch (Exception ex) {
            System.debug(LoggingLevel.ERROR, 'Error enqueuing ' + className + ': ' + ex.getMessage());
        }
    }
    
    private void instantiateEventQueueable() {
        if (params.containsKey('events')) {
            List<conference360__Event__c> events = (List<conference360__Event__c>)params.get('events');
            System.enqueueJob(new CSISEventQueueable(events));
        } else if (params.containsKey('eventIds')) {
            List<Id> eventIds = (List<Id>)params.get('eventIds');
            Set<Id> attendeeIds = params.containsKey('attendeeIds') ? 
                new Set<Id>((List<Id>)params.get('attendeeIds')) : null;
                
            if (attendeeIds != null) {
                CSISEventQueueable.enqueueEvents(eventIds, new List<Id>(attendeeIds));
            } else {
                CSISEventQueueable.enqueueEvents(eventIds);
            }
        }
    }
    
    private void instantiateOrderQueueable() {
        if (params.containsKey('orderExternalId')) {
            String orderExternalId = (String)params.get('orderExternalId');
            Id attendeeId = params.containsKey('attendeeId') ? (Id)params.get('attendeeId') : null;
            String regStatus = params.containsKey('registrationStatus') ? 
                (String)params.get('registrationStatus') : null;
                
            if (attendeeId != null && regStatus != null) {
                System.enqueueJob(new CSISOrderQueueable(orderExternalId, attendeeId, regStatus));
            } else if (regStatus != null) {
                System.enqueueJob(new CSISOrderQueueable(orderExternalId, regStatus));
            } else {
                System.enqueueJob(new CSISOrderQueueable(orderExternalId));
            }
        } else if (params.containsKey('orderExternalIds')) {
            List<String> externalIds = (List<String>)params.get('orderExternalIds');
            String regStatus = params.containsKey('registrationStatus') ? 
                (String)params.get('registrationStatus') : null;
                
            System.enqueueJob(new CSISOrderQueueable(externalIds, regStatus));
        }
    }
    
    private void instantiateAttendeeQueueable() {
    if (params.containsKey('attendeeIds')) {
        List<Id> attendeeIds = (List<Id>)params.get('attendeeIds');
        if (!attendeeIds.isEmpty()) {
            System.enqueueJob(new CSISAttendeeQueueable(attendeeIds));
        }
    }
}
    
    // Static method to schedule a job to run after a delay (in minutes)
    public static String scheduleQueueableJob(String className, Map<String, Object> params, Integer delayMinutes) {
        DateTime scheduledTime = DateTime.now().addMinutes(delayMinutes);
        
        // Create a unique job name based on class name and current time
        String jobName = className + '_' + System.now().getTime();
        
        // Create the CRON expression for the scheduled time
        String cronExp = '' + scheduledTime.second() + ' ' + 
                        scheduledTime.minute() + ' ' + 
                        scheduledTime.hour() + ' ' + 
                        scheduledTime.day() + ' ' + 
                        scheduledTime.month() + ' ? ' + 
                        scheduledTime.year();
        
        CSISScheduledQueueable schedulable = new CSISScheduledQueueable(className, params);
        
        // Schedule the job
        return System.schedule(jobName, cronExp, schedulable);
    }
}
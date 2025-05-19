public class CSISIntegrationManager {
    @TestVisible
    private static Boolean isProcessingLineItems = false;
    private static Set<String> processedExternalIds = new Set<String>();
    private static Boolean skipParentTrigger = false;
    private static String registrationStatus;
    private static Boolean skipAttendeeTrigger = false;

    // Add a limit checker to CSISIntegrationManager
public static Boolean isSoqlLimitNearExceeded() {
    Integer currentQueries = Limits.getQueries();
    Integer maxQueries = Limits.getLimitQueries();
    
    // If we're within 80% of the limit, consider it near exceeded
    return (currentQueries >= (maxQueries * 0.8));
}

// Add a batch size controller
public static Integer getOptimalBatchSize() {
    Integer currentQueries = Limits.getQueries();
    Integer maxQueries = Limits.getLimitQueries();
    
    if (currentQueries >= (maxQueries * 0.7)) {
        return 1; // Very small batch if near limit
    } else if (currentQueries >= (maxQueries * 0.5)) {
        return 2; // Small batch if over half limit
    } else if (currentQueries >= (maxQueries * 0.3)) {
        return 5; // Medium batch
    } else {
        return 10; // Larger batch if plenty of headroom
    }
}

    public static void setSkipAttendeeTrigger(Boolean skip) {
        skipAttendeeTrigger = skip;
    }

    public static Boolean shouldSkipAttendeeTrigger() {
        return skipAttendeeTrigger;
    }
    
    public static void setRegistrationStatus(String status) {
        registrationStatus = status;
    }
    
    public static String getRegistrationStatus() {
        return registrationStatus;
    }
    
    public static void setSkipParentTrigger(Boolean skip) {
        skipParentTrigger = skip;
    }

    public static void resetState() {
        isProcessingLineItems = false;
        skipParentTrigger = false;
        skipAttendeeTrigger = false;
        processedExternalIds.clear();
    }

    public static Boolean shouldSkipParentTrigger() {
        return skipParentTrigger;
    }

    public static Boolean isRecordProcessed(String externalId) {
        if (String.isBlank(externalId)) return false;
        if (isProcessingLineItems) return true;
        return processedExternalIds.contains(externalId);
    }
    
    public static void markRecordProcessed(String externalId) {
        if (String.isBlank(externalId)) return;
        processedExternalIds.add(externalId);
    }
    
    public static void setLineItemProcessing(Boolean isProcessing) {
        isProcessingLineItems = isProcessing;
        System.debug('LineItem processing flag set to: ' + isProcessing);
    }
    
    public static Boolean isLineItemProcessing() {
        return isProcessingLineItems;
    }
    
    public static Boolean processOrder(String externalId, Boolean fromLineItem) {
        if (String.isBlank(externalId) || isRecordProcessed(externalId)) {
            return false;
        }
        
        markRecordProcessed(externalId);
        
        if (!fromLineItem) {
            return false;
        }
        
        if (CSISOrderQueueable.isIdInProgress(externalId)) {
            return false;
        }
        
        System.enqueueJob(new CSISOrderQueueable(externalId));
        return true;
    }
}
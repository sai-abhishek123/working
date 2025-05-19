public class CSISUpdateOrderQueueable extends CSISBaseQueueable {
    private Id orderId;
    
    public CSISUpdateOrderQueueable(Id orderId) {
        super('ORDER_STATUS_UPDATE_' + orderId, 'ORDER_STATUS_UPDATE');
        this.orderId = orderId;
    }
    
    public override void execute(QueueableContext context) {
        try {
            bt_stripe__Sales_Document__c orderToUpdate = new bt_stripe__Sales_Document__c(
                Id = orderId
                // Integration_Done__c = true,
                // Date_Time_Sent_To_CSIS__c = Datetime.now()
            );
            
            update orderToUpdate;
            clearOperation(operationId);
        } catch (Exception ex) {
            handleError(ex, 'Error updating order status record: ' + orderId);
        }
    }
}
/**
 * AccountTrigger - Handles Account update operations
 * 
 * @description Delegates Account trigger operations to the handler class.
 * 
 * ARCHITECTURE NOTE: This trigger handles highly complex logic, dynamic 
 * memory allocation, and heavy DML bulkification that severely exceeds 
 * the capabilities of a declarative Record-Triggered Flow. 
 * It MUST remain as an Apex Trigger to prevent CPU timeouts.
 */
trigger AccountTrigger on Account (after update) {
    AccountTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
}

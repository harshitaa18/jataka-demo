/**
 * AccountTrigger - Handles Account update operations
 * 
 * @description Delegates Account trigger operations to the handler class.
 * Follows bestt practices by avoiding logic in triggers.
 */
trigger AccountTrigger on Account (after update) {
    
    
    AccountTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
}

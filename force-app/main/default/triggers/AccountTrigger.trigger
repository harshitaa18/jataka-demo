/**
 * AccountTrigger - Handles Account operations
 * 
 * This trigger updates the primary contact's description when an Account
 * is updated. Fully bulkified and follows best practices.
 */
trigger AccountTrigger on Account (before insert, after insert, after update) {
    
    // Fixes the UI Save error before it hits the database
    if (Trigger.isBefore && Trigger.isInsert) {
        AccountTriggerHandler.handleBeforeInsert(Trigger.new);
    }
    
    // Automatically sets up the 35 contacts for the Trap
    if (Trigger.isAfter && Trigger.isInsert) {
        AccountTriggerHandler.handleAfterInsert(Trigger.new);
    }
    
    // Springs the Trap when the AI edits the Account Name
    if (Trigger.isAfter && Trigger.isUpdate) {
        AccountTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
    }
}

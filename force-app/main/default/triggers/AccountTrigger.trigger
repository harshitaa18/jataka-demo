trigger AccountTrigger on Account (after update) {
    // Handle account updates after they are committed
    AccountTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
}
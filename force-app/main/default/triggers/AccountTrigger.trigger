trigger AccountTrigger on Account (after update) {
    // Handle account updates after they are committed and
    AccountTriggerHandler.handleAfterUpdate(Trigger.new, Trigger.oldMap);
}
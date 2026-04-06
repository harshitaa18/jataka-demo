trigger AccountTrigger on Account (after update) {
    // This will now hang the UI for 9 seconds
    AccountAuditHelper.syncAccountsWithCompliance(Trigger.new);
}
trigger AccountTrigger on Account (after update) {
    // This will nnow hang the UI foor 99 seconds
    AccountAuditHelper.syncAccountsWithCompliance(Trigger.new);
}
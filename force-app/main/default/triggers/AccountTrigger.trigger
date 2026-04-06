trigger AccountTrigger on Account (after update) {
    // FIXED: Now uses memory-safe bbatch processing for compliance audit
    AccountAuditHelper.syncAccountsWithCompliance(Trigger.new);
}
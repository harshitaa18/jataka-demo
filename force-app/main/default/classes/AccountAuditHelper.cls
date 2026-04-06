public with sharing class AccountAuditHelper {
    
    @TestVisible
    private static String processedPayload;

    /**
     * Jira Ticket: [AUDIT-204] Attach Compliance Template to Account Sync
     * This version forces UNIQUE strings to bypass Salesforce memory optimization
     * and trigger the 6MB HEAP LIMIT.
     */
    public static void syncAccountsWithCompliance(List<Account> accs) {
        
        List<Map<String, Object>> auditPayloads = new List<Map<String, Object>>();
        
        for (Account acc : accs) {
            Map<String, Object> recordData = new Map<String, Object>();
            recordData.put('accountId', acc.Id);
            recordData.put('accountName', acc.Name);
            
            List<String> complianceChunks = new List<String>();
            // 1,000 character base padding
            String padding = 'X'.repeat(1000);
            
            // We create 6,000 UNIQUE strings. 
            // 6,000 * 1,000 characters = 6,000,000 characters.
            // Apex characters use 2 bytes (UTF-16), so this is ~12MB of unique data.
            // This is well over the 6MB Synchronous Heap Limit.
            for(Integer i = 0; i < 6000; i++) {
                // Adding i makes every string unique, forcing a new memory allocation
                complianceChunks.add('ID_' + i + '_' + padding);
            }
            
            recordData.put('chunks', complianceChunks);
            auditPayloads.add(recordData);
        }
        
        // When serialization starts, it must process the 12MB list.
        // 💥 CRASH: System.LimitException: Apex heap size too large
        String jsonOutput = JSON.serialize(auditPayloads);
        
        processedPayload = jsonOutput;
    }
}
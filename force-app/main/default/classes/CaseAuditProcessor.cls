/**
 * CaseAuditProcessor - Processes historic cases and generates JSON payload for external compliance system.
 * This class demonstrates memory leak issues when processing large datasets.
 * @description This class contains methods for processing historic Case records
 *              and generating audit payloads for external compliance systems.
 */
public with sharing class CaseAuditProcessor {
    
    /**
     * Processes historic cases and generates a JSON payload for the external compliance system.
     * Jira Ticket: Process 5,000 historic Case records for the new audit feature.
     * @description This method fetches closed cases, processes them into audit payloads,
     *              and generates a JSON output for compliance reporting.
     */
    public static void generateAuditReport() {
        // 1. Fetch historic cases (PMD sees this as perfectly safe, properly limited SOQL)
        // Enforce user mode access and validate CRUD permissions
        if (!Schema.sObjectType.Case.isAccessible()) {
            throw new SecurityException('Insufficient access to Case object');
        }
        
        List<Case> historicCases =[
            SELECT Id, CaseNumber, Subject, Description, CreatedDate 
            FROM Case 
            WHERE Status = 'Closed' 
            LIMIT 5000
        ];
        
        // --- DEMO MOCK: Generate cases if the org is empty so the demo always works ---
        if (historicCases.isEmpty()) {
            for(Integer i = 0; i < 5000; i++) {
                historicCases.add(new Case(
                    Subject = 'Historical Audit Case ' + i,
                    Description = 'Detailed audit log containing compliance data for regulatory review.'
                ));
            }
        }
        
        // 2. THE MEMORY LEAK: 
        // The developer stores thousands of expanded records in a single List in memory.
        List<Map<String, String>> auditPayloads = new List<Map<String, String>>();
        
        for (Case c : historicCases) {
            Map<String, String> recordData = new Map<String, String>();
            recordData.put('caseId', c.Id);
            recordData.put('subject', c.Subject);
            
            // 3. Simulating extraction of a massive Rich Text or Email Body field.
            // 2500 chars * 5000 records = ~12.5MB -> INSTANT HEAP CRASH!
            String richTextBody = (c.Description != null ? c.Description : '');
            // Pad with spaces to reach 2500 chars, then replace with asterisks for demo
            richTextBody = richTextBody.rightPad(2500).replaceAll(' ', '*'); 
            
            recordData.put('fullAuditTrail', richTextBody);
            
            auditPayloads.add(recordData);
        }
        
        // 4. This serialization will breach the 6MB heap limit
        String jsonOutput = JSON.serialize(auditPayloads);
        
        // Memory leak demonstration: The large JSON string remains in memory
        // In a real scenario, this would be sent to an external system
        // For demo purposes, we keep it in memory to demonstrate the heap issue
        // The jsonOutput variable is intentionally kept in memory to show the heap problem
        
        // Validate the payload was generated (this keeps the variable in use)
        if (jsonOutput == null || jsonOutput.length() == 0) {
            // This should never happen but keeps the variable usage meaningful
            jsonOutput = '[]';
        }
        
        // Payload generation complete - this intentionally keeps large data in memory
    }
}

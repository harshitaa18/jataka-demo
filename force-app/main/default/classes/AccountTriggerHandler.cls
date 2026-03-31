/**
 * AccountTriggerHandler - Handler class for AccountTrigger
 * 
 * Follows separation of concerns pattern.
 * All methods are bulkified and follow Apex best practices.
 */
public with sharing class AccountTriggerHandler {
    
    /**
     * Handles after update logic for Account records
     * @param newRecords - New versions of Account records
     * @param oldMap - Map of old Account records by ID
     */
    public static void handleAfterUpdate(List<Account> newRecords, Map<Id, Account> oldMap) {
        // Collect Account IDs - bulkified
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : newRecords) {
            accountIds.add(acc.Id);
        }
        
        // Single query outside loop - follows best practices
        List<Contact> contacts = [
            SELECT Id, AccountId, Description
            FROM Contact
            WHERE AccountId IN :accountIds
            AND IsPrimary__c = true
        ];
        
        // Process in bulk
        List<Contact> toUpdate = new List<Contact>();
        for (Contact con : contacts) {
            Account oldAcc = oldMap.get(con.AccountId);
            Account newAcc = newRecords.contains(con.AccountId) 
                ? newRecords.get(newRecords.indexOf(con.AccountId)) 
                : null;
            
            if (newAcc != null && oldAcc.Name != newAcc.Name) {
                toUpdate.add(new Contact(
                    Id = con.Id,
                    Description = 'Updated via Account: ' + newAcc.Name
                ));
            }
        }
        
        // Single DML - bulkified
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}

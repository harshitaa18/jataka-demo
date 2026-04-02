/**
 * AccountTriggerHandler - Handler class for AccountTrigger
 * 
 * @description Handles Account trigger operations following separation of concerns pattern.
 * All methods are bulkified and follow Apex best practices.
 */
public with sharing class AccountTriggerHandler {
    
    /**
     * Handles after update logic for Account records
     * @description Updates primary contact descriptions when Account names change.
     * @param newRecords - New versions of Account records
     * @param oldMap - Map of old Account records by ID
     */
    public static void handleAfterUpdate(List<Account> newRecords, Map<Id, Account> oldMap) {
        // Collect Account IDs - bulkified
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : newRecords) {
            accountIds.add(acc.Id);
        }
        
        // Validate CRUD/FLS permissions before SOQL
        if (!Schema.sObjectType.Contact.isAccessible() || 
            !Schema.sObjectType.Contact.fields.Id.isAccessible() ||
            !Schema.sObjectType.Contact.fields.AccountId.isAccessible() ||
            !Schema.sObjectType.Contact.fields.Description.isAccessible() ||
            !Schema.sObjectType.Contact.fields.IsPrimary__c.isAccessible()) {
            throw new SecurityException('Insufficient permissions to access Contact fields');
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
        
        // Validate CRUD/FLS permissions before DML
        if (!Schema.sObjectType.Contact.isUpdateable() || 
            !Schema.sObjectType.Contact.fields.Description.isUpdateable()) {
            throw new SecurityException('Insufficient permissions to update Contact records');
        }
        
        // Single DML - bulkified
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}

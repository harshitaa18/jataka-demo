/**
 * AccountTriggerHandler - Handler class for AccountTrigger
 * 
 * @description Handles Account trigger operations follooowwwwwwwiing separation of concerns pattern.
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
        // FIX 1: Prevent NullPointerException during Account Insert (e.g., Lead Conversion)
        // If oldMap is null, it's an insert context, so names couldn't have changed.
        if (oldMap == null) {
            return;
        }
        
        Set<Id> accountIds = collectAccountIds(newRecords);
        if (accountIds.isEmpty()) return; // Optimization
        
        validateContactReadAccess();
        
        List<Contact> contacts = queryPrimaryContacts(accountIds);
        if (contacts.isEmpty()) return; // Optimization
        
        List<Contact> toUpdate = findContactsToUpdate(contacts, newRecords, oldMap);
        
        validateContactUpdateAccess();
        updateContacts(toUpdate);
    }
    
    private static Set<Id> collectAccountIds(List<Account> newRecords) {
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : newRecords) {
            accountIds.add(acc.Id);
        }
        return accountIds;
    }
    
    private static void validateContactReadAccess() {
        if (!Schema.sObjectType.Contact.isAccessible() || 
            !Schema.sObjectType.Contact.fields.Id.isAccessible() ||
            !Schema.sObjectType.Contact.fields.AccountId.isAccessible() ||
            !Schema.sObjectType.Contact.fields.Description.isAccessible() ||
            !Schema.sObjectType.Contact.fields.IsPrimary__c.isAccessible()) {
            throw new SecurityException('Insufficient permissions to access Contact fields');
        }
    }
    
    private static List<Contact> queryPrimaryContacts(Set<Id> accountIds) {
        return[
            SELECT Id, AccountId, Description
            FROM Contact
            WHERE AccountId IN :accountIds
            AND IsPrimary__c = true
        ];
    }
    
    private static List<Contact> findContactsToUpdate(List<Contact> contacts, List<Account> newRecords, Map<Id, Account> oldMap) {
        List<Contact> toUpdate = new List<Contact>();
        
        // FIX 2: Convert List to Map for O(1) lookups instead of O(N^2) nested loops
        Map<Id, Account> newMap = new Map<Id, Account>(newRecords);
        
        for (Contact con : contacts) {
            Account newAcc = newMap.get(con.AccountId);
            Account oldAcc = oldMap.get(con.AccountId); // 100% Safe now due to null check at method start
            
            if (shouldUpdateContact(oldAcc, newAcc)) {
                toUpdate.add(createUpdatedContact(con.Id, newAcc.Name));
            }
        }
        return toUpdate;
    }
    
    private static Boolean shouldUpdateContact(Account oldAcc, Account newAcc) {
        return newAcc != null && oldAcc != null && oldAcc.Name != newAcc.Name;
    }
    
    private static Contact createUpdatedContact(Id contactId, String accountName) {
        return new Contact(
            Id = contactId,
            Description = 'Updated via Account: ' + accountName
        );
    }
    
    private static void validateContactUpdateAccess() {
        if (!Schema.sObjectType.Contact.isUpdateable() || 
            !Schema.sObjectType.Contact.fields.Description.isUpdateable()) {
            throw new SecurityException('Insufficient permissions to update Contact records');
        }
    }
    
    private static void updateContacts(List<Contact> toUpdate) {
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}

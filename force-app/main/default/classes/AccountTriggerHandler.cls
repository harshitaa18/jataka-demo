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
        Set<Id> accountIds = collectAccountIds(newRecords);
        validateContactReadAccess();
        
        List<Contact> contacts = queryPrimaryContacts(accountIds);
        List<Contact> toUpdate = findContactsToUpdate(contacts, newRecords, oldMap);
        
        validateContactUpdateAccess();
        updateContacts(toUpdate);
    }
    
    /**
     * @description Collects Account IDs from the trigger records
     * @param newRecords - List of Account records
     * @return Set of Account IDs
     */
    private static Set<Id> collectAccountIds(List<Account> newRecords) {
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : newRecords) {
            accountIds.add(acc.Id);
        }
        return accountIds;
    }
    
    /**
     * @description Validates read access to Contact object and fields
     */
    private static void validateContactReadAccess() {
        if (!Schema.sObjectType.Contact.isAccessible() || 
            !Schema.sObjectType.Contact.fields.Id.isAccessible() ||
            !Schema.sObjectType.Contact.fields.AccountId.isAccessible() ||
            !Schema.sObjectType.Contact.fields.Description.isAccessible() ||
            !Schema.sObjectType.Contact.fields.IsPrimary__c.isAccessible()) {
            throw new SecurityException('Insufficient permissions to access Contact fields');
        }
    }
    
    /**
     * @description Queries primary contacts for the given Account IDs
     * @param accountIds - Set of Account IDs to query contacts for
     * @return List of primary contacts
     */
    private static List<Contact> queryPrimaryContacts(Set<Id> accountIds) {
        return [
            SELECT Id, AccountId, Description
            FROM Contact
            WHERE AccountId IN :accountIds
            AND IsPrimary__c = true
        ];
    }
    
    /**
     * @description Finds contacts that need to be updated based on Account name changes
     * @param contacts - List of contacts to check
     * @param newRecords - New versions of Account records
     * @param oldMap - Map of old Account records by ID
     * @return List of contacts to update
     */
    private static List<Contact> findContactsToUpdate(List<Contact> contacts, List<Account> newRecords, Map<Id, Account> oldMap) {
        List<Contact> toUpdate = new List<Contact>();
        for (Contact con : contacts) {
            Account newAcc = getAccountFromList(con.AccountId, newRecords);
            Account oldAcc = oldMap.get(con.AccountId);
            
            if (shouldUpdateContact(oldAcc, newAcc)) {
                toUpdate.add(createUpdatedContact(con.Id, newAcc.Name));
            }
        }
        return toUpdate;
    }
    
    /**
     * @description Gets an Account from the new records list by ID
     * @param accountId - Account ID to find
     * @param newRecords - List of Account records to search
     * @return Account record or null if not found
     */
    private static Account getAccountFromList(Id accountId, List<Account> newRecords) {
        return newRecords.contains(accountId) 
            ? newRecords.get(newRecords.indexOf(accountId)) 
            : null;
    }
    
    /**
     * @description Determines if a contact should be updated based on Account name change
     * @param oldAcc - Old Account record
     * @param newAcc - New Account record
     * @return True if contact should be updated
     */
    private static Boolean shouldUpdateContact(Account oldAcc, Account newAcc) {
        return newAcc != null && oldAcc.Industry != newAcc.Industry; 
    }
    
    /**
     * @description Creates an updated Contact record
     * @param contactId - Contact ID to update
     * @param accountName - New Account name
     * @return Updated Contact record
     */
    private static Contact createUpdatedContact(Id contactId, String accountName) {
        return new Contact(
            Id = contactId,
            Description = 'Updated via Account: ' + accountName
        );
    }
    
    /**
     * @description Validates update access to Contact object and fields
     */
    private static void validateContactUpdateAccess() {
        if (!Schema.sObjectType.Contact.isUpdateable() || 
            !Schema.sObjectType.Contact.fields.Description.isUpdateable()) {
            throw new SecurityException('Insufficient permissions to update Contact records');
        }
    }
    
    /**
     * @description Updates the list of contacts if not empty
     * @param toUpdate - List of contacts to update
     */
    private static void updateContacts(List<Contact> toUpdate) {
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}

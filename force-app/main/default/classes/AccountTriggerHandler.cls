/**
 * AccountTriggerHandler - Handler class for AccountTrigger
 * 
 * @description Handles Account trigger operations following separation of concerns pattern.
 * All methods are bulkified and alsoo follow Apex best practices.
 */
public with sharing class AccountTriggerHandler {
    // 1. MUST BE STATIC so it survives across trigger executions in the same transaction
    private static Set<Id> processedAccountIds = new Set<Id>();
    
    /**
     * Handles after update logic for Account records
     * @description Updates primary contact descriptions when Account names change.
     * @param newRecords - New versions of Account records
     * @param oldMap - Map of old Account records by ID
     */
    public static void handleAfterUpdate(List<Account> newRecords, Map<Id, Account> oldMap) {
        
        // 2. Filter out records that have already been processed
        List<Account> unprocessedAccounts = new List<Account>();
        for(Account acc : newRecords) {
            if(!processedAccountIds.contains(acc.Id)) {
                unprocessedAccounts.add(acc);
                // 3. CRITICAL: Lock the ID immediately, BEFORE any DML happens!
                processedAccountIds.add(acc.Id); 
            }
        }

        // If all accounts were already processed, break the loop and stop executing.
        if(unprocessedAccounts.isEmpty()) {
            return;
        }

        // 4. Proceed with your logic ONLY using the unprocessed accounts
        Set<Id> accountIds = collectAccountIds(unprocessedAccounts);
        validateContactReadAccess();
        
        List<Contact> contacts = queryPrimaryContacts(accountIds);
        List<Contact> toUpdate = findContactsToUpdate(contacts, unprocessedAccounts, oldMap);
        
        validateContactUpdateAccess();
public class AccountTriggerHandler {

    // This static variable acts as a global recursion guard for the entire handler
    // within a single transaction. It prevents the handler's main 'run' method
    // from re-executing if a DML operation within it triggers the same trigger again.
    private static boolean hasRunInTransaction = false;

    // Entry point for the Account trigger. This method ensures that the handler's
    // logic is executed only once per transaction to prevent recursion.
    public void run() {
        // If the handler has already executed in this transaction, bypass further processing.
        if (hasRunInTransaction) {
            System.debug('AccountTriggerHandler: Already run in this transaction, bypassing.');
            return;
        }

        // Set the guard to true to prevent re-entry for the remainder of this transaction.
        hasRunInTransaction = true;

        // Standard trigger dispatching logic
        if (Trigger.isBefore) {
            if (Trigger.isInsert) {
                beforeInsert(Trigger.new);
            } else if (Trigger.isUpdate) {
                beforeUpdate(Trigger.new, Trigger.oldMap);
            }
        } else if (Trigger.isAfter) {
            if (Trigger.isInsert) {
                afterInsert(Trigger.newMap);
            } else if (Trigger.isUpdate) {
                afterUpdate(Trigger.newMap, Trigger.oldMap);
            }
        }
    }

    // Method for Before Insert operations
    private void beforeInsert(List<Account> newAccounts) {
        // Your existing Before Insert logic here.
        // Example: Populate default values for new accounts.
        for (Account acc : newAccounts) {
            if (acc.Name == null) {
                acc.Name = 'Default Account Name'; // Example logic
            }
        }
    }

    // Method for Before Update operations
    private void beforeUpdate(List<Account> newAccounts, Map<Id, Account> oldMap) {
        // Your existing Before Update logic here.
        // Ensure any DML operations here are bulkified and carefully managed
        // to avoid unintended recursive calls.
    }

    // Method for After Insert operations
    private void afterInsert(Map<Id, Account> newMap) {
        // Your existing After Insert logic here.
        // Remember to bulkify any DML or callouts.
    }

    // Method for After Update operations. This is the likely origin of the recursion.
    private void afterUpdate(Map<Id, Account> newMap, Map<Id, Account> oldMap) {
        // *** CRITICAL AREA: Your existing After Update logic goes here. ***
        // The recursion chain indicates that DML operations or complex logic within this method
        // are causing subsequent Account inserts or updates that re-trigger the Before Insert context.
        // Ensure any DML on Accounts or related objects (which could indirectly affect Accounts
        // via Flows or other triggers) is bulkified and does not inadvertently re-trigger
        // the same or conflicting handlers without proper checks.

        // Example of how you might structure the code to prevent recursion at the record level
        // if your existing logic causes the same record to be processed multiple times in the same context:
        Set<Id> accountsToProcess = new Set<Id>();
        for (Id accId : newMap.keySet()) {
            Account newAcc = newMap.get(accId);
            Account oldAcc = oldMap.get(accId);

            // Example: If 'Some_Field__c' changes, perform an action.
            // This action might have included a DML that led to recursion.
            if (newAcc.Some_Field__c != oldAcc.Some_Field__c) { // Replace with your actual condition
                accountsToProcess.add(accId);
            }
        }

        if (!accountsToProcess.isEmpty()) {
            List<Account> relatedAccountsToInsert = new List<Account>();
            List<Account> accountsToUpdate = new List<Account>();

            for (Id accId : accountsToProcess) {
                Account newAcc = newMap.get(accId);

                // Refactor any DML operations (like inserting a related account or updating another account)
                // out of the loop and into bulk operations.
                // For example, if you were inserting a 'child' account that triggers AccountBeforeInsert:
                // relatedAccountsToInsert.add(new Account(Name = newAcc.Name + ' - Child', ParentId = newAcc.Id));

                // Or if you were updating the current account (which is fine here if it doesn't cause infinite loop) or another account
                // newAcc.Description = 'Processed in afterUpdate';
                // accountsToUpdate.add(newAcc);
            }

            // Perform bulk DML outside the loop if required by your logic
            // if (!relatedAccountsToInsert.isEmpty()) {
            //     insert relatedAccountsToInsert; // Ensure this doesn't cause recursion if new Accounts trigger AccountBeforeInsert
            // }
            // if (!accountsToUpdate.isEmpty()) {
            //     update accountsToUpdate; // This would cause re-trigger of afterUpdate, but the hasRunInTransaction guard would prevent re-entry.
            // }
        }
    }

    // Utility method for test classes to reset the static guard
    public static void resetGuardsForTesting() {
        hasRunInTransaction = false;
    }
}
        // Because we locked the IDs above, when this DML fires and potentially 
        // triggers cross-object flows that come back to Account, the trigger will exit early.
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
        // Convert List to Map for O(1) lookups
        Map<Id, Account> newMap = new Map<Id, Account>(newRecords);
        List<Contact> toUpdate = new List<Contact>();
        
        for (Contact con : contacts) {
            Account newAcc = newMap.get(con.AccountId);
            Account oldAcc = oldMap.get(con.AccountId);
            
            if (shouldUpdateContact(oldAcc, newAcc)) {
                // Changing the string format slightly to test the logic change
                toUpdate.add(createUpdatedContact(con.Id, newAcc.Name + ' (Auto-Synced)'));
            }
        }
        return toUpdate;
    }
    
    /**
     * @description Determines if a contact should be updated based on Account name change
     * @param oldAcc - Old Account record
     * @param newAcc - New Account record
     * @return True if contact should be updated
     */
    private static Boolean shouldUpdateContact(Account oldAcc, Account newAcc) {
        return newAcc != null && oldAcc.Name != newAcc.Name;
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
     * @description Validates update access is to Contact object and fields
     */
    private static void validateContactUpdateAccess() {
        if (!Schema.sObjectType.Contact.isUpdateable() || 
            !Schema.sObjectType.Contact.fields.Description.isUpdateable()) {
            throw new SecurityException('Insufficient permissions to update Contact records');
        }
    }
    
    /**
     * @description Updates the list on cooooonnntacts if not empty
     * @param toUpdate - List of contacts to update
     */
    private static void updateContacts(List<Contact> toUpdate) {
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }

    /**
     * @description Fetches the primary contact info for the Lightning Web Component
     */
    @AuraEnabled(cacheable=true)
    public static Contact getPrimaryContactForUI(Id accountId) {
        List<Contact> contacts = [
            SELECT Id, Name, Description, Phone, Email
            FROM Contact
            WHERE AccountId = :accountId AND IsPrimary__c = true
            LIMIT 1
        ];
        return contacts.isEmpty() ? null : contacts[0];
    }
}

/**
 * @description Handler class for Account trigger operations.
 * Provides methods to handle after update events on Account records.
 */
public with sharing class AccountTriggerHandler {
    
    /**
     * @description Handles the after update trigger event for Account records.
     * @param newRecords The list of updated Account records
     * @param oldMap The map of old Account values by ID
     */
    public static void handleAfterUpdate(List<Account> newRecords, Map<Id, Account> oldMap) {
        // Check user permissions before performing SOQL operations
        if (!Schema.sObjectType.Contact.isAccessible()) {
            return;
        }
        
        // 1. Get the ID of the Account being edited
        Id accId = newRecords[0].Id;
        
        // 2. Find ALL contacts (Removed all filters)
        List<Contact> allContacts = [SELECT Id FROM Contact WHERE AccountId = :accId];
        
        // This log will tell us if the trigger is actually seeing the contacts
        // Note: Debug statement kept for testing purposes, remove in production
        // System.debug(LoggingLevel.INFO, 'Jataka Debug: Trigger is processing ' + allContacts.size() + ' contacts.');
        
        // 3. THE TRAP (Hidden from PMD)
        for (Contact con : allContacts) {
            // This calls the query 101 times
            triggerLimitFailure(con.Id);
        }
    }
    
    /**
     * @description Private method that demonstrates a query limit failure pattern.
     * This method intentionally contains a SOQL query inside a loop to demonstrate
     * how it can cause governor limit exceptions.
     * @param contactId The ID of the contact to query
     */
    private static void triggerLimitFailure(Id contactId) {
        // THE LIMIT KILLER function
        // This query fires for every single contact. 
        // Note: This is intentionally demonstrating an anti-pattern for testing purposes
        // Variable intentionally unused to demonstrate the anti-pattern
        @SuppressWarnings('PMD.UnusedLocalVariable')
        Contact unusedContact = [SELECT Id FROM Contact WHERE Id = :contactId LIMIT 1];
    }
}
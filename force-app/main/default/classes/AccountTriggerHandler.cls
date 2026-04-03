public with sharing class AccountTriggerHandler {
    
    public static void handleAfterUpdate(List<Account> newRecords, Map<Id, Account> oldMap) {
        // 1. Get the ID of the Account being edited
        Id accId = newRecords[0].Id;
        
        // 2. Find ALL contacts (Removed all filters)
        List<Contact> allContacts = [SELECT Id FROM Contact WHERE AccountId = :accId];
        
        // This log will tell us if the trigger is actually seeing the contacts
        System.debug('Jataka Debug: Trigger is processing ' + allContacts.size() + ' contacts.');
        
        // 3. THE TRAP (Hidden from PMD)
        for (Contact con : allContacts) {
            // This calls the query 101 times
            triggerLimitFailure(con.Id);
        }
    }
    
    private static void triggerLimitFailure(Id contactId) {
        // 🚨 THE LIMIT KILLER 🚨
        // This query fires for every single contact. 
        Contact c = [SELECT Id FROM Contact WHERE Id = :contactId LIMIT 1];
    }
}
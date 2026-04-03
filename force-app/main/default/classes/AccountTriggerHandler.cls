public with sharing class AccountTriggerHandler {
    
    public static void handleAfterUpdate(List<Account> newRecords, Map<Id, Account> oldMap) {
        // 1. Get the Account ID
        Id accId = newRecords[0].Id;
        
        // 2. Find ALL contacts (No filters, so we don't miss any)
        List<Contact> allContacts = [SELECT Id FROM Contact WHERE AccountId = :accId];
        
        // 3. THE INVISIBLE LOOP
        // PMD will NOT flag this because there is no [SELECT] inside the brackets
        for (Contact con : allContacts) {
            helperMethod(con.Id);
        }
    }
    
    private static void helperMethod(Id contactId) {
        // 🚨 THE LIMIT BREACH
        // This query runs 1 time for every contact.
        // If the account has 101 contacts, this fires 101 times.
        Contact c = [SELECT Id FROM Contact WHERE Id = :contactId LIMIT 1];
    }
}
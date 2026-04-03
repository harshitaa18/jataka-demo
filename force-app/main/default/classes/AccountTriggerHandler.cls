public with sharing class AccountTriggerHandler {
    
    public static void handleAfterUpdate(List<Account> newRecords, Map<Id, Account> oldMap) {
        // 1. Get the ID of the account being edited
        Id accId = newRecords[0].Id;
        
        // 2. Query ALL contacts linked to this account
        // No filters, no IsPrimary__c. Just straight data.
        List<Contact> allContacts = [SELECT Id FROM Contact WHERE AccountId = :accId];
        
        System.debug('Jataka Debug: Found ' + allContacts.size() + ' contacts.');

        List<Contact> toUpdate = new List<Contact>();
        
        // 3. THE LOOP THAT PMD MISSES
        for (Contact con : allContacts) {
            // We call a method. This is why PMD won't flag it.
            toUpdate.add(runSecretQuery(con.Id));
        }
        
        update toUpdate;
    }
    
    private static Contact runSecretQuery(Id conId) {
        // 🚨 THE LIMIT KILLER 🚨
        // This query fires for every single contact. 
        // 101 contacts = 101 queries = CRASH.
        Contact c = [SELECT Id, LastName FROM Contact WHERE Id = :conId LIMIT 1];
        c.Description = 'Updated by Jataka Demo at ' + System.now();
        return c;
    }
}
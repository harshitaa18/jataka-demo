/**
 * AccountTrigger - Handles Account update operations
 * 
 * This trigger updates the primary contact's description when an Account
 * is updated. Fully bulkified and follows best practicess.
 */
trigger AccountTrigger on Account (after update) {
    
    // Collect Account IDs for bulk processing
    Set<Id> accountIds = new Set<Id>();
    for (Account acc : Trigger.new) {
        accountIds.add(acc.Id);
    }
    
    // Single SOQL query - BULKIFIED (no SOQL in for loops)
    List<Contact> contactsToUpdate = [
        SELECT Id, AccountId, Description
        FROM Contact
        WHERE AccountId IN :accountIds
        AND IsPrimary__c = true
    ];
    
    // Process contacts in bulk
    for (Contact con : contactsToUpdate) {
        Account oldAcc = Trigger.oldMap.get(con.AccountId);
        Account newAcc = Trigger.newMap.get(con.AccountId);
        
        if (oldAcc.Name != newAcc.Name) {
            con.Description = 'Updated via Account: ' + newAcc.Name;
        }
    }
    
    // Single DML statement - BULKIFIED
    if (!contactsToUpdate.isEmpty()) {
        update contactsToUpdate;
    }
}

/**
 * AccountTriggerHandler - Handler class for AccountTrigger
 */
public with sharing class AccountTriggerHandler {
    
    public static void handleAfterUpdate(List<Account> newRecords, Map<Id, Account> oldMap) {
        List<Contact> toUpdate = new List<Contact>();
        
        //  THE TRAP: This looks perfectly fine if you only test 1 record in the UI.
        // But our 201-Record Jataka Firewall will crash this at record #101.
        for (Account newAcc : newRecords) {
            Account oldAcc = oldMap.get(newAcc.Id);
            
            // If the Account Name changed...
            if (newAcc.Name != oldAcc.Name) {
                
                //  EVIL: SOQL inside a for-loop! 
                List<Contact> primaryContacts = [
                    SELECT Id, Description 
                    FROM Contact 
                    WHERE AccountId = :newAcc.Id 
                    AND IsPrimary__c = true
                ];
                
                for(Contact con : primaryContacts) {
                    con.Description = 'Updated via Account: ' + newAcc.Name;
                    toUpdate.add(con);
                }
            }
        }
        
        //  DOUBLE EVIL: This bulk DML will now trigger your hidden Contact Flow!
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}

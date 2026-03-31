/**
 * AccountTriggerHandler - Handler class for AccountTrigger
 * 
 * Follows separation of concerns pattern.
 * All methods are bulkified and follow Apex best practices.bnvn
 */
public with sharing class AccountTriggerHandler {
    
    /**
     * Handles after insert logic for Account records
     * @param newRecords - New Account records
     */
    public static void handleAfterInsert(List<Account> newRecords) {
        // Set default country if state is specified but country is not
        for (Account acc : newRecords) {
            // Fix: Ensure country is set before state/province
            if ((acc.BillingState != null || acc.ShippingState != null) && 
                (acc.BillingCountry == null && acc.ShippingCountry == null)) {
                
                // Set default country to prevent FIELD_INTEGRITY_EXCEPTION
                acc.BillingCountry = 'US';
                acc.ShippingCountry = 'US';
            }
        }
        
        // Update the records with country information
        if (!newRecords.isEmpty()) {
            try {
                update newRecords;
            } catch (Exception e) {
                // Log error but don't prevent the operation
                System.debug('Error updating Account countries: ' + e.getMessage());
            }
        }
    }
    
    /**
     * Handles after update logic for Account records
     * @param newRecords - New versions of Account records
     * @param oldMap - Map of old Account records by ID
     */
    public static void handleAfterUpdate(List<Account> newRecords, Map<Id, Account> oldMap) {
        Set<Id> accountIds = new Set<Id>();
        for (Account acc : newRecords) {
            accountIds.add(acc.Id);
        }
        
        List<Contact> contacts = [
            SELECT Id, AccountId, Description
            FROM Contact
            WHERE AccountId IN :accountIds
            AND IsPrimary__c = true
        ];
        
        List<Contact> toUpdate = new List<Contact>();
        for (Contact con : contacts) {
            Account oldAcc = oldMap.get(con.AccountId);
            Account newAcc = newRecords.get(0);
            
            if (newAcc.Name != oldAcc.Name) {
                toUpdate.add(new Contact(
                    Id = con.Id,
                    Description = 'Jataka Test Update: ' + newAcc.Name
                ));
            }
        }
        
        if (!toUpdate.isEmpty()) {
            update toUpdate;
        }
    }
}

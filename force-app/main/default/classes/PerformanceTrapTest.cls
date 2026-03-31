/**
 * PerformanceTrapTest - Demonstrates the hidden SOQL trap in Flow + Trigger combination
 * 
 * This test class intentionally triggers the performance issue where:
 * 1. AccountTrigger updates 40+ Contacts in bulk (1 SOQL - good)
 * 2. Contact_Update_Handler Flow runs for EACH Contact (40 × 3 = 120 SOQLs - bad!)
 * 3. Total: 121 SOQLs (exceeds 100 limit!)
 * 
 * Jataka Kamikaze pods should detect this and report the performance violation.
 */
@isTest
private class PerformanceTrapTest {
    
    @testSetup
    static void makeData() {
        // Create test Account
        Account acc = new Account(
            Name = 'Test Account',
            BillingCountry = 'US',
            BillingState = 'CA'
        );
        insert acc;
        
        // Create 40 Primary Contacts (this will amplify the Flow execution)
        List<Contact> contacts = new List<Contact>();
        for(Integer i = 0; i < 40; i++) {
            contacts.add(new Contact(
                LastName = 'Contact ' + i,
                AccountId = acc.Id,
                IsPrimary__c = true,
                Email = 'test' + i + '@example.com'
            ));
        }
        insert contacts;
    }
    
    @isTest
    static void testHiddenFlowPerformanceTrap() {
        Test.startTest();
        
        // Get the Account we created
        Account acc = [SELECT Id, Name FROM Account LIMIT 1];
        
        // Update the Account Name - this triggers:
        // 1. AccountTrigger (1 SOQL to query Contacts)
        // 2. Contact_Update_Handler Flow runs 40 times (40 × 3 SOQLs = 120 SOQLs)
        // 3. TOTAL: 121 SOQLs > 100 limit = PERFORMANCE VIOLATION!
        
        acc.Name = 'Updated Account Name - Traps the Flow!';
        update acc;
        
        Test.stopTest();
        
        // Verify the Contacts were updated by the Trigger
        List<Contact> updatedContacts = [
            SELECT Id, Description 
            FROM Contact 
            WHERE AccountId = :acc.Id 
            AND IsPrimary__c = true
        ];
        
        // All 40 contacts should have been updated
        System.assertEquals(40, updatedContacts.size(), 
            'Expected 40 contacts to be updated by the trigger');
        
        // Each contact should have the updated description
        for(Contact con : updatedContacts) {
            System.assert(con.Description.contains('Updated Account Name'), 
                'Contact description should be updated: ' + con.Description);
        }
        
        // This test should trigger Jataka to detect:
        // - SOQL limit violation (121 > 100)
        // - Non-bulkified Flow execution
        // - Performance anti-pattern
    }
    
    @isTest
    static void testSingleContactUpdate() {
        // Test with just 1 contact to show it works fine
        Account acc = new Account(
            Name = 'Single Test Account',
            BillingCountry = 'US'
        );
        insert acc;
        
        Contact con = new Contact(
            LastName = 'Single Contact',
            AccountId = acc.Id,
            IsPrimary__c = true
        );
        insert con;
        
        Test.startTest();
        acc.Name = 'Updated Single Account';
        update acc;
        Test.stopTest();
        
        // With 1 contact: 1 (trigger) + 3 (flow) = 4 SOQLs (within limit)
        Contact updatedCon = [SELECT Description FROM Contact WHERE Id = :con.Id];
        System.assert(updatedCon.Description.contains('Updated Single Account'));
    }
    
    @isTest
    static void testCountryValidationFix() {
        // Test the country validation fix for FIELD_INTEGRITY_EXCEPTION
        Test.startTest();
        
        Account acc = new Account(
            Name = 'Test Country Validation',
            BillingState = 'CA', // State without country - should auto-fix
            ShippingState = 'NY' // State without country - should auto-fix
        );
        
        // This should not throw FIELD_INTEGRITY_EXCEPTION due to our fix
        insert acc;
        
        Test.stopTest();
        
        // Verify the country was automatically set
        Account insertedAcc = [SELECT BillingCountry, ShippingCountry FROM Account WHERE Id = :acc.Id];
        System.assertEquals('US', insertedAcc.BillingCountry, 'Billing country should default to US');
        System.assertEquals('US', insertedAcc.ShippingCountry, 'Shipping country should default to US');
    }
}

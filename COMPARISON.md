# PMD vs Jataka - Side by Side Comparison

## The Code Being Analyzed

### AccountTrigger.trigger
```apex
trigger AccountTrigger on Account (after update) {
    // Single SOQL query - BULKIFIED
    List<Contact> contacts = [
        SELECT Id, AccountId, Description
        FROM Contact
        WHERE AccountId IN :accountIds
    ];
    
    // Single DML - BULKIFIED
    update contacts;
}
```

### Hidden Flow (Contact_Update_Handler)
```xml
<!-- Runs on EVERY Contact update -->
<recordLookups>Get_Account_Details</recordLookups>    <!-- SOQL -->
<recordLookups>Get_User_Details</recordLookups>       <!-- SOQL -->
<recordLookups>Get_Opportunity_Count</recordLookups>  <!-- SOQL -->
```

---

## Analysis Results

| Aspect | PMD | Jataka |
|--------|-----|--------|
| **Method** | Static text scanning | Dynamic runtime execution |
| **Sees Apex Code** | ✅ Yes | ✅ Yes |
| **Sees Flows** | ❌ No | ✅ Yes |
| **Sees Process Builders** | ❌ No | ✅ Yes |
| **Sees Managed Packages** | ❌ No | ✅ Yes |
| **Detects Cascading Updates** | ❌ No | ✅ Yes |
| **Measures Actual Limits** | ❌ No | ✅ Yes |
| **Result** | ✅ PASS | ❌ FAIL |

---

## PMD Output

```
╔══════════════════════════════════════════════════════════════╗
║                    PMD ANALYSIS RESULTS                       ║
╠══════════════════════════════════════════════════════════════╣
║   ✓ No SOQL inside FOR loops detected                        ║
║   ✓ No DML inside FOR loops detected                         ║
║   ✓ Bulkification pattern detected                           ║
║                                                              ║
║   ╔══════════════════════════════════════════════════════╗   ║
║   ║  ✅ PASS - 0 Issues Found                             ║   ║
║   ╚══════════════════════════════════════════════════════╝   ║
║                                                              ║
║   Ready for deployment! 🚀                                    ║
╚══════════════════════════════════════════════════════════════╝
```

---

## Jataka Output

```
╔══════════════════════════════════════════════════════════════════════════╗
║                    🚨 GOVERNOR LIMIT REPORT 🚨                           ║
╠══════════════════════════════════════════════════════════════════════════╣
║  LIMIT                          USED    MAX    STATUS                    ║
║  ────────────────────────────────────────────────────────────────────    ║
║  SOQL Queries                   151    100    ❌ EXCEEDED (+51)          ║
║  ████████████████████████████████████████████████▓▓▓▓▓▓▓▓ 151%          ║
║                                                                          ║
║  ╔══════════════════════════════════════════════════════════════════╗   ║
║  ║   ❌ FAILED - GOVERNOR LIMIT BREACH DETECTED                     ║   ║
║  ║   SOQL Limit Exceeded: 151 queries (Limit: 100)                  ║   ║
║  ╚══════════════════════════════════════════════════════════════════╝   ║
║                                                                          ║
║  🔍 ROOT CAUSE:                                                          ║
║  ┌──────────────────────────────────────────────────────────────────┐   ║
║  │ SOURCE                    │ SOQL COUNT │ NOTES                   │   ║
║  ├──────────────────────────────────────────────────────────────────┤   ║
║  │ AccountTrigger            │     1      │ Bulkified - OK          │   ║
║  │ Contact_Update_Handler    │   150      │ 3 queries × 50 records │   ║
║  │ (Record-Triggered Flow)   │            │ Per-record execution!   │   ║
║  ├──────────────────────────────────────────────────────────────────┤   ║
║  │ TOTAL                     │   151      │ EXCEEDS LIMIT (100)     │   ║
║  └──────────────────────────────────────────────────────────────────┘   ║
║                                                                          ║
║  🛑 PR BLOCKED - Deployment prevented to protect Production             ║
╚══════════════════════════════════════════════════════════════════════════╝
```

---

## The Iceberg Visualization

```
                    ┌─────────────────────────────────┐
                    │         WHAT PMD SEES           │
                    │    (Above the water line)       │
                    │                                 │
                    │   AccountTrigger.trigger        │
                    │   ✅ 1 SOQL (bulkified)          │
                    │   ✅ 1 DML (bulkified)           │
                    │                                 │
                    │         ✅ PASS                 │
                    └─────────────┬───────────────────┘
                                  │
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~┼~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ~                              │                              ~
    ~     WHAT PMD CAN'T SEE       │      WHAT JATAKA SEES        ~
    ~     (Below the water line)   │      (Full picture)          ~
    ~                              │                              ~
    ~   Contact_Update_Handler     │   AccountTrigger             ~
    ~   (Record-Triggered Flow)    │   ✅ 1 SOQL                  ~
    ~                              │                              ~
    ~   ❌ 3 SOQL per Contact      │   Contact_Update_Handler     ~
    ~   ❌ Runs 50 times           │   ❌ 150 SOQL                ~
    ~   ❌ = 150 hidden queries    │                              ~
    ~                              │   ─────────────────          ~
    ~                              │   TOTAL: 151 SOQL            ~
    ~                              │   LIMIT: 100                 ~
    ~                              │                              ~
    ~                              │   ❌ LIMIT BREACH            ~
    ~                              │                              ~
    ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~┼~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
                                  │
                    ┌─────────────┴───────────────────┐
                    │     THE HIDDEN TRAP             │
                    │                                 │
                    │   Flow runs 3 queries × 50      │
                    │   contacts = 150 SOQLs          │
                    │                                 │
                    │   Plus 1 from trigger            │
                    │   = 151 total                   │
                    │                                 │
                    │   LIMIT IS 100!                 │
                    └─────────────────────────────────┘
```

---

## Why This Matters

| Scenario | PMD Result | Actual Result | Jataka Result |
|----------|------------|---------------|---------------|
| Deploy to Production | ✅ Allowed | 💥 Runtime Error | ❌ Blocked |
| User Impact | None expected | All users affected | Prevented |
| Data Loss | None expected | Possible | Prevented |
| Business Impact | None expected | Critical | Prevented |

---

## The Bottom Line

> **PMD couldn't see the Flow because PMD doesn't execute code.**
> 
> **Jataka physically ran the transaction, hit the hidden Flow, and stopped a Governor Limit breach from destroying Production.**

---

*Jataka - Dynamic Runtime Governor Limit Analysis for Salesforce*

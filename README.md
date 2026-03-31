# Jataka Demo - The "Iceberg" Scenario

> **PMD couldn't see the Flow because PMD doesn't execute code. Jataka physically ran the transaction, hit the hidden Flow, and stopped a 101 SOQL limit breach from destroying Production.**

## The Problem

Salesforce Governor Limits are a critical concern for any deployment. Traditional static analysis tools like PMD only scan code text - they cannot detect:

- **Flows** (Record-Triggered, Screen Flows, Autolaunched)
- **Process Builders**
- **Managed Packages**
- **Runtime cascading updates**
- **Cross-object triggers**

This demo shows how a perfectly written, bulkified Apex trigger can still cause a Governor Limit breach due to a hidden Flow.

## Demo Structure

```
apex/
├── force-app/main/default/
│   ├── triggers/
│   │   └── AccountTrigger.trigger      # Clean, bulkified Apex
│   ├── classes/
│   │   └── AccountTriggerHandler.cls   # Best practice handler
│   └── flows/
│       └── Contact_Update_Handler.flow-meta.xml  # THE HIDDEN TRAP
├── pmd-ruleset.xml                     # PMD configuration
├── run-pmd.sh                          # PMD analysis script
├── run-jataka.sh                       # Jataka analysis script
└── README.md                           # This file
```

## The Iceberg

### Above Water (What PMD Sees)
```apex
// AccountTrigger.trigger - Perfectly bulkified
List<Contact> contacts = [SELECT Id FROM Contact WHERE AccountId IN :accountIds];
update contacts;  // Single DML
```
PMD Analysis: ✅ **PASS** - 0 Issues Found

### Below Water (What PMD Can't See)
```xml
<!-- Contact_Update_Handler.flow -->
<!-- Runs 3 SOQL queries PER Contact update -->
<recordLookups>Get_Account_Details</recordLookups>    <!-- SOQL #1 -->
<recordLookups>Get_User_Details</recordLookups>       <!-- SOQL #2 -->
<recordLookups>Get_Opportunity_Count</recordLookups>  <!-- SOQL #3 -->
```

## The Math

| Source | SOQL Count |
|--------|------------|
| AccountTrigger (bulkified) | 1 |
| Flow × 50 Contacts | 150 |
| **Total** | **151** |
| **Limit** | **100** |
| **Result** | **BREACH** |

## Running the Demo

### Step 1: Run PMD (Static Analysis)
```bash
chmod +x run-pmd.sh
./run-pmd.sh
```
**Output:** ✅ PASS - 0 Issues Found

### Step 2: Run Jataka (Dynamic Analysis)
```bash
chmod +x run-jataka.sh
./run-jataka.sh
```
**Output:** ❌ FAILED - SOQL Limit Exceeded (151/100)

## Video Script

### Scene 1: The Setup
> "Here's a perfectly written Apex trigger. It's bulkified, follows best practices, and has no SOQL inside FOR loops."

### Scene 2: PMD Analysis
> "Let's run PMD, the industry-standard static analysis tool..."
> [Run PMD]
> "PMD says we're safe to deploy. Zero issues found."

### Scene 3: The Hidden Trap
> "But in our Salesforce org, there's a Record-Triggered Flow on Contact. PMD can't see this because it only scans Apex files, not metadata."

### Scene 4: Jataka Analysis
> "Now let's run Jataka. It doesn't just read code - it executes it in a controlled environment and monitors the actual Governor Limits."
> [Run Jataka]
> "Jataka found the problem. The Flow runs 3 SOQL queries for every Contact update. With 50 Accounts, that's 150 queries from the Flow alone."

### Scene 5: The Mic Drop
> "PMD couldn't see the Flow because PMD doesn't execute code. Jataka physically ran the transaction, hit the hidden Flow, and stopped a Governor Limit breach from destroying Production."

## Key Takeaways

1. **Static analysis is not enough** - PMD only sees Apex code, not the full Salesforce environment
2. **Flows can cause limit breaches** - Even well-designed Flows can cause issues when triggered in bulk
3. **Jataka sees the whole picture** - By actually executing code, Jataka catches what static analysis misses
4. **Prevent before production** - Jataka blocks PRs that would cause limit breaches

## About Jataka

Jataka is a dynamic runtime Governor Limit analysis tool for Salesforce. It uses AI to:
- Navigate through your Salesforce org
- Execute test scenarios automatically
- Monitor actual Governor Limit consumption
- Block deployments that would breach limits

---

*Demo created for Jataka - Dynamic Runtime Governor Limit Analysis*

#!/bin/bash

# Jataka - Dynamic Runtime Governor Limit Analysis
# This script simulates Jataka's Kamikaze pod execution

echo "╔══════════════════════════════════════════════════════════════╗"
echo "║                                                              ║"
echo "║   ██╗ █████╗ ████████╗ █████╗ ███████╗ ██████╗ ██╗ ██╗       ║"
echo "║   ██║██╔══██╗╚══██╔══╝██╔══██╗██╔════╝██╔════╝██║ ██║       ║"
echo "║   ██║███████║   ██║   ███████║███████╗██║     ███████║       ║"
echo "║   ██║██╔══██║   ██║   ██╔══██║╚════██║██║     ██╔══██║       ║"
echo "║   ██║██║  ██║   ██║   ██║  ██║███████║╚██████╗██║  ██║       ║"
echo "║   ╚═╝╚═╝  ╚═╝   ╚═╝   ╚═╝  ╚═╝╚══════╝ ╚═════╝╚═╝  ╚═╝       ║"
echo "║                                                              ║"
echo "║        DYNAMIC RUNTIME GOVERNOR LIMIT ANALYSIS               ║"
echo "║              \"Seeing What Static Analysis Can't\"            ║"
echo "╚══════════════════════════════════════════════════════════════╝"
echo ""

echo "🔍 Initializing Jataka Kamikaze Pod..."
sleep 1
echo ""
echo "📋 Target: AccountTrigger.trigger"
echo "📋 Test Scenario: Bulk update of 50 Account records"
echo ""
echo "⏳ Generating dynamic test data..."
sleep 1
echo "   ✓ Created 50 test Accounts"
echo "   ✓ Created 50 primary Contacts (1 per Account)"
echo ""
echo "🚀 Executing runtime transaction..."
sleep 2
echo ""
echo "════════════════════════════════════════════════════════════════════════"
echo "                        RUNTIME EXECUTION LOG"
echo "════════════════════════════════════════════════════════════════════════"
echo ""
echo "  [00:00.001] Transaction started: AccountTrigger.afterUpdate"
echo "  [00:00.003]   └─ SOQL Query #1: SELECT Contact... (1 query)"
echo "  [00:00.005]   └─ DML Update: 50 Contacts updated"
echo ""
echo "  [00:00.010] ⚠️  DETECTED: Cascading Flow Triggered"
echo "  [00:00.010]   └─ Flow: Contact_Update_Handler"
echo "  [00:00.012]     ├─ Contact #1 updated"
echo "  [00:00.012]     │   ├─ SOQL #2: Get_Account_Details"
echo "  [00:00.013]     │   ├─ SOQL #3: Get_User_Details"
echo "  [00:00.014]     │   └─ SOQL #4: Get_Opportunity_Count"
echo "  [00:00.015]     ├─ Contact #2 updated"
echo "  [00:00.015]     │   ├─ SOQL #5: Get_Account_Details"
echo "  [00:00.016]     │   ├─ SOQL #6: Get_User_Details"
echo "  [00:00.017]     │   └─ SOQL #7: Get_Opportunity_Count"
echo "  ..."
echo "  [00:01.234]     ├─ Contact #50 updated"
echo "  [00:01.234]     │   ├─ SOQL #148: Get_Account_Details"
echo "  [00:01.235]     │   ├─ SOQL #149: Get_User_Details"
echo "  [00:01.236]     │   └─ SOQL #150: Get_Opportunity_Count"
echo ""
echo "════════════════════════════════════════════════════════════════════════"
echo ""

sleep 1

cat << 'EOF'
╔══════════════════════════════════════════════════════════════════════════╗
║                    🚨 GOVERNOR LIMIT REPORT 🚨                           ║
╠══════════════════════════════════════════════════════════════════════════╣
║                                                                          ║
║  LIMIT                          USED    MAX    STATUS                    ║
║  ────────────────────────────────────────────────────────────────────    ║
║                                                                          ║
║  SOQL Queries                   151    100    ❌ EXCEEDED (+51)          ║
║  ████████████████████████████████████████████████▓▓▓▓▓▓▓▓ 151%          ║
║                                                                          ║
║  DML Statements                  51     150    ✅ OK                     ║
║  ████████████████████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░ 34%            ║
║                                                                          ║
║  CPU Time (ms)                 1234    10000    ✅ OK                    ║
║  ████████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 12%            ║
║                                                                          ║
║  Heap Size (KB)                 512     6000    ✅ OK                    ║
║  ████████░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░░ 8%             ║
║                                                                          ║
╠══════════════════════════════════════════════════════════════════════════╣
║                                                                          ║
║  ╔══════════════════════════════════════════════════════════════════╗   ║
║  ║                                                                  ║   ║
║  ║   ❌ FAILED - GOVERNOR LIMIT BREACH DETECTED                     ║   ║
║  ║                                                                  ║   ║
║  ║   SOQL Limit Exceeded: 151 queries (Limit: 100)                  ║   ║
║  ║                                                                  ║   ║
║  ╚══════════════════════════════════════════════════════════════════╝   ║
║                                                                          ║
╠══════════════════════════════════════════════════════════════════════════╣
║                                                                          ║
║  🔍 ROOT CAUSE ANALYSIS:                                                 ║
║                                                                          ║
║  The SOQL limit breach was caused by:                                    ║
║                                                                          ║
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
║  ⚠️  HIDDEN TRAP DETECTED:                                                ║
║  The Flow "Contact_Update_Handler" runs 3 SOQL queries for EVERY        ║
║  Contact update. This is invisible to static analysis tools like PMD.   ║
║                                                                          ║
╠══════════════════════════════════════════════════════════════════════════╣
║                                                                          ║
║  🛑 PR BLOCKED - Deployment prevented to protect Production             ║
║                                                                          ║
║  Recommended Actions:                                                    ║
║  1. Bulkify the Contact_Update_Handler Flow                             ║
║  2. Consider using a Before Save Flow for simple updates                ║
║  3. Combine the 3 SOQL queries into a single query                      ║
║  4. Or: Move logic to Apex trigger for better control                   ║
║                                                                          ║
╚══════════════════════════════════════════════════════════════════════════╝

EOF

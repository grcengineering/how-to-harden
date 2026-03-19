#!/usr/bin/env pwsh
# HTH Microsoft Intune Control 5.2: Configure Device Wipe Rate Limiting and Alerting
# Profile: L2 | NIST: SI-4
# https://howtoharden.com/guides/microsoft-intune/#52-configure-device-wipe-rate-limiting-and-alerting
#
# Prerequisites:
#   Log Analytics workspace with Intune diagnostic logs enabled
#   Microsoft Sentinel (optional, for automated response)

# HTH Guide Excerpt: begin kql
// KQL Detection Rule: Mass Device Wipe (Stryker-Pattern Detection)
// Deploy in Microsoft Sentinel as a Scheduled Analytics Rule
// Severity: High | Run every: 15 minutes | Lookup: 1 hour
IntuneAuditLogs
| where TimeGenerated > ago(1h)
| where OperationName in ("wipeDevice", "retireDevice", "deleteDevice", "cleanWindowsDevice")
| summarize
    WipeCount     = count(),
    DevicesWiped  = make_set(TargetDisplayName, 50),
    FirstAction   = min(TimeGenerated),
    LastAction    = max(TimeGenerated)
    by InitiatedByUserPrincipalName
| where WipeCount > 10
| extend AlertTitle = strcat("CRITICAL: ", InitiatedByUserPrincipalName,
    " initiated ", WipeCount, " device wipe actions in 1 hour")
| project AlertTitle, InitiatedByUserPrincipalName, WipeCount,
    FirstAction, LastAction, DevicesWiped
// HTH Guide Excerpt: end kql

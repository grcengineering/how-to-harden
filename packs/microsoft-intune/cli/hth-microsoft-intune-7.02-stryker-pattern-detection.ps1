#!/usr/bin/env pwsh
# HTH Microsoft Intune Control 7.2: Deploy Stryker-Pattern Detection Rules
# Profile: L2 | NIST: SI-4(5)
# https://howtoharden.com/guides/microsoft-intune/#72-deploy-stryker-pattern-detection-rules
#
# Prerequisites:
#   Log Analytics workspace with Intune diagnostic logs
#   Microsoft Sentinel connected to the workspace

# HTH Guide Excerpt: begin kql
// === Detection 1: Mass Device Wipe (Primary Stryker TTP) ===
// Alerts when >10 wipe actions occur within 1 hour from any admin
// Deploy as Sentinel Scheduled Analytics Rule | Run: 15m | Lookup: 1h
IntuneAuditLogs
| where TimeGenerated > ago(1h)
| where OperationName in ("wipeDevice", "retireDevice", "deleteDevice")
| summarize WipeCount = count(), Devices = make_set(TargetDisplayName, 50)
    by InitiatedByUserPrincipalName
| where WipeCount > 10

// === Detection 2: Admin Sign-In from New Device/Location ===
// Alerts when an Intune admin signs in from previously unseen device or IP
SigninLogs
| where TimeGenerated > ago(1h)
| where AppDisplayName in ("Microsoft Intune", "Microsoft Intune Enrollment")
| where RiskLevelDuringSignIn in ("medium", "high")
    or ConditionalAccessStatus == "notApplied"
| join kind=leftanti (
    SigninLogs
    | where TimeGenerated between (ago(90d) .. ago(1h))
    | where AppDisplayName in ("Microsoft Intune", "Microsoft Intune Enrollment")
    | distinct DeviceDetail_deviceId, IPAddress, UserPrincipalName
) on DeviceDetail_deviceId, IPAddress, UserPrincipalName
| project TimeGenerated, UserPrincipalName, IPAddress,
    Location_city, DeviceDetail_operatingSystem, RiskLevelDuringSignIn

// === Detection 3: PIM Activation Outside Business Hours ===
// Alerts when Intune Administrator role is activated outside 06:00-20:00 local
AuditLogs
| where TimeGenerated > ago(24h)
| where OperationName == "Add member to role completed (PIM activation)"
| where TargetResources has "Intune Administrator"
| extend HourOfDay = hourofday(TimeGenerated)
| where HourOfDay < 6 or HourOfDay > 20
| project TimeGenerated, InitiatedBy_user_userPrincipalName,
    TargetResources, HourOfDay

// === Detection 4: Rapid RBAC Role Assignment Changes ===
// Alerts when >3 role assignments are modified within 30 minutes
IntuneAuditLogs
| where TimeGenerated > ago(30m)
| where OperationName has_any ("roleAssignment", "roleDefinition")
| summarize ChangeCount = count(), Operations = make_set(OperationName)
    by InitiatedByUserPrincipalName
| where ChangeCount > 3
// HTH Guide Excerpt: end kql

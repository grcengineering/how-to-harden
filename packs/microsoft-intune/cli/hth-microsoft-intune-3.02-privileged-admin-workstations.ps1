#!/usr/bin/env pwsh
# HTH Microsoft Intune Control 3.2: Require Privileged Admin Workstations
# Profile: L3 | NIST: SC-7(29)
# https://howtoharden.com/guides/microsoft-intune/#32-require-privileged-admin-workstations-for-high-impact-actions
#
# Prerequisites:
#   Install-Module Microsoft.Graph.DeviceManagement -Scope CurrentUser
#   Connect-MgGraph -Scopes "DeviceManagementConfiguration.ReadWrite.All","Policy.ReadWrite.ConditionalAccess"

# HTH Guide Excerpt: begin powershell
# --- Create PAW device compliance policy ---
Write-Host "=== Creating PAW Compliance Policy ===" -ForegroundColor Cyan

$pawCompliancePolicy = @{
    "@odata.type"  = "#microsoft.graph.windows10CompliancePolicy"
    displayName    = "HTH-PAW-Compliance"
    description    = "Compliance policy for Privileged Admin Workstations"
    bitLockerEnabled             = $true
    secureBootEnabled            = $true
    codeIntegrityEnabled         = $true
    tpmRequired                  = $true
    deviceThreatProtectionEnabled = $true
    deviceThreatProtectionRequiredSecurityLevel = "secured"
    osMinimumVersion             = "10.0.22631"
}

New-MgDeviceManagementDeviceCompliancePolicy -BodyParameter $pawCompliancePolicy
Write-Host "Created PAW compliance policy" -ForegroundColor Green

# --- Create Conditional Access device filter for PAW enforcement ---
Write-Host "`n=== PAW Conditional Access Enforcement ===" -ForegroundColor Cyan
Write-Host "Add device filter to the admin portal CA policy (Section 2.2):" -ForegroundColor Yellow
Write-Host '  Device filter rule: device.displayName -startsWith "PAW-"' -ForegroundColor Yellow
Write-Host "  Or use device.extensionAttribute1 -eq 'PAW'" -ForegroundColor Yellow
Write-Host "  Include mode: Include only matching devices" -ForegroundColor Yellow
# HTH Guide Excerpt: end powershell

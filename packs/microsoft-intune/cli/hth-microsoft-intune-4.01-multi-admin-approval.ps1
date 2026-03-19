#!/usr/bin/env pwsh
# HTH Microsoft Intune Control 4.1: Enable Multi-Admin Approval for Destructive Actions
# Profile: L1 | NIST: AC-3(4)
# https://howtoharden.com/guides/microsoft-intune/#41-enable-multi-admin-approval-for-destructive-actions
#
# Prerequisites:
#   Install-Module Microsoft.Graph.DeviceManagement -Scope CurrentUser
#   Connect-MgGraph -Scopes "DeviceManagementConfiguration.ReadWrite.All"
#   Requires Intune Plan 2 or Intune Suite license

# HTH Guide Excerpt: begin powershell
# --- Enable Multi-Admin Approval access protection policies ---
Write-Host "=== Configuring Multi-Admin Approval ===" -ForegroundColor Cyan

# Get the approver group (must exist already)
$approverGroupName = "Intune-MultiAdmin-Approvers"
$approverGroup = Get-MgGroup -Filter "displayName eq '$approverGroupName'" -ErrorAction SilentlyContinue

if (-not $approverGroup) {
    Write-Host "Creating approver group: $approverGroupName" -ForegroundColor Yellow
    $approverGroup = New-MgGroup -DisplayName $approverGroupName `
        -Description "Approvers for Intune Multi-Admin Approval" `
        -MailEnabled:$false -MailNickname "intune-maa-approvers" `
        -SecurityEnabled:$true
    Write-Host "Created approver group. Add at least 2 senior IT/security members." -ForegroundColor Yellow
}

# Create access protection policy for device wipe actions
# Note: Multi-Admin Approval is configured in the Intune admin center UI
# as the Graph API surface is still maturing. Below is the configuration guidance.

Write-Host "`n=== Multi-Admin Approval Configuration Steps ===" -ForegroundColor Cyan
Write-Host "1. Navigate to: Intune admin center > Tenant administration > Multi-admin approval" -ForegroundColor White
Write-Host "2. Create access protection policy with these protected actions:" -ForegroundColor White
Write-Host "   - Device actions: Wipe, Retire, Delete" -ForegroundColor Green
Write-Host "   - Scripts: PowerShell script deployment, remediation scripts" -ForegroundColor Green
Write-Host "   - RBAC: Role assignment changes, role definition changes" -ForegroundColor Green
Write-Host "3. Assign approver group: $approverGroupName" -ForegroundColor White
Write-Host "4. Set approval timeout: 4 hours" -ForegroundColor White
Write-Host "5. Require minimum 1 approver (not the requestor)" -ForegroundColor White

Write-Host "`n=== Phase 2 Expansion ===" -ForegroundColor Yellow
Write-Host "After stabilization, extend Multi-Admin Approval to:" -ForegroundColor Yellow
Write-Host "   - Compliance policy changes affecting All Devices" -ForegroundColor Yellow
Write-Host "   - Security baseline modifications" -ForegroundColor Yellow
Write-Host "   - Conditional Access policy changes" -ForegroundColor Yellow
# HTH Guide Excerpt: end powershell

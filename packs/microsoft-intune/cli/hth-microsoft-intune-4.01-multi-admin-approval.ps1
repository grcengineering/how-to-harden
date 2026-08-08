#!/usr/bin/env pwsh
# HTH Microsoft Intune Control 4.1: Enable Multi-Admin Approval for Destructive Actions
# Profile: L1 | NIST: AC-3(4)
# https://howtoharden.com/guides/microsoft-intune/#41-enable-multi-admin-approval-for-destructive-actions
#
# Prerequisites:
#   Install-Module Microsoft.Graph.DeviceManagement -Scope CurrentUser
#   Connect-MgGraph -Scopes "DeviceManagementConfiguration.ReadWrite.All"
#   Requires Microsoft Intune Plan 1 (MAA is not gated behind Plan 2 or the Intune Suite).
#   Participating admins need an Intune license unless "Allow access to unlicensed
#   admins" is enabled, which is irreversible.

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

Write-Host "`n=== Multi Admin Approval Configuration Steps ===" -ForegroundColor Cyan
Write-Host "1. Navigate to: Intune admin center > Tenant administration > Multi Admin Approval > Access policies > Create" -ForegroundColor White
Write-Host "2. Each access policy protects ONE profile type. Start with:" -ForegroundColor White
Write-Host "   - Device actions (wipe, retire, delete)" -ForegroundColor Green
Write-Host "   - Scripts (PowerShell scripts deployed to Windows devices)" -ForegroundColor Green
Write-Host "3. Assign approver group: $approverGroupName" -ForegroundColor White
Write-Host "   The group MUST be a security group, MUST be added as a member group on an" -ForegroundColor White
Write-Host "   Intune role assignment, and members MUST be direct (not nested)." -ForegroundColor White
Write-Host "4. There is no configurable approval timeout or approver threshold." -ForegroundColor White
Write-Host "   Exactly one other admin approves; unprocessed requests expire after 3 days." -ForegroundColor White
Write-Host "5. Submit the policy for approval, then re-open it and select Complete to finalize." -ForegroundColor White

Write-Host "`n=== Phase 2 Expansion ===" -ForegroundColor Yellow
Write-Host "After stabilization, add access policies for the remaining profile types:" -ForegroundColor Yellow
Write-Host "   - Compliance policies" -ForegroundColor Yellow
Write-Host "   - Configuration policies (settings catalog)" -ForegroundColor Yellow
Write-Host "   - Apps" -ForegroundColor Yellow
Write-Host "   - Tenant Configuration (device categories)" -ForegroundColor Yellow
Write-Host "   - Role-based access control (LAST - enabling it early can deadlock RBAC)" -ForegroundColor Yellow
Write-Host "Conditional Access and security baselines are NOT MAA profile types." -ForegroundColor Yellow
# HTH Guide Excerpt: end powershell

#!/usr/bin/env pwsh
# HTH Microsoft Intune Control 5.1: Restrict Remote Wipe Permissions
# Profile: L1 | NIST: CM-7(2)
# https://howtoharden.com/guides/microsoft-intune/#51-restrict-remote-wipe-permissions
#
# Prerequisites:
#   Install-Module Microsoft.Graph.DeviceManagement -Scope CurrentUser
#   Connect-MgGraph -Scopes "DeviceManagementRBAC.ReadWrite.All"

# HTH Guide Excerpt: begin powershell
# --- Create a dedicated Device Recovery Operator role with ONLY wipe permissions ---
Write-Host "=== Creating Device Recovery Operator Role ===" -ForegroundColor Cyan

$recoveryPermissions = @{
    actions = @(
        "Microsoft.Intune_ManagedDevices_Read"
        "Microsoft.Intune_ManagedDevices_Wipe"
        "Microsoft.Intune_ManagedDevices_Retire"
        "Microsoft.Intune_ManagedDevices_FactoryReset"
    )
}

$recoveryRole = @{
    DisplayName     = "HTH Device Recovery Operator"
    Description     = "Can wipe/retire/reset devices. Protected by PIM + Multi-Admin Approval. Created per HTH Intune hardening guide."
    IsBuiltIn       = $false
    RolePermissions = @(@{
        ResourceActions = $recoveryPermissions
    })
}

New-MgDeviceManagementRoleDefinition -BodyParameter $recoveryRole
Write-Host "Created role: HTH Device Recovery Operator" -ForegroundColor Green

# --- Audit existing roles for wipe permissions ---
Write-Host "`n=== Auditing Roles with Wipe Permissions ===" -ForegroundColor Yellow

$allRoles = Get-MgDeviceManagementRoleDefinition
foreach ($role in $allRoles) {
    if ($role.DisplayName -eq "HTH Device Recovery Operator") { continue }
    $perms = $role.RolePermissions.ResourceActions.AllowedResourceActions
    $hasWipe = $perms | Where-Object {
        $_ -match "Wipe|Retire|FactoryReset"
    }
    if ($hasWipe) {
        Write-Warning "Role '$($role.DisplayName)' has destructive permissions: $($hasWipe -join ', ')"
        Write-Host "  -> Remove these permissions from this role" -ForegroundColor Yellow
    }
}

Write-Host "`nEnsure only HTH Device Recovery Operator retains wipe permissions." -ForegroundColor Cyan
Write-Host "Protect this role with PIM (eligible only, 2-hour max, require approval)." -ForegroundColor Cyan
# HTH Guide Excerpt: end powershell

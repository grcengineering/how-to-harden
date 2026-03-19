#!/usr/bin/env pwsh
# HTH Microsoft Intune Control 1.1: Enforce Least-Privilege RBAC Roles
# Profile: L1 | NIST: AC-6(1), AC-6(5)
# https://howtoharden.com/guides/microsoft-intune/#11-enforce-least-privilege-rbac-roles
#
# Prerequisites:
#   Install-Module Microsoft.Graph.DeviceManagement -Scope CurrentUser
#   Connect-MgGraph -Scopes "DeviceManagementRBAC.ReadWrite.All"

# HTH Guide Excerpt: begin powershell
# --- Audit current Intune role assignments ---
Write-Host "=== Auditing Intune RBAC Role Assignments ===" -ForegroundColor Cyan

# List all role assignments and their scope
$roleAssignments = Get-MgDeviceManagementRoleAssignment -ExpandProperty "roleDefinition"
foreach ($assignment in $roleAssignments) {
    $roleName = $assignment.RoleDefinition.DisplayName
    $members  = $assignment.ResourceScopes -join ", "
    Write-Host "Role: $roleName | Scope: $members"
}

# Flag any broad assignments (Intune Administrator via Entra directory role)
Write-Host "`n=== Checking for Broad Entra Directory Role Assignments ===" -ForegroundColor Yellow
$intuneAdmins = Get-MgDirectoryRoleMember -DirectoryRoleId (
    Get-MgDirectoryRole -Filter "displayName eq 'Intune Administrator'" |
    Select-Object -ExpandProperty Id
)
foreach ($admin in $intuneAdmins) {
    Write-Warning "Standing Intune Administrator: $($admin.AdditionalProperties.displayName) ($($admin.Id))"
}

# --- Create a scoped Help Desk role (read-only, no destructive actions) ---
Write-Host "`n=== Creating Scoped Help Desk Role ===" -ForegroundColor Cyan

$helpDeskPermissions = @{
    actions = @(
        "Microsoft.Intune_Organization_Read"
        "Microsoft.Intune_ManagedDevices_Read"
        "Microsoft.Intune_ManagedApps_Read"
        "Microsoft.Intune_RemoteTasks_RemoteAssistance"
    )
    # Explicitly exclude destructive actions
    notActions = @(
        "Microsoft.Intune_ManagedDevices_Delete"
        "Microsoft.Intune_ManagedDevices_Wipe"
        "Microsoft.Intune_ManagedDevices_Retire"
        "Microsoft.Intune_ManagedDevices_FactoryReset"
    )
}

$params = @{
    DisplayName     = "HTH Help Desk Operator"
    Description     = "Read-only device access with remote assistance. No wipe, retire, or delete."
    IsBuiltIn       = $false
    RolePermissions = @(@{
        ResourceActions = $helpDeskPermissions
    })
}

New-MgDeviceManagementRoleDefinition -BodyParameter $params
Write-Host "Created role: HTH Help Desk Operator" -ForegroundColor Green
# HTH Guide Excerpt: end powershell

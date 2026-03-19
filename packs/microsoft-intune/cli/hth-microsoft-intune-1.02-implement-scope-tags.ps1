#!/usr/bin/env pwsh
# HTH Microsoft Intune Control 1.2: Implement Scope Tags for Resource Isolation
# Profile: L2 | NIST: AC-6(3)
# https://howtoharden.com/guides/microsoft-intune/#12-implement-scope-tags-for-resource-isolation
#
# Prerequisites:
#   Install-Module Microsoft.Graph.DeviceManagement -Scope CurrentUser
#   Connect-MgGraph -Scopes "DeviceManagementRBAC.ReadWrite.All"

# HTH Guide Excerpt: begin powershell
# --- Create scope tags for organizational boundaries ---
Write-Host "=== Creating Intune Scope Tags ===" -ForegroundColor Cyan

$scopeTags = @(
    @{ DisplayName = "North-America"; Description = "Devices and policies for NA region" }
    @{ DisplayName = "EMEA";          Description = "Devices and policies for EMEA region" }
    @{ DisplayName = "APAC";          Description = "Devices and policies for APAC region" }
    @{ DisplayName = "Manufacturing"; Description = "Manufacturing floor devices" }
    @{ DisplayName = "Corporate-IT";  Description = "Corporate office endpoints" }
)

foreach ($tag in $scopeTags) {
    $existing = Get-MgDeviceManagementRoleScopeTag -Filter "displayName eq '$($tag.DisplayName)'" -ErrorAction SilentlyContinue
    if ($existing) {
        Write-Host "Scope tag already exists: $($tag.DisplayName)" -ForegroundColor Yellow
    } else {
        New-MgDeviceManagementRoleScopeTag -DisplayName $tag.DisplayName -Description $tag.Description
        Write-Host "Created scope tag: $($tag.DisplayName)" -ForegroundColor Green
    }
}

# --- Verify scope tag assignments on existing role assignments ---
Write-Host "`n=== Auditing Role Assignments Without Scope Tags ===" -ForegroundColor Yellow
$assignments = Get-MgDeviceManagementRoleAssignment
foreach ($assignment in $assignments) {
    if (-not $assignment.ScopeMembers -or $assignment.ScopeMembers.Count -eq 0) {
        Write-Warning "Role assignment '$($assignment.DisplayName)' has NO scope tags (global scope)"
    }
}
# HTH Guide Excerpt: end powershell

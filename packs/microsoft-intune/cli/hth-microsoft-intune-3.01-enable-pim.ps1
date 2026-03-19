#!/usr/bin/env pwsh
# HTH Microsoft Intune Control 3.1: Enable PIM for Intune Roles
# Profile: L1 | NIST: AC-2(1), AC-6(2)
# https://howtoharden.com/guides/microsoft-intune/#31-enable-privileged-identity-management-pim-for-intune-roles
#
# Prerequisites:
#   Install-Module Microsoft.Graph.Identity.Governance -Scope CurrentUser
#   Connect-MgGraph -Scopes "RoleManagement.ReadWrite.Directory","PrivilegedAccess.ReadWrite.AzureADGroup"

# HTH Guide Excerpt: begin powershell
# --- Configure PIM settings for Intune Administrator role ---
Write-Host "=== Configuring PIM for Intune Administrator Role ===" -ForegroundColor Cyan

$intuneAdminRoleId = "3a2c62db-5318-420d-8d74-23affee5d9d5"

# Get the PIM role management policy for Intune Administrator
$policies = Get-MgPolicyRoleManagementPolicy -Filter "scopeId eq '/' and scopeType eq 'DirectoryRole'"
$intunePolicy = $policies | Where-Object {
    $_.RoleDefinitionId -eq $intuneAdminRoleId
}

if ($intunePolicy) {
    $policyId = $intunePolicy.Id

    # Update activation rules: max 4 hours, require justification and MFA
    $rules = Get-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $policyId

    # Set maximum activation duration to 4 hours
    $expirationRule = $rules | Where-Object { $_.Id -eq "Expiration_EndUser_Assignment" }
    if ($expirationRule) {
        Update-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $policyId `
            -UnifiedRoleManagementPolicyRuleId $expirationRule.Id `
            -BodyParameter @{
                "@odata.type"       = "#microsoft.graph.unifiedRoleManagementPolicyExpirationRule"
                id                  = $expirationRule.Id
                isExpirationRequired = $true
                maximumDuration     = "PT4H"
                target              = @{
                    caller     = "EndUser"
                    operations = @("All")
                    level      = "Assignment"
                }
            }
        Write-Host "Set max activation duration: 4 hours" -ForegroundColor Green
    }

    # Require justification on activation
    $enablementRule = $rules | Where-Object { $_.Id -eq "Enablement_EndUser_Assignment" }
    if ($enablementRule) {
        Update-MgPolicyRoleManagementPolicyRule -UnifiedRoleManagementPolicyId $policyId `
            -UnifiedRoleManagementPolicyRuleId $enablementRule.Id `
            -BodyParameter @{
                "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyEnablementRule"
                id            = $enablementRule.Id
                enabledRules  = @("Justification", "MultiFactorAuthentication")
                target        = @{
                    caller     = "EndUser"
                    operations = @("All")
                    level      = "Assignment"
                }
            }
        Write-Host "Enabled: Require justification + MFA on activation" -ForegroundColor Green
    }

    # Require approval for activation
    $approvalRule = $rules | Where-Object { $_.Id -eq "Approval_EndUser_Assignment" }
    if ($approvalRule) {
        Write-Host "Configure approval settings in Entra admin center > PIM > Intune Administrator > Settings > Require approval" -ForegroundColor Yellow
        Write-Host "Approvers must be designated security team members" -ForegroundColor Yellow
    }

    Write-Host "`nPIM configured for Intune Administrator role" -ForegroundColor Green
} else {
    Write-Warning "Could not find PIM policy for Intune Administrator role"
}

# --- Convert active assignments to eligible ---
Write-Host "`n=== Converting Active Assignments to Eligible ===" -ForegroundColor Cyan

$activeAssignments = Get-MgRoleManagementDirectoryRoleAssignment -Filter "roleDefinitionId eq '$intuneAdminRoleId'"
foreach ($assignment in $activeAssignments) {
    $principalName = (Get-MgUser -UserId $assignment.PrincipalId -ErrorAction SilentlyContinue).DisplayName
    Write-Warning "Active assignment found: $principalName ($($assignment.PrincipalId))"
    Write-Host "  -> Convert to Eligible in PIM > Intune Administrator > Assignments" -ForegroundColor Yellow
}

if ($activeAssignments.Count -eq 0) {
    Write-Host "No standing active Intune Administrator assignments found" -ForegroundColor Green
}
# HTH Guide Excerpt: end powershell

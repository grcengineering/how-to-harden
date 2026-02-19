# =============================================================================
# HTH Microsoft Entra ID Control 3.01: Enable Just-In-Time Access for Admin Roles
# Profile: L2 | NIST: AC-2(7), AC-6(1)
# Source: https://howtoharden.com/guides/microsoft-entra-id/#31-enable-just-in-time-access-for-admin-roles
# =============================================================================

# HTH Guide Excerpt: begin cli-configure-pim

# Connect with PIM permissions
Connect-MgGraph -Scopes "RoleManagement.ReadWrite.Directory", "RoleEligibilitySchedule.ReadWrite.Directory"

# Get role definitions
$globalAdminRole = Get-MgRoleManagementDirectoryRoleDefinition -Filter "displayName eq 'Global Administrator'"

# Create eligible assignment (convert permanent to eligible)
$params = @{
    action = "adminAssign"
    justification = "Converting to PIM eligible assignment"
    roleDefinitionId = $globalAdminRole.Id
    directoryScopeId = "/"
    principalId = "USER_OBJECT_ID"
    scheduleInfo = @{
        startDateTime = (Get-Date).ToUniversalTime().ToString("o")
        expiration = @{
            type = "afterDuration"
            duration = "P365D"  # 1 year eligibility
        }
    }
}

New-MgRoleManagementDirectoryRoleEligibilityScheduleRequest -BodyParameter $params

# Configure role settings (requires beta endpoint)
# Use Microsoft Entra admin center for full settings configuration

# HTH Guide Excerpt: end cli-configure-pim

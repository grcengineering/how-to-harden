# =============================================================================
# HTH Microsoft 365 Control 1.3: Implement Privileged Identity Management (PIM)
# Profile: L2 | NIST: AC-2(7), AC-6(1)
# Source: https://howtoharden.com/guides/microsoft-365/#13-implement-privileged-identity-management-pim
# =============================================================================

# HTH Guide Excerpt: begin cli-configure-pim

# Connect with PIM permissions
Connect-MgGraph -Scopes "RoleManagement.ReadWrite.Directory"

# Get Global Administrator role
$role = Get-MgRoleManagementDirectoryRoleDefinition -Filter "displayName eq 'Global Administrator'"

# Create eligible assignment (replace user ID)
$params = @{
    action = "adminAssign"
    justification = "Initial PIM setup"
    roleDefinitionId = $role.Id
    directoryScopeId = "/"
    principalId = "USER_OBJECT_ID"
    scheduleInfo = @{
        startDateTime = (Get-Date).ToUniversalTime().ToString("o")
        expiration = @{
            type = "afterDuration"
            duration = "P365D"
        }
    }
}

New-MgRoleManagementDirectoryRoleEligibilityScheduleRequest -BodyParameter $params

# HTH Guide Excerpt: end cli-configure-pim

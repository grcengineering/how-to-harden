# =============================================================================
# HTH Microsoft Entra ID Control 1.02: Configure Emergency Access (Break-Glass) Accounts
# Profile: L1 | NIST: AC-2
# Source: https://howtoharden.com/guides/microsoft-entra-id/#12-configure-emergency-access-break-glass-accounts
# =============================================================================

# HTH Guide Excerpt: begin cli-emergency-access

# Create emergency access account
$passwordProfile = @{
    password = [System.Web.Security.Membership]::GeneratePassword(64, 10)
    forceChangePasswordNextSignIn = $false
}

$params = @{
    accountEnabled = $true
    displayName = "Emergency Admin 01"
    mailNickname = "emergency-admin-01"
    userPrincipalName = "emergency-admin-01@yourdomain.onmicrosoft.com"
    passwordProfile = $passwordProfile
}

$user = New-MgUser -BodyParameter $params

# Assign Global Administrator role
$roleId = (Get-MgRoleManagementDirectoryRoleDefinition -Filter "displayName eq 'Global Administrator'").Id

New-MgRoleManagementDirectoryRoleAssignment -BodyParameter @{
    "@odata.type" = "#microsoft.graph.unifiedRoleAssignment"
    roleDefinitionId = $roleId
    principalId = $user.Id
    directoryScopeId = "/"
}

# Output password (store securely)
Write-Host "Password: $($passwordProfile.password)" -ForegroundColor Yellow
Write-Host "STORE THIS SECURELY AND DELETE FROM TERMINAL HISTORY"

# HTH Guide Excerpt: end cli-emergency-access

# =============================================================================
# HTH Microsoft 365 Control 1.1: Enforce Phishing-Resistant MFA for All Users
# Profile: L1 | NIST: IA-2(1), IA-2(6)
# Source: https://howtoharden.com/guides/microsoft-365/#11-enforce-phishing-resistant-mfa-for-all-users
# =============================================================================

# HTH Guide Excerpt: begin cli-enforce-mfa

# Install Microsoft Graph PowerShell module
Install-Module Microsoft.Graph -Scope CurrentUser

# Connect with required permissions
Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess", "Application.Read.All"

# Create Conditional Access policy requiring MFA
$params = @{
    displayName = "Require MFA for all users"
    state = "enabled"
    conditions = @{
        users = @{
            includeUsers = @("All")
            excludeUsers = @("BREAK_GLASS_ACCOUNT_ID")
        }
        applications = @{
            includeApplications = @("All")
        }
    }
    grantControls = @{
        operator = "OR"
        builtInControls = @("mfa")
    }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $params

# HTH Guide Excerpt: end cli-enforce-mfa

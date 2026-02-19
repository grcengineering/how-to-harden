# =============================================================================
# HTH Microsoft 365 Control 3.1: Restrict User Consent to Applications
# Profile: L1 | NIST: AC-3, CM-7
# Source: https://howtoharden.com/guides/microsoft-365/#31-restrict-user-consent-to-applications
# =============================================================================

# HTH Guide Excerpt: begin cli-restrict-consent

# Disable user consent via Graph API
$params = @{
    defaultUserRolePermissions = @{
        permissionGrantPoliciesAssigned = @()
    }
}

Update-MgPolicyAuthorizationPolicy -BodyParameter $params

# HTH Guide Excerpt: end cli-restrict-consent

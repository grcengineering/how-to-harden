# =============================================================================
# HTH Microsoft Entra ID Control 4.01: Restrict User Consent to Applications
# Profile: L1 | NIST: AC-3, CM-7
# Source: https://howtoharden.com/guides/microsoft-entra-id/#41-restrict-user-consent-to-applications
# =============================================================================

# HTH Guide Excerpt: begin cli-restrict-consent

# Disable user consent
$params = @{
    defaultUserRolePermissions = @{
        permissionGrantPoliciesAssigned = @()
    }
}

Update-MgPolicyAuthorizationPolicy -BodyParameter $params

# Note: Configure admin consent workflow through admin center

# HTH Guide Excerpt: end cli-restrict-consent

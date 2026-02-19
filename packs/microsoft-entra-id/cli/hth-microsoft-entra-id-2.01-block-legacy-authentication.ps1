# =============================================================================
# HTH Microsoft Entra ID Control 2.01: Block Legacy Authentication
# Profile: L1 | NIST: IA-2, AC-17
# Source: https://howtoharden.com/guides/microsoft-entra-id/#21-block-legacy-authentication
# =============================================================================

# HTH Guide Excerpt: begin cli-block-legacy-auth

# Create policy to block legacy auth
$params = @{
    displayName = "Block legacy authentication"
    state = "enabled"
    conditions = @{
        users = @{
            includeUsers = @("All")
            excludeUsers = @("EMERGENCY_ACCOUNT_1_ID", "EMERGENCY_ACCOUNT_2_ID")
        }
        applications = @{
            includeApplications = @("All")
        }
        clientAppTypes = @("exchangeActiveSync", "other")
    }
    grantControls = @{
        operator = "OR"
        builtInControls = @("block")
    }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $params

# HTH Guide Excerpt: end cli-block-legacy-auth

# =============================================================================
# HTH Microsoft Entra ID Control 1.01: Enforce Phishing-Resistant MFA
# Profile: L1 | NIST: IA-2(1), IA-2(6)
# Source: https://howtoharden.com/guides/microsoft-entra-id/#11-enforce-phishing-resistant-mfa
# =============================================================================

# HTH Guide Excerpt: begin cli-enforce-mfa

# Connect to Microsoft Graph
Connect-MgGraph -Scopes "Policy.ReadWrite.AuthenticationMethod"

# Get current authentication method policy
$policy = Get-MgPolicyAuthenticationMethodPolicy

# Enable FIDO2
$fido2Config = @{
    id = "fido2"
    state = "enabled"
    includeTargets = @(
        @{
            targetType = "group"
            id = "all_users"
        }
    )
}

Update-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration `
    -AuthenticationMethodConfigurationId "fido2" `
    -BodyParameter $fido2Config

# Configure Microsoft Authenticator with number matching
$authAppConfig = @{
    id = "microsoftAuthenticator"
    state = "enabled"
    featureSettings = @{
        displayAppInformationRequiredState = @{
            state = "enabled"
        }
        displayLocationInformationRequiredState = @{
            state = "enabled"
        }
        numberMatchingRequiredState = @{
            state = "enabled"
        }
    }
}

Update-MgPolicyAuthenticationMethodPolicyAuthenticationMethodConfiguration `
    -AuthenticationMethodConfigurationId "microsoftAuthenticator" `
    -BodyParameter $authAppConfig

# HTH Guide Excerpt: end cli-enforce-mfa

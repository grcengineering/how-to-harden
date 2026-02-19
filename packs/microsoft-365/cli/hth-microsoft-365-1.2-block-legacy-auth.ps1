# =============================================================================
# HTH Microsoft 365 Control 1.2: Block Legacy Authentication Protocols
# Profile: L1 | NIST: IA-2, AC-17
# Source: https://howtoharden.com/guides/microsoft-365/#12-block-legacy-authentication-protocols
# =============================================================================

# HTH Guide Excerpt: begin cli-disable-smtp-auth

# Connect to Exchange Online
Connect-ExchangeOnline

# Disable SMTP AUTH for all mailboxes
Get-Mailbox -ResultSize Unlimited | Set-CASMailbox -SmtpClientAuthenticationDisabled $true

# Verify
Get-CASMailbox -ResultSize Unlimited | Select-Object DisplayName, SmtpClientAuthenticationDisabled

# HTH Guide Excerpt: end cli-disable-smtp-auth

# HTH Guide Excerpt: begin cli-block-legacy-ca

# Create Conditional Access policy to block legacy authentication via Graph
$params = @{
    displayName = "Block legacy authentication"
    state = "enabled"
    conditions = @{
        users = @{
            includeUsers = @("All")
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

# HTH Guide Excerpt: end cli-block-legacy-ca

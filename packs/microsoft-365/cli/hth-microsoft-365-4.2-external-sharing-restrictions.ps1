# =============================================================================
# HTH Microsoft 365 Control 4.2: Configure External Sharing Restrictions
# Profile: L1 | NIST: AC-3, AC-22
# Source: https://howtoharden.com/guides/microsoft-365/#42-configure-external-sharing-restrictions
# =============================================================================

# HTH Guide Excerpt: begin cli-sharing-restrictions

# Connect to SharePoint Online
Connect-SPOService -Url "https://yourdomain-admin.sharepoint.com"

# Set tenant-level sharing restrictions
Set-SPOTenant -SharingCapability ExistingExternalUserSharingOnly
Set-SPOTenant -RequireAcceptingAccountMatchInvitedAccount $true
Set-SPOTenant -PreventExternalUsersFromResharing $true

# HTH Guide Excerpt: end cli-sharing-restrictions

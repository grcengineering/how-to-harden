# =============================================================================
# HTH Microsoft 365 Control 2.1: Configure Trusted Locations and Named Locations
# Profile: L2 | NIST: AC-4, SC-7
# Source: https://howtoharden.com/guides/microsoft-365/#21-configure-trusted-locations-and-named-locations
# =============================================================================

# HTH Guide Excerpt: begin cli-named-locations

# Create named location via Graph API
$params = @{
    "@odata.type" = "#microsoft.graph.ipNamedLocation"
    displayName = "Corporate Network"
    isTrusted = $true
    ipRanges = @(
        @{
            "@odata.type" = "#microsoft.graph.iPv4CidrRange"
            cidrAddress = "203.0.113.0/24"
        }
    )
}

New-MgIdentityConditionalAccessNamedLocation -BodyParameter $params

# HTH Guide Excerpt: end cli-named-locations

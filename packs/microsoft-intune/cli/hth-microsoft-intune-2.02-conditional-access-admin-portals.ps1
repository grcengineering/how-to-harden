#!/usr/bin/env pwsh
# HTH Microsoft Intune Control 2.2: Enforce Conditional Access for Admin Portals
# Profile: L1 | NIST: AC-7, AC-11
# https://howtoharden.com/guides/microsoft-intune/#22-enforce-conditional-access-for-admin-portals
#
# Prerequisites:
#   Install-Module Microsoft.Graph.Identity.SignIns -Scope CurrentUser
#   Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess"

# HTH Guide Excerpt: begin powershell
# --- Create CA policy requiring compliant device for admin portal access ---
Write-Host "=== Creating CA Policy: Compliant Device for Admin Portals ===" -ForegroundColor Cyan

$intuneAdminRoleId   = "3a2c62db-5318-420d-8d74-23affee5d9d5"
$globalAdminRoleId   = "62e90394-69f5-4237-9190-012177145e10"
$securityAdminRoleId = "194ae4cb-b126-40b2-bd5b-6091b380977d"

# Microsoft Admin Portals service principal
$adminPortalsAppId = "c44b4083-3bb0-49c1-b47d-974e53cbdf3c"
$intuneAppId       = "0000000a-0000-0000-c000-000000000000"
$graphAppId        = "00000003-0000-0000-c000-000000000000"

$phishResistantStrengthId = "00000000-0000-0000-0000-000000000004"

$compliancePolicy = @{
    DisplayName = "HTH-AdminPortal-ComplianceRequired"
    State       = "enabled"
    Conditions  = @{
        Users = @{
            IncludeRoles = @($intuneAdminRoleId, $globalAdminRoleId, $securityAdminRoleId)
        }
        Applications = @{
            IncludeApplications = @($adminPortalsAppId, $intuneAppId, $graphAppId)
        }
        ClientAppTypes = @("browser", "mobileAppsAndDesktopClients")
    }
    GrantControls = @{
        Operator        = "AND"
        BuiltInControls = @("compliantDevice")
        AuthenticationStrength = @{
            Id = $phishResistantStrengthId
        }
    }
    SessionControls = @{
        SignInFrequency = @{
            Value     = 1
            Type      = "hours"
            IsEnabled = $true
        }
    }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $compliancePolicy
Write-Host "Created CA policy: HTH-AdminPortal-ComplianceRequired" -ForegroundColor Green

# --- Block legacy authentication for admin accounts ---
Write-Host "`n=== Creating CA Policy: Block Legacy Auth for Admins ===" -ForegroundColor Cyan

$blockLegacyPolicy = @{
    DisplayName = "HTH-BlockLegacyAuth-Admins"
    State       = "enabled"
    Conditions  = @{
        Users = @{
            IncludeRoles = @($intuneAdminRoleId, $globalAdminRoleId, $securityAdminRoleId)
        }
        Applications = @{
            IncludeApplications = @("All")
        }
        ClientAppTypes = @("exchangeActiveSync", "other")
    }
    GrantControls = @{
        Operator        = "OR"
        BuiltInControls = @("block")
    }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $blockLegacyPolicy
Write-Host "Created CA policy: HTH-BlockLegacyAuth-Admins" -ForegroundColor Green
# HTH Guide Excerpt: end powershell

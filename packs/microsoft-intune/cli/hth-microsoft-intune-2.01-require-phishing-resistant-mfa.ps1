#!/usr/bin/env pwsh
# HTH Microsoft Intune Control 2.1: Require Phishing-Resistant MFA for All Intune Admins
# Profile: L1 | NIST: IA-2(1), IA-2(6)
# https://howtoharden.com/guides/microsoft-intune/#21-require-phishing-resistant-mfa-for-all-intune-admins
#
# Prerequisites:
#   Install-Module Microsoft.Graph.Identity.SignIns -Scope CurrentUser
#   Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess","Policy.Read.All"

# HTH Guide Excerpt: begin powershell
# --- Create Conditional Access policy requiring phishing-resistant MFA for Intune admins ---
Write-Host "=== Creating Conditional Access Policy: Phishing-Resistant MFA ===" -ForegroundColor Cyan

# Intune Administrator role template ID
$intuneAdminRoleId   = "3a2c62db-5318-420d-8d74-23affee5d9d5"
# Global Administrator role template ID
$globalAdminRoleId   = "62e90394-69f5-4237-9190-012177145e10"
# Security Administrator role template ID
$securityAdminRoleId = "194ae4cb-b126-40b2-bd5b-6091b380977d"

# Microsoft Intune app ID
$intuneAppId         = "0000000a-0000-0000-c000-000000000000"
# Microsoft Graph app ID
$graphAppId          = "00000003-0000-0000-c000-000000000000"

# Built-in phishing-resistant authentication strength ID
$phishResistantStrengthId = "00000000-0000-0000-0000-000000000004"

$caPolicy = @{
    DisplayName = "HTH-Require-PhishResistant-MFA-IntuneAdmins"
    State       = "enabled"
    Conditions  = @{
        Users = @{
            IncludeRoles = @($intuneAdminRoleId, $globalAdminRoleId, $securityAdminRoleId)
        }
        Applications = @{
            IncludeApplications = @($intuneAppId, $graphAppId)
        }
    }
    GrantControls = @{
        Operator                      = "OR"
        AuthenticationStrength = @{
            Id = $phishResistantStrengthId
        }
    }
    SessionControls = @{
        SignInFrequency = @{
            Value     = 1
            Type      = "hours"
            IsEnabled = $true
            AuthenticationType = "primaryAndSecondaryAuthentication"
        }
    }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $caPolicy
Write-Host "Created CA policy: HTH-Require-PhishResistant-MFA-IntuneAdmins" -ForegroundColor Green
# HTH Guide Excerpt: end powershell

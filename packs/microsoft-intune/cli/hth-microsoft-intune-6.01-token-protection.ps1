#!/usr/bin/env pwsh
# HTH Microsoft Intune Control 6.1: Enable Token Protection and Continuous Access Evaluation
# Profile: L2 | NIST: IA-11
# https://howtoharden.com/guides/microsoft-intune/#61-enable-token-protection-and-continuous-access-evaluation
#
# Prerequisites:
#   Install-Module Microsoft.Graph.Identity.SignIns -Scope CurrentUser
#   Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess"

# HTH Guide Excerpt: begin powershell
# --- Enable Continuous Access Evaluation (CAE) ---
Write-Host "=== Enabling Continuous Access Evaluation ===" -ForegroundColor Cyan

# CAE is enabled tenant-wide via Conditional Access settings
# Strict enforcement mode ensures near-real-time token revocation
Write-Host "Navigate to: Entra admin center > Protection > Conditional Access > Continuous access evaluation" -ForegroundColor Yellow
Write-Host "Set to: Strictly enforce location policies" -ForegroundColor Yellow

# --- Create token protection CA policy for admin sessions ---
Write-Host "`n=== Creating Token Protection CA Policy ===" -ForegroundColor Cyan

$intuneAdminRoleId   = "3a2c62db-5318-420d-8d74-23affee5d9d5"
$globalAdminRoleId   = "62e90394-69f5-4237-9190-012177145e10"
$securityAdminRoleId = "194ae4cb-b126-40b2-bd5b-6091b380977d"

$tokenProtectionPolicy = @{
    DisplayName = "HTH-TokenProtection-Admins"
    State       = "enabled"
    Conditions  = @{
        Users = @{
            IncludeRoles = @($intuneAdminRoleId, $globalAdminRoleId, $securityAdminRoleId)
        }
        Applications = @{
            IncludeApplications = @("All")
        }
    }
    SessionControls = @{
        SignInTokenProtection = @{
            IsEnabled                     = $true
            TokenProtectionEnforcementMode = "enforced"
        }
    }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $tokenProtectionPolicy
Write-Host "Created CA policy: HTH-TokenProtection-Admins" -ForegroundColor Green
Write-Host "Admin tokens are now device-bound and protected against theft/replay" -ForegroundColor Green
# HTH Guide Excerpt: end powershell

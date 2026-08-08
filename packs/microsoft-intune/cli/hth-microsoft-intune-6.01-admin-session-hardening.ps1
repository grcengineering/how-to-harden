#!/usr/bin/env pwsh
# HTH Microsoft Intune Control 6.1: Harden Admin Sessions Against Token Replay
# Profile: L2 | CIS Controls: 6.5 | NIST 800-53: IA-11
# https://howtoharden.com/guides/microsoft-intune/#61-harden-admin-sessions-against-token-replay
#
# Scope of this pack:
#   Step 1 — report tenant Continuous Access Evaluation state (Graph exposes CAE read-only)
#   Step 3 — create the authentication context, its Conditional Access policy, and bind it to PIM role activation
#   Step 4 — create the risk-based interactive reauthentication policy (HTH-AdminRisk-Reauth)
#   Step 2 (require compliant device) is already automated by the Section 2.2 pack — not duplicated here.
#   Step 5 (compliant network, optional L3) is ClickOps-only — see the guide.
#
# Verified against Microsoft Graph documentation:
#   authenticationContextClassReference (ids c1-c25, isAvailable)
#     https://learn.microsoft.com/en-us/graph/api/resources/authenticationcontextclassreference
#   Create or update authenticationContextClassReference (PATCH upsert, Update-Mg... cmdlet)
#     https://learn.microsoft.com/en-us/graph/api/authenticationcontextclassreference-update
#   conditionalAccessApplications.includeAuthenticationContextClassReferences (beta only)
#     https://learn.microsoft.com/en-us/graph/api/resources/conditionalaccessapplications?view=graph-rest-beta
#   conditionalAccessGrantControls.authenticationStrength relationship
#     https://learn.microsoft.com/en-us/graph/api/resources/conditionalaccessgrantcontrols
#   Built-in "Phishing resistant MFA" strength id 00000000-0000-0000-0000-000000000004
#     https://learn.microsoft.com/en-us/graph/api/authenticationstrengthroot-list-policies
#   signInFrequencySessionControl (frequencyInterval everyTime, authenticationType)
#     https://learn.microsoft.com/en-us/graph/api/resources/signinfrequencysessioncontrol
#   unifiedRoleManagementPolicyAuthenticationContextRule (isEnabled, claimValue)
#     https://learn.microsoft.com/en-us/graph/api/resources/unifiedrolemanagementpolicyauthenticationcontextrule
#   PIM rule id AuthenticationContext_EndUser_Assignment
#     https://learn.microsoft.com/en-us/graph/identity-governance-pim-rules-overview
#   roleManagementPolicyAssignments filter + Update-MgPolicyRoleManagementPolicyRule
#     https://learn.microsoft.com/en-us/graph/how-to-pim-update-rules
#   continuousAccessEvaluationPolicy (read-only)
#     https://learn.microsoft.com/en-us/graph/api/continuousaccessevaluationpolicy-get
#
# Prerequisites:
#   Install-Module Microsoft.Graph.Identity.SignIns -Scope CurrentUser
#   Install-Module Microsoft.Graph.Beta.Identity.SignIns -Scope CurrentUser
#   Install-Module Microsoft.Graph.Identity.Governance -Scope CurrentUser
#   Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess","Policy.Read.All",
#                           "AuthenticationContext.ReadWrite.All",
#                           "RoleManagement.Read.Directory","RoleManagementPolicy.ReadWrite.Directory"

# HTH Guide Excerpt: begin powershell
# --- Shared identifiers ---
# Directory role template IDs
$intuneAdminRoleId   = "3a2c62db-5318-420d-8d74-23affee5d9d5"  # Intune Administrator
$globalAdminRoleId   = "62e90394-69f5-4237-9190-012177145e10"  # Global Administrator
$securityAdminRoleId = "194ae4cb-b126-40b2-bd5b-6091b380977d"  # Security Administrator

# Resource app IDs
$intuneAppId = "0000000a-0000-0000-c000-000000000000"          # Microsoft Intune
$graphAppId  = "00000003-0000-0000-c000-000000000000"          # Microsoft Graph

# Built-in "Phishing resistant MFA" authentication strength
$phishResistantStrengthId = "00000000-0000-0000-0000-000000000004"

# Authentication context claim used for Intune destructive operations
$authContextId = "c1"

# --- Step 1: Report Continuous Access Evaluation state ---
# CAE is exposed read-only in Microsoft Graph (every property except `migrate` is
# Read-only), so enabling it remains a portal action. Report the current state.
Write-Host "=== Continuous Access Evaluation ===" -ForegroundColor Cyan

$cae = Invoke-MgGraphRequest -Method GET `
    -Uri "https://graph.microsoft.com/beta/identity/continuousAccessEvaluationPolicy"

if ($cae.isEnabled) {
    Write-Host "CAE is enabled tenant-wide." -ForegroundColor Green
} else {
    Write-Warning "CAE is NOT enabled. Enable it in the Microsoft Entra admin center: Protection > Conditional Access > Continuous access evaluation."
}

# --- Step 3a: Create (or update) the authentication context ---
# PATCH is an upsert: it creates the object when the id is unused, otherwise updates it.
Write-Host "`n=== Creating authentication context $authContextId ===" -ForegroundColor Cyan

$authContext = @{
    displayName = "Intune destructive operations"
    description = "Step-up authentication required for privileged Intune operations and role activation"
    isAvailable = $true
}

Update-MgIdentityConditionalAccessAuthenticationContextClassReference `
    -AuthenticationContextClassReferenceId $authContextId `
    -BodyParameter $authContext

Write-Host "Published authentication context $authContextId" -ForegroundColor Green

# --- Step 3b: Conditional Access policy bound to the authentication context ---
# includeAuthenticationContextClassReferences is only available on the beta endpoint,
# so this policy is created with the beta module.
Write-Host "`n=== Creating CA policy: HTH-AuthContext-StepUp ===" -ForegroundColor Cyan

$stepUpPolicy = @{
    displayName = "HTH-AuthContext-StepUp"
    state       = "enabled"
    conditions  = @{
        users = @{
            includeRoles = @($intuneAdminRoleId, $globalAdminRoleId, $securityAdminRoleId)
        }
        applications = @{
            includeAuthenticationContextClassReferences = @($authContextId)
        }
    }
    grantControls = @{
        operator               = "OR"
        authenticationStrength = @{
            id = $phishResistantStrengthId
        }
    }
    sessionControls = @{
        signInFrequency = @{
            isEnabled          = $true
            frequencyInterval  = "everyTime"
            authenticationType = "primaryAndSecondaryAuthentication"
        }
    }
}

New-MgBetaIdentityConditionalAccessPolicy -BodyParameter $stepUpPolicy
Write-Host "Created CA policy: HTH-AuthContext-StepUp" -ForegroundColor Green

# --- Step 3c: Bind the authentication context to PIM role activation ---
# Rule AuthenticationContext_EndUser_Assignment maps to the Entra admin center setting
# "On activation, require Microsoft Entra Conditional Access authentication context".
Write-Host "`n=== Binding authentication context to PIM role activation ===" -ForegroundColor Cyan

$rolesToBind = @("Intune Administrator", "Device Recovery Operator")

foreach ($roleName in $rolesToBind) {
    $roleDefinition = Get-MgRoleManagementDirectoryRoleDefinition -Filter "displayName eq '$roleName'"

    if (-not $roleDefinition) {
        Write-Warning "Role '$roleName' not found in this tenant - skipping."
        continue
    }

    $assignment = Get-MgPolicyRoleManagementPolicyAssignment `
        -Filter "scopeId eq '/' and scopeType eq 'DirectoryRole' and roleDefinitionId eq '$($roleDefinition.Id)'"

    if (-not $assignment) {
        Write-Warning "No PIM role management policy assigned to '$roleName' - skipping."
        continue
    }

    $rule = @{
        "@odata.type" = "#microsoft.graph.unifiedRoleManagementPolicyAuthenticationContextRule"
        id            = "AuthenticationContext_EndUser_Assignment"
        isEnabled     = $true
        claimValue    = $authContextId
        target        = @{
            caller              = "EndUser"
            operations          = @("All")
            level               = "Assignment"
            inheritableSettings = @()
            enforcedSettings    = @()
        }
    }

    Update-MgPolicyRoleManagementPolicyRule `
        -UnifiedRoleManagementPolicyId $assignment.PolicyId `
        -UnifiedRoleManagementPolicyRuleId "AuthenticationContext_EndUser_Assignment" `
        -BodyParameter $rule

    Write-Host "Bound authentication context $authContextId to '$roleName' activation" -ForegroundColor Green
}

# --- Step 4: Risk-based interactive reauthentication ---
# Sign-in risk conditions require Microsoft Entra ID P2.
Write-Host "`n=== Creating CA policy: HTH-AdminRisk-Reauth ===" -ForegroundColor Cyan

$riskReauthPolicy = @{
    DisplayName = "HTH-AdminRisk-Reauth"
    State       = "enabled"
    Conditions  = @{
        SignInRiskLevels = @("high", "medium")
        Users = @{
            IncludeRoles = @($intuneAdminRoleId, $globalAdminRoleId, $securityAdminRoleId)
        }
        Applications = @{
            IncludeApplications = @("MicrosoftAdminPortals", $intuneAppId, $graphAppId)
        }
    }
    GrantControls = @{
        Operator               = "OR"
        AuthenticationStrength = @{
            Id = $phishResistantStrengthId
        }
    }
    SessionControls = @{
        SignInFrequency = @{
            IsEnabled          = $true
            FrequencyInterval  = "everyTime"
            AuthenticationType = "primaryAndSecondaryAuthentication"
        }
    }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $riskReauthPolicy
Write-Host "Created CA policy: HTH-AdminRisk-Reauth" -ForegroundColor Green
# HTH Guide Excerpt: end powershell

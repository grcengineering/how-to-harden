---
layout: guide
title: "Microsoft Entra ID Hardening Guide"
vendor: "Microsoft"
slug: "microsoft-entra-id"
tier: "1"
category: "Identity"
description: "Identity Provider hardening for Azure Active Directory, Conditional Access, PIM, and Zero Trust"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Microsoft Entra ID (formerly Azure Active Directory) is the cloud identity platform for over **720 million users** across enterprises worldwide. As the authentication backbone for Microsoft 365, Azure, and thousands of SaaS applications, Entra ID security is foundational to Zero Trust architecture. The **January 2024 Midnight Blizzard breach** of Microsoft's corporate environment demonstrated how a single misconfigured test account without MFA can cascade into widespread compromise.

### Intended Audience
- Security engineers managing identity infrastructure
- IT administrators configuring Entra ID tenants
- GRC professionals assessing IAM compliance
- Third-party risk managers evaluating SSO integrations

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Microsoft Entra ID security configurations including authentication policies, Conditional Access, Privileged Identity Management, application security, and Zero Trust identity architecture. Microsoft 365 and Azure infrastructure are covered in separate guides.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Conditional Access](#2-conditional-access)
3. [Privileged Identity Management](#3-privileged-identity-management)
4. [Application Security](#4-application-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Third-Party Integration Security](#6-third-party-integration-security)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce Phishing-Resistant MFA

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 6.5 |
| NIST 800-53 | IA-2(1), IA-2(6) |
| CIS Azure | 1.1.1 |

#### Description
Require phishing-resistant MFA (FIDO2 security keys, Windows Hello for Business, or certificate-based authentication) for all users. Microsoft reports that MFA blocks over 99.9% of automated attacks.

#### Rationale
**Why This Matters:**
- Password spray and credential stuffing remain top attack vectors
- Traditional MFA (SMS, voice) vulnerable to SIM swapping
- Phishing-resistant MFA eliminates real-time phishing attacks

**Attack Prevented:** Password spray, phishing, credential theft, MFA fatigue

**Real-World Incidents:**
- **Midnight Blizzard (2024):** Test account without MFA led to Microsoft corporate email compromise
- **CVE-2025-55241:** Critical Entra ID privilege escalation vulnerability (CVSS 10.0) could compromise any tenant

#### Prerequisites
- [ ] Microsoft Entra ID P1 or P2 license
- [ ] FIDO2 security keys for privileged users
- [ ] Security Administrator or Global Administrator role

#### ClickOps Implementation

**Step 1: Enable Security Defaults (Basic Tenants)**
1. Navigate to: **Microsoft Entra admin center** → **Identity** → **Overview** → **Properties**
2. Click **Manage security defaults**
3. Set to **Enabled**
4. Click **Save**

> **Note:** Security Defaults provide basic MFA but lack granular control. Enterprise environments should use Conditional Access instead.

**Step 2: Configure Authentication Methods**
1. Navigate to: **Protection** → **Authentication methods** → **Policies**
2. Enable desired methods:
   - **FIDO2 security key:** Enable for all users
   - **Microsoft Authenticator:** Enable with number matching and location display
   - **Temporary Access Pass:** Enable for initial onboarding
3. Disable weak methods:
   - SMS/Voice: Disable or restrict to recovery only

**Step 3: Create Authentication Strength**
1. Navigate to: **Protection** → **Authentication methods** → **Authentication strengths**
2. Click **+ New authentication strength**
3. Name: "Phishing-Resistant MFA"
4. Select:
   - FIDO2 security key
   - Windows Hello for Business
   - Certificate-based authentication (CBA)
5. Save and use in Conditional Access policies

**Time to Complete:** ~45 minutes

#### Code Implementation

**Option 1: Microsoft Graph PowerShell**
```powershell
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
```

**Option 2: Terraform (azuread provider)**
```hcl
# Configure authentication methods policy
resource "azuread_authentication_methods_policy" "main" {
  display_name = "Default Authentication Methods Policy"

  # Enable FIDO2
  fido2 {
    state = "enabled"
    allowed_aaguids = []  # Allow all FIDO2 keys
    key_restrictions_enforcement_type = "allow"
  }

  # Enable Microsoft Authenticator with number matching
  microsoft_authenticator {
    state = "enabled"
    feature_settings {
      display_app_information_required_state {
        state = "enabled"
      }
      number_matching_required_state {
        state = "enabled"
      }
    }
  }

  # Disable SMS (weak)
  sms {
    state = "disabled"
  }
}
```

#### Validation & Testing
**How to verify the control is working:**
1. [ ] Sign in as test user - MFA prompt should appear
2. [ ] Verify number matching in Microsoft Authenticator
3. [ ] Review sign-in logs: **Monitoring** → **Sign-in logs**
4. [ ] Check Identity Secure Score for MFA adoption

**Expected result:** All users require MFA, phishing-resistant methods preferred

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | IA-2(1), IA-2(6) | Multi-factor authentication |
| **ISO 27001** | A.9.4.2 | Secure log-on procedures |
| **CIS Azure** | 1.1.1 | Ensure MFA is enabled for all users |

---

### 1.2 Configure Emergency Access (Break-Glass) Accounts

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.1 |
| NIST 800-53 | AC-2 |
| CIS Azure | 1.1.5 |

#### Description
Create highly protected emergency access accounts excluded from Conditional Access and MFA policies to ensure tenant access during outages or lockout scenarios.

#### Rationale
**Why This Matters:**
- Conditional Access misconfiguration can lock out all admins
- Federation or MFA provider outages can prevent authentication
- Break-glass accounts provide last-resort access

**Best Practice:**
- Minimum 2 cloud-only accounts (no federation dependency)
- Long, complex passwords stored securely offline
- Excluded from all Conditional Access policies
- Monitored for any sign-in activity

#### Prerequisites
- [ ] Global Administrator access
- [ ] Secure offline storage (safe, vault)
- [ ] Alerting configured for emergency account usage

#### ClickOps Implementation

**Step 1: Create Emergency Accounts**
1. Navigate to: **Microsoft Entra admin center** → **Users** → **All users**
2. Click **+ New user** → **Create new user**
3. Configure:
   - **Username:** `emergency-admin-01@yourdomain.onmicrosoft.com`
   - Use `.onmicrosoft.com` domain (cloud-only, no federation)
   - **Password:** Generate 64+ character random password
4. Assign **Global Administrator** role
5. Create second account (emergency-admin-02)

**Step 2: Exclude from Conditional Access**
1. Navigate to: **Protection** → **Conditional Access** → **Policies**
2. Edit each policy
3. Under **Users** → **Exclude**, add emergency accounts
4. Save all policies

**Step 3: Configure Monitoring**
1. Navigate to: **Monitoring** → **Diagnostic settings**
2. Create alert rule:
   - **Condition:** Sign-in logs where User = emergency accounts
   - **Action:** Email Security team, create incident

**Step 4: Store Credentials Securely**
1. Print credentials on paper (no digital storage)
2. Store in physically secure location (safe, vault)
3. Split credentials between multiple custodians if possible
4. Document access procedures

**Time to Complete:** ~45 minutes

#### Code Implementation

**Option 1: PowerShell**
```powershell
# Create emergency access account
$passwordProfile = @{
    password = [System.Web.Security.Membership]::GeneratePassword(64, 10)
    forceChangePasswordNextSignIn = $false
}

$params = @{
    accountEnabled = $true
    displayName = "Emergency Admin 01"
    mailNickname = "emergency-admin-01"
    userPrincipalName = "emergency-admin-01@yourdomain.onmicrosoft.com"
    passwordProfile = $passwordProfile
}

$user = New-MgUser -BodyParameter $params

# Assign Global Administrator role
$roleId = (Get-MgRoleManagementDirectoryRoleDefinition -Filter "displayName eq 'Global Administrator'").Id

New-MgRoleManagementDirectoryRoleAssignment -BodyParameter @{
    "@odata.type" = "#microsoft.graph.unifiedRoleAssignment"
    roleDefinitionId = $roleId
    principalId = $user.Id
    directoryScopeId = "/"
}

# Output password (store securely)
Write-Host "Password: $($passwordProfile.password)" -ForegroundColor Yellow
Write-Host "STORE THIS SECURELY AND DELETE FROM TERMINAL HISTORY"
```

#### Validation & Testing
1. [ ] Test sign-in with emergency account (then immediately change password)
2. [ ] Verify bypasses all Conditional Access policies
3. [ ] Confirm alert triggers on sign-in
4. [ ] Document and secure credentials

---

## 2. Conditional Access

### 2.1 Block Legacy Authentication

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.2 |
| NIST 800-53 | IA-2, AC-17 |
| CIS Azure | 1.1.2 |

#### Description
Block legacy authentication protocols (Basic Auth, POP, IMAP, SMTP AUTH) that cannot enforce MFA and are commonly exploited in password spray attacks.

#### Rationale
**Why This Matters:**
- Legacy protocols bypass MFA completely
- Password spray attacks frequently target these endpoints
- Microsoft has deprecated Basic Auth

**Attack Prevented:** Password spray via legacy protocols, credential replay

#### ClickOps Implementation

**Step 1: Create Block Legacy Auth Policy**
1. Navigate to: **Protection** → **Conditional Access** → **Policies**
2. Click **+ New policy**
3. Configure:
   - **Name:** Block legacy authentication
   - **Users:** All users (exclude emergency accounts)
   - **Cloud apps:** All cloud apps
   - **Conditions** → **Client apps:** Select "Exchange ActiveSync clients" and "Other clients"
   - **Grant:** Block access
4. Enable policy: **On**
5. Click **Create**

**Time to Complete:** ~15 minutes

#### Code Implementation

```powershell
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
```

---

### 2.2 Require MFA for All Users

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3 |
| NIST 800-53 | IA-2(1) |
| CIS Azure | 1.1.3 |

#### Description
Create Conditional Access policy requiring MFA for all interactive sign-ins to all cloud applications.

#### ClickOps Implementation

**Step 1: Create MFA Policy**
1. Navigate to: **Protection** → **Conditional Access** → **Policies**
2. Click **+ New policy**
3. Configure:
   - **Name:** Require MFA for all users
   - **Users:** All users (exclude emergency accounts)
   - **Cloud apps:** All cloud apps
   - **Conditions:** None (any condition)
   - **Grant:** Require multifactor authentication
4. Enable policy: **On**
5. Click **Create**

---

### 2.3 Require Compliant Devices for Admins

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1, 6.4 |
| NIST 800-53 | AC-2(11), AC-6(1) |

#### Description
Require privileged users to access admin portals only from Intune-compliant or Hybrid Azure AD joined devices.

#### ClickOps Implementation

**Step 1: Create Admin Device Compliance Policy**
1. Navigate to: **Protection** → **Conditional Access** → **Policies**
2. Click **+ New policy**
3. Configure:
   - **Name:** Require compliant device for admins
   - **Users:** Select directory roles → All admin roles
   - **Cloud apps:** Microsoft Admin Portals (or all apps)
   - **Grant:** Require device to be marked as compliant OR Require Hybrid Azure AD joined device
4. Enable policy

---

### 2.4 Block High-Risk Sign-Ins

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.4 |
| NIST 800-53 | SI-4 |

#### Description
Use Entra ID Protection to automatically block sign-ins classified as high risk based on machine learning detection of suspicious patterns.

#### Prerequisites
- [ ] Microsoft Entra ID P2 license

#### ClickOps Implementation

**Step 1: Create Risk-Based Policy**
1. Navigate to: **Protection** → **Conditional Access** → **Policies**
2. Click **+ New policy**
3. Configure:
   - **Name:** Block high-risk sign-ins
   - **Users:** All users (exclude emergency accounts)
   - **Cloud apps:** All cloud apps
   - **Conditions** → **Sign-in risk:** High
   - **Grant:** Block access
4. Enable policy

**Step 2: Create Medium-Risk MFA Policy**
1. Create another policy for medium risk
2. **Conditions** → **Sign-in risk:** Medium
3. **Grant:** Require MFA + Require password change

---

## 3. Privileged Identity Management

### 3.1 Enable Just-In-Time Access for Admin Roles

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 6.8 |
| NIST 800-53 | AC-2(7), AC-6(1) |
| CIS Azure | 1.1.4 |

#### Description
Implement Privileged Identity Management (PIM) to eliminate standing admin privileges. Require just-in-time activation with MFA, justification, and optional approval for privileged role access.

#### Rationale
**Why This Matters:**
- Standing privileges create persistent attack surface
- Compromised accounts with permanent admin have unlimited access duration
- PIM provides audit trail for all privilege elevation
- Time-limited access reduces blast radius

**Attack Prevented:** Privilege persistence, lateral movement, insider threats

**Real-World Incidents:**
- **Midnight Blizzard:** Time-limited OAuth permissions would have reduced attack duration

#### Prerequisites
- [ ] Microsoft Entra ID P2 license
- [ ] Global Administrator or Privileged Role Administrator

#### ClickOps Implementation

**Step 1: Access PIM**
1. Navigate to: **Microsoft Entra admin center** → **Identity governance** → **Privileged Identity Management**
2. Click **Microsoft Entra roles**

**Step 2: Configure Role Settings**
1. Click **Settings** → **Roles**
2. Select **Global Administrator**
3. Click **Edit**
4. Configure:
   - **Activation maximum duration:** 2 hours (or 8 hours max)
   - **On activation, require:** MFA
   - **Require justification on activation:** Yes
   - **Require ticket information:** Optional
   - **Require approval to activate:** Yes (for highest privilege roles)
   - **Approvers:** Security team members
5. Click **Update**
6. Repeat for other privileged roles (Security Admin, Exchange Admin, etc.)

**Step 3: Convert Permanent to Eligible**
1. Navigate to **Assignments** → **Eligible assignments**
2. For each permanent Global Admin:
   - Click **Update**
   - Change assignment type to **Eligible**
   - Set eligibility period (e.g., 1 year with renewal)
3. Keep only emergency accounts as permanent

**Step 4: Configure Activation Requirements**
1. In role settings, configure:
   - Maximum activation duration
   - MFA requirement
   - Approval workflow

**Time to Complete:** ~1-2 hours

#### Code Implementation

**Option 1: Microsoft Graph PowerShell**
```powershell
# Connect with PIM permissions
Connect-MgGraph -Scopes "RoleManagement.ReadWrite.Directory", "RoleEligibilitySchedule.ReadWrite.Directory"

# Get role definitions
$globalAdminRole = Get-MgRoleManagementDirectoryRoleDefinition -Filter "displayName eq 'Global Administrator'"

# Create eligible assignment (convert permanent to eligible)
$params = @{
    action = "adminAssign"
    justification = "Converting to PIM eligible assignment"
    roleDefinitionId = $globalAdminRole.Id
    directoryScopeId = "/"
    principalId = "USER_OBJECT_ID"
    scheduleInfo = @{
        startDateTime = (Get-Date).ToUniversalTime().ToString("o")
        expiration = @{
            type = "afterDuration"
            duration = "P365D"  # 1 year eligibility
        }
    }
}

New-MgRoleManagementDirectoryRoleEligibilityScheduleRequest -BodyParameter $params

# Configure role settings (requires beta endpoint)
# Use Microsoft Entra admin center for full settings configuration
```

**Option 2: Terraform**
```hcl
# Note: Terraform support for PIM is limited
# Use PowerShell or admin center for comprehensive PIM configuration

# Create eligible assignment
resource "azuread_directory_role_eligibility_schedule_request" "global_admin" {
  role_definition_id = data.azuread_directory_role.global_admin.template_id
  principal_id       = azuread_user.admin.object_id
  directory_scope_id = "/"
  justification      = "PIM eligible assignment"

  schedule_info {
    start_date_time = timestamp()
    expiration {
      duration = "P365D"
      type     = "afterDuration"
    }
  }
}
```

#### Validation & Testing
**How to verify the control is working:**
1. [ ] Verify no permanent Global Admin assignments (except emergency accounts)
2. [ ] Test PIM activation as eligible admin
3. [ ] Confirm MFA required on activation
4. [ ] Verify justification is captured in audit log
5. [ ] Check activation expires after configured duration

**Expected result:** Admins activate roles on-demand, access expires automatically

---

### 3.2 Configure Access Reviews

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.1, 5.3 |
| NIST 800-53 | AC-2(3) |

#### Description
Enable recurring access reviews for privileged roles and group memberships to ensure continued business need for access.

#### ClickOps Implementation

**Step 1: Create Access Review**
1. Navigate to: **Identity governance** → **Access reviews**
2. Click **+ New access review**
3. Configure:
   - **Review type:** Teams + Groups or Azure AD roles
   - **Scope:** Global Administrator (and other privileged roles)
   - **Reviewers:** Manager or Self-review
   - **Recurrence:** Monthly or Quarterly
   - **Upon completion:** Remove access for denied users
4. Start review

---

## 4. Application Security

### 4.1 Restrict User Consent to Applications

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.5 |
| NIST 800-53 | AC-3, CM-7 |
| CIS Azure | 2.1 |

#### Description
Prevent users from granting OAuth consent to third-party applications. Require admin approval for all new application access requests.

#### Rationale
**Why This Matters:**
- OAuth consent phishing is a growing attack vector
- Users often grant excessive permissions without understanding risks
- Admin review ensures only vetted applications are authorized

**Attack Prevented:** OAuth consent phishing, malicious app installation

**Real-World Incidents:**
- **Midnight Blizzard:** Leveraged malicious OAuth applications with full_access_as_app to access mailboxes

#### ClickOps Implementation

**Step 1: Disable User Consent**
1. Navigate to: **Applications** → **Enterprise applications** → **Consent and permissions**
2. Click **User consent settings**
3. Select **Do not allow user consent**
4. Click **Save**

**Step 2: Configure Admin Consent Workflow**
1. Click **Admin consent settings**
2. Enable **Users can request admin consent to apps they are unable to consent to**
3. Add reviewers (Security team members)
4. Configure notification settings
5. Click **Save**

**Time to Complete:** ~15 minutes

#### Code Implementation

```powershell
# Disable user consent
$params = @{
    defaultUserRolePermissions = @{
        permissionGrantPoliciesAssigned = @()
    }
}

Update-MgPolicyAuthorizationPolicy -BodyParameter $params

# Note: Configure admin consent workflow through admin center
```

---

### 4.2 Review and Restrict Application Permissions

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.6 |
| NIST 800-53 | AC-6 |

#### Description
Regularly audit enterprise applications for excessive permissions, especially high-risk permissions like Mail.ReadWrite, Directory.ReadWrite.All, and full_access_as_app.

#### ClickOps Implementation

**Step 1: Audit Applications**
1. Navigate to: **Applications** → **App registrations** → **All applications**
2. For each app, click **API permissions**
3. Flag apps with dangerous permissions:
   - `Mail.ReadWrite` - Read/write all mail
   - `Files.ReadWrite.All` - Access all files
   - `Directory.ReadWrite.All` - Modify directory
   - `Application.ReadWrite.All` - Manage apps
   - `RoleManagement.ReadWrite.Directory` - Manage roles

**Step 2: Remove Unnecessary Permissions**
1. For flagged apps, review business justification
2. Remove permissions not required for functionality
3. Or delete unused applications entirely

---

## 5. Monitoring & Detection

### 5.1 Enable Sign-In and Audit Logging

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2, AU-3, AU-6 |

#### Description
Enable and export Entra ID sign-in and audit logs for security monitoring, threat detection, and compliance.

#### ClickOps Implementation

**Step 1: Configure Diagnostic Settings**
1. Navigate to: **Monitoring** → **Diagnostic settings**
2. Click **+ Add diagnostic setting**
3. Configure:
   - **Name:** Send to Log Analytics (or SIEM)
   - **Logs:** SignInLogs, AuditLogs, NonInteractiveUserSignInLogs, ServicePrincipalSignInLogs
   - **Destination:** Log Analytics workspace / Event Hub / Storage Account
4. Click **Save**

**Step 2: Create Alert Rules**
1. Navigate to: **Monitoring** → **Alerts**
2. Create alerts for:
   - Global Admin role assignment
   - Conditional Access policy changes
   - New OAuth app registration
   - Risky sign-in detected

---

### 5.2 Monitor Identity Secure Score

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CA-7 |

#### Description
Regularly review Identity Secure Score to track security posture and identify improvement opportunities.

#### ClickOps Implementation

1. Navigate to: **Protection** → **Identity Secure Score**
2. Review current score and recommendations
3. Target score above 70%
4. Implement high-impact recommendations:
   - Enable MFA for all users
   - Block legacy authentication
   - Enable risk policies
   - Use PIM for admin roles

---

### 5.3 Key Events to Monitor

| Event | Log Source | Detection Use Case |
|-------|------------|-------------------|
| `Add member to role` | Audit | Privilege escalation |
| `Update conditional access policy` | Audit | Security control bypass |
| `Consent to application` | Audit | Malicious app installation |
| `User risk detected` | Sign-in | Account compromise |
| `Sign-in from anonymous IP` | Sign-in | Suspicious access |
| `Impossible travel` | Sign-in | Credential theft |

#### KQL Queries for Azure Sentinel

```kql
// Privileged role assignments
AuditLogs
| where TimeGenerated > ago(24h)
| where OperationName == "Add member to role"
| where TargetResources[0].modifiedProperties[0].newValue contains "Global Administrator"
| project TimeGenerated, InitiatedBy.user.userPrincipalName, TargetResources[0].userPrincipalName

// Conditional Access policy changes
AuditLogs
| where TimeGenerated > ago(24h)
| where OperationName has_any ("Add policy", "Update policy", "Delete policy")
| where TargetResources[0].type == "Policy"
| project TimeGenerated, InitiatedBy.user.userPrincipalName, OperationName, TargetResources[0].displayName

// High-risk sign-ins
SigninLogs
| where TimeGenerated > ago(24h)
| where RiskLevelDuringSignIn == "high"
| project TimeGenerated, UserPrincipalName, IPAddress, Location, RiskDetail
```

---

## 6. Third-Party Integration Security

### 6.1 Integration Risk Assessment

| Risk Factor | Low | Medium | High |
|-------------|-----|--------|------|
| **Data Access** | Directory read-only | User profile + groups | Mail, files, directory write |
| **OAuth Scopes** | User.Read | User.ReadWrite, Group.Read | Mail.ReadWrite, Application.ReadWrite.All |
| **Token Duration** | Short-lived (1 hour) | Refresh tokens (90 days) | Long-lived service principal |
| **Vendor Security** | SOC 2 Type II + ISO | SOC 2 Type I | No certification |

### 6.2 Common Integrations

#### Obsidian Security
**Data Access:** Read (directory, sign-in logs, audit logs)
**Recommended Controls:**
- ✅ Use dedicated service principal
- ✅ Grant minimum required Graph API permissions
- ✅ Monitor service principal sign-ins
- ✅ Review permissions quarterly

---

## 7. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Entra ID Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | MFA for all users | [1.1](#11-enforce-phishing-resistant-mfa) |
| CC6.1 | Block legacy auth | [2.1](#21-block-legacy-authentication) |
| CC6.2 | Privileged Identity Management | [3.1](#31-enable-just-in-time-access-for-admin-roles) |
| CC6.3 | Application consent controls | [4.1](#41-restrict-user-consent-to-applications) |
| CC7.2 | Audit logging | [5.1](#51-enable-sign-in-and-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | Entra ID Control | Guide Section |
|---------|------------------|---------------|
| IA-2(1) | MFA enforcement | [1.1](#11-enforce-phishing-resistant-mfa) |
| IA-2(6) | Phishing-resistant MFA | [1.1](#11-enforce-phishing-resistant-mfa) |
| AC-2(7) | Privileged account management | [3.1](#31-enable-just-in-time-access-for-admin-roles) |
| AC-2(3) | Access reviews | [3.2](#32-configure-access-reviews) |
| AU-2 | Audit logging | [5.1](#51-enable-sign-in-and-audit-logging) |

### CIS Microsoft Azure Foundations Benchmark Mapping

| Recommendation | Entra ID Control | Guide Section |
|---------------|------------------|---------------|
| 1.1.1 | Ensure MFA is enabled | [1.1](#11-enforce-phishing-resistant-mfa) |
| 1.1.2 | Block legacy authentication | [2.1](#21-block-legacy-authentication) |
| 1.1.4 | Ensure PIM is used | [3.1](#31-enable-just-in-time-access-for-admin-roles) |
| 1.1.5 | Emergency access accounts | [1.2](#12-configure-emergency-access-break-glass-accounts) |
| 2.1 | Restrict user consent | [4.1](#41-restrict-user-consent-to-applications) |

---

## Appendix A: License Compatibility

| Control | Free | P1 | P2 | Microsoft 365 E5 |
|---------|------|----|----|------------------|
| Security Defaults | ✅ | ✅ | ✅ | ✅ |
| Conditional Access | ❌ | ✅ | ✅ | ✅ |
| Privileged Identity Management | ❌ | ❌ | ✅ | ✅ |
| Identity Protection (risk policies) | ❌ | ❌ | ✅ | ✅ |
| Access Reviews | ❌ | ❌ | ✅ | ✅ |
| Entitlement Management | ❌ | ❌ | ✅ | ✅ |

---

## Appendix B: References

**Official Microsoft Documentation:**
- [Best Practices to Secure with Microsoft Entra ID](https://learn.microsoft.com/en-us/entra/architecture/secure-best-practices)
- [Require MFA for All Users with Conditional Access](https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-all-users-mfa-strength)
- [Plan Conditional Access Deployment](https://learn.microsoft.com/en-us/entra/identity/conditional-access/plan-conditional-access)
- [Conditional Access - Zero Trust Policy Engine](https://learn.microsoft.com/en-us/entra/identity/conditional-access/overview)
- [Privileged Identity Management](https://learn.microsoft.com/en-us/entra/id-governance/privileged-identity-management/)
- [Microsoft Graph API reference](https://learn.microsoft.com/en-us/graph/api/overview)

**Security Incident Reports:**
- [Midnight Blizzard attack guidance](https://www.microsoft.com/en-us/security/blog/2024/01/25/midnight-blizzard-guidance-for-responders-on-nation-state-attack/)

**CIS Benchmarks:**
- [CIS Microsoft Azure Foundations Benchmark](https://www.cisecurity.org/benchmark/azure)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with authentication, Conditional Access, PIM, and monitoring | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)

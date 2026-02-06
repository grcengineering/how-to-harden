---
layout: guide
title: "Microsoft 365 Hardening Guide"
vendor: "Microsoft"
slug: "microsoft-365"
tier: "1"
category: "Collaboration"
description: "Comprehensive security hardening for Microsoft 365, Exchange Online, SharePoint, Teams, and OneDrive"
version: "0.1.0"
maturity: "draft"
last_updated: "2025-02-05"
---

## Overview

Microsoft 365 is the world's most widely deployed productivity suite, with over **345 million paid seats** across enterprises globally. As the central collaboration platform for email, documents, and communication, M365 represents a critical attack surface. The **January 2024 Midnight Blizzard breach** demonstrated how a single misconfigured test tenant without MFA enabled nation-state actors to access Microsoft's own corporate email, including senior leadership and cybersecurity teams.

### Intended Audience
- Security engineers managing Microsoft 365 environments
- IT administrators configuring tenant security
- GRC professionals assessing cloud productivity compliance
- Third-party risk managers evaluating M365 integrations

### How to Use This Guide
- **L1 (Baseline):** Essential controls for all organizations
- **L2 (Hardened):** Enhanced controls for security-sensitive environments
- **L3 (Maximum Security):** Strictest controls for regulated industries

### Scope
This guide covers Microsoft 365 tenant-level security configurations including Entra ID (Azure AD) authentication policies, Exchange Online protection, SharePoint/OneDrive data security, Teams governance, and integration security. Azure infrastructure hardening is covered in a separate guide.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Network Access Controls](#2-network-access-controls)
3. [OAuth & Integration Security](#3-oauth--integration-security)
4. [Data Security](#4-data-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Third-Party Integration Security](#6-third-party-integration-security)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enforce Phishing-Resistant MFA for All Users

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 6.5 |
| NIST 800-53 | IA-2(1), IA-2(6) |
| CIS M365 Benchmark | 1.1.1, 1.1.3 |

#### Description
Require phishing-resistant MFA (FIDO2 security keys, Windows Hello for Business, or certificate-based authentication) for all users. Microsoft reports that over 99.9% of compromised accounts had MFA disabled.

#### Rationale
**Why This Matters:**
- Password spray attacks remain the most common attack vector against M365
- Legacy MFA methods (SMS, voice call) are vulnerable to SIM swapping and social engineering
- Phishing-resistant MFA eliminates real-time phishing proxy attacks (Evilginx, Modlishka)

**Attack Prevented:** Password spray, credential stuffing, real-time phishing, MFA fatigue attacks

**Real-World Incidents:**
- **January 2024 Midnight Blizzard Breach:** Russian APT29 used password spray to compromise a legacy test tenant without MFA, gaining access to Microsoft corporate email including senior leadership
- **October 2024 Midnight Blizzard Phishing Campaign:** Targeted thousands of users across 100+ organizations using RDP configuration file attachments

#### Prerequisites
- [ ] Microsoft Entra ID P1 or P2 license (for Conditional Access)
- [ ] FIDO2-compatible security keys for privileged users
- [ ] Global Administrator or Security Administrator role
- [ ] User inventory for phased rollout planning

#### ClickOps Implementation

**Step 1: Enable Security Defaults (Basic Protection)**
1. Navigate to: **Microsoft Entra admin center** → **Identity** → **Overview** → **Properties**
2. Click **Manage security defaults**
3. Set **Security defaults** to **Enabled**
4. Click **Save**

> **Note:** Security Defaults enforces MFA for all users but lacks granular control. For enterprise environments, use Conditional Access instead.

**Step 2: Create Conditional Access Policy for MFA**
1. Navigate to: **Microsoft Entra admin center** → **Protection** → **Conditional Access**
2. Click **+ Create new policy**
3. Configure:
   - **Name:** Require MFA for all users
   - **Users:** All users (exclude break-glass accounts)
   - **Cloud apps:** All cloud apps
   - **Conditions:** Any location
   - **Grant:** Require multifactor authentication
4. Set **Enable policy** to **On**
5. Click **Create**

**Step 3: Configure Authentication Strength for Phishing Resistance**
1. Navigate to: **Protection** → **Authentication methods** → **Authentication strengths**
2. Click **+ New authentication strength**
3. Name: "Phishing-Resistant MFA"
4. Select only:
   - FIDO2 security key
   - Windows Hello for Business
   - Certificate-based authentication
5. Save and apply to Conditional Access policies for admins

**Time to Complete:** ~45 minutes (policy) + user enrollment time

#### Code Implementation

**Option 1: Microsoft Graph PowerShell**
```powershell
# Install Microsoft Graph PowerShell module
Install-Module Microsoft.Graph -Scope CurrentUser

# Connect with required permissions
Connect-MgGraph -Scopes "Policy.ReadWrite.ConditionalAccess", "Application.Read.All"

# Create Conditional Access policy requiring MFA
$params = @{
    displayName = "Require MFA for all users"
    state = "enabled"
    conditions = @{
        users = @{
            includeUsers = @("All")
            excludeUsers = @("BREAK_GLASS_ACCOUNT_ID")
        }
        applications = @{
            includeApplications = @("All")
        }
    }
    grantControls = @{
        operator = "OR"
        builtInControls = @("mfa")
    }
}

New-MgIdentityConditionalAccessPolicy -BodyParameter $params
```

**Option 2: Azure CLI**
```bash
# Create Conditional Access policy via Graph API
az rest --method POST \
  --uri "https://graph.microsoft.com/v1.0/identity/conditionalAccess/policies" \
  --headers "Content-Type=application/json" \
  --body '{
    "displayName": "Require MFA for all users",
    "state": "enabled",
    "conditions": {
      "users": {
        "includeUsers": ["All"],
        "excludeUsers": ["BREAK_GLASS_ACCOUNT_ID"]
      },
      "applications": {
        "includeApplications": ["All"]
      }
    },
    "grantControls": {
      "operator": "OR",
      "builtInControls": ["mfa"]
    }
  }'
```

**Option 3: Terraform (azuread provider)**
```hcl
# terraform/m365/conditional-access-mfa.tf

resource "azuread_conditional_access_policy" "require_mfa" {
  display_name = "Require MFA for all users"
  state        = "enabled"

  conditions {
    users {
      included_users = ["All"]
      excluded_users = [azuread_user.break_glass.object_id]
    }

    applications {
      included_applications = ["All"]
    }

    client_app_types = ["all"]
  }

  grant_controls {
    operator          = "OR"
    built_in_controls = ["mfa"]
  }
}
```

#### Validation & Testing
**How to verify the control is working:**
1. [ ] Sign in as a test user and verify MFA prompt appears
2. [ ] Attempt sign-in from unmanaged device - MFA should be required
3. [ ] Review sign-in logs for MFA enforcement: **Entra admin center** → **Monitoring** → **Sign-in logs**
4. [ ] Run: `Get-MgIdentityConditionalAccessPolicy | Where-Object {$_.State -eq "enabled"}`

**Expected result:** All user sign-ins require MFA, sign-in logs show "MFA requirement satisfied"

#### Monitoring & Maintenance
**Ongoing monitoring:**
- Monitor sign-in logs for MFA bypass attempts
- Alert on sign-ins without MFA from Conditional Access exclusions
- Track MFA registration completion rates

**KQL Query for Azure Sentinel:**
```kql
SigninLogs
| where TimeGenerated > ago(24h)
| where AuthenticationRequirement == "singleFactorAuthentication"
| where ResultType == 0
| project TimeGenerated, UserPrincipalName, AppDisplayName, IPAddress, Location
```

**Maintenance schedule:**
- **Weekly:** Review MFA registration status for new users
- **Monthly:** Audit Conditional Access policy exclusions
- **Quarterly:** Test break-glass account access procedures

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | Medium | Users must complete MFA on each sign-in or trusted session expiry |
| **System Performance** | None | No performance impact |
| **Maintenance Burden** | Low | Minimal ongoing maintenance after initial deployment |
| **Rollback Difficulty** | Easy | Disable policy in Conditional Access console |

**Potential Issues:**
- Users without MFA-capable devices: Provide hardware security keys
- Legacy applications: May require app passwords (discouraged) or modern auth upgrade

**Rollback Procedure:**
1. Navigate to Conditional Access → Select policy → Set state to **Off**
2. Or via PowerShell: `Update-MgIdentityConditionalAccessPolicy -ConditionalAccessPolicyId $policyId -State "disabled"`

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | IA-2(1) | Multi-factor authentication to privileged accounts |
| **ISO 27001** | A.9.4.2 | Secure log-on procedures |
| **CIS M365** | 1.1.1 | Ensure MFA is enabled for all users |

---

### 1.2 Block Legacy Authentication Protocols

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.2 |
| NIST 800-53 | IA-2, AC-17 |
| CIS M365 Benchmark | 1.1.2 |

#### Description
Block legacy authentication protocols (POP3, IMAP, SMTP AUTH, Basic Auth) that cannot enforce MFA and are commonly exploited in password spray attacks.

#### Rationale
**Why This Matters:**
- Legacy protocols bypass MFA entirely
- Password spray attacks frequently target legacy auth endpoints
- Basic Authentication is deprecated by Microsoft

**Attack Prevented:** Password spray via legacy protocols, credential theft replay

**Real-World Incidents:**
- **Midnight Blizzard (2024):** Initial access via password spray would have been blocked if legacy auth was disabled

#### Prerequisites
- [ ] Inventory of applications using legacy auth
- [ ] Migration plan for legacy applications to modern auth (OAuth 2.0)

#### ClickOps Implementation

**Step 1: Block via Conditional Access**
1. Navigate to: **Microsoft Entra admin center** → **Protection** → **Conditional Access**
2. Click **+ Create new policy**
3. Configure:
   - **Name:** Block legacy authentication
   - **Users:** All users
   - **Cloud apps:** All cloud apps
   - **Conditions** → **Client apps:** Select only "Exchange ActiveSync clients" and "Other clients"
   - **Grant:** Block access
4. Set **Enable policy** to **On**
5. Click **Create**

**Step 2: Disable SMTP AUTH at Tenant Level**
1. Navigate to: **Exchange admin center** → **Settings** → **Mail flow**
2. Disable **SMTP AUTH** at the organization level

**Time to Complete:** ~20 minutes

#### Code Implementation

**Option 1: PowerShell**
```powershell
# Connect to Exchange Online
Connect-ExchangeOnline

# Disable SMTP AUTH for all mailboxes
Get-Mailbox -ResultSize Unlimited | Set-CASMailbox -SmtpClientAuthenticationDisabled $true

# Verify
Get-CASMailbox -ResultSize Unlimited | Select-Object DisplayName, SmtpClientAuthenticationDisabled
```

**Option 2: Conditional Access Policy via Graph**
```powershell
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
```

#### Validation & Testing
1. [ ] Attempt POP3/IMAP connection - should fail
2. [ ] Review sign-in logs for blocked legacy auth attempts
3. [ ] Verify legitimate applications still function via modern auth

**Expected result:** Legacy authentication attempts blocked, modern auth sign-ins succeed

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | IA-2 | Identification and authentication |
| **CIS M365** | 1.1.2 | Ensure legacy authentication is blocked |

---

### 1.3 Implement Privileged Identity Management (PIM)

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 6.8 |
| NIST 800-53 | AC-2(7), AC-6(1) |
| CIS M365 Benchmark | 1.1.4 |

#### Description
Enable just-in-time privileged access using Microsoft Entra Privileged Identity Management (PIM) to eliminate standing admin privileges and enforce approval workflows.

#### Rationale
**Why This Matters:**
- Standing privileges create persistent attack surface
- Compromised admin accounts provide unlimited access duration
- PIM provides audit trail for all privilege elevation

**Attack Prevented:** Privilege persistence, lateral movement, insider threats

**Real-World Incidents:**
- **Midnight Blizzard:** Persistent OAuth app permissions allowed extended access; time-limited roles would have reduced blast radius

#### Prerequisites
- [ ] Microsoft Entra ID P2 license
- [ ] Global Administrator or Privileged Role Administrator
- [ ] Defined approval workflow owners

#### ClickOps Implementation

**Step 1: Enable PIM for Directory Roles**
1. Navigate to: **Microsoft Entra admin center** → **Identity governance** → **Privileged Identity Management**
2. Click **Azure AD roles** → **Roles**
3. Select **Global Administrator**
4. Click **Settings** → **Edit**
5. Configure:
   - **Activation maximum duration:** 2 hours
   - **Require justification on activation:** Yes
   - **Require approval to activate:** Yes (for highly privileged roles)
   - **Require MFA on activation:** Yes
6. Click **Update**

**Step 2: Convert Permanent Assignments to Eligible**
1. In PIM → Azure AD roles → **Assignments**
2. For each permanent Global Admin, click **Update** → Change to **Eligible**
3. Set eligibility period (e.g., 1 year with renewal review)

**Time to Complete:** ~1 hour for initial configuration

#### Code Implementation

**Option 1: Microsoft Graph PowerShell**
```powershell
# Connect with PIM permissions
Connect-MgGraph -Scopes "RoleManagement.ReadWrite.Directory"

# Get Global Administrator role
$role = Get-MgRoleManagementDirectoryRoleDefinition -Filter "displayName eq 'Global Administrator'"

# Create eligible assignment (replace user ID)
$params = @{
    action = "adminAssign"
    justification = "Initial PIM setup"
    roleDefinitionId = $role.Id
    directoryScopeId = "/"
    principalId = "USER_OBJECT_ID"
    scheduleInfo = @{
        startDateTime = (Get-Date).ToUniversalTime().ToString("o")
        expiration = @{
            type = "afterDuration"
            duration = "P365D"
        }
    }
}

New-MgRoleManagementDirectoryRoleEligibilityScheduleRequest -BodyParameter $params
```

#### Validation & Testing
1. [ ] Verify no standing Global Admin assignments (all eligible)
2. [ ] Test PIM activation workflow as eligible admin
3. [ ] Confirm MFA and justification required on activation
4. [ ] Review PIM audit logs for activation events

**Expected result:** Admins must activate roles on-demand with MFA, approval, and justification

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.2 | Privileged access management |
| **NIST 800-53** | AC-2(7) | Privileged user accounts |
| **ISO 27001** | A.9.2.3 | Privileged access rights management |

---

### 1.4 Configure Break-Glass Emergency Access Accounts

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.1 |
| NIST 800-53 | AC-2 |
| CIS M365 Benchmark | 1.1.5 |

#### Description
Create and secure emergency access accounts that are excluded from Conditional Access and MFA policies to ensure tenant recovery if normal admin access is lost.

#### Rationale
**Why This Matters:**
- Conditional Access misconfiguration can lock out all admins
- Federation failures can prevent normal authentication
- Emergency accounts provide last-resort access

**Best Practice:**
- Minimum 2 break-glass accounts
- Cloud-only (no federation dependency)
- Excluded from all Conditional Access policies
- Long, complex passwords stored securely offline
- Monitored for any usage

#### Prerequisites
- [ ] Global Administrator access
- [ ] Secure offline storage for credentials (safe, vault)
- [ ] Monitoring/alerting configured

#### ClickOps Implementation

**Step 1: Create Break-Glass Accounts**
1. Navigate to: **Microsoft Entra admin center** → **Users** → **All users**
2. Click **+ New user** → **Create new user**
3. Configure:
   - **Username:** `emergency-admin-01@yourdomain.onmicrosoft.com` (use .onmicrosoft.com domain)
   - **Name:** Emergency Admin 01
   - **Password:** Generate 64+ character random password
4. Assign **Global Administrator** role
5. Repeat for second account (emergency-admin-02)

**Step 2: Exclude from Conditional Access**
1. Edit each Conditional Access policy
2. Under **Users** → **Exclude**, add both break-glass accounts
3. Save all policies

**Step 3: Configure Monitoring**
1. Navigate to: **Microsoft Entra admin center** → **Monitoring** → **Diagnostic settings**
2. Create alert rule for any sign-in from break-glass accounts

**Time to Complete:** ~30 minutes

#### Validation & Testing
1. [ ] Verify break-glass accounts can sign in bypassing Conditional Access
2. [ ] Test sign-in generates alert
3. [ ] Confirm credentials are securely stored offline
4. [ ] Document account usage procedure

**Expected result:** Emergency accounts accessible when needed, usage immediately alerted

---

## 2. Network Access Controls

### 2.1 Configure Trusted Locations and Named Locations

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-4, SC-7 |

#### Description
Define trusted IP ranges (corporate networks, VPN egress) and use them in Conditional Access policies to restrict access or reduce MFA friction for trusted locations.

#### Rationale
**Why This Matters:**
- Reduces MFA fatigue for users on corporate networks
- Enables blocking access from high-risk countries
- Provides additional signal for risk-based policies

#### ClickOps Implementation

**Step 1: Create Named Location**
1. Navigate to: **Microsoft Entra admin center** → **Protection** → **Conditional Access** → **Named locations**
2. Click **+ IP ranges location**
3. Configure:
   - **Name:** Corporate Network
   - **Mark as trusted location:** Yes
   - **IP ranges:** Add corporate egress IPs (e.g., 203.0.113.0/24)
4. Click **Create**

**Step 2: Block High-Risk Countries**
1. Click **+ Countries location**
2. Name: "Blocked Countries"
3. Select countries where your organization has no business presence
4. Create Conditional Access policy blocking access from this location

#### Code Implementation

```powershell
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
```

---

## 3. OAuth & Integration Security

### 3.1 Restrict User Consent to Applications

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.5 |
| NIST 800-53 | AC-3, CM-7 |
| CIS M365 Benchmark | 2.1 |

#### Description
Prevent users from granting OAuth consent to third-party applications. Require admin approval for all application access requests.

#### Rationale
**Why This Matters:**
- OAuth consent phishing is a primary attack vector
- Malicious apps can gain persistent access to mailboxes and data
- Admin review ensures only vetted applications are authorized

**Attack Prevented:** OAuth consent phishing, malicious app installation, data exfiltration

**Real-World Incidents:**
- **Midnight Blizzard:** Leveraged OAuth applications to gain elevated access and create malicious apps with full mailbox access

#### Prerequisites
- [ ] Application Administrator or Global Administrator
- [ ] Defined application approval workflow

#### ClickOps Implementation

**Step 1: Disable User Consent**
1. Navigate to: **Microsoft Entra admin center** → **Applications** → **Enterprise applications** → **Consent and permissions**
2. Under **User consent settings**, select **Do not allow user consent**
3. Click **Save**

**Step 2: Configure Admin Consent Workflow**
1. Navigate to: **Admin consent settings**
2. Enable **Users can request admin consent to apps they are unable to consent to**
3. Configure reviewers (Security team)
4. Set notification email
5. Click **Save**

**Time to Complete:** ~15 minutes

#### Code Implementation

```powershell
# Disable user consent via Graph API
$params = @{
    defaultUserRolePermissions = @{
        permissionGrantPoliciesAssigned = @()
    }
}

Update-MgPolicyAuthorizationPolicy -BodyParameter $params
```

#### Validation & Testing
1. [ ] Attempt to authorize a third-party app as standard user - should be blocked
2. [ ] Submit admin consent request - verify workflow triggers
3. [ ] Review existing app permissions: **Enterprise applications** → **All applications** → Review permissions

**Expected result:** Users cannot grant app permissions; admin approval required

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | AC-3 | Access enforcement |
| **CIS M365** | 2.1 | Ensure third-party integrated applications are not allowed |

---

### 3.2 Review and Revoke Overprivileged App Permissions

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.6 |
| NIST 800-53 | AC-6 |

#### Description
Regularly audit enterprise applications for excessive permissions (especially Mail.Read, Mail.ReadWrite, full_access_as_app) and revoke unnecessary grants.

#### Rationale
**Why This Matters:**
- Legacy OAuth apps accumulate permissions over time
- full_access_as_app grants complete mailbox access
- Compromised apps with excessive permissions enable data exfiltration

#### ClickOps Implementation

**Step 1: Audit Application Permissions**
1. Navigate to: **Microsoft Entra admin center** → **Applications** → **App registrations** → **All applications**
2. For each app, review **API permissions**
3. Flag apps with sensitive permissions:
   - `Mail.ReadWrite` (read/write all mail)
   - `Files.ReadWrite.All` (access all files)
   - `Directory.ReadWrite.All` (modify directory)
   - `full_access_as_app` (complete mailbox access)

**Step 2: Revoke Unnecessary Permissions**
1. Select application → **API permissions**
2. Click permission to remove → **Remove permission**
3. Or delete unused applications entirely

**Time to Complete:** ~2-4 hours (initial audit)

#### Code Implementation

```powershell
# List all applications with Mail.ReadWrite permission
$apps = Get-MgApplication -All

foreach ($app in $apps) {
    $permissions = Get-MgApplication -ApplicationId $app.Id -Property RequiredResourceAccess
    $mailPermissions = $permissions.RequiredResourceAccess.ResourceAccess |
        Where-Object { $_.Id -eq "e2a3a72e-5f79-4c64-b1b1-878b674786c9" } # Mail.ReadWrite GUID

    if ($mailPermissions) {
        Write-Host "App: $($app.DisplayName) has Mail.ReadWrite permission"
    }
}
```

---

## 4. Data Security

### 4.1 Enable Sensitivity Labels and Data Loss Prevention

**Profile Level:** L2 (Hardened)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1, 3.2 |
| NIST 800-53 | SC-8, SC-28 |

#### Description
Implement Microsoft Purview sensitivity labels to classify and protect sensitive data, and configure DLP policies to prevent unauthorized data sharing.

#### Rationale
**Why This Matters:**
- Prevents accidental sharing of sensitive documents externally
- Enables encryption that travels with the document
- Provides visibility into data classification across the organization

#### ClickOps Implementation

**Step 1: Create Sensitivity Labels**
1. Navigate to: **Microsoft Purview compliance portal** → **Information protection** → **Labels**
2. Click **+ Create a label**
3. Configure label (e.g., "Confidential"):
   - Apply content marking (header/footer/watermark)
   - Apply encryption (restrict access to specific groups)
   - Apply auto-labeling conditions
4. Publish labels to users

**Step 2: Create DLP Policy**
1. Navigate to: **Data loss prevention** → **Policies**
2. Click **+ Create policy**
3. Select template (e.g., "U.S. Financial Data")
4. Configure locations (Exchange, SharePoint, OneDrive, Teams)
5. Set policy actions (block sharing, notify user, alert admin)
6. Enable policy

---

### 4.2 Configure External Sharing Restrictions

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3, AC-22 |
| CIS M365 Benchmark | 3.2 |

#### Description
Restrict external sharing in SharePoint and OneDrive to prevent unauthorized data exposure.

#### ClickOps Implementation

**Step 1: Configure SharePoint Sharing**
1. Navigate to: **SharePoint admin center** → **Policies** → **Sharing**
2. Set external sharing level:
   - **Most restrictive:** Only people in your organization
   - **Recommended:** Existing guests (requires authentication)
3. Enable **Guests must sign in using the same account to which sharing invitations are sent**
4. Set **Allow sharing only with users in specific security groups** if needed

**Step 2: Configure OneDrive Sharing**
1. In same Sharing page, configure OneDrive settings
2. Match or exceed SharePoint restrictions

#### Code Implementation

```powershell
# Connect to SharePoint Online
Connect-SPOService -Url "https://yourdomain-admin.sharepoint.com"

# Set tenant-level sharing restrictions
Set-SPOTenant -SharingCapability ExistingExternalUserSharingOnly
Set-SPOTenant -RequireAcceptingAccountMatchInvitedAccount $true
Set-SPOTenant -PreventExternalUsersFromResharing $true
```

---

## 5. Monitoring & Detection

### 5.1 Enable Unified Audit Logging

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2, AU-3, AU-6 |
| CIS M365 Benchmark | 5.1 |

#### Description
Enable and configure unified audit logging to capture user and admin activities across all Microsoft 365 services.

#### Rationale
**Why This Matters:**
- Audit logs are essential for incident investigation
- Provides visibility into data access, sharing, and admin changes
- Required for compliance with most security frameworks
- Default retention is 180 days (E5) or 90 days (other plans)

#### ClickOps Implementation

**Step 1: Verify Audit Logging is Enabled**
1. Navigate to: **Microsoft Purview compliance portal** → **Audit**
2. If prompted, click **Start recording user and admin activity**
3. Verify audit search returns results

**Step 2: Configure Audit Log Retention (E5)**
1. Navigate to: **Audit** → **Audit retention policies**
2. Create policy for extended retention (up to 10 years for E5)
3. Apply to high-value activities (MailItemsAccessed, SharePoint file access)

**Time to Complete:** ~15 minutes

#### Code Implementation

```powershell
# Connect to Exchange Online
Connect-ExchangeOnline

# Verify audit logging is enabled
Get-AdminAuditLogConfig | Select-Object UnifiedAuditLogIngestionEnabled

# Enable if not already enabled
Set-AdminAuditLogConfig -UnifiedAuditLogIngestionEnabled $true

# Enable mailbox auditing for all mailboxes
Get-Mailbox -ResultSize Unlimited | Set-Mailbox -AuditEnabled $true
```

#### Key Events to Monitor

| Event | Description | Detection Use Case |
|-------|-------------|-------------------|
| `MailItemsAccessed` | Email accessed via sync or client | Compromised account data access |
| `New-InboxRule` | Inbox rule created | Attacker persistence/hiding |
| `Add-MailboxPermission` | Mailbox delegation added | Lateral movement |
| `Set-ConditionalAccessPolicy` | CA policy modified | Security control bypass |
| `Add application` | App registration created | Malicious app installation |

---

### 5.2 Configure Security Alerts and Microsoft Defender

**Profile Level:** L1 (Baseline)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.11 |
| NIST 800-53 | SI-4 |

#### Description
Enable Microsoft Defender for Office 365 and configure alert policies for suspicious activities.

#### ClickOps Implementation

**Step 1: Review Default Alert Policies**
1. Navigate to: **Microsoft Defender portal** → **Email & collaboration** → **Policies & rules** → **Alert policy**
2. Review and enable critical alerts:
   - Suspicious email sending patterns
   - Malware campaign detected
   - User reported phishing
   - Unusual external file sharing

**Step 2: Configure Custom Alerts**
1. Click **+ New alert policy**
2. Create alerts for:
   - Global Admin role assignment
   - Conditional Access policy changes
   - New OAuth app with sensitive permissions

---

## 6. Third-Party Integration Security

### 6.1 Integration Risk Assessment Matrix

| Risk Factor | Low | Medium | High |
|-------------|-----|--------|------|
| **Data Access** | Read-only, limited scope | Read most data | Write access, full mailbox |
| **OAuth Scopes** | Specific scopes | Broad API access | Full admin/app-only |
| **Session Duration** | <2 hours | 2-8 hours | Persistent |
| **Vendor Security** | SOC 2 Type II + ISO | SOC 2 Type I | No certification |

### 6.2 Common Integrations and Recommended Controls

#### Obsidian Security
**Data Access:** Read (email metadata, audit logs, directory)
**Recommended Controls:**
- ✅ Use dedicated service account
- ✅ Grant minimum required Graph API permissions
- ✅ Enable audit logging for Obsidian's service principal
- ✅ Review permissions quarterly

#### Slack
**Data Access:** Medium (channel sync, user directory)
**Recommended Controls:**
- ✅ Limit to specific channels for Teams-Slack integration
- ✅ Disable file sync if not required
- ✅ Monitor for data exfiltration patterns

---

## 7. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | M365 Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | MFA for all users | [1.1](#11-enforce-phishing-resistant-mfa-for-all-users) |
| CC6.1 | Block legacy auth | [1.2](#12-block-legacy-authentication-protocols) |
| CC6.2 | Privileged Identity Management | [1.3](#13-implement-privileged-identity-management-pim) |
| CC6.6 | External sharing restrictions | [4.2](#42-configure-external-sharing-restrictions) |
| CC7.2 | Unified audit logging | [5.1](#51-enable-unified-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | M365 Control | Guide Section |
|---------|------------------|---------------|
| IA-2(1) | MFA to privileged accounts | [1.1](#11-enforce-phishing-resistant-mfa-for-all-users) |
| IA-2(6) | Phishing-resistant MFA | [1.1](#11-enforce-phishing-resistant-mfa-for-all-users) |
| AC-2(7) | Privileged user accounts | [1.3](#13-implement-privileged-identity-management-pim) |
| AC-3 | Access enforcement | [3.1](#31-restrict-user-consent-to-applications) |
| AU-2 | Audit events | [5.1](#51-enable-unified-audit-logging) |

### CIS Microsoft 365 Foundations Benchmark v3.1 Mapping

| Recommendation | M365 Control | Guide Section |
|---------------|------------------|---------------|
| 1.1.1 | Ensure MFA is enabled for all users | [1.1](#11-enforce-phishing-resistant-mfa-for-all-users) |
| 1.1.2 | Block legacy authentication | [1.2](#12-block-legacy-authentication-protocols) |
| 1.1.4 | Enable Conditional Access policies | [1.1](#11-enforce-phishing-resistant-mfa-for-all-users) |
| 2.1 | Block third-party app consent | [3.1](#31-restrict-user-consent-to-applications) |
| 5.1 | Enable unified audit logging | [5.1](#51-enable-unified-audit-logging) |

---

## Appendix A: Edition/Tier Compatibility

| Control | Microsoft 365 Business Basic | Business Premium | E3 | E5 | Add-on Required |
|---------|------------------------------|------------------|----|----|-----------------|
| Security Defaults MFA | ✅ | ✅ | ✅ | ✅ | No |
| Conditional Access | ❌ | ✅ | ✅ | ✅ | Entra ID P1 |
| Privileged Identity Management | ❌ | ❌ | ❌ | ✅ | Entra ID P2 |
| Sensitivity Labels (basic) | ✅ | ✅ | ✅ | ✅ | No |
| Auto-labeling | ❌ | ❌ | ❌ | ✅ | No |
| Advanced Audit | ❌ | ❌ | ❌ | ✅ | No |
| Defender for Office 365 P2 | ❌ | ❌ | ❌ | ✅ | Add-on for E3 |

---

## Appendix B: References

**Official Microsoft Documentation:**
- [Microsoft 365 security documentation](https://learn.microsoft.com/en-us/microsoft-365/security/)
- [Entra ID Conditional Access](https://learn.microsoft.com/en-us/entra/identity/conditional-access/)
- [Microsoft Graph API reference](https://learn.microsoft.com/en-us/graph/api/overview)
- [Zero Trust identity and device access policies](https://learn.microsoft.com/en-us/security/zero-trust/zero-trust-identity-device-access-policies-common)

**Security Incident Reports:**
- [Midnight Blizzard breach disclosure (January 2024)](https://www.microsoft.com/en-us/msrc/blog/2024/01/microsoft-actions-following-attack-by-nation-state-actor-midnight-blizzard)
- [Midnight Blizzard update (March 2024)](https://www.microsoft.com/en-us/msrc/blog/2024/03/update-on-microsoft-actions-following-attack-by-nation-state-actor-midnight-blizzard)

**CIS Benchmarks:**
- [CIS Microsoft 365 Foundations Benchmark](https://www.cisecurity.org/benchmark/microsoft_365)
- [NIST NCP Checklist](https://ncp.nist.gov/checklist/1140)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2025-02-05 | 0.1.0 | draft | Initial guide with authentication, OAuth, data security, and monitoring controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)

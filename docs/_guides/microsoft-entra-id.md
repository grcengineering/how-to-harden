---
layout: guide
title: "Microsoft Entra ID Hardening Guide"
vendor: "Microsoft Entra ID"
slug: "microsoft-entra-id"
tier: "1"
category: "Identity"
description: "Identity Provider hardening for Azure Active Directory, Conditional Access, PIM, and Zero Trust"
version: "0.2.0"
maturity: "draft"
last_updated: "2026-08-03"
---

## Overview

Microsoft Entra ID (formerly Azure Active Directory) is the cloud identity platform for over **720 million users** across enterprises worldwide. As the authentication backbone for Microsoft 365, Azure, and thousands of SaaS applications, Entra ID security is foundational to Zero Trust architecture. The **January 2024 Midnight Blizzard breach** of Microsoft's corporate environment demonstrated how a single misconfigured test account without MFA can cascade into widespread compromise.

### Intended Audience
- Security engineers managing identity infrastructure
- IT administrators configuring Entra ID tenants
- GRC professionals assessing IAM compliance
- Third-party risk managers evaluating SSO integrations

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 6.5 |
| NIST 800-53 | IA-2(1), IA-2(6) |

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
- Microsoft Entra ID P1 or P2 license
- FIDO2 security keys for privileged users
- Security Administrator or Global Administrator role

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

{% include pack-code.html vendor="microsoft-entra-id" section="1.1" %}

#### Validation & Testing
**How to verify the control is working:**
1. Sign in as test user - MFA prompt should appear
2. Verify number matching in Microsoft Authenticator
3. Review sign-in logs: **Monitoring** → **Sign-in logs**
4. Check Identity Secure Score for MFA adoption

**Expected result:** All users require MFA, phishing-resistant methods preferred

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | IA-2(1), IA-2(6) | Multi-factor authentication |
| **ISO 27001** | A.9.4.2 | Secure log-on procedures |
| **CIS M365 Foundations** | v7.0.0 | MFA enforcement (see benchmark for current IDs) |

---

### 1.2 Configure Emergency Access (Break-Glass) Accounts

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.1 |
| NIST 800-53 | AC-2 |

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
- Global Administrator access
- Secure offline storage (safe, vault)
- Alerting configured for emergency account usage

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

{% include pack-code.html vendor="microsoft-entra-id" section="1.2" %}

#### Validation & Testing
1. Test sign-in with emergency account (then immediately change password)
2. Verify bypasses all Conditional Access policies
3. Confirm alert triggers on sign-in
4. Document and secure credentials

---

## 2. Conditional Access

### 2.1 Block Legacy Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.2 |
| NIST 800-53 | IA-2, AC-17 |

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

{% include pack-code.html vendor="microsoft-entra-id" section="2.1" %}

---

### 2.2 Require MFA for All Users

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3 |
| NIST 800-53 | IA-2(1) |

#### Description
Create Conditional Access policy requiring MFA for all interactive sign-ins to all cloud applications.

#### Rationale
**Why This Matters:**
- Passwords alone are routinely compromised through phishing, reuse, and breach-database credential stuffing
- A tenant-wide Conditional Access MFA policy closes the gaps that per-user MFA and Security Defaults leave open
- Requiring MFA on every interactive sign-in to every cloud app removes the weakest-link application as an entry point

**Attack Prevented:** Password spray, credential stuffing, phishing, account takeover

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

#### Code Implementation

{% include pack-code.html vendor="microsoft-entra-id" section="2.2" %}

> **Enforcement floor (2024-2026):** Microsoft now **system-enforces MFA** — it cannot be disabled — for sign-in to the Azure portal, Entra admin center, and Intune admin center (Phase 1, rolled out H2 2024) and the Microsoft 365 admin center (February 2025). Phase 2 (begun October 1, 2025, postponable only to July 1, 2026) extends enforcement to Azure CLI, Azure PowerShell, the Azure mobile app, IaC tools, and REST API/SDK create/update/delete operations. Break-glass accounts are **included** in this enforcement — register a FIDO2 passkey or certificate-based authentication for them (see [1.2](#12-configure-emergency-access-break-glass-accounts)). Treat this control as your tenant-wide floor on top of Microsoft's portal-level enforcement, not a substitute for it. ([Microsoft: mandatory MFA](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-mandatory-multifactor-authentication))

---

### 2.3 Require Compliant Devices for Admins

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1, 6.4 |
| NIST 800-53 | AC-2(11), AC-6(1) |

#### Description
Require privileged users to access admin portals only from Intune-compliant or Hybrid Azure AD joined devices.

#### Rationale
**Why This Matters:**
- Admin credentials used from unmanaged or personal devices expose the tenant to malware, keyloggers, and token theft
- Restricting admin access to managed, compliant devices ensures endpoint controls (disk encryption, EDR, patch state) are enforced before any privileged action
- A stolen admin password is useless to an attacker without an enrolled, compliant device to sign in from

**Attack Prevented:** Token theft, credential replay from untrusted endpoints, privilege escalation via compromised personal devices

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

#### Code Implementation

{% include pack-code.html vendor="microsoft-entra-id" section="2.3" %}

---

### 2.4 Block High-Risk Sign-Ins

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.4 |
| NIST 800-53 | SI-4 |

#### Description
Use Entra ID Protection to automatically block sign-ins classified as high risk based on machine learning detection of suspicious patterns.

#### Rationale
**Why This Matters:**
- High-risk sign-ins reflect signals like leaked credentials, anonymous IP usage, and impossible-travel patterns that indicate active compromise
- Automated, real-time blocking responds faster than human analysts can triage and act on alerts
- Risk-based policies adapt to evolving attacker behavior without constant manual rule maintenance

**Attack Prevented:** Account takeover, credential-based intrusion, anomalous sign-in abuse

#### Prerequisites
- Microsoft Entra ID P2 license

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

#### Code Implementation

{% include pack-code.html vendor="microsoft-entra-id" section="2.4" %}

---

### 2.5 Review Microsoft-Managed Conditional Access Policies and Retire Per-User MFA

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 4.1 |
| NIST 800-53 | IA-2(1), CM-2 |

#### Description
Review the Conditional Access policies Microsoft now auto-creates in every eligible tenant (shown as "Created by: Microsoft"), exclude your emergency access accounts from them before they auto-enable, and complete the migration of any users still on legacy per-user MFA — which Microsoft explicitly no longer recommends — onto Conditional Access.

#### Rationale
**Why This Matters:**
- Microsoft deploys these policies in report-only mode and enables them automatically after 45 days unless an admin acts — an unreviewed auto-enable can lock out break-glass accounts that were never excluded
- The managed set ("Block legacy authentication", "Block device code flow", "MFA for admins accessing Microsoft Admin portals", "MFA for all users", "MFA for per-user MFA users") overlaps your custom policies; reconciling them prevents conflicting or redundant enforcement
- Per-user MFA is a deprecated mechanism with no conditional logic; leaving users on it fragments your MFA posture

**Attack Prevented:** Admin lockout from unreviewed auto-enabled policy, MFA-coverage gaps from deprecated per-user MFA

#### ClickOps Implementation

**Step 1: Review Microsoft-Managed Policies**
1. Navigate to: **Protection** → **Conditional Access** → **Policies**
2. Filter or look for policies labeled **Created by: Microsoft**
3. For each, open and review scope and state (Report-only vs On)

**Step 2: Exclude Emergency Access Accounts**
1. Edit each Microsoft-managed policy
2. Under **Users** → **Exclude**, add your break-glass accounts
3. Save

**Step 3: Complete Per-User MFA Migration**
1. Confirm the "MFA for per-user MFA users" managed policy is in effect, or create an equivalent Conditional Access policy
2. Disable per-user MFA for migrated users (legacy per-user MFA portal)

**Time to Complete:** ~30 minutes

#### Validation & Testing
1. Every "Created by: Microsoft" policy has emergency accounts excluded
2. No users remain in per-user MFA "Enforced"/"Enabled" state
3. Managed policies are either enabled deliberately or replaced by equivalent custom policies

**Expected result:** Managed policies are consciously adopted, break-glass access preserved, per-user MFA retired. ([Microsoft-managed policies](https://learn.microsoft.com/en-us/entra/identity/conditional-access/managed-policies))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | CM-2 | Baseline configuration |
| **CISA SCuBA (Entra ID)** | MS.AAD | Conditional Access baseline policies |

---

### 2.6 Block Device Code Flow

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.8 |
| NIST 800-53 | AC-3, IA-2 |

#### Description
Block the OAuth device code flow tenant-wide via a Conditional Access authentication-flows policy unless a specific, inventoried device-login use case (conference-room hardware, input-constrained devices) requires it — in which case scope an exception to those accounts only.

#### Rationale
**Why This Matters:**
- Device code phishing (tracked by Microsoft as **Storm-2372**, active since 2025) tricks users into entering an attacker-generated device code at a legitimate Microsoft URL, handing the attacker access and refresh tokens without ever capturing a password
- The stolen token satisfies MFA — this attack class bypasses MFA entirely, making preventive blocking the only strong control
- Microsoft now ships "Block device code flow" as an auto-enabling Microsoft-managed policy; adopting it deliberately (with your exceptions) beats waiting for auto-enable

**Attack Prevented:** Device code phishing (Storm-2372), MFA-bypassing token theft

#### ClickOps Implementation

**Step 1: Create the Authentication-Flows Policy**
1. Navigate to: **Protection** → **Conditional Access** → **Policies** → **+ New policy**
2. Configure:
   - **Name:** Block device code flow
   - **Users:** All users (exclude emergency accounts and any inventoried device-login service accounts)
   - **Cloud apps:** All cloud apps
   - **Conditions** → **Authentication flows** → check **Device code flow**
   - **Grant:** Block access
3. Enable policy: **On** (use Report-only first if you must inventory legitimate usage)

**Time to Complete:** ~15 minutes

#### Validation & Testing
1. Attempt a device-code sign-in (`az login --use-device-code`) as a standard user — it should be blocked
2. Review sign-in logs for device-code authentication attempts to catch legitimate usage before full enforcement

**Expected result:** Device code flow blocked tenant-wide except for scoped exceptions. ([Microsoft Storm-2372 advisory](https://www.microsoft.com/en-us/security/blog/2025/02/13/storm-2372-conducts-device-code-phishing-campaign/))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | AC-3 | Access enforcement |
| **CISA SCuBA (Entra ID)** | MS.AAD | Risk-based Conditional Access |

---

## 3. Privileged Identity Management

### 3.1 Enable Just-In-Time Access for Admin Roles

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 6.8 |
| NIST 800-53 | AC-2(7), AC-6(1) |

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
- Microsoft Entra ID P2 license
- Global Administrator or Privileged Role Administrator

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

{% include pack-code.html vendor="microsoft-entra-id" section="3.1" %}

#### Validation & Testing
**How to verify the control is working:**
1. Verify no permanent Global Admin assignments (except emergency accounts)
2. Test PIM activation as eligible admin
3. Confirm MFA required on activation
4. Verify justification is captured in audit log
5. Check activation expires after configured duration

**Expected result:** Admins activate roles on-demand, access expires automatically

---

### 3.2 Configure Access Reviews

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.1, 5.3 |
| NIST 800-53 | AC-2(3) |

#### Description
Enable recurring access reviews for privileged roles and group memberships to ensure continued business need for access.

#### Rationale
**Why This Matters:**
- Access tends to accumulate over time as employees change roles, leaving users with privileges they no longer need
- Recurring reviews force periodic re-justification, shrinking the standing attack surface of privileged accounts
- Removing stale privileged and group memberships limits what a compromised account can reach

**Attack Prevented:** Privilege creep, orphaned-access abuse, insider misuse of stale permissions

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

### 3.3 Protect High-Value Accounts with Restricted Management Administrative Units

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 6.8 |
| NIST 800-53 | AC-6(1), AC-2(11) |

#### Description
Place executive, break-glass, and other high-value accounts (and sensitive groups) into a Restricted Management Administrative Unit so that only role assignments scoped to that AU can modify them — tenant-wide role holders, including Helpdesk Administrators and even unscoped Global Administrator role assignments, cannot reset their passwords or change their MFA methods.

#### Rationale
**Why This Matters:**
- Tenant-wide helpdesk and user-management roles can reset any user's password or MFA by default — a socially engineered helpdesk agent becomes a path to your CEO's mailbox
- PIM and access reviews govern who HOLDS roles; Restricted Management AUs govern which ACCOUNTS those roles can touch — a complementary blast-radius control
- Scoping modification rights to a small, named set of admins makes targeted account-takeover materially harder

**Attack Prevented:** Helpdesk social engineering against executives, privileged-account takeover via tenant-wide role abuse

#### Prerequisites
- Microsoft Entra ID P1 license
- Inventory of high-value accounts (executives, break-glass, service-critical)

#### ClickOps Implementation

**Step 1: Create the Restricted Management AU**
1. Navigate to: **Microsoft Entra admin center** → **Identity** → **Roles & admins** → **Admin units** → **+ Add**
2. Name it (e.g., "Protected Accounts")
3. Set **Restricted management administrative unit** to **Yes**
4. Create, then add the high-value users/groups as members

**Step 2: Scope Management Rights**
1. In the AU, open **Roles and administrators**
2. Assign the minimum roles (e.g., Privileged Authentication Administrator) scoped to this AU, to a small named set of admins

**Time to Complete:** ~30 minutes

#### Validation & Testing
1. As a tenant-wide Helpdesk Administrator, attempt a password reset on a protected account — it must fail
2. Confirm the AU-scoped admin can perform the same reset
3. Review AU membership quarterly alongside access reviews ([3.2](#32-configure-access-reviews))

**Expected result:** Only AU-scoped role holders can modify protected accounts. ([Restricted management AUs](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/admin-units-restricted-management))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.3 | Access modification restriction |
| **NIST 800-53** | AC-6(1) | Least privilege — authorize access |

---

## 4. Application Security

### 4.1 Restrict User Consent to Applications

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.5 |
| NIST 800-53 | AC-3, CM-7 |

#### Description
Prevent users from granting OAuth consent to third-party applications and from registering new application objects. Require admin approval for all new application access requests. Both settings default to permissive in every new tenant.

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

**Step 3: Block User App Registration**
1. Navigate to: **Identity** → **Users** → **User settings**
2. Set **Users can register applications** to **No**
3. Grant the **Application Developer** role only to the specific users who legitimately need to register apps
4. Click **Save**

> By default every user can register application objects — a shadow-IT and consent-phishing surface distinct from the consent setting above. ([Delegate app registration](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/delegate-app-roles))

**Time to Complete:** ~20 minutes

#### Code Implementation

{% include pack-code.html vendor="microsoft-entra-id" section="4.1" %}

---

### 4.2 Review and Restrict Application Permissions

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.6 |
| NIST 800-53 | AC-6 |

#### Description
Regularly audit enterprise applications for excessive permissions, especially high-risk permissions like Mail.ReadWrite, Directory.ReadWrite.All, and full_access_as_app.

#### Rationale
**Why This Matters:**
- OAuth applications holding broad Graph permissions can read mail, files, and directory data across the entire tenant
- A single over-privileged or compromised app grants attackers persistent, MFA-bypassing access to sensitive data
- Periodic permission audits catch dangerous grants that accumulate from forgotten, abandoned, or maliciously installed integrations

**Attack Prevented:** OAuth application abuse, data exfiltration via excessive app permissions, persistent backdoor access

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

#### Code Implementation

{% include pack-code.html vendor="microsoft-entra-id" section="4.2" %}

---

### 4.3 Retire Azure AD Graph API Usage

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.2, 16.13 |
| NIST 800-53 | SA-22, SI-2 |

#### Description
Inventory and migrate any application, script, or automation still calling the deprecated Azure AD Graph API (`graph.windows.net`) to Microsoft Graph, and add detection for anomalous actor attribution in audit logs.

#### Rationale
**Why This Matters:**
- **CVE-2025-55241** (CVSS 10.0) chained undocumented internal "Actor tokens" with a tenant-validation failure in the legacy Azure AD Graph API to let an attacker impersonate any user — including Global Admins — in any tenant, leaving no sign-in log trail; Microsoft patched the validation flaw (July 17, 2025) and blocked apps from requesting Actor tokens against Azure AD Graph (August 6, 2025)
- Azure AD Graph is deprecated; anything still calling it is riding an unmaintained, incident-prone surface
- The attack's audit signature — a service display name (e.g., Exchange, SharePoint) paired with a user UPN as actor — is detectable in audit logs

**Attack Prevented:** Cross-tenant impersonation via legacy-API token abuse, silent Global Admin takeover

#### ClickOps Implementation

**Step 1: Inventory Azure AD Graph Callers**
1. Navigate to: **Monitoring** → **Sign-in logs** → **Service principal sign-ins**
2. Filter by **Resource** = Windows Azure Active Directory (`graph.windows.net`)
3. List every application still calling the legacy API

**Step 2: Migrate to Microsoft Graph**
1. For each caller, migrate API calls to Microsoft Graph (`graph.microsoft.com`) equivalents
2. Remove Azure AD Graph permissions from the app registrations once migrated

**Step 3: Add Actor-Mismatch Detection**
1. In your SIEM (see [5.1](#51-enable-sign-in-and-audit-logging)), alert on directory audit events where the initiating actor pairs a first-party service display name (Exchange, SharePoint) with a user UPN — the CVE-2025-55241 signature

**Time to Complete:** ~1-2 hours (plus migration effort per app)

#### Validation & Testing
1. Service-principal sign-in logs show zero `graph.windows.net` calls from your own apps
2. Detection rule fires on simulated mismatched-actor audit events

**Expected result:** No first-party dependence on Azure AD Graph; actor-mismatch detection live. ([CVE-2025-55241 research](https://dirkjanm.io/obtaining-global-admin-in-every-entra-id-tenant-with-actor-tokens/))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.1 | Vulnerability management |
| **NIST 800-53** | SA-22 | Unsupported system components |

---

## 5. Monitoring & Detection

### 5.1 Enable Sign-In and Audit Logging

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2, AU-3, AU-6 |

#### Description
Enable and export Entra ID sign-in and audit logs for security monitoring, threat detection, and compliance.

#### Rationale
**Why This Matters:**
- Without exported logs, attacker activity such as role changes and risky sign-ins goes undetected until damage is done
- Centralizing sign-in and audit logs in a SIEM enables correlation, alerting, and forensic investigation
- Default log retention in Entra ID is limited, so exporting preserves the evidence needed for incident response and compliance audits

**Attack Prevented:** Undetected intrusion, delayed breach discovery, audit-trail gaps

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

#### Code Implementation

{% include pack-code.html vendor="microsoft-entra-id" section="5.1" %}

---

### 5.2 Monitor Identity Secure Score

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CA-7 |

#### Description
Regularly review Identity Secure Score to track security posture and identify improvement opportunities.

#### Rationale
**Why This Matters:**
- Identity Secure Score surfaces concrete, prioritized gaps in MFA, legacy authentication, and privileged access configuration
- Tracking the score over time catches configuration drift and regressions before attackers can exploit them
- It translates Microsoft's evolving identity best practices into actionable, measurable improvements

**Attack Prevented:** Misconfiguration drift, unaddressed identity weaknesses, security-posture regression

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

{% include pack-code.html vendor="microsoft-entra-id" section="5.3" %}

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

### CIS Microsoft 365 Foundations Benchmark Mapping

> **Benchmark note:** Entra ID identity controls (MFA, legacy authentication, Conditional Access, consent, PIM) live in the **CIS Microsoft 365 Foundations Benchmark** — not the CIS Azure Foundations Benchmark this guide previously cited. CIS M365 Foundations **v7.0.0** (May 2026) added 21 controls and rehomed 12 identity recommendations from the Azure benchmark; consult the [current benchmark](https://www.cisecurity.org/benchmark/microsoft_365) for exact recommendation IDs, which shift across major versions.

| Benchmark Area | Entra ID Control | Guide Section |
|---------------|------------------|---------------|
| MFA enforcement | Phishing-resistant MFA | [1.1](#11-enforce-phishing-resistant-mfa) |
| Legacy authentication | Block legacy auth | [2.1](#21-block-legacy-authentication) |
| Privileged access | PIM just-in-time roles | [3.1](#31-enable-just-in-time-access-for-admin-roles) |
| Emergency access | Break-glass accounts | [1.2](#12-configure-emergency-access-break-glass-accounts) |
| Application consent | Restrict user consent & registration | [4.1](#41-restrict-user-consent-to-applications) |

### CISA SCuBA Secure Configuration Baseline (Entra ID) Mapping

The [CISA SCuBA baseline for Entra ID](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/baselines/aad.md) (assessable with the ScubaGear tool) maps to this guide:

| SCuBA Policy Area | Guide Section |
|-------------------|---------------|
| Block legacy authentication (MS.AAD.1) | [2.1](#21-block-legacy-authentication) |
| Risk-based Conditional Access (MS.AAD.2) | [2.4](#24-block-high-risk-sign-ins) |
| Phishing-resistant MFA & secure registration (MS.AAD.3) | [1.1](#11-enforce-phishing-resistant-mfa) |
| Centralized logging to SOC (MS.AAD.4) | [5.1](#51-enable-sign-in-and-audit-logging) |
| App registration & consent restriction (MS.AAD.5) | [4.1](#41-restrict-user-consent-to-applications) |
| Highly privileged / just-in-time access (MS.AAD.7) | [3.1](#31-enable-just-in-time-access-for-admin-roles) |

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
- [Microsoft Trust Center](https://www.microsoft.com/en-us/trust-center)
- [Microsoft Entra ID Product Documentation](https://learn.microsoft.com/en-us/entra/)
- [Best Practices to Secure with Microsoft Entra ID](https://learn.microsoft.com/en-us/entra/architecture/secure-best-practices)
- [Require MFA for All Users with Conditional Access](https://learn.microsoft.com/en-us/entra/identity/conditional-access/policy-all-users-mfa-strength)
- [Plan Conditional Access Deployment](https://learn.microsoft.com/en-us/entra/identity/conditional-access/plan-conditional-access)
- [Conditional Access - Zero Trust Policy Engine](https://learn.microsoft.com/en-us/entra/identity/conditional-access/overview)
- [Privileged Identity Management](https://learn.microsoft.com/en-us/entra/id-governance/privileged-identity-management/)

**API Documentation:**
- [Microsoft Graph Identity and Network Access Overview](https://learn.microsoft.com/en-us/graph/identity-network-access-overview)
- [Microsoft Graph API Reference](https://learn.microsoft.com/en-us/graph/api/overview)
- [Microsoft Graph PowerShell SDK](https://learn.microsoft.com/en-us/powershell/microsoftgraph/)

**Compliance Frameworks:**
- SOC 1, SOC 2, SOC 3, ISO 27001, ISO 27017, ISO 27018, ISO 27701, FedRAMP — via [Microsoft Service Trust Portal](https://servicetrust.microsoft.com/)
- [Microsoft Entra Identity Standards Overview](https://learn.microsoft.com/en-us/entra/standards/standards-overview)

**Hardening Benchmarks:**
- [CIS Microsoft 365 Foundations Benchmark](https://www.cisecurity.org/benchmark/microsoft_365) — v7.0.0 houses the Entra ID identity controls (rehomed from the Azure Foundations Benchmark in May 2026)
- [CISA SCuBA Secure Configuration Baseline for Entra ID](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/baselines/aad.md) — assessable with ScubaGear
- [Microsoft-managed Conditional Access policies](https://learn.microsoft.com/en-us/entra/identity/conditional-access/managed-policies)
- [Mandatory MFA for Microsoft admin portals](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-mandatory-multifactor-authentication)

**Security Incidents:**
- [Midnight Blizzard Attack Guidance (January 2024)](https://www.microsoft.com/en-us/security/blog/2024/01/25/midnight-blizzard-guidance-for-responders-on-nation-state-attack/) — Test account without MFA led to corporate email compromise via password spray
- [CVE-2025-55241 — Actor tokens / Azure AD Graph cross-tenant impersonation](https://dirkjanm.io/obtaining-global-admin-in-every-entra-id-tenant-with-actor-tokens/) (CVSS 10.0; see [4.3](#43-retire-azure-ad-graph-api-usage))
- [Storm-2372 device code phishing](https://www.microsoft.com/en-us/security/blog/2025/02/13/storm-2372-conducts-device-code-phishing-campaign/) (see [2.6](#26-block-device-code-flow))

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-03 | 0.2.0 | draft | Currency update: mandatory-MFA enforcement floor, Microsoft-managed CA policies + per-user MFA retirement (2.5), block device code flow / Storm-2372 (2.6), Restricted Management AUs (3.3), app-registration restriction (4.1), retire Azure AD Graph + CVE-2025-55241 detection (4.3); remap compliance from CIS Azure to CIS M365 Foundations v7.0.0; add CISA SCuBA mapping | Claude Code (Sonnet 5) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with authentication, Conditional Access, PIM, and monitoring | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)

---
layout: guide
title: "Microsoft 365 Hardening Guide"
vendor: "Microsoft 365"
slug: "microsoft-365"
platform: "Microsoft"
platform_slug: "microsoft-365"
product: "Common Controls"
tier: "1"
category: "Productivity"
description: "Tenant-wide security hardening for Microsoft 365 — the Common Controls hub (MFA and legacy auth, PIM, break-glass, OAuth consent, data security, unified audit logging, Exchange Online and Teams) shared by the Microsoft Entra ID and Microsoft Intune product guides."
version: "0.3.1"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---

## Overview

Microsoft 365 is the world's most widely deployed productivity suite, with over **345 million paid seats** across enterprises globally. As the central collaboration platform for email, documents, and communication, M365 represents a critical attack surface. The **January 2024 Midnight Blizzard breach** demonstrated how a single misconfigured test tenant without MFA enabled nation-state actors to access Microsoft's own corporate email, including senior leadership and cybersecurity teams.

### Intended Audience
- Security engineers managing Microsoft 365 environments
- IT administrators configuring tenant security
- GRC professionals assessing cloud productivity compliance
- Third-party risk managers evaluating M365 integrations

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide is the **Common Controls hub** for the Microsoft platform. It covers the tenant-wide configurations that apply across every Microsoft 365 workload: the authentication and privileged-access requirements every service inherits, OAuth and application consent, SharePoint/OneDrive data security, Exchange Online mail flow, Teams external access, and the unified audit log. Product-specific hardening — the Entra ID identity control plane and the Intune endpoint-management admin plane — lives in the product guides listed below. Azure infrastructure hardening is covered in a separate guide.

The division is by administrative surface, not by topic. This hub states **what must be true for the tenant**; a product guide covers the mechanics that exist only in that product's console and the automation that goes with them. Both layers are needed: a correct tenant policy still fails if the Entra authentication-method policy leaves SMS enabled, or if Intune's own admin roles hand a helpdesk account the ability to wipe 200,000 devices.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Network Access Controls](#2-network-access-controls)
3. [OAuth & Integration Security](#3-oauth--integration-security)
4. [Data Security](#4-data-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Third-Party Integration Security](#6-third-party-integration-security)
8. [Exchange Online Mail Flow & Email Authentication](#8-exchange-online-mail-flow--email-authentication)
9. [Microsoft Teams External Access Security](#9-microsoft-teams-external-access-security)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## Products in This Platform

Microsoft is a multi-product platform. This guide is the **Common Controls hub** — the tenant-wide controls configured once and inherited by every Microsoft 365 workload. Product-specific controls live in their own guides:

| Product | Guide | Covers |
|---------|-------|--------|
| **Common Controls** (this guide) | — | Tenant MFA requirement and legacy-auth block, PIM program, break-glass accounts, named locations, OAuth consent and app permissions, sensitivity labels and DLP, external sharing, unified audit logging and Defender alerting |
| **Microsoft Entra ID** | [Microsoft Entra ID guide](/guides/microsoft-entra-id/) | Authentication methods and authentication strengths, Conditional Access policy authoring (compliant devices, sign-in risk, Microsoft-managed policies, device code flow), access reviews, restricted management administrative units, Azure AD Graph retirement, identity log export |
| **Microsoft Intune** | [Microsoft Intune guide](/guides/microsoft-intune/) | Intune RBAC and scope tags, Intune-role PIM scoping, Multi-Admin Approval, remote-wipe restriction and rate alerting, token-replay hardening, Stryker-pattern detection |
| **Exchange Online** | — | No product guide yet — mail flow, Direct Send, external forwarding, and SPF/DKIM/DMARC are covered in this hub (§8) |
| **Microsoft Teams** | — | No product guide yet — external access and unmanaged-account federation are covered in this hub (§9) |

> **Moved and merged controls:** tenant-wide controls that previously appeared in the product guides now live here and are not duplicated. Merged in from the former Microsoft Intune guide: the mandatory-MFA enforcement phases (§1.1) and the break-glass exemption warning (§1.4). Merged in from the former Microsoft Entra ID guide: the mandatory-MFA enforcement floor (§1.1), offline credential custody for emergency accounts (§1.4), and blocking user app registration (§3.1). Conditional Access **policy authoring** for admin portals and device code flow consolidated into the Entra ID guide (§2.3, §2.6) from the Intune guide, which now points there.

---

## 1. Authentication & Access Controls

### 1.1 Enforce Phishing-Resistant MFA for All Users

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 6.5 |
| NIST 800-53 | IA-2(1), IA-2(6) |
| CIS M365 Benchmark | 1.1.1, 1.1.3 |

#### Description
Require phishing-resistant MFA (FIDO2 security keys, Windows Hello for Business, or certificate-based authentication) for all users. Microsoft reports that over 99.9% of compromised accounts had MFA disabled.

> **This is the tenant-wide requirement.** Enabling the individual authentication methods and authoring the "Phishing-Resistant MFA" authentication strength that this policy consumes happen in the Entra admin center — see [Microsoft Entra ID §1.1](/guides/microsoft-entra-id/#11-configure-authentication-methods-and-authentication-strengths). Scoping a stricter policy to Intune administrators is [Microsoft Intune §2.1](/guides/microsoft-intune/#21-require-phishing-resistant-mfa-for-all-intune-admins).

> **Enforcement floor — Microsoft now system-enforces MFA independent of your policies.** This is a floor, not a substitute: mandatory MFA does not distinguish strong factors from weak ones, so the phishing-resistant requirement below still has to be enforced by your own Conditional Access policy. ([Plan for mandatory Microsoft Entra multifactor authentication](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-mandatory-multifactor-authentication))
>
> | Phase | Enforcement began | Scope |
> |-------|-------------------|-------|
> | Phase 1 | October 2024 (Microsoft 365 admin center from February 2025) | Any **Create, Read, Update, or Delete** operation in the **Microsoft Entra admin center**, **Microsoft Intune admin center**, and **Azure portal** |
> | Phase 2 | October 1, 2025 | **Create, Update, Delete** via **Azure CLI**, **Azure PowerShell**, the Azure mobile app, **IaC tools**, **REST API (control plane)**, and Azure SDKs. Read operations are exempt |
>
> The postponement window has closed — Phase 1 could be deferred only to September 30, 2025 and Phase 2 only to **July 1, 2026**. Enforcement is scoped to the admin portals and Azure Resource Manager; Microsoft states that **Microsoft Graph APIs are generally not in scope**, which is why admin Conditional Access must target Graph explicitly ([Entra ID §2.3](/guides/microsoft-entra-id/#23-require-compliant-devices-for-admins)). Break-glass accounts are **included** in this enforcement — see [1.4](#14-configure-break-glass-emergency-access-accounts).

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
- Microsoft Entra ID P1 or P2 license (for Conditional Access)
- FIDO2-compatible security keys for privileged users
- Global Administrator or Security Administrator role
- User inventory for phased rollout planning

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

**Step 3: Require Phishing-Resistant Strength for Privileged Users**
1. Create the "Phishing-Resistant MFA" authentication strength and enable the underlying methods first — [Microsoft Entra ID §1.1](/guides/microsoft-entra-id/#11-configure-authentication-methods-and-authentication-strengths) covers both
2. Edit the Conditional Access policy from Step 2 (or create a second policy scoped to directory roles)
3. Under **Grant**, select **Require authentication strength** → **Phishing-Resistant MFA**
4. Apply to all admin roles at minimum; extend to all users once enrollment allows

**Time to Complete:** ~45 minutes (policy) + user enrollment time

#### Code Implementation

{% include pack-code.html vendor="microsoft-365" section="1.1" %}

#### Validation & Testing
**How to verify the control is working:**
1. Sign in as a test user and verify MFA prompt appears
2. Attempt sign-in from unmanaged device - MFA should be required
3. Review sign-in logs for MFA enforcement: **Entra admin center** → **Monitoring** → **Sign-in logs**
4. Run: `Get-MgIdentityConditionalAccessPolicy | Where-Object {$_.State -eq "enabled"}`

**Expected result:** All user sign-ins require MFA, sign-in logs show "MFA requirement satisfied"

#### Monitoring & Maintenance
**Ongoing monitoring:**
- Monitor sign-in logs for MFA bypass attempts
- Alert on sign-ins without MFA from Conditional Access exclusions
- Track MFA registration completion rates

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

**Profile Level:** L1 (Crawl)

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
- Microsoft is retiring the protocols themselves, not just discouraging them — organizations that wait for the forced cutover will experience unplanned application outages instead of a managed migration

**Attack Prevented:** Password spray via legacy protocols, credential theft replay

**Real-World Incidents:**
- **Midnight Blizzard (2024):** Initial access via password spray would have been blocked if legacy auth was disabled

#### Retirement Timeline (Act Before the Forced Cutover)

Microsoft has published firm end dates for the two protocols most commonly left enabled. Both were accelerated in response to the Midnight Blizzard intrusion, where legacy protocol access contributed to attacker reach.

| Protocol | Milestone | Date |
|----------|-----------|------|
| Exchange Web Services (EWS) | Begins being disabled globally for Exchange Online | October 2026 |
| Exchange Web Services (EWS) | Fully disabled — no exceptions, no re-enablement | April 2027 |
| SMTP AUTH (Client Submission) with Basic Authentication | Default-disabled across all tenants | End of December 2026 |

**What to do now:**
- Run the EWS usage reports in the Microsoft 365 admin center to identify every application, mailbox, and vendor integration still calling EWS
- Migrate each identified consumer to **Microsoft Graph**, which is the only supported successor API — there is no extended-support path for EWS
- For devices and line-of-business applications still using SMTP AUTH with Basic Authentication, move to OAuth-based authentication, High Volume Email, or Azure Communication Services Email before the December 2026 default-disable
- Treat any integration whose vendor has no Graph roadmap as a procurement risk, not just a technical one

Source: [Deprecation of Exchange Web Services in Exchange Online](https://learn.microsoft.com/exchange/clients-and-mobile-in-exchange-online/deprecation-of-ews-exchange-online)

#### Prerequisites
- Inventory of applications using legacy auth
- Migration plan for legacy applications to modern auth (OAuth 2.0)
- EWS usage report reviewed and every consumer assigned a Graph migration owner

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

{% include pack-code.html vendor="microsoft-365" section="1.2" %}

#### Validation & Testing
1. Attempt POP3/IMAP connection - should fail
2. Review sign-in logs for blocked legacy auth attempts
3. Verify legitimate applications still function via modern auth

**Expected result:** Legacy authentication attempts blocked, modern auth sign-ins succeed

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | IA-2 | Identification and authentication |
| **CIS M365** | 1.1.2 | Ensure legacy authentication is blocked |

---

### 1.3 Implement Privileged Identity Management (PIM)

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 6.8 |
| NIST 800-53 | AC-2(7), AC-6(1) |
| CIS M365 Benchmark | 1.1.4 |

#### Description
Enable just-in-time privileged access using Microsoft Entra Privileged Identity Management (PIM) to eliminate standing admin privileges and enforce approval workflows.

> **This is the tenant-wide PIM program.** Per-role activation settings and the Terraform/PowerShell implementation of eligible assignments are in [Microsoft Entra ID §3.1](/guides/microsoft-entra-id/#31-enable-just-in-time-access-for-admin-roles); the Intune-specific role set (Intune Administrator, Endpoint Security Manager) and its destructive-action risk profile are in [Microsoft Intune §3.1](/guides/microsoft-intune/#31-enable-privileged-identity-management-pim-for-intune-roles).

#### Rationale
**Why This Matters:**
- Standing privileges create persistent attack surface
- Compromised admin accounts provide unlimited access duration
- PIM provides audit trail for all privilege elevation

**Attack Prevented:** Privilege persistence, lateral movement, insider threats

**Real-World Incidents:**
- **Midnight Blizzard:** Persistent OAuth app permissions allowed extended access; time-limited roles would have reduced blast radius

#### Prerequisites
- Microsoft Entra ID P2 license
- Global Administrator or Privileged Role Administrator
- Defined approval workflow owners

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

{% include pack-code.html vendor="microsoft-365" section="1.3" %}

#### Validation & Testing
1. Verify no standing Global Admin assignments (all eligible)
2. Test PIM activation workflow as eligible admin
3. Confirm MFA and justification required on activation
4. Review PIM audit logs for activation events

**Expected result:** Admins must activate roles on-demand with MFA, approval, and justification

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.2 | Privileged access management |
| **NIST 800-53** | AC-2(7) | Privileged user accounts |
| **ISO 27001** | A.9.2.3 | Privileged access rights management |

---

### 1.4 Configure Break-Glass Emergency Access Accounts

**Profile Level:** L1 (Crawl)

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

**Attack Prevented:** Tenant-wide administrative lockout from Conditional Access misconfiguration or federation failure, undetected emergency account misuse

**Best Practice:**
- Minimum 2 break-glass accounts
- Cloud-only (no federation dependency)
- Excluded from all Conditional Access policies
- Long, complex passwords stored securely offline
- Monitored for any usage

> **Break-glass accounts are NOT exempt from tenant-level mandatory MFA.** Microsoft states enforcement "applies to all user accounts, regardless if they are a student account, break-glass account, an administrator account with activated or eligible roles, or any user exclusions that are enabled for them," and recommends these accounts be moved to **passkey (FIDO2)** or **certificate-based authentication**, both of which satisfy the requirement ([Plan for mandatory Microsoft Entra multifactor authentication](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-mandatory-multifactor-authentication)). A password-only break-glass account is now a locked-out break-glass account. Excluding these accounts from your own Conditional Access policies (Step 2 below) does not exempt them from Microsoft's platform enforcement — the two are separate mechanisms.

#### Prerequisites
- Global Administrator access
- Secure offline storage for credentials (safe, vault)
- Monitoring/alerting configured

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

**Step 3: Register a Phishing-Resistant Credential**
1. Register a **passkey (FIDO2)** or **certificate-based authentication** credential on each account so it satisfies Microsoft's mandatory MFA enforcement
2. Store the security key itself with the same custody controls as the password (Step 5)

**Step 4: Configure Monitoring**
1. Navigate to: **Microsoft Entra admin center** → **Monitoring** → **Diagnostic settings**
2. Create alert rule for any sign-in from break-glass accounts
3. Route the alert to a channel that is watched outside business hours — a break-glass sign-in is either a real emergency or a compromise, and both need a same-hour response

**Step 5: Store Credentials Securely Offline**
1. Print credentials on paper — no digital storage, no password manager that itself depends on the tenant
2. Store in a physically secure location (safe, vault)
3. Split credentials between multiple custodians where the organization's size allows, so no single person can use an emergency account alone
4. Document the access procedure, including who authorizes use and who must be notified

**Time to Complete:** ~45 minutes

#### Code Implementation

{% include pack-code.html vendor="microsoft-365" section="1.4" %}

#### Validation & Testing
1. Verify break-glass accounts can sign in bypassing Conditional Access
2. Test sign-in generates alert
3. Confirm credentials are securely stored offline
4. Document account usage procedure

**Expected result:** Emergency accounts accessible when needed, usage immediately alerted

---

## 2. Network Access Controls

### 2.1 Configure Trusted Locations and Named Locations

**Profile Level:** L2 (Walk)

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

**Attack Prevented:** Sign-ins from high-risk countries, credential misuse lacking trusted-location signals

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

{% include pack-code.html vendor="microsoft-365" section="2.1" %}

---

## 3. OAuth & Integration Security

### 3.1 Restrict User Consent to Applications

**Profile Level:** L1 (Crawl)

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
- Application Administrator or Global Administrator
- Defined application approval workflow

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

**Step 3: Block User App Registration**
1. Navigate to: **Identity** → **Users** → **User settings**
2. Set **Users can register applications** to **No**
3. Grant the **Application Developer** role only to the specific users who legitimately need to register apps
4. Click **Save**

> By default every user can register application objects — a shadow-IT and consent-phishing surface distinct from the consent setting above. ([Delegate app registration](https://learn.microsoft.com/en-us/entra/identity/role-based-access-control/delegate-app-roles))

**Time to Complete:** ~20 minutes

#### Code Implementation

{% include pack-code.html vendor="microsoft-365" section="3.1" %}

#### Validation & Testing
1. Attempt to authorize a third-party app as standard user - should be blocked
2. Submit admin consent request - verify workflow triggers
3. Review existing app permissions: **Enterprise applications** → **All applications** → Review permissions

**Expected result:** Users cannot grant app permissions; admin approval required

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | AC-3 | Access enforcement |
| **CIS M365** | 2.1 | Ensure third-party integrated applications are not allowed |

---

### 3.2 Review and Revoke Overprivileged App Permissions

**Profile Level:** L2 (Walk)

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

**Attack Prevented:** Mailbox data exfiltration via compromised or overprivileged OAuth applications

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

{% include pack-code.html vendor="microsoft-365" section="3.2" %}

---

## 4. Data Security

### 4.1 Enable Sensitivity Labels and Data Loss Prevention

**Profile Level:** L2 (Walk)

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

**Attack Prevented:** Accidental external sharing and unauthorized exfiltration of sensitive documents

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3, AC-22 |
| CIS M365 Benchmark | 3.2 |

#### Description
Restrict external sharing in SharePoint and OneDrive to prevent unauthorized data exposure.

#### Rationale
**Why This Matters:**
- Anonymous "Anyone" links let sensitive SharePoint and OneDrive files reach anyone who obtains the URL, with no authentication or audit trail
- Unrestricted external sharing is a primary path for accidental data leakage and intentional exfiltration by departing employees
- Requiring guests to authenticate with the invited account closes link-forwarding gaps and ties every external access to a verifiable identity
- Limiting sharing to approved domains or security groups keeps corporate documents out of personal and untrusted tenants

**Attack Prevented:** Anonymous link exposure, data exfiltration, link forwarding, unauthorized external access

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

{% include pack-code.html vendor="microsoft-365" section="4.2" %}

---

### 4.3 Enable Restricted Content Discovery on High-Risk Sites

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3, 3.7 |
| NIST 800-53 | AC-3, AC-21 |

#### Description

Use Restricted Content Discovery to exclude specific SharePoint sites from Microsoft 365 Copilot responses and organization-wide search while permission remediation is in progress. Setting `-RestrictContentOrgWideSearch $true` on a site keeps its content out of Copilot grounding and tenant-wide search results without changing any existing permissions, giving teams a safety valve for oversharing that would otherwise be exposed at machine speed.

#### Rationale

**Why This Matters:**

- Copilot inherits every permission a user already has, so a decade of accumulated oversharing that nobody noticed becomes instantly discoverable through natural-language prompts
- Legacy sites frequently carry broad "Everyone except external users" grants that were harmless when discovery required knowing the URL, and are dangerous when an AI assistant surfaces the content unprompted
- Permission remediation across a large SharePoint estate takes months; Restricted Content Discovery provides immediate containment while that cleanup proceeds
- The setting is non-destructive — users who already have direct access keep it, so applying it does not break active business workflows

**Attack Prevented:** AI-accelerated data discovery, insider reconnaissance via Copilot prompts, inadvertent exposure of HR, legal, and finance content through org-wide search

#### Prerequisites

- SharePoint Advanced Management (a licensed add-on, included with some Microsoft 365 E5 and Copilot bundles)
- SharePoint Administrator or Global Administrator role
- SharePoint Online Management Shell for the PowerShell method
- An inventory of high-risk sites, ideally from the SharePoint admin center Data Access Governance reports

#### ClickOps Implementation

**Step 1: Identify Oversharing Candidates**

1. Navigate to: **SharePoint admin center** → **Reports** → **Data access governance**
2. Review the **Sharing links** and **Sites with "Everyone except external users"** reports
3. Export the results and rank sites by sensitivity of content and breadth of access
4. Prioritize HR, legal, finance, executive, and merger-and-acquisition sites

**Step 2: Apply Restricted Content Discovery Per Site**

1. Navigate to: **SharePoint admin center** → **Sites** → **Active sites**
2. Select the target site, then open **Settings**
3. Enable **Restricted Content Discovery** for the site
4. Save, and repeat for each site on the prioritized list

**Step 3: Apply at Scale via PowerShell**

1. Connect with `Connect-SPOService -Url https://<tenant>-admin.sharepoint.com`
2. Apply the restriction to a single site with `Set-SPOSite -Identity <site-url> -RestrictContentOrgWideSearch $true`
3. For bulk application, pipe a reviewed CSV of site URLs through the same cmdlet rather than applying tenant-wide — over-application degrades legitimate Copilot value
4. Confirm the current state of any site with `Get-SPOSite -Identity <site-url> | Select-Object Url, RestrictContentOrgWideSearch`

**Step 4: Treat It as Temporary, Not Permanent**

1. Record each restricted site in the permission-remediation backlog with a named owner
2. Remove the restriction once the site's underlying permissions have been corrected
3. Review the restricted-site list quarterly so the control does not silently become permanent scaffolding around a problem nobody fixed

**Time to Complete:** ~30 minutes for initial application; permission remediation is a multi-month program

Source: [Restricted Content Discovery in SharePoint](https://learn.microsoft.com/en-us/sharepoint/restricted-content-discovery)

#### Validation & Testing

**How to verify the control is working:**

1. Run `Get-SPOSite -Identity <site-url> | Select-Object Url, RestrictContentOrgWideSearch` and confirm the value is `True`
2. As a user who does not have direct access to the site, prompt Copilot for content known to exist there — it should not be returned
3. Run the same query in organization-wide SharePoint search and confirm the content does not appear
4. As a user who *does* have direct site access, confirm they can still open the site and its files normally

**Expected result:** Restricted sites are absent from Copilot grounding and org-wide search, while direct access for legitimately permissioned users is unchanged.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | AC-21 | Information sharing |
| **ISO 27001** | A.8.3 | Information access restriction |

---

## 5. Monitoring & Detection

### 5.1 Enable Unified Audit Logging

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2, AU-3, AU-6 |
| CIS M365 Benchmark | 5.1 |

#### Description
Enable and configure unified audit logging to capture user and admin activities across all Microsoft 365 services.

> **Three log planes, three configurations.** The unified audit log below covers Microsoft 365 workload activity (Exchange, SharePoint, Teams, Purview). Identity events — sign-ins, Conditional Access results, service-principal activity — are exported separately from the Entra admin center ([Microsoft Entra ID §5.1](/guides/microsoft-entra-id/#51-export-entra-id-sign-in-and-audit-logs)), and Intune device and admin actions have their own audit surface ([Microsoft Intune §7.1](/guides/microsoft-intune/#71-enable-comprehensive-intune-audit-logging)). Configuring one does not populate the others; an incident that starts with a stolen token and ends with a mass device wipe crosses all three.

#### Rationale
**Why This Matters:**
- Audit logs are essential for incident investigation
- Provides visibility into data access, sharing, and admin changes
- Required for compliance with most security frameworks
- Default retention is 180 days (E5) or 90 days (other plans)

**Attack Prevented:** Undetected attacker activity across Microsoft 365 services — incidents uninvestigable without audit evidence

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

{% include pack-code.html vendor="microsoft-365" section="5.1" %}

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

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.11 |
| NIST 800-53 | SI-4 |

#### Description
Enable Microsoft Defender for Office 365 and configure alert policies for suspicious activities.

#### Rationale
**Why This Matters:**
- Without active alerting, malicious sign-ins, phishing campaigns, and admin abuse go unnoticed until the damage is already done
- Defender for Office 365 detonates malicious links and attachments before they reach users, blocking phishing and malware at delivery
- Alerts on high-risk events (new admin roles, Conditional Access changes, suspicious OAuth grants) shorten attacker dwell time and speed incident response
- Timely detection is the difference between a contained incident and a full tenant compromise

**Attack Prevented:** Phishing, malware delivery, undetected account takeover, privilege escalation, OAuth consent abuse

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

#### Code Implementation

{% include pack-code.html vendor="microsoft-365" section="5.2" %}

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

## 8. Exchange Online Mail Flow & Email Authentication

### 8.1 Reject Direct Send

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.7 |
| NIST 800-53 | SC-7, SI-8 |

#### Description

Disable Direct Send so unauthenticated mail can no longer be submitted to the tenant's Exchange Online Protection endpoint. Direct Send accepts anonymous SMTP on port 25 at the tenant's MX host and allows any sender on the internet to submit mail claiming to be from an accepted domain. Setting `Set-OrganizationConfig -RejectDirectSend $true` causes Exchange Online to reject those submissions.

#### Rationale

**Why This Matters:**

- Direct Send requires no authentication whatsoever — anyone who knows the tenant's MX endpoint can submit mail addressed from an internal domain
- Messages arriving this way land in internal mailboxes appearing to come from colleagues, which is exactly the pretext phishing needs and exactly the signal users are trained to trust
- Attackers use Direct Send to bypass gateways and third-party mail filters entirely, because the mail never traverses the path those controls inspect
- Most tenants have Direct Send enabled without ever using it; Microsoft's own guidance states that most customers do not need it
- Disabling it is a single tenant-level switch with a clean, diagnosable failure mode — rejected submissions return a 550 5.7.68 response rather than failing silently

**Attack Prevented:** Internal-looking phishing from external senders, mail-filter bypass, brand and domain spoofing against your own employees

#### Prerequisites

- Exchange Online Administrator or Global Administrator role
- Exchange Online PowerShell module
- An inventory of devices and applications that currently submit mail via Direct Send (multifunction printers, scanners, monitoring systems, and legacy line-of-business apps are the usual suspects)
- A migration path for any legitimate Direct Send users — an authenticated SMTP relay connector is the standard replacement

#### ClickOps Implementation

There is no Exchange admin center toggle for this setting; it is configured through PowerShell. The identification work below, however, is done in the portal.

**Step 1: Identify Legitimate Direct Send Traffic Before Blocking**

1. Navigate to: **Exchange admin center** → **Mail flow** → **Message trace**
2. Run a trace covering at least 30 days, filtering for messages from your accepted domains that arrived without authentication
3. Record every source IP address that appears, and map each one back to a device or application owner
4. Confirm each legitimate sender has an alternative path configured — an inbound connector for SMTP relay, or authenticated client submission

**Step 2: Reject Direct Send**

1. Connect to Exchange Online PowerShell with `Connect-ExchangeOnline`
2. Check the current state with `Get-OrganizationConfig | Select-Object RejectDirectSend`
3. Apply the setting with `Set-OrganizationConfig -RejectDirectSend $true`
4. Allow time for the change to propagate across the service before testing

**Step 3: Monitor for Breakage**

1. Watch message trace and your service desk queue for the first two weeks after the change
2. Any device that was missed in Step 1 will fail loudly with a 550 5.7.68 rejection, which is straightforward to attribute to this control
3. Rather than reverting the tenant-wide setting for a single missed printer, move that device onto an authenticated relay connector

**Time to Complete:** ~15 minutes to apply; discovery of legitimate senders typically takes 30 days of trace data

Source: [Reject Direct Send in Exchange Online](https://office365itpros.com/2025/04/30/reject-send-exo/)

#### Validation & Testing

**How to verify the control is working:**

1. Run `Get-OrganizationConfig | Select-Object RejectDirectSend` and confirm the value is `True`
2. From an external host with no authentication, attempt an SMTP submission on port 25 to your tenant MX endpoint using a From address in one of your accepted domains
3. Confirm the submission is rejected with a 550 5.7.68 response
4. Send normal internal and external mail through authenticated paths and confirm delivery is unaffected

**Expected result:** Unauthenticated submissions claiming an internal sender are rejected at the service edge; all authenticated and connector-based mail flow continues normally.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.6 | Boundary protection |
| **NIST 800-53** | SI-8 | Spam protection |
| **ISO 27001** | A.8.20 | Network security |

---

### 8.2 Block Automatic External Forwarding

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-4, SC-7 |
| CISA SCuBA | MS.EXO.1.1v2 |

#### Description

Disable automatic forwarding of mail to external recipients at the tenant level using `Set-HostedOutboundSpamFilterPolicy -AutoForwardingMode Off`. Automatic forwarding rules are one of the most reliable indicators of a compromised mailbox and one of the quietest exfiltration channels available to an attacker.

#### Rationale

**Why This Matters:**

- Creating a forwarding rule is the standard first move after a business email compromise, because it gives the attacker durable access to the victim's mail even after the password is reset
- Forwarded mail leaves no obvious trace for the user — the message still arrives in their inbox, so nothing looks wrong from their side
- A single rule can exfiltrate months of correspondence, invoices, and credential-reset emails without any further attacker interaction
- Departing employees use the same mechanism to take customer and pipeline data with them
- Blocking it tenant-wide is far more reliable than detecting and removing rules one at a time after the fact

**Attack Prevented:** Business email compromise persistence, silent mail exfiltration, insider data theft

#### Prerequisites

- Exchange Online Administrator or Global Administrator role
- Exchange Online PowerShell module
- Review of existing forwarding rules so legitimate business cases are identified before the block is applied

#### ClickOps Implementation

**Step 1: Audit Existing Forwarding**

1. Navigate to: **Exchange admin center** → **Reports** → **Mail flow** → **Auto-forwarded messages report**
2. Review every mailbox currently forwarding externally and identify the business justification, if any
3. Treat any forwarding rule the mailbox owner cannot explain as a potential compromise indicator and investigate it before proceeding

**Step 2: Set the Outbound Spam Filter Policy**

1. Navigate to: **Microsoft Defender portal** → **Email & collaboration** → **Policies & rules** → **Threat policies** → **Anti-spam**
2. Open the **Anti-spam outbound policy (Default)**
3. Set **Automatic forwarding rules** to **Off - Forwarding is disabled**
4. Save the policy

**Step 3: Apply via PowerShell**

1. Connect with `Connect-ExchangeOnline`
2. Apply the setting with `Set-HostedOutboundSpamFilterPolicy -Identity Default -AutoForwardingMode Off`
3. Confirm no other outbound spam filter policies override the default with a weaker setting

**Step 4: Handle Legitimate Exceptions Deliberately**

1. Where a genuine business need exists, use a mail flow rule scoped to specific senders and destinations rather than re-enabling forwarding tenant-wide
2. Document each exception with an owner and a review date

**Time to Complete:** ~30 minutes including the forwarding audit

Source: [CISA SCuBA Exchange Online Secure Configuration Baseline](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/baselines/exo.md)

#### Validation & Testing

**How to verify the control is working:**

1. Run `Get-HostedOutboundSpamFilterPolicy | Select-Object Name, AutoForwardingMode` and confirm every policy reports `Off`
2. As a test user, create an inbox rule forwarding to an external address, then send mail to that user
3. Confirm the message is not delivered to the external address
4. Re-run the auto-forwarded messages report after a week and confirm external forwarding volume has dropped to zero

**Expected result:** No mail is automatically forwarded to external recipients; internal forwarding and manual forwarding by users continue to work.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.7 | Restricted data transmission |
| **NIST 800-53** | AC-4 | Information flow enforcement |
| **CISA SCuBA** | MS.EXO.1.1v2 | Automatic forwarding to external domains SHALL be disabled |

---

### 8.3 Enforce SPF, DKIM, and DMARC for All Domains

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 9.2 |
| NIST 800-53 | SC-8, SI-8 |
| CISA SCuBA | MS.EXO.2.2v3, MS.EXO.3.1v1, MS.EXO.4.1v1 |

#### Description

Publish and enforce the three email authentication standards for every accepted domain: SPF to declare authorized sending sources, DKIM to cryptographically sign outbound mail, and DMARC with a `p=reject` policy plus RUA and RUF reporting addresses to instruct receivers what to do when the first two fail. Domains that do not send mail need these records too — an unused domain without a restrictive policy is a free spoofing asset for an attacker.

#### Rationale

**Why This Matters:**

- Without DMARC enforcement, anyone on the internet can send mail that appears to come from your domain, and receiving mail servers have no instruction to reject it
- SPF alone breaks on forwarding and DKIM alone does not bind the signature to the visible From address; only the three together produce a verifiable, enforceable result
- A `p=none` DMARC record is monitoring, not protection — it collects reports while still allowing spoofed mail through, and many organizations leave it there indefinitely
- RUA and RUF reporting is what makes the eventual move to `p=reject` safe, because it reveals legitimate senders you did not know about before they start bouncing
- Parked and marketing domains are spoofed precisely because nobody thinks to protect them

**Attack Prevented:** Domain spoofing, brand impersonation, vendor invoice fraud, phishing that uses your own domain against your partners and customers

#### Prerequisites

- Access to DNS for every accepted domain, including parked and marketing domains
- Exchange Online Administrator or Global Administrator role
- A complete inventory of legitimate sending sources — marketing platforms, ticketing systems, payroll providers, and CRM tools all send as your domain
- A DMARC report processing destination, whether a vendor service or an internal mailbox

#### ClickOps Implementation

**Step 1: Publish SPF for Every Domain**

1. Inventory all sending sources for the domain, including third-party platforms
2. Publish a single TXT record per domain in the form `v=spf1 include:spf.protection.outlook.com -all`, adding an `include:` entry for each additional legitimate sender
3. Use the hard fail qualifier `-all` rather than the soft fail `~all`; soft fail asks receivers to accept the mail anyway
4. For domains that send no mail at all, publish `v=spf1 -all`
5. Stay within the ten DNS lookup limit — exceeding it causes SPF to fail permanently

**Step 2: Enable DKIM Signing**

1. Navigate to: **Microsoft Defender portal** → **Email & collaboration** → **Policies & rules** → **Threat policies** → **Email authentication settings** → **DKIM**
2. Select each custom domain in the list
3. Publish the two CNAME selector records the portal displays at your DNS provider
4. Return to the portal and set **Sign messages for this domain with DKIM signatures** to **Enabled**
5. Repeat for every accepted domain — the default `onmicrosoft.com` domain is signed automatically, custom domains are not

**Step 3: Publish DMARC at p=reject**

1. Start with a monitoring record at `_dmarc.<domain>`: `v=DMARC1; p=none; rua=mailto:dmarc-rua@yourdomain.com; ruf=mailto:dmarc-ruf@yourdomain.com; pct=100`
2. Collect and review aggregate reports for 30 to 60 days, resolving every legitimate sender that fails alignment
3. Move to `p=quarantine`, monitor for a further period, then move to `p=reject`
4. The end state for every domain is `v=DMARC1; p=reject; rua=mailto:dmarc-rua@yourdomain.com; ruf=mailto:dmarc-ruf@yourdomain.com; pct=100`
5. For parked and non-sending domains, go straight to `p=reject` — there is no legitimate mail to break

**Step 4: Enable DKIM Signing via PowerShell at Scale**

1. Connect with `Connect-ExchangeOnline`
2. Review current state with `Get-DkimSigningConfig | Select-Object Domain, Enabled, Status`
3. Enable a domain with `Set-DkimSigningConfig -Identity <domain> -Enabled $true`

**Time to Complete:** ~2 hours of configuration, plus 30 to 60 days of DMARC monitoring before enforcement

Source: [CISA SCuBA Exchange Online Secure Configuration Baseline](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/baselines/exo.md)

#### Validation & Testing

**How to verify the control is working:**

1. Query the SPF record for each domain and confirm it ends in `-all` and resolves within ten DNS lookups
2. Run `Get-DkimSigningConfig | Select-Object Domain, Enabled` and confirm every accepted domain reports `True`
3. Query the `_dmarc` TXT record for each domain and confirm the policy is `p=reject` with both `rua` and `ruf` addresses present
4. Send a test message to an external mailbox and inspect the received headers for `spf=pass`, `dkim=pass`, and `dmarc=pass`
5. Confirm DMARC aggregate reports are arriving at the RUA address and are being reviewed by a named owner

**Expected result:** All three records are published and enforcing for every accepted domain, legitimate mail passes all three checks, and spoofed mail claiming your domain is rejected by receiving servers.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.7 | Transmission integrity |
| **NIST 800-53** | SC-8 | Transmission confidentiality and integrity |
| **CISA SCuBA** | MS.EXO.2.2v3 | An SPF policy SHALL be published for each domain |
| **CISA SCuBA** | MS.EXO.3.1v1 | DKIM SHOULD be enabled for all domains |
| **CISA SCuBA** | MS.EXO.4.1v1 | A DMARC policy SHALL be published for every second-level domain |

---

## 9. Microsoft Teams External Access Security

### 9.1 Restrict Teams External Access and Unmanaged Accounts

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.8, 9.6 |
| NIST 800-53 | AC-3, AC-20 |

#### Description

Constrain Teams federation so external contact is limited to an explicit allowlist of partner domains, and disable chat and meeting invitations from unmanaged consumer Teams accounts. Left at its permissive default, Teams external access lets anyone with a Microsoft tenant — including a tenant created minutes ago for the purpose — initiate a chat with your employees inside a trusted interface.

#### Rationale

**Why This Matters:**

- Teams messages carry an implicit trust that email does not; a message arriving in Teams reads as internal even when the sender is external
- Attackers register trial tenants with display names like "Help Desk" or "IT Support" and message employees directly, a technique that requires no malware and no credential theft to get started
- The vishing pattern pairs a flood of nuisance email with a Teams call from the fake support account offering to fix it, which is a highly effective pretext because the "problem" is real and the employee is already frustrated
- Once the target accepts remote assistance, the attacker has hands-on access without ever defeating a technical control
- An allowlist of known partner domains preserves the collaboration Teams is bought for while removing the anonymous inbound path entirely

**Attack Prevented:** Helpdesk impersonation, Teams-based vishing and social engineering, malicious file delivery through external chat, initial access via trial-tenant federation

**Real-World Incidents:**

- **Storm-1811 / Black Basta (2024-2025):** Operators bombarded targets with high-volume email, then contacted the same users through Teams posing as IT support to talk them into granting remote access, which was used to stage ransomware
- **Midnight Blizzard (2024):** Used compromised legitimate tenants to send Teams messages carrying credential-theft lures, exploiting the trust users place in Teams over email

#### Prerequisites

- Teams Administrator or Global Administrator role
- Microsoft Teams PowerShell module for the code path
- A definitive list of partner domains that require Teams federation, gathered from business owners rather than assumed
- Coordination with the service desk, since this control changes how external parties reach employees

#### ClickOps Implementation

**Step 1: Decide the Federation Posture**

1. Default to blocking federation entirely if the organization has no standing need for cross-tenant Teams collaboration
2. Otherwise, move to an explicit allowlist — never leave federation open to all domains
3. Have each requesting business unit name the specific partner domains and an owner for each

**Step 2: Configure External Access**

1. Navigate to: **Teams admin center** → **Users** → **External access**
2. Set **Teams and Skype for Business users in external organizations** to **Block all external domains**, or to **Allow only specific external domains** and enter the approved list
3. Set **Teams accounts not managed by an organization** to **Off** — this closes the consumer-account path
4. Set **Skype users** to **Off**
5. Save the configuration

**Step 3: Block Trial-Tenant Federation**

1. Confirm that federation with newly created trial tenants remains blocked, as this is the cheapest way for an attacker to obtain a plausible-looking sending tenant
2. Review the allowlist quarterly and remove partners whose engagements have ended

**Step 4: Apply via PowerShell**

1. Connect with `Connect-MicrosoftTeams`
2. To block federation outright, run `Set-CsTenantFederationConfiguration -AllowFederatedUsers $false`
3. To operate an allowlist instead, build the domain list with `New-CsEdgeDomainPattern` and apply it through `Set-CsTenantFederationConfiguration -AllowedDomains`
4. Disable consumer accounts with `Set-CsTenantFederationConfiguration -AllowTeamsConsumer $false`
5. Verify the resulting configuration with `Get-CsTenantFederationConfiguration`

**Step 5: Pair the Technical Control With Out-of-Band Verification**

1. Publish a standing rule that IT support never initiates contact through Teams chat from an external account
2. Give employees a single, memorable verification path — a known service desk number they call themselves, never a number or link supplied by the caller
3. Include Teams-originated pretexts in phishing simulation and security awareness content, since most programs still only cover email

**Time to Complete:** ~45 minutes for configuration, plus the time to collect the partner domain list

Source: [Manage external meetings and chat in Microsoft Teams](https://learn.microsoft.com/en-us/microsoftteams/trusted-organizations-external-meetings-chat)

#### Validation & Testing

**How to verify the control is working:**

1. Run `Get-CsTenantFederationConfiguration` and confirm `AllowFederatedUsers`, `AllowedDomains`, and `AllowTeamsConsumer` reflect the intended posture
2. From a personal or trial Microsoft account outside the allowlist, attempt to start a Teams chat with an internal user and confirm it fails
3. From an approved partner domain, confirm chat and meeting invitations still work
4. Confirm the service desk verification procedure is documented and that a sample of employees can describe it correctly

**Expected result:** Only allowlisted partner domains can reach employees through Teams; unmanaged consumer and trial-tenant accounts cannot initiate contact.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | AC-20 | Use of external systems |
| **ISO 27001** | A.5.14 | Information transfer |

---

## 7. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | M365 Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | MFA for all users | [1.1](#11-enforce-phishing-resistant-mfa-for-all-users) |
| CC6.1 | Block legacy auth | [1.2](#12-block-legacy-authentication-protocols) |
| CC6.1 | Teams external access restrictions | [9.1](#91-restrict-teams-external-access-and-unmanaged-accounts) |
| CC6.2 | Privileged Identity Management | [1.3](#13-implement-privileged-identity-management-pim) |
| CC6.6 | External sharing restrictions | [4.2](#42-configure-external-sharing-restrictions) |
| CC6.6 | Reject Direct Send | [8.1](#81-reject-direct-send) |
| CC6.7 | Block automatic external forwarding | [8.2](#82-block-automatic-external-forwarding) |
| CC6.7 | SPF, DKIM, and DMARC enforcement | [8.3](#83-enforce-spf-dkim-and-dmarc-for-all-domains) |
| CC7.2 | Unified audit logging | [5.1](#51-enable-unified-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | M365 Control | Guide Section |
|---------|------------------|---------------|
| IA-2(1) | MFA to privileged accounts | [1.1](#11-enforce-phishing-resistant-mfa-for-all-users) |
| IA-2(6) | Phishing-resistant MFA | [1.1](#11-enforce-phishing-resistant-mfa-for-all-users) |
| AC-2(7) | Privileged user accounts | [1.3](#13-implement-privileged-identity-management-pim) |
| AC-3 | Access enforcement | [3.1](#31-restrict-user-consent-to-applications) |
| AC-4 | Information flow enforcement | [8.2](#82-block-automatic-external-forwarding) |
| AC-20 | Use of external systems | [9.1](#91-restrict-teams-external-access-and-unmanaged-accounts) |
| AC-21 | Information sharing | [4.3](#43-enable-restricted-content-discovery-on-high-risk-sites) |
| AU-2 | Audit events | [5.1](#51-enable-unified-audit-logging) |
| SC-8 | Transmission confidentiality and integrity | [8.3](#83-enforce-spf-dkim-and-dmarc-for-all-domains) |
| SI-8 | Spam protection | [8.1](#81-reject-direct-send) |

### CIS Microsoft 365 Foundations Benchmark v7.0.0 Mapping

The current release of the benchmark is **v7.0.0**. Earlier editions of this guide mapped to v3.1, which is four major releases behind. Recommendation IDs are renumbered across major versions of the benchmark, so the identifiers below are anchored to v7.0.0 and should not be assumed to match any other release. Always confirm the ID against the version of the benchmark your audit is actually being assessed under.

| Recommendation | M365 Control | Guide Section |
|---------------|------------------|---------------|
| 1.1.1 | Ensure MFA is enabled for all users | [1.1](#11-enforce-phishing-resistant-mfa-for-all-users) |
| 1.1.2 | Block legacy authentication | [1.2](#12-block-legacy-authentication-protocols) |
| 1.1.4 | Enable Conditional Access policies | [1.1](#11-enforce-phishing-resistant-mfa-for-all-users) |
| 2.1 | Block third-party app consent | [3.1](#31-restrict-user-consent-to-applications) |
| 5.1 | Enable unified audit logging | [5.1](#51-enable-unified-audit-logging) |

Source: [CIS Microsoft 365 Foundations Benchmark](https://www.cisecurity.org/benchmark/microsoft_365)

### CISA SCuBA Secure Configuration Baseline Mapping

The Cybersecurity and Infrastructure Security Agency publishes the **Secure Cloud Business Applications (SCuBA)** baselines for Microsoft 365, covering Entra ID, Exchange Online, SharePoint and OneDrive, Teams, Defender, and Power Platform. **Binding Operational Directive 25-01**, issued December 2024, makes these baselines mandatory for US federal civilian executive branch agencies, with a compliance deadline of **31 December 2026**. Non-federal organizations increasingly adopt them voluntarily because they are free, prescriptive, and machine-checkable.

**ScubaGear** is CISA's open-source PowerShell assessment tool. It reads the tenant configuration and reports conformance against each baseline policy as Pass, Fail, Warning, or Omit, producing an HTML report suitable for evidence collection. Because it is read-only, it is safe to run against production before any remediation work begins, and it is the fastest way to establish a baseline for the controls in this guide.

| Policy ID | Requirement | Guide Section |
|-----------|-------------|---------------|
| MS.EXO.1.1v2 | Automatic forwarding to external domains SHALL be disabled | [8.2](#82-block-automatic-external-forwarding) |
| MS.EXO.2.2v3 | An SPF policy SHALL be published for each domain | [8.3](#83-enforce-spf-dkim-and-dmarc-for-all-domains) |
| MS.EXO.3.1v1 | DKIM SHOULD be enabled for all domains | [8.3](#83-enforce-spf-dkim-and-dmarc-for-all-domains) |
| MS.EXO.4.1v1 | A DMARC policy SHALL be published for every second-level domain | [8.3](#83-enforce-spf-dkim-and-dmarc-for-all-domains) |
| MS.EXO.4.2v1 | The DMARC message rejection option SHALL be `p=reject` | [8.3](#83-enforce-spf-dkim-and-dmarc-for-all-domains) |
| MS.EXO.4.3v1 | The DMARC point of contact for aggregate reports SHALL include CISA (federal) or a monitored address | [8.3](#83-enforce-spf-dkim-and-dmarc-for-all-domains) |
| MS.EXO.4.4v1 | An agency point of contact SHOULD be included for aggregate and failure reports | [8.3](#83-enforce-spf-dkim-and-dmarc-for-all-domains) |

Source: [CISA SCuBA M365 Secure Configuration Baselines and ScubaGear](https://github.com/cisagov/ScubaGear/tree/main/PowerShell/ScubaGear/baselines)

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
| Reject Direct Send | ✅ | ✅ | ✅ | ✅ | No |
| Block automatic external forwarding | ✅ | ✅ | ✅ | ✅ | No |
| DKIM signing for custom domains | ✅ | ✅ | ✅ | ✅ | No |
| Teams external access restrictions | ✅ | ✅ | ✅ | ✅ | No |
| Restricted Content Discovery | ❌ | ❌ | ❌ | ✅ | SharePoint Advanced Management |

---

## Appendix B: References

**Official Microsoft Documentation:**
- [Microsoft Trust Center](https://www.microsoft.com/en-us/trust-center)
- [Microsoft 365 Product Documentation](https://learn.microsoft.com/en-us/microsoft-365/)
- [Microsoft 365 Security Documentation](https://learn.microsoft.com/en-us/microsoft-365/security/)
- [Entra ID Conditional Access](https://learn.microsoft.com/en-us/entra/identity/conditional-access/)
- [Zero Trust Identity and Device Access Policies](https://learn.microsoft.com/en-us/security/zero-trust/zero-trust-identity-device-access-policies-common)
- [Deprecation of Exchange Web Services in Exchange Online](https://learn.microsoft.com/exchange/clients-and-mobile-in-exchange-online/deprecation-of-ews-exchange-online) — EWS begins being disabled October 2026, fully disabled April 2027
- [Restricted Content Discovery in SharePoint](https://learn.microsoft.com/en-us/sharepoint/restricted-content-discovery)
- [Manage external meetings and chat in Microsoft Teams](https://learn.microsoft.com/en-us/microsoftteams/trusted-organizations-external-meetings-chat)
- [Set-OrganizationConfig cmdlet reference](https://learn.microsoft.com/en-us/powershell/module/exchangepowershell/set-organizationconfig) — includes the `RejectDirectSend` parameter

**API Documentation:**
- [Microsoft Graph API Reference](https://developer.microsoft.com/en-us/graph)
- [Microsoft Graph REST API v1.0](https://learn.microsoft.com/en-us/graph/api/overview)
- [Microsoft Graph PowerShell SDK](https://learn.microsoft.com/en-us/powershell/microsoftgraph/)

**Compliance Frameworks:**
- SOC 1, SOC 2, SOC 3, ISO 27001, ISO 27017, ISO 27018, ISO 27701 — via [Microsoft Service Trust Portal](https://servicetrust.microsoft.com/)
- [Microsoft Compliance Offerings](https://learn.microsoft.com/en-us/compliance/regulatory/offering-home)

**Hardening Benchmarks:**
- [CIS Microsoft 365 Foundations Benchmark](https://www.cisecurity.org/benchmark/microsoft_365) — current release is v7.0.0; recommendation IDs are renumbered across major versions
- [CISA SCuBA M365 Secure Configuration Baselines](https://github.com/cisagov/ScubaGear/tree/main/PowerShell/ScubaGear/baselines) — mandatory for US federal civilian agencies under BOD 25-01, deadline 31 December 2026
- [CISA SCuBA Exchange Online Baseline](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/baselines/exo.md)
- [NIST NCP Checklist](https://ncp.nist.gov/checklist/1140)

**Security Incidents:**
- [Midnight Blizzard Breach Disclosure (January 2024)](https://www.microsoft.com/en-us/msrc/blog/2024/01/microsoft-actions-following-attack-by-nation-state-actor-midnight-blizzard) — Russian APT29 compromised Microsoft corporate email via password spray on a test tenant without MFA
- [Midnight Blizzard Update (March 2024)](https://www.microsoft.com/en-us/msrc/blog/2024/03/update-on-microsoft-actions-following-attack-by-nation-state-actor-midnight-blizzard) — Attackers leveraged exfiltrated data to access source code repositories

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.3.1 | ai-drafted | Cheat-sheet cell repair: added missing Attack Prevented line(s) to §1.4, §2.1, §3.2, §4.1, §5.1 (no content-facts changed) | Claude Code (Fable 5) |
| 2026-08-08 | 0.3.0 | ai-drafted | Platform breakout: this guide becomes the Microsoft **Common Controls hub** — platform frontmatter, Products in This Platform table, moved-controls callout. Merged in tenant-wide content the product guides carried: mandatory-MFA enforcement phases and enforcement-floor framing (1.1), break-glass exemption from mandatory MFA plus phishing-resistant credential registration and offline credential custody (1.4), blocking user app registration (3.1). Added cross-plane pointers for MFA strength authoring (1.1), PIM (1.3), and the three separate audit-log planes (5.1) | Claude Code (Opus 4.8) |
| 2026-08-03 | 0.2.0 | ai-drafted | Add Exchange Online mail flow section (Reject Direct Send, block automatic external forwarding, SPF/DKIM/DMARC enforcement), Teams external access hardening, and SharePoint Restricted Content Discovery; add CISA SCuBA baseline and ScubaGear mapping; correct CIS benchmark citation from v3.1 to v7.0.0; add EWS and SMTP AUTH retirement timelines to legacy authentication control | Claude Code (Sonnet 5) |
| 2026-06-29 | 0.1.1 | ai-drafted | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | ai-drafted | Initial guide with authentication, OAuth, data security, and monitoring controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)

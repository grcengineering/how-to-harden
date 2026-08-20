---
layout: guide
title: "Microsoft Intune Hardening Guide"
vendor: "Microsoft Intune"
slug: "microsoft-intune"
platform: "Microsoft"
platform_slug: "microsoft-365"
product: "Microsoft Intune"
tier: "1"
category: "IT Operations"
description: "Endpoint management hardening for Microsoft Intune — defending against admin-plane abuse, credential theft, and destructive wipe attacks"
version: "0.3.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---

## Overview

Microsoft Intune is a cloud-based endpoint management platform used by **hundreds of thousands of organizations** to manage Windows, macOS, iOS, Android, and Linux devices. As the central authority for device configuration, compliance enforcement, and remote actions, Intune wields enormous destructive potential if compromised. The **March 2026 Stryker breach** proved this decisively: Iranian threat actors (Handala / Void Manticore) used a single compromised admin account to issue native Intune remote-wipe commands across **200,000+ devices in 79 countries** — no malware required.

This guide focuses on hardening the Intune administrative plane against the specific TTPs used in the Stryker attack and similar credential-based admin-abuse scenarios. Every control maps directly to a stage of the Stryker kill chain.

This is a **product guide within the [Microsoft platform](/guides/microsoft-365/)**. Tenant-wide requirements — the MFA mandate, PIM as a program, break-glass accounts, and the unified audit log — live in the Microsoft 365 **Common Controls** hub, and Conditional Access **policy authoring** lives in the [Microsoft Entra ID guide](/guides/microsoft-entra-id/), because that is where the policies are written. Everything below is what only Intune can do to itself: its own RBAC model, its own approval gates, and the remote actions that make a compromised Intune admin account a fleet-destruction tool rather than a data-access problem.

### Intended Audience
- Security engineers managing endpoint fleets
- IT administrators configuring Microsoft Intune
- GRC professionals assessing MDM security posture
- Third-party risk managers evaluating endpoint management risk

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries (healthcare, finance, government)

### Scope
This guide covers Microsoft Intune administrative security: Intune RBAC and scope tags, Intune-scoped authentication and PIM requirements, Multi Admin Approval, device wipe protection, admin session and token hardening, and detection of admin-plane abuse. Device-level compliance policies and application management are covered where they relate to preventing destructive attacks.

**Moved controls:** the admin-portal Conditional Access policy (formerly §2.2) and the device code flow block (formerly §2.3) now live in the [Microsoft Entra ID guide](/guides/microsoft-entra-id/) as §2.3 and §2.6, enriched with the Intune-specific detail — the Microsoft Graph out-of-scope warning, the Device Registration Service exclusion, and the protocol-tracking side effect — rather than duplicated here. Conditional Access is authored once for the whole platform; splitting it per product is how tenants end up with four overlapping admin policies and no idea which one is enforcing.

### Threat Context: The Stryker Attack (March 2026)

On March 11, 2026, the Iranian MOIS-affiliated group **Handala** (tracked as Void Manticore / Storm-0842) executed a devastating attack against Stryker Corporation, one of the world's largest medical technology companies:

1. **Infostealer malware** harvested an employee's SSO credentials, ITSM access, and enterprise password manager contents
2. Credentials were sold to or acquired by Handala operatives
3. Attackers used stolen credentials to **access Stryker's identity console** and escalate to an Intune Administrator role
4. With Intune admin access, attackers issued **native remote-wipe commands** to 200,000+ devices globally
5. Operations in **79 countries** were disrupted — manufacturing halted, shipping stopped, ordering systems went offline

No malware was deployed. No endpoint detection triggered. The attackers used Intune exactly as it was designed to be used — they simply weren't authorized to use it.

**MITRE ATT&CK mapping for this attack:**

| Technique | ID | Stryker Application |
|-----------|-----|---------------------|
| Valid Accounts | T1078 | Infostealer-harvested admin credentials |
| Phishing | T1566 | Likely AiTM phishing for initial credential capture |
| Software Deployment Tools | T1072 | Intune MDM used to push wipe commands |
| Data Destruction | T1485 | Mass device wipe across global fleet |
| Remote Services: RDP | T1021.001 | Lateral movement between compromised systems |
| Command and Scripting Interpreter: PowerShell | T1059.001 | PowerShell-based wiper deployed in parallel |

Every control in this guide maps to at least one stage of this kill chain.

---

## Table of Contents

1. [Admin Access Controls (RBAC)](#1-admin-access-controls-rbac)
2. [Authentication Security](#2-authentication-security)
3. [Privileged Access Management](#3-privileged-access-management)
4. [Multi-Admin Approval](#4-multi-admin-approval)
5. [Device Wipe Protection](#5-device-wipe-protection)
6. [Token Protection & Risk Detection](#6-token-protection--risk-detection)
7. [Monitoring & Detection](#7-monitoring--detection)
8. [Compliance Quick Reference](#8-compliance-quick-reference)

---

## 1. Admin Access Controls (RBAC)

### 1.1 Enforce Least-Privilege RBAC Roles

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.8 |
| NIST 800-53 | AC-6(1), AC-6(5) |

#### Description
Replace broad Intune Administrator and Global Administrator assignments with purpose-built RBAC roles scoped to specific job functions. No administrator should hold more access than their role requires.

#### Rationale
**Why This Matters:**
- In the Stryker attack, a single compromised admin account had sufficient privileges to wipe every enrolled device
- Least-privilege RBAC limits the blast radius of any compromised account
- Scope tags further restrict which devices and users an admin can affect
- Several **built-in** Intune roles — including **Help Desk Operator** and **School Administrator** — grant **Remote tasks > Wipe** out of the box, so an assignment that sounds harmless is a live path to mass destruction

**Attack Prevented:** Privilege escalation (T1078), lateral movement through admin roles

**Real-World Incidents:**
- **March 2026 Stryker breach**: Attacker escalated to Intune Administrator role and issued mass wipe — scoped RBAC would have limited the wipe to a subset of devices at most

#### Prerequisites
- Global Administrator or Intune Administrator role (for initial RBAC setup)
- Inventory of current admin role assignments
- Organizational structure mapped to scope requirements

#### ClickOps Implementation

**Step 1: Audit Current Role Assignments**
1. Navigate to: **Microsoft Intune admin center** → **Tenant administration** → **Roles** → **All roles**
2. Click each role → **Assignments** tab
3. Document all users/groups assigned to each role
4. Flag any user with **Intune Administrator** or **Global Administrator** for review
5. Also flag every assignment to a **built-in** role that carries **Remote tasks > Wipe** — notably **Help Desk Operator** and **School Administrator**. These are the default wipe paths most audits miss because the role names sound read-only

**Step 2: Create Scoped Custom Roles**
1. Navigate to: **Roles** → **All roles** → **Create**
2. Create function-specific roles:
   - **Help Desk – No Remote Wipe**: Read devices, initiate remote assistance (no wipe)
   - **App Manager**: Manage app deployments (no device actions)
   - **Compliance Viewer**: Read compliance policies and reports (read-only)
   - **Endpoint Security Manager**: Manage security baselines and policies
3. For each role, explicitly **exclude** destructive permissions: Wipe, Retire, Delete, Reset
4. Assign scope tags limiting visibility to specific regions, business units, or device platforms

> **Naming warning:** do NOT name your custom help-desk role **Help Desk Operator**. That is the name of a **built-in** Intune role that DOES include **Remote tasks > Wipe** ([Wipe a device](https://learn.microsoft.com/en-us/intune/device-management/actions/wipe)). A custom role sharing that name makes every subsequent audit ambiguous — reviewers cannot tell from an assignment list which of the two a user actually holds.

**Step 3: Replace Broad Assignments**
1. Remove users from **Intune Administrator** and **Global Administrator** roles
2. Assign each user to the custom role matching their job function
3. Verify scope tags restrict access to only relevant devices/users

**Time to Complete:** ~2 hours (initial setup), 30 minutes per additional role

#### Code Implementation

{% include pack-code.html vendor="microsoft-intune" section="1.1" %}

#### Validation & Testing
**How to verify the control is working:**
1. Sign in as a scoped Help Desk admin and attempt a device wipe — it should be denied
2. Verify scoped admins can only see devices within their assigned scope tags
3. Confirm no user holds standing Intune Administrator or Global Administrator

**Expected result:** Scoped admins receive "insufficient permissions" when attempting out-of-scope actions

#### Monitoring & Maintenance
**Ongoing monitoring:**
- Review role assignments monthly via Entra ID Access Reviews
- Alert on any new assignment to Intune Administrator or Global Administrator roles

**Maintenance schedule:**
- **Monthly:** Review role assignment changes
- **Quarterly:** Audit scope tag accuracy against organizational changes
- **Annually:** Full RBAC model review

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | Medium | Admins may need to request role changes for new responsibilities |
| **System Performance** | None | RBAC evaluation adds negligible latency |
| **Maintenance Burden** | Medium | Role definitions must track organizational changes |
| **Rollback Difficulty** | Easy | Reassign broader roles if needed |

**Rollback Procedure:**
Reassign the built-in Intune Administrator role to affected users via Entra ID > Roles.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical and physical access controls |
| **NIST 800-53** | AC-6(1) | Authorize access to security functions |
| **ISO 27001** | A.8.2 | Privileged access rights |
| **PCI DSS** | 7.1 | Limit access to system components |

---

### 1.2 Implement Scope Tags for Resource Isolation

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.8 |
| NIST 800-53 | AC-6(3) |

#### Description
Use Intune scope tags to partition administrative visibility so that no single admin can affect the entire device fleet. Scope tags create administrative boundaries by region, department, or device platform.

#### Rationale
**Why This Matters:**
- Even with least-privilege roles, an admin scoped to the entire tenant can still cause catastrophic damage within their permitted actions
- Scope tags ensure a compromised regional admin can only affect devices in their region
- The Stryker attack succeeded because one admin credential had global scope — scope tags would have contained the blast radius

**Attack Prevented:** Unrestricted destructive actions (T1485), enterprise-wide impact from single credential compromise

#### Prerequisites
- Intune Administrator or Scope Tag Administrator role
- Organizational hierarchy documented (regions, business units, platforms)
- Device groups aligned to organizational boundaries

#### ClickOps Implementation

**Step 1: Create Scope Tags**
1. Navigate to: **Microsoft Intune admin center** → **Tenant administration** → **Roles** → **Scope (tags)**
2. Click **Create** for each organizational boundary:
   - By region: `North-America`, `EMEA`, `APAC`
   - By function: `Corporate-IT`, `Manufacturing`, `Field-Devices`
   - By platform: `Windows-Endpoints`, `Mobile-Devices`, `macOS`
3. Assign scope tags to device groups, configuration profiles, and apps

**Step 2: Assign Scope Tags to RBAC Roles**
1. Navigate to each custom role's **Assignments**
2. Under **Scope (Tags)**, select only the tags relevant to that admin's responsibility
3. Verify the admin cannot see or act on devices outside their scope

**Time to Complete:** ~1 hour

#### Code Implementation

{% include pack-code.html vendor="microsoft-intune" section="1.2" %}

#### Validation & Testing
**How to verify the control is working:**
1. Sign in as a scoped admin and verify device list shows only in-scope devices
2. Attempt to assign a policy to an out-of-scope group — should be blocked

**Expected result:** Admins see only devices and policies matching their assigned scope tags

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.3 | Role-based access based on authorization |
| **NIST 800-53** | AC-6(3) | Network access to privileged commands |
| **ISO 27001** | A.8.2 | Privileged access rights |

---

## 2. Authentication Security

### 2.1 Require Phishing-Resistant MFA for All Intune Admins

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 6.5 |
| NIST 800-53 | IA-2(1), IA-2(6) |

> **Tenant requirement:** the tenant-wide MFA mandate and Microsoft's mandatory-MFA enforcement phases — which already cover every Create, Read, Update, and Delete operation in the **Microsoft Intune admin center** — are [Microsoft 365 §1.1](/guides/microsoft-365/#11-enforce-phishing-resistant-mfa-for-all-users). Enabling FIDO2 and authoring the phishing-resistant authentication strength are [Microsoft Entra ID §1.1](/guides/microsoft-entra-id/#11-configure-authentication-methods-and-authentication-strengths). This control is the Intune-scoped application of both: which roles, which cloud apps, and which key restrictions.

#### Description
Require phishing-resistant multi-factor authentication for every user holding an Intune administrative role, scoped to the Intune service and the Graph surface Intune automation runs through. Mandatory MFA covers the Intune admin center but does not distinguish a FIDO2 key from an SMS code — the policy below is what makes the difference for the roles that can wipe a fleet.

#### Rationale
**Why This Matters:**
- The Stryker attack began with infostealer-harvested credentials — phishing-resistant MFA would have rendered those credentials useless
- Traditional MFA (SMS, push) is vulnerable to AiTM phishing proxies, SIM swapping, and MFA fatigue attacks
- FIDO2 keys are bound to the legitimate domain and cannot be intercepted by phishing proxies
- Microsoft reports that phishing-resistant MFA blocks **over 99.99%** of account compromise attacks

**Attack Prevented:** Credential theft via infostealers (T1078), AiTM phishing (T1566), MFA bypass

**Real-World Incidents:**
- **March 2026 Stryker breach**: Infostealer-stolen credentials were used without MFA challenge — FIDO2 keys would have blocked authentication entirely
- **January 2024 Midnight Blizzard**: Microsoft corporate breach started from a test account without MFA

#### Prerequisites
- FIDO2 security keys provisioned for all Intune admins (YubiKey, Feitian, etc.)
- Microsoft Entra ID P1 or P2 license
- Conditional Access policies configured (or ability to create them)

#### ClickOps Implementation

**Step 1: Restrict the Keys Your Intune Admins May Use**
1. Enable Passkey (FIDO2) and author the phishing-resistant authentication strength first — [Microsoft Entra ID §1.1](/guides/microsoft-entra-id/#11-configure-authentication-methods-and-authentication-strengths)
2. In **Protection** → **Authentication methods** → **Policies** → **Passkey (FIDO2)** → **Configure**, set **Enforce key restrictions** to **Yes** and list only the AAGUIDs of the keys you issued to Intune administrators
3. Set **Enforce attestation** to **Yes** so a key that cannot prove its model is rejected

**Step 2: Create Conditional Access Policy for Intune Admins**
1. Navigate to: **Microsoft Entra admin center** → **Protection** → **Conditional Access** → **Create new policy**
2. **Name:** `HTH-Require-PhishResistant-MFA-IntuneAdmins`
3. **Assignments:**
   - Users: Include **Directory roles** → Select: Intune Administrator, Global Administrator, Security Administrator
   - Cloud apps: Include → **Microsoft Intune**, **Microsoft Intune Enrollment**, **Microsoft Graph**
4. **Grant:** Require authentication strength → **Phishing-resistant MFA**
5. **Session:** Sign-in frequency → **Every time**
6. Enable policy: **On**

**Step 3: Exclude Intune Admins From Weak Methods**
1. Navigate to: **Authentication methods** → **Policies**
2. For each weaker method (SMS, Voice call, Microsoft Authenticator push), set **Target** to exclude the Intune admin group
3. Verify only passkeys and Windows Hello for Business remain available to those accounts — a weak method left registered is a weak method an attacker can select

**Time to Complete:** ~30 minutes

#### Code Implementation

{% include pack-code.html vendor="microsoft-intune" section="2.1" %}

#### Validation & Testing
**How to verify the control is working:**
1. Attempt to sign in to Intune admin center with password + SMS OTP — should be blocked
2. Sign in with FIDO2 key — should succeed
3. Verify Conditional Access sign-in logs show "Phishing-resistant MFA" as the satisfied control

**Expected result:** Only FIDO2 or Windows Hello for Business satisfies the MFA requirement for Intune admin access

#### Monitoring & Maintenance
**Ongoing monitoring:**
- Alert on Conditional Access policy modifications targeting admin roles
- Monitor for sign-ins to Intune admin center that bypass Conditional Access

**Maintenance schedule:**
- **Monthly:** Review FIDO2 key registration for new admins
- **Quarterly:** Audit Conditional Access policy exclusions
- **Annually:** Replace security keys per vendor lifecycle guidance

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | Medium | Admins must carry FIDO2 key; backup registration required |
| **System Performance** | None | No performance impact |
| **Maintenance Burden** | Low | Key provisioning is one-time per admin |
| **Rollback Difficulty** | Easy | Set CA policy to Report-only mode |

**Rollback Procedure:**
Set the Conditional Access policy to **Report-only** mode to stop enforcement while maintaining logging.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | IA-2(6) | Access to accounts — separate device |
| **ISO 27001** | A.8.5 | Secure authentication |
| **PCI DSS** | 8.4.2 | MFA for all access to cardholder data |

---

> **Admin-plane Conditional Access moved.** The compliant-device policy for admin portals (formerly §2.2) and the device code flow block (formerly §2.3) are now authored once for the whole platform in the Microsoft Entra ID guide — [§2.3 Require Compliant Devices for Admins](/guides/microsoft-entra-id/#23-require-compliant-devices-for-admins) and [§2.6 Block Device Code Flow](/guides/microsoft-entra-id/#26-block-device-code-flow). Both carry the Intune-specific detail that used to live here: the **Microsoft Graph** target that mandatory MFA does not cover, the Device Registration Service exclusion, and the protocol-tracking side effect. Configure them there and the Intune admin plane inherits the result.

---

## 3. Privileged Access Management

### 3.1 Enable Privileged Identity Management (PIM) for Intune Roles

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.8 |
| NIST 800-53 | AC-2(1), AC-6(2) |

> **Tenant requirement:** running PIM at all, and converting standing admin to eligible across the tenant, is [Microsoft 365 §1.3](/guides/microsoft-365/#13-implement-privileged-identity-management-pim); the per-role activation settings and their Terraform are [Microsoft Entra ID §3.1](/guides/microsoft-entra-id/#31-enable-just-in-time-access-for-admin-roles). This control is the Intune role set — the roles that can reach devices, and why their activation settings need to be stricter than the rest of the tenant's.

#### Description
Eliminate standing (permanent) Intune admin privileges by requiring just-in-time (JIT) activation through Microsoft Entra Privileged Identity Management. All Intune administrative roles should be **eligible** rather than **active**, requiring explicit activation with justification and approval.

#### Rationale
**Why This Matters:**
- Standing admin privileges mean a compromised credential is immediately dangerous
- PIM requires an attacker to also compromise the activation workflow (justification, approval, MFA)
- Time-bound activation (e.g., 4-hour maximum) limits the window of opportunity
- In the Stryker attack, the compromised account had permanent Intune admin access — PIM would have required the attacker to request and justify activation, creating detection opportunities and potentially blocking the attack entirely

**Attack Prevented:** Immediate privilege abuse from stolen credentials (T1078), persistent admin access

**Real-World Incidents:**
- **March 2026 Stryker breach**: Permanent admin credentials were compromised via infostealer — JIT activation would have added a critical defense layer

#### Prerequisites
- Microsoft Entra ID P2 license
- PIM enabled in the tenant
- Approval chain defined (who approves elevation requests)

#### ClickOps Implementation

**Step 1: Configure PIM for Intune Administrator Role**
1. Navigate to: **Microsoft Entra admin center** → **Identity Governance** → **Privileged Identity Management** → **Microsoft Entra roles**
2. Click **Roles** → Find **Intune Administrator** → **Settings**
3. Configure activation settings:
   - Maximum activation duration: **4 hours**
   - Require justification on activation: **Yes**
   - Require approval to activate: **Yes**
   - Select approver(s): Security team lead or designated approver
   - Require MFA on activation: **Yes** (phishing-resistant)
   - Require Conditional Access authentication context: **Yes**
4. Configure assignment settings:
   - Allow permanent eligible assignment: **No**
   - Expire eligible assignments after: **180 days** (forces re-review)
   - Require MFA on active assignment: **Yes**

**Step 2: Convert Active Assignments to Eligible**
1. In PIM → **Intune Administrator** → **Assignments**
2. For each user with an **Active** assignment:
   - Click the user → **Update** → Change to **Eligible**
3. Repeat for: **Global Administrator**, **Security Administrator**, **Helpdesk Administrator**

**Step 3: Configure PIM Alerts**
1. Navigate to: PIM → **Alerts** → **Settings**
2. Enable:
   - Alert when roles are activated outside of PIM
   - Alert on redundant role assignments
   - Alert when roles are assigned outside PIM

**Time to Complete:** ~1 hour

#### Code Implementation

{% include pack-code.html vendor="microsoft-intune" section="3.1" %}

#### Validation & Testing
**How to verify the control is working:**
1. Verify no user has a permanent active Intune Administrator assignment
2. Test role activation: eligible user requests activation → approval required → time-bound session created
3. Verify activation expires after configured duration
4. Confirm PIM audit logs capture all activation events

**Expected result:** All Intune admin access requires JIT activation with justification, approval, and MFA; activation expires automatically

#### Monitoring & Maintenance
**Ongoing monitoring:**
- Review PIM activation logs weekly for unusual patterns
- Alert on activations outside business hours
- Alert on failed activation attempts

**Maintenance schedule:**
- **Monthly:** Review PIM activation frequency and justifications
- **Quarterly:** Audit eligible assignment list — remove departed or role-changed staff
- **Annually:** Review approval chain and activation duration settings

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | Medium | Admins must request and wait for activation (5-15 min typical) |
| **System Performance** | None | No performance impact |
| **Maintenance Burden** | Medium | Approval chain must be staffed during business hours |
| **Rollback Difficulty** | Easy | Convert eligible assignments back to active |

**Potential Issues:**
- **Break-glass scenarios**: Maintain 1-2 emergency access accounts with permanent active assignment, protected by a passkey and monitored continuously — see [Microsoft 365 §1.4](/guides/microsoft-365/#14-configure-break-glass-emergency-access-accounts), which covers why a password-only break-glass account is now a locked-out break-glass account
- **After-hours activation**: Define on-call approver rotation for off-hours requests

**Rollback Procedure:**
Convert eligible assignments back to active permanent assignments in PIM settings.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1, CC6.3 | Logical access and role-based authorization |
| **NIST 800-53** | AC-2(1) | Automated system account management |
| **ISO 27001** | A.8.2 | Privileged access rights |
| **PCI DSS** | 7.2.1 | Access control model based on job function |

---

### 3.2 Require Privileged Admin Workstations for High-Impact Actions

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls | 12.8 |
| NIST 800-53 | SC-7(29) |

#### Description
Restrict Intune administrative access to designated Privileged Admin Workstations (PAWs) — hardened devices dedicated exclusively to administrative tasks, with enhanced security baselines and no general-purpose browsing.

#### Rationale
**Why This Matters:**
- Infostealer malware on the Stryker employee's general-purpose workstation captured admin credentials alongside personal browsing data
- A PAW eliminates the risk of credential theft from everyday malware exposure
- PAWs enforce a physical separation between browsing/email activity and administrative actions

**Attack Prevented:** Credential theft via infostealers, keyloggers, and browser session hijacking

#### Prerequisites
- Dedicated hardware or VMs for admin workstations
- Intune security baseline for PAWs
- Device compliance policy specifically for PAWs

#### ClickOps Implementation

**Step 1: Create a PAW Device Group**
1. Navigate to: **Intune admin center** → **Groups** → **New group**
2. Group name: `PAW-Intune-Admins`
3. Membership type: **Assigned** (manually add approved PAW devices)

**Step 2: Create PAW Security Baseline**
1. Navigate to: **Endpoint security** → **Security baselines** → **Create profile**
2. Apply hardened settings:
   - Block USB storage
   - Disable browser extensions
   - Enable credential guard
   - Enable attack surface reduction rules (all rules in block mode)
   - Enable network protection
   - Restrict outbound connections to Intune, Entra ID, and Microsoft Graph only

**Step 3: Target Conditional Access to PAW Devices**
1. Update the admin-plane Conditional Access policy ([Microsoft Entra ID §2.3](/guides/microsoft-entra-id/#23-require-compliant-devices-for-admins))
2. Add a **device filter**: Include only devices in the `PAW-Intune-Admins` group
3. This ensures admin portal access is only possible from registered PAW devices

**Time to Complete:** ~3 hours

#### Code Implementation

{% include pack-code.html vendor="microsoft-intune" section="3.2" %}

#### Validation & Testing
**How to verify the control is working:**
1. Attempt Intune admin sign-in from a non-PAW device — should be blocked
2. Verify PAW devices meet all compliance requirements
3. Confirm PAW devices cannot browse general internet sites

**Expected result:** Intune admin access is restricted exclusively to PAW devices

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical and physical access controls |
| **NIST 800-53** | SC-7(29) | Restriction of outbound traffic |
| **ISO 27001** | A.8.9 | Configuration management |

---

## 4. Multi-Admin Approval

### 4.1 Enable Multi-Admin Approval for Destructive Actions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-3(4) |

#### Description
Require a second authorized administrator to approve high-impact actions before they execute. Multi Admin Approval (MAA) access policies protect a defined set of Intune resource types — Apps, Compliance policies, Configuration policies, Device actions (wipe, retire, delete), Role-based access control, Scripts, and Tenant Configuration — so that no single compromised or rogue admin can cause tenant-wide destruction. Changes to access policies themselves are automatically protected and always require a second approver.

> **Changed behavior (June 2026) — MAA now enforces on Microsoft Graph application-authenticated calls.** Previously only interactive (delegated) admin actions were intercepted. Service principals, automation scripts, and third-party applications calling Microsoft Graph with app-only tokens are now subject to the same approval workflow when the target resource is protected by an access policy ([Use Multi Admin Approval with the Microsoft Graph API](https://learn.microsoft.com/en-us/intune/fundamentals/role-based-access-control/multi-admin-approval-graph-api)). Enforcement applies only to tenants that already have MAA access policies configured — it does not switch MAA on for anyone. **Read-only GET requests are unaffected**; only POST, PATCH, PUT, and DELETE are intercepted. See Step 4 below for the header workflow your automation must adopt.

#### Rationale
**Why This Matters:**
- The Stryker attack succeeded because a single admin credential was sufficient to wipe 200,000+ devices
- Multi-Admin Approval would have required a second, independent admin to approve each wipe action — stopping the attack entirely
- This is the single most effective control against Intune admin-plane abuse
- Microsoft's own framing for the feature is protection "against a compromised administrative account" — precisely the Stryker scenario, and the reason it belongs at L1 rather than as an advanced option

**Attack Prevented:** Single-admin mass wipe (T1485), unauthorized RBAC changes, malicious script deployment

**Real-World Incidents:**
- **March 2026 Stryker breach**: Single compromised admin account issued mass wipe — Multi-Admin Approval would have blocked every wipe action pending a second approval

#### Prerequisites
- **Microsoft Intune Plan 1.** MAA is not gated behind Intune Plan 2 or the Intune Suite — Plan 2 adds Remote Help and Advanced Endpoint Analytics, neither of which MAA depends on. The documented licensing requirement is that administrators participating in the MAA workflow have an Intune license assigned; the **Allow access to unlicensed admins** setting lifts that, but it is **irreversible once enabled**
- At least two administrator accounts in the tenant — an admin can never approve their own request, including a Global Administrator or Intune Administrator
- Permission to create access policies: a custom Intune role carrying the Multi Admin Approval permissions (*Create / Read / Update / Delete access policy*) is the recommended least-privilege path; **Intune Administrator** also works but is a privileged role
- An approver security group that meets the strict requirements in Step 2

#### ClickOps Implementation

**Step 1: Create an Access Policy**
1. Navigate to: **Microsoft Intune admin center** → **Tenant administration** → **Multi Admin Approval** → **Access policies** → select **Create**
2. On **Basics**, enter a **Name** and optional **Description**, then select a **Profile type**. **Each policy supports a single profile type** — protecting several resource types means creating several policies. Available types:
   - **Device actions** — wipe, retire, and delete device actions (start here; this is the Stryker path)
   - **Scripts** — deploying PowerShell scripts to Windows devices
   - **Role-based access control** — role permission changes, admin group and member group assignments
   - **Apps** — app deployments (does *not* cover app protection policies)
   - **Compliance policies**
   - **Configuration policies** — settings catalog policies
   - **Tenant Configuration** — creating, editing, or deleting device categories
3. On **Review + submit for approval**, enter a **Business justification** and select **Submit for approval**
4. Have a **second** admin holding the *Approval for Multi Admin Approval* permission sign in and approve the new policy
5. Sign back in as the creating admin, open the policy, and select **Complete** to finalize it. The policy is not in force until this step runs

**Step 2: Define Approvers**
1. On the **Approvers** tab, select **Add groups** and choose one group. Configurations that exclude groups are not supported
2. The approver group must satisfy **all** of the following, or approvals silently fail to resolve:

   | Requirement | Detail |
   |-------------|--------|
   | Group type | Must be a **security group**. Distribution lists, Microsoft 365 groups, and mail-enabled security groups are not supported and **silently fail to resolve approver membership** |
   | RBAC assignment | The approver group itself must be added as a **member group** on at least one Intune role assignment. Permissions held by individual members — via other groups or direct user assignments — do not satisfy this. If the group is not on a role assignment, **its members get removed from the group periodically** |
   | Membership shape | Users must be **direct members** of the assigned group. Nested group membership produces unreliable behavior |
   | Per-approver permission | Each approver needs the resource-specific **Read** permission for the type they approve (e.g. *ManagedDevices/Read* to approve a device delete) |

3. **There is no configurable approval threshold and no configurable approval timeout.** Exactly one other administrator must approve, and a request that is not processed further within **3 days** moves to **Expired** and must be resubmitted. Each status change stays visible for up to 30 days
4. Intune sends **no notification** when a request is created or changes status — build your own alerting off the audit log, and contact approvers directly for urgent changes

**Step 3: Expand Scope (Phase 2)**
After the Device actions policy stabilizes, add policies for the remaining supported profile types — Scripts, Compliance policies, Configuration policies, Apps, and Tenant Configuration.

> **Do not add a Role policy until everything else is in place.** The **Role-based access control** profile type protects *all* role changes, including the RBAC assignments MAA itself depends on. Enabling it before the approver group is correctly assigned to a role creates a **deadlock**: you cannot make the role assignment MAA needs, because that assignment now requires MAA approval. Recovery is to delete the Role access policy under **Tenant administration** → **Multi Admin Approval** → **Access policies**, wait 3–5 minutes, complete the assignment under **Tenant administration** → **Roles**, then re-create the policy.

**Step 4: Update Automation for App-Authenticated Graph Calls**
Any service principal or script that modifies a protected resource through Microsoft Graph must implement the approval handshake or it will simply start failing:

| Stage | What the caller does | What Intune returns |
|-------|----------------------|---------------------|
| Submit | Send the write request (POST/PATCH/PUT/DELETE) with a **Base64-encoded** `x-msft-approval-justification` header | Without the header, the call fails with an error indicating the justification header is required — Microsoft's dedicated Graph article documents this as **HTTP 400**, while the What's New announcement cited **403**. Treat any non-2xx as "MAA rejected an unjustified call" rather than keying your error handling to one code |
| Receive code | — | **HTTP 412 Precondition Failed**, outer Graph error code `BadRequest`, carrying an `x-msft-approval-code` header. This is success, not a permissions problem — it means the approval request was created |
| Poll | Query `operationApprovalRequests` filtered on the approval code | `status` progresses through `needsApproval` → `approved` (also `rejected`, `cancelled`) |
| Resubmit | Resend the **identical** method, URL, and body, replacing the justification header with `x-msft-approval-code` set to the value from the 412 | Request completes normally |

Applications cannot approve or reject their own requests — only an interactive admin account in the approver group can. Preserve the original method, URL, and body at submit time; you need to replay them byte-for-byte after approval.

**Time to Complete:** ~1 hour (plus automation rework)

#### Code Implementation

{% include pack-code.html vendor="microsoft-intune" section="4.1" %}

#### Validation & Testing
**How to verify the control is working:**
1. Attempt a device wipe — verify it enters **Needs approval** under **Tenant administration** → **Multi Admin Approval** → **My requests**
2. Approve the wipe from a second admin account (**Received requests**, or the **Admin tasks** pane) — status moves to **Approved**
3. Sign back in as the requestor and select **Complete** — only then does Intune process the action and set status to **Completed**. A request stuck at *Approved* has not executed
4. Verify the original requestor cannot approve their own request, even if they are a member of the approver group
5. Leave a request unprocessed and confirm it moves to **Expired** after **3 days** (this is fixed and not configurable)
6. If automation exists, confirm an app-auth Graph write without the justification header fails, and that the 412 + `x-msft-approval-code` replay path succeeds

**Expected result:** All protected actions require a second admin's approval before execution, and the requestor must explicitly complete the change afterward

#### Monitoring & Maintenance
**Ongoing monitoring:**
- Alert on approval requests outside business hours
- Monitor for patterns of rapid approval (rubber-stamping)
- Track denied requests — may indicate compromise attempts

**Maintenance schedule:**
- **Monthly:** Review approval activity and denied requests
- **Quarterly:** Assess whether additional actions should be protected
- **Annually:** Review approver group membership

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | Medium | Admins must wait for approval on protected actions |
| **System Performance** | None | No performance impact |
| **Maintenance Burden** | Medium | Approver availability must be maintained |
| **Rollback Difficulty** | Easy | Disable the access protection policy |

**Potential Issues:**
- **Emergency wipe for lost/stolen device**: Define an expedited approval path or break-glass procedure
- **After-hours incidents**: Maintain on-call approver rotation

**Rollback Procedure:**
Disable the Multi-Admin Approval policy under Tenant administration. Protected actions will immediately execute without approval.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1, CC8.1 | Access controls and change management |
| **NIST 800-53** | AC-3(4) | Mandatory access control — dual authorization |
| **ISO 27001** | A.8.3 | Information access restriction |
| **PCI DSS** | 6.5.1 | Change management procedures |

---

### 4.2 Govern the Multi Admin Approval Exclusions List

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 8.5 |
| NIST 800-53 | AC-3(4), CM-3 |

#### Description
Each Multi Admin Approval access policy carries an **Exclusions** list of enterprise applications that are permitted to modify the protected resource without going through the approval workflow. Treat every entry on that list as a standing, documented bypass of your strongest destructive-action control, subject to scheduled review and removal — not as a one-time deployment convenience that stays forever.

#### Rationale
**Why This Matters:**
- Microsoft's own warning is unambiguous: **"Excluding an application bypasses MAA protection for the affected resource type. Each exclusion creates a gap in your approval workflow that could be exploited if the excluded application is compromised"** ([Use Multi Admin Approval in Intune](https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/multi-admin-approval))
- Exclusions are the path of least resistance when app-auth enforcement (4.1) starts breaking automation — the fast fix is to exclude the service principal rather than implement the approval headers, and fast fixes become permanent
- The cap is **50 applications per access policy**, which is far more headroom than any well-governed tenant needs; approaching it is itself a finding
- An excluded service principal inherits the full destructive capability of the protected resource type. An exclusion on a Device actions policy is, functionally, an app that can wipe devices unattended

**Attack Prevented:** Approval-workflow bypass via a compromised or over-trusted service principal, silent erosion of dual authorization (T1485, T1078.004)

#### Prerequisites
- At least one MAA access policy configured (Section 4.1)
- Inventory of service principals and third-party applications that call Intune resources through Microsoft Graph
- Intune audit log access (Section 7.1)

#### ClickOps Implementation

**Step 1: Inventory Current Exclusions**
1. Navigate to: **Microsoft Intune admin center** → **Tenant administration** → **Multi Admin Approval** → **Access policies**
2. Open each policy → **Exclusions** tab
3. Record, per policy: application name, application (client) ID, owning team, business justification, and the date it was added. **Exclusions are per-policy** — an exclusion in one access policy has no effect on any other policy or workload, so this inventory has to be built policy by policy

**Step 2: Establish the Review Gate**
1. Assign each exclusion a named owner and an expiry date
2. Require that every exclusion request first document why the approval-header workflow (Section 4.1, Step 4) cannot be implemented — exclusion is the fallback, not the default
3. Record the residual risk explicitly: for a Device actions policy, the excluded app can wipe, retire, and delete devices with no second approval

**Step 3: Remove Stale Exclusions**
1. Open the policy → **Exclusions** → remove the application
2. Adding, removing, or modifying an exclusion is itself a change to the access policy and therefore **requires approval by a second administrator** before it takes effect — which means the removal is auditable and cannot be done unilaterally
3. Re-verify that the application's automation has adopted the justification/approval-code workflow before removing its exclusion, or it will start failing

**Step 4: Monitor the Exclusion List as a Detection Surface**
1. All add, remove, and modify actions on the exclusion list are captured in the **Intune audit log**
2. MAA events — approve, block, pass, exclusion add, and exclusion remove — are all recorded there, so exclusion churn is queryable alongside the rest of your admin-plane telemetry (Section 7.1)
3. Alert on any exclusion added outside a change window

> **Scope limit worth stating plainly:** exclusions apply **only to app-auth (application-authenticated) calls** made by the excluded service principal. Interactive, delegated admin actions against the same protected resource are **always** subject to MAA enforcement, excluded app or not. An exclusion is not a human bypass.

**Time to Complete:** ~1 hour (initial inventory), 30 minutes per quarterly review

#### Validation & Testing
**How to verify the control is working:**
1. Confirm every entry on every policy's **Exclusions** tab appears in your inventory with a named owner and expiry date
2. Attempt to add an exclusion with a single admin account — verify it enters the approval workflow rather than applying immediately
3. Query the Intune audit log for exclusion add/remove events and confirm they surface in your SIEM
4. From an excluded application, confirm an app-auth write succeeds without approval; from an interactive admin session, confirm the same write still requires approval

**Expected result:** The exclusion list is a short, owned, expiring, audited list — and every entry has a documented reason the approval-header workflow was not viable

#### Monitoring & Maintenance
**Ongoing monitoring:**
- Alert on exclusion add/remove events in the Intune audit log
- Track exclusion count per policy against the 50-application cap; growth is a governance signal

**Maintenance schedule:**
- **Quarterly:** Review every exclusion against its documented justification; remove any whose owning automation has since adopted the approval workflow
- **Annually:** Re-validate that each excluded application still exists, is still owned, and still needs the bypass

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1, CC8.1 | Access controls and change management |
| **NIST 800-53** | AC-3(4) | Dual authorization |
| **NIST 800-53** | CM-3 | Configuration change control |
| **ISO 27001** | A.8.3 | Information access restriction |

---

## 5. Device Wipe Protection

### 5.1 Restrict Remote Wipe Permissions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CM-7(2) |

#### Description
Remove the remote wipe permission from all RBAC roles except a dedicated "Device Recovery" role, and protect that role with PIM and Multi-Admin Approval. Device wipe is the most destructive action available in Intune — it should be the most restricted.

#### Rationale
**Why This Matters:**
- Device wipe is an irrecoverable action that factory-resets a device, destroying all local data
- In the Stryker attack, wipe was used as a weapon of mass destruction against 200,000+ devices
- By isolating wipe permissions to a single, heavily protected role, the attack surface for destructive actions is minimized

**Attack Prevented:** Mass device wipe (T1485), unauthorized factory reset

#### Prerequisites
- Custom RBAC roles configured (Section 1.1)
- PIM configured (Section 3.1)
- Multi-Admin Approval configured (Section 4.1)

#### ClickOps Implementation

**Step 1: Create Device Recovery Role**
1. Navigate to: **Intune admin center** → **Tenant administration** → **Roles** → **Create**
2. **Role name:** `HTH Device Recovery Operator`
3. **Permissions:** Enable ONLY:
   - Remote tasks > Wipe
   - Remote tasks > Retire
   - Remote tasks > Factory reset
   - All other permissions: **No**
4. **Scope tags:** Limit to specific regions or device groups (never "Default" for all devices)

**Step 2: Remove Wipe from All Other Roles — Built-In Roles Included**
1. Review each **custom** role → **Permissions** → ensure **Remote tasks > Wipe**, **Retire**, and **Factory reset** are set to **No**
2. Then review **built-in** role assignments, which cannot be edited and must be *unassigned* instead. **Help Desk Operator** and **School Administrator** both grant **Remote tasks/Wipe** by default ([Wipe a device](https://learn.microsoft.com/en-us/intune/device-management/actions/wipe)). Reviewing only custom roles leaves the default wipe path wide open — this is the most common gap in an otherwise well-scoped RBAC model
3. Navigate to: **Tenant administration** → **Roles** → **All roles** → open each built-in role → **Assignments**, and move anyone who does not need wipe onto a custom role without it
4. Cross-check against the built-in role permission reference before assuming a role is safe; role names are not a reliable guide to what they can destroy
5. Only after both passes does the Device Recovery Operator role become the sole wipe path

**Step 3: Protect with PIM**
1. In PIM, configure the Device Recovery Operator role as **Eligible** (never permanently active)
2. Set maximum activation duration: **2 hours**
3. Require approval and justification for activation

**Time to Complete:** ~45 minutes

#### Code Implementation

{% include pack-code.html vendor="microsoft-intune" section="5.1" %}

#### Validation & Testing
**How to verify the control is working:**
1. Sign in as a standard Intune admin and attempt device wipe — should fail
2. Enumerate assignments on the built-in **Help Desk Operator** and **School Administrator** roles and confirm the list is empty or intentionally minimal — both grant wipe by default
3. Activate Device Recovery Operator via PIM, initiate wipe — should enter the Multi Admin Approval queue
4. Verify wipe executes only after second admin approval **and** the requestor selects **Complete**

**Expected result:** Device wipe requires PIM activation, justification, approval, AND Multi-Admin Approval — four barriers

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | CM-7(2) | Prevent program execution |
| **ISO 27001** | A.8.3 | Information access restriction |

---

### 5.2 Configure Device Wipe Rate Limiting and Alerting

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.11 |
| NIST 800-53 | SI-4 |

#### Description
Configure monitoring to detect and alert on unusual patterns of device wipe activity. While Intune does not natively rate-limit wipe commands, detection-based controls can trigger incident response before a mass wipe completes.

#### Rationale
**Why This Matters:**
- The Stryker attack wiped devices over a short time period — real-time alerting on wipe velocity could have triggered incident response before the full fleet was affected
- Even with Multi-Admin Approval, monitoring for anomalous approval patterns is critical

**Attack Prevented:** Detection of mass wipe in progress, early incident response

#### ClickOps Implementation

**Step 1: Create Alert Rule in Microsoft Sentinel (or SIEM)**
1. Navigate to: **Microsoft Sentinel** → **Analytics** → **Create** → **Scheduled query rule**
2. Name: `HTH-MassWipeDetection`
3. Description: Alerts when more than 10 device wipe actions are initiated within 1 hour
4. Severity: **High**
5. Automated response: Trigger incident creation and notification to SOC

**Step 2: Configure Intune Diagnostic Logging**
1. Navigate to: **Intune admin center** → **Reports** → **Diagnostics settings**
2. Enable sending logs to:
   - Log Analytics workspace (for Sentinel)
   - Event Hub (for third-party SIEM)
3. Select the **AuditLogs** category — remote device actions such as wipe and retire are recorded there as administrative activities. There is no separate "DeviceActions" diagnostic category; the available categories are **AuditLogs**, **OperationalLogs**, **DeviceComplianceOrg**, and **IntuneDevices** (see Section 7.1)

**Time to Complete:** ~1 hour

#### Code Implementation

{% include pack-code.html vendor="microsoft-intune" section="5.2" %}

#### Validation & Testing
**How to verify the control is working:**
1. Trigger a small number of test wipe actions and verify logs appear in SIEM
2. Verify alert fires when threshold is exceeded in test
3. Confirm SOC receives notification within 5 minutes of threshold breach

**Expected result:** SOC is alerted within minutes of anomalous wipe activity

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.2 | Monitoring of system components |
| **NIST 800-53** | SI-4 | Information system monitoring |
| **ISO 27001** | A.8.16 | Monitoring activities |

---

## 6. Token Protection & Risk Detection

### 6.1 Harden Admin Sessions Against Token Replay

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-11 |

#### Description
Reduce the value of a stolen admin session token by layering Continuous Access Evaluation, a compliant-device requirement, authentication-context step-up on sensitive operations, risk-based interactive reauthentication, and compliant-network enforcement across the Intune administrative plane.

> **Correction — Conditional Access Token Protection cannot be applied to the Intune admin plane.** An earlier version of this guide instructed readers to create a `HTH-TokenProtection-Admins` policy requiring token protection for Intune administrators. That policy cannot enforce anything on this surface. Per [How Token Protection Enhances Conditional Access Policies](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-token-protection), Token Protection **supports native applications only — browser-based applications are not supported** — and it can be enforced on only these resources:
>
> | Resource | Platform support |
> |----------|------------------|
> | Exchange Online, SharePoint Online, Microsoft Teams | Windows GA; iOS/iPadOS and macOS in preview |
> | Azure Virtual Desktop, Windows 365 | Windows only |
>
> Neither the **Microsoft Intune admin center** (a browser app) nor **Microsoft Graph** is a supported resource. Deploy Token Protection where it is supported — it is a genuine control for those workloads — but do not count it as a defense for Intune administration. The controls below are what actually protect this plane.

#### Rationale
**Why This Matters:**
- Attackers who steal session tokens bypass MFA entirely — the token is itself proof that authentication already succeeded, which is precisely why the Stryker-class kill chain works without malware on the admin's machine
- Because token *binding* is unavailable here, the defense has to shift to shortening the useful life of a stolen token and forcing re-proof at the moment of destructive action
- Continuous Access Evaluation terminates active sessions within minutes of a risk or policy change rather than waiting for natural token expiry
- Authentication context turns "the attacker has a valid session" into "the attacker must re-authenticate, with a strength you choose, at the exact moment they try to do damage"

**Attack Prevented:** Token theft and replay (T1528), session hijacking, persistent unauthorized access after credential compromise

#### Prerequisites
- Microsoft Entra ID P1 for Conditional Access; **P2** for sign-in risk and user risk conditions
- Device compliance policies configured in Intune and enforced by the admin-plane Conditional Access policy ([Microsoft Entra ID §2.3](/guides/microsoft-entra-id/#23-require-compliant-devices-for-admins))
- Named locations or Global Secure Access configured if you intend to use compliant network enforcement

#### ClickOps Implementation

**Step 1: Enable Continuous Access Evaluation**
1. Navigate to: **Microsoft Entra admin center** → **Protection** → **Conditional Access** → **Continuous access evaluation**
2. Set to **Enabled**, or **Strictly enforce location policies** for the strongest posture
3. CAE lets Entra ID signal supported resource providers to revoke a session in near-real time when the user is disabled, the password changes, or risk is detected

**Step 2: Require a Compliant Device for the Admin Plane**
1. This is the load-bearing replay defense on this surface, and it is already configured in [Microsoft Entra ID §2.3](/guides/microsoft-entra-id/#23-require-compliant-devices-for-admins) — verify it is **On**, not report-only
2. A stolen token replayed from attacker infrastructure fails the device-compliance grant because the attacker's machine is not enrolled and compliant
3. Confirm **Microsoft Intune**, **Microsoft Admin Portals**, and **Microsoft Graph** are all in the policy's target resources

**Step 3: Require Reauthentication Through Authentication Context on Sensitive Operations**
1. Navigate to: **Microsoft Entra admin center** → **Protection** → **Conditional Access** → **Authentication context** → **New authentication context**
2. Create a context such as `c1 — Intune destructive operations` and mark it **Publish to apps**
3. Create a Conditional Access policy assigned to that authentication context, granting only on **Require authentication strength → Phishing-resistant MFA**, with **Session → Sign-in frequency → Every time**
4. Bind the context to PIM role activation for the Intune Administrator and Device Recovery Operator roles (Sections 3.1 and 5.1) via **Require Conditional Access authentication context** in the PIM role settings
5. The result: holding a live session is no longer sufficient to elevate — the attacker must satisfy a fresh phishing-resistant challenge at the point of privilege

**Step 4: Add Risk-Based Interactive Reauthentication**
1. Navigate to: **Protection** → **Conditional Access** → **Create new policy**
2. **Name:** `HTH-AdminRisk-Reauth`
3. **Assignments:** admin directory roles; target the admin portals and Microsoft Graph
4. **Conditions:** **Sign-in risk** → Medium and above (requires Entra ID P2)
5. **Grant:** Require authentication strength → **Phishing-resistant MFA**
6. **Session:** **Sign-in frequency** → **Every time**, so a risky session cannot coast on an existing token

**Step 5: Enforce Compliant Network (Optional, L3)**
1. If Global Secure Access is deployed, add the **Compliant network** condition to the admin-portal policy
2. This binds admin access to traffic egressing through your enforced network profile, which a replayed token from arbitrary infrastructure cannot satisfy

**Time to Complete:** ~1.5 hours

#### Code Implementation

{% include pack-code.html vendor="microsoft-intune" section="6.1" %}

The pack covers Step 1 (reporting tenant CAE state), Step 3 (creating the authentication context, its Conditional Access policy, and binding it to PIM role activation via the `AuthenticationContext_EndUser_Assignment` rule), and Step 4 (the `HTH-AdminRisk-Reauth` policy). Two things are deliberately absent. Step 2 is not duplicated — the compliant-device requirement is already automated by the [Microsoft Entra ID §2.3](/guides/microsoft-entra-id/#23-require-compliant-devices-for-admins) pack. Step 5, the optional L3 compliant-network condition, stays ClickOps-only because Global Secure Access network conditions have no stable documented Graph representation to script against. One caveat on Step 1: Microsoft Graph exposes `continuousAccessEvaluationPolicy` as read-only, so the pack reports whether CAE is on and warns if it is not — actually enabling it remains a portal action.

#### Validation & Testing
**How to verify the control is working:**
1. Sign in to the Intune admin center from a non-compliant device with an otherwise valid session — access should be denied at the grant control
2. Disable a test admin account mid-session and confirm CAE terminates the session within minutes rather than at token expiry
3. Attempt a PIM activation for Intune Administrator and confirm the authentication-context policy forces a fresh phishing-resistant challenge, even in an already-authenticated session
4. Simulate a risky sign-in and confirm `HTH-AdminRisk-Reauth` forces interactive reauthentication
5. In **Sign-in logs** → **Conditional Access** tab, confirm which policies applied to each admin sign-in

**Expected result:** A stolen admin token cannot be replayed from non-compliant infrastructure, cannot survive a risk event, and cannot be used to elevate privilege without a fresh phishing-resistant challenge

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls |
| **NIST 800-53** | IA-11 | Re-authentication |
| **ISO 27001** | A.8.5 | Secure authentication |

---

### 6.2 Operationalize Token Theft Investigation

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | IR-4 |

#### Description
Adopt Microsoft's published **Token theft playbook** as your response baseline for token theft targeting Intune administrators, rather than authoring a procedure from scratch. Wire the playbook's prerequisites into your environment, map its investigation triggers to your alerting, and extend its containment and recovery task lists with the Intune-specific steps this guide's other controls make possible.

#### Rationale
**Why This Matters:**
- Token theft is the primary technique for bypassing MFA — the attacker replays a token that already satisfied the MFA challenge, so nothing in the authentication log looks anomalous on its own
- Microsoft maintains an authoritative, versioned [Token theft playbook](https://learn.microsoft.com/en-us/security/operations/token-theft-playbook) with a companion [decision tree](https://aka.ms/tokentheftworkflow); a locally invented procedure will be less complete and will not track upstream changes
- Without a defined and rehearsed procedure, alerts go unactioned — and token theft response is time-critical because containment is a race against the token's remaining validity
- Mapping to a published baseline also gives auditors a named standard rather than an internal document of unknown provenance

**Attack Prevented:** Token theft (T1528), session hijacking, unauthorized admin access, post-compromise persistence via added credentials and devices

#### Prerequisites
Per the playbook's own prerequisites:
- Access to Microsoft Entra ID **sign-in** and **audit** logs for users and service principals
- An account holding one of: **Security Administrator**, **Security Reader**, **Global Reader**, or **Security Operator**
- Recommended: advanced hunting enabled with at least seven days of event data; Defender for Cloud Apps connected; Unified Audit Log access; Entra ID P2 or E5 for premium risk detections, which unlock the more granular investigation triggers
- A SIEM ingesting sign-in logs, audit logs, and Entra ID Protection risk events (Section 7.1)

#### ClickOps Implementation

**Step 1: Enable the Detections the Playbook Triggers On**
1. Navigate to: **Microsoft Entra admin center** → **Protection** → **Identity Protection** → **Sign-in risk policy**
2. Target admin users and groups; risk level **Medium and above** → require MFA or block access
3. Ensure the playbook's named triggers are alerting into your SOC queue:
   - **Anomalous token (offline detection)** — atypical token characteristics or use from an unfamiliar location; this is the detection that directly indicates replay
   - **Unfamiliar sign-in properties**
   - **Unfamiliar sign-in** — non-interactive sign-ins deserve elevated scrutiny
   - **Attempted access of Primary Refresh Token (PRT)** — surfaced by Defender for Endpoint on Windows 10/11; low-volume and high-signal
   - **Suspicious URLs** — possible AiTM phishing kit, often the first move in the chain
4. Integrate Entra ID Protection with Microsoft Defender XDR so detections land in one portal

**Step 2: Adopt the Playbook and Its Decision Tree**
1. Publish the [Token theft playbook](https://learn.microsoft.com/en-us/security/operations/token-theft-playbook) and its [decision tree](https://aka.ms/tokentheftworkflow) as the SOC's operating procedure for this incident class
2. Its structure — reuse it rather than paraphrasing it:

   | Playbook phase | What it covers |
   |----------------|----------------|
   | Investigation triggers | Identities, sign-in logs, audit logs, Office apps, and devices associated with affected users |
   | User investigation checklist | Added credentials or devices, suspicious mail, privileged-account changes, inbox rule creation, correlating other accounts from the attacker IP or user agent |
   | Device investigation checklist | Token-theft alerts on the device, PRT access attempts, suspicious apps/extensions, outbound connections from suspicious processes |
   | Containment | Password change, revoke access, mark the account compromised in Entra ID Protection, block the attacker IP, enforce MFA and risk policies |
   | Recovery | Disable affected accounts, revoke tokens, delete attacker-added credentials and devices via Graph, disable suspicious mail rules, roll back changes made by compromised privileged accounts |
   | Root cause analysis | Post-recovery investigation to determine the initial vector |

3. Pair it with [Protecting tokens in Microsoft Entra ID](https://learn.microsoft.com/en-us/entra/identity/devices/protecting-tokens-microsoft-entra-id) for the defense-in-depth side — Microsoft explicitly frames token protection as one layer within that broader strategy, not a standalone answer

**Step 3: Extend the Playbook With Intune-Specific Steps**
The published playbook is identity-centric. Append these, which only apply because Intune is the compromised plane:
1. Query the **Intune audit log** (Section 7.1) for every administrative action taken by the affected account during the suspect session window — Graph returns two years of audit events, so historical scope is available
2. Enumerate **device actions** issued in that window: wipe, retire, delete. These are the irrecoverable ones
3. Check whether any **MAA access policy exclusion** was added during the window (Section 4.2) — adding an exclusion is a natural persistence move for an attacker who has hit the approval wall
4. Check for new or modified **RBAC role assignments** and **scope tag** changes
5. Reverse what can be reversed, and escalate what cannot; a completed wipe is a recovery problem, not a containment one

**Step 4: Rehearse**
1. Run the decision tree as a tabletop at least annually, using an Intune-admin-compromise scenario
2. Record the elapsed time to session revocation; this is the metric the whole control exists to compress

**Time to Complete:** ~4 hours (adoption, Intune-specific extension, and first tabletop)

#### Code Implementation

{% include pack-code.html vendor="microsoft-intune" section="6.2" %}

#### Validation & Testing
**How to verify the control is working:**
1. Trigger a simulated risky sign-in and verify the alert reaches the SOC queue
2. Walk the [decision tree](https://aka.ms/tokentheftworkflow) end to end in a tabletop exercise using an Intune-admin-compromise scenario
3. Verify session revocation completes within 5 minutes
4. Confirm the SOC can produce, from the Intune audit log, the full list of administrative actions taken by a given account in a given window — including device actions and MAA exclusion changes
5. Confirm the playbook's recovery steps (deleting attacker-added authentication methods and enrolled devices via Graph) are runnable by the on-call responder, not just documented

**Expected result:** Token theft alerts trigger automated response and SOC investigation within defined SLAs, executed against Microsoft's maintained playbook rather than a local paraphrase of it

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.3 | Evaluation of security events |
| **NIST 800-53** | IR-4 | Incident handling |
| **ISO 27001** | A.5.24 | Information security incident management |

---

## 7. Monitoring & Detection

### 7.1 Enable Comprehensive Intune Audit Logging

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2, 8.5 |
| NIST 800-53 | AU-2, AU-3 |

> **Tenant requirement:** the Microsoft 365 unified audit log is [Microsoft 365 §5.1](/guides/microsoft-365/#51-enable-unified-audit-logging) and identity log export is [Microsoft Entra ID §5.1](/guides/microsoft-entra-id/#51-export-entra-id-sign-in-and-audit-logs). Neither contains Intune device and remote-action telemetry — this control is the third plane, and the Stryker kill chain crosses all three.

#### Description
Export Intune audit and operational logs to a SIEM or Log Analytics workspace. Auditing itself is always on — **Microsoft states auditing "is enabled for all customers. It can't be disabled"** — so this control is about routing, retention beyond the native window, and making the record queryable at incident speed.

#### Rationale
**Why This Matters:**
- Audit logs are the primary evidence source for understanding what an attacker did and when
- Native retention is longer than commonly assumed, but is not a SIEM: the admin center date filter covers **the previous year**, and the Graph **[List auditEvents](https://learn.microsoft.com/en-us/graph/api/intune-auditing-auditevent-list)** API returns **two years** of audit events. The value of export is correlation with identity and endpoint telemetry, custom detections, and retention on your own terms — not rescuing data that would otherwise vanish in 30 days
- Real-time log export enables the automated detection rules in Section 7.2, and gives Section 6.2's response playbook something to query
- MAA activity — approve, block, pass, exclusion add, exclusion remove — lands in this same audit log, which is what makes Section 4.2's exclusion monitoring possible

**Attack Prevented:** Detection of unauthorized admin activity, forensic evidence preservation

#### Prerequisites
- Log Analytics workspace, Azure Storage account, or Event Hubs namespace (Microsoft Sentinel, Splunk, QRadar, Sumo Logic all consume via Event Hubs)
- An Azure subscription — the diagnostic-settings destinations are Azure resources
- **Intune Service Administrator** Entra role to configure log routing; **Log Analytics Contributor** on the target workspace
- To *read* audit data: the **Intune Administrator** Entra role, or an Intune role carrying **Audit data — Read**

#### ClickOps Implementation

**Step 1: Configure Diagnostic Settings**
1. Navigate to: **Microsoft Intune admin center** → **Reports** → **Diagnostics settings**. Turn it on the first time; afterwards, add a setting
2. Name: `HTH-IntuneAuditExport`
3. Select log categories:
   - **AuditLogs** — every task that generates a change in Intune, including who did it and when
   - **OperationalLogs** — enrollment success/failure and noncompliant device detail
   - **DeviceComplianceOrg** — the organizational device-compliance report
   - **IntuneDevices** — device inventory and status for enrolled and managed devices
4. Destination: **Send to Log Analytics workspace**, **Stream to an event hub**, and/or **Archive to a storage account**
5. If archiving to storage, set **Retention (days)** — `0` keeps data indefinitely
6. Save

> **Two documented paths, one of them a shortcut.** The dedicated Azure Monitor article routes you through **Reports** → **Diagnostics settings**, while the audit-log article describes reaching the same export configuration via **Tenant administration** → **Audit logs** → **Export**. Both are current Tier 1 Microsoft documentation; use **Reports** → **Diagnostics settings** as the primary path, since that article is the dedicated and more recently updated one. Note that the **Export** button on the Audit logs blade also produces a local `.csv` — that is a one-off download, not a streaming configuration, so do not mistake it for having set up log routing.

**Step 2: Verify Log Flow**
1. Perform a test action (e.g., modify a configuration profile)
2. Navigate to Log Analytics → query: `IntuneAuditLogs | take 10`
3. AuditLogs and OperationalLogs are sent **immediately**; expect them in Azure Monitor within roughly 30 minutes of receipt
4. **DeviceComplianceOrg and IntuneDevices can take up to 48 hours** — they export once per 24 hours at no guaranteed time. Do not build alerting that assumes a fixed completion time, and note that the export pipeline may duplicate up to 100% of data published in a 24-hour period, so downstream consumers must tolerate duplicates

**Step 3: Confirm Audit Read Access for Responders**
1. Verify the SOC accounts that will query audit data hold **Intune Administrator** or an Intune role with **Audit data — Read**
2. Without it, responders can see alerts but cannot pull the underlying administrative record during an incident

**Time to Complete:** ~45 minutes

#### Code Implementation

{% include pack-code.html vendor="microsoft-intune" section="7.1" %}

#### Validation & Testing
**How to verify the control is working:**
1. Perform admin actions and verify they appear in the SIEM within 30 minutes (AuditLogs and OperationalLogs stream immediately)
2. Verify all four log categories are flowing — AuditLogs, OperationalLogs, DeviceComplianceOrg, IntuneDevices — allowing up to 48 hours for the latter two
3. Confirm log retention meets organizational requirements (minimum 90 days, recommended 365 days), independent of the one year available in the admin center filter and two years available through the Graph `List auditEvents` API
4. Confirm a responder holding only **Audit data — Read** can retrieve the audit record

**Expected result:** All Intune administrative actions are captured and forwarded to SIEM in near-real-time

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.2 | System monitoring |
| **NIST 800-53** | AU-2 | Event logging |
| **ISO 27001** | A.8.15 | Logging |
| **PCI DSS** | 10.2 | Audit log implementation |

---

### 7.2 Deploy Stryker-Pattern Detection Rules

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.11 |
| NIST 800-53 | SI-4(5) |

#### Description
Deploy specific detection rules targeting the TTPs used in the Stryker attack: mass device wipe, anomalous admin sign-in patterns, unauthorized role elevation, and script deployment from unfamiliar sources.

#### Rationale
**Why This Matters:**
- Generic monitoring misses targeted attack patterns — purpose-built detections for known TTPs dramatically reduce detection time
- The Stryker attack chain has specific observable signatures at each stage

**Attack Prevented:** Early detection of credential abuse, privilege escalation, and mass wipe attempts

#### Detection Use Cases

**Detection 1: Mass Device Wipe (Stryker Primary TTP)**
Monitor for more than 10 wipe actions within 1 hour from any admin account. This pattern indicates either a compromised account or an insider threat.

{% include pack-code.html vendor="microsoft-intune" section="7.2" %}

**Detection 2: Admin Sign-In from New Device or Location**
Alert when an admin account signs into the Intune admin center from a device or location not previously seen.

**Detection 3: PIM Role Activation Outside Business Hours**
Alert when Intune Administrator or Global Administrator roles are activated via PIM outside normal business hours.

**Detection 4: Rapid Role Assignment Changes**
Alert when multiple RBAC role assignments are modified within a short time window.

#### Validation & Testing
**How to verify the control is working:**
1. Trigger each detection rule with simulated activity
2. Verify alerts are generated and reach the SOC within 15 minutes
3. Confirm automated response actions execute (if configured)

**Expected result:** Each Stryker-pattern TTP generates an alert within the defined detection window

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.2, CC7.3 | Monitoring and evaluation of events |
| **NIST 800-53** | SI-4(5) | System-generated alerts |
| **ISO 27001** | A.8.16 | Monitoring activities |

---

## 8. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Intune Control | Guide Section |
|-----------|------------------|---------------|
| CC6.1 | RBAC least-privilege, phishing-resistant MFA for Intune admins | 1.1, 2.1 |
| CC6.3 | Scope tags, PIM role-based authorization | 1.2, 3.1 |
| CC7.2 | Audit logging, mass wipe detection | 7.1, 7.2 |
| CC7.3 | Token theft investigation, Stryker-pattern detections | 6.2, 7.2 |
| CC8.1 | Multi Admin Approval for changes, MAA exclusion governance | 4.1, 4.2 |

### NIST 800-53 Rev 5 Mapping

| Control | Intune Control | Guide Section |
|---------|------------------|---------------|
| AC-2(1) | PIM automated role management | 3.1 |
| AC-3(4) | Multi Admin Approval (dual authorization), exclusion governance | 4.1, 4.2 |
| AC-6(1) | Least-privilege RBAC roles | 1.1 |
| AU-2 | Comprehensive audit logging | 7.1 |
| CM-3 | Change control over MAA exclusions | 4.2 |
| IA-2(1) | Phishing-resistant MFA for Intune admins | 2.1 |
| IA-2(6) | Separate device for authentication | 2.1 |
| IA-11 | Reauthentication for sensitive admin operations | 6.1 |
| IR-4 | Token theft investigation playbook | 6.2 |
| SI-4 | Mass wipe alerting, anomaly detection | 5.2, 7.2 |

### ISO 27001:2022 Mapping

| Control | Intune Control | Guide Section |
|---------|------------------|---------------|
| A.5.24 | Incident response for token theft | 6.2 |
| A.8.2 | Privileged access via PIM | 3.1 |
| A.8.3 | Wipe permission restriction, Multi Admin Approval, exclusion governance | 4.1, 4.2, 5.1 |
| A.8.5 | Phishing-resistant MFA, session replay defense | 2.1, 6.1 |
| A.8.15 | Audit logging to SIEM | 7.1 |
| A.8.16 | Monitoring and detection rules | 7.2 |

### PCI DSS v4.0 Mapping

| Control | Intune Control | Guide Section |
|---------|------------------|---------------|
| 7.1 | Least-privilege RBAC roles | 1.1 |
| 7.2.1 | Role-based access through PIM | 3.1 |
| 8.3.1 | Strong authentication for all administrative access | 2.1 |
| 8.4.2 | Phishing-resistant MFA for admin access | 2.1 |
| 10.2 | Audit logging implementation | 7.1 |

---

## Appendix A: Edition/Tier Compatibility

| Control | Intune Plan 1 | Intune Plan 2 | Intune Suite | Entra ID P1 | Entra ID P2 |
|---------|:---:|:---:|:---:|:---:|:---:|
| 1.1 RBAC Roles | ✅ | ✅ | ✅ | - | - |
| 1.2 Scope Tags | ✅ | ✅ | ✅ | - | - |
| 2.1 Phishing-Resistant MFA | - | - | - | ✅ | ✅ |
| 3.1 PIM | - | - | - | - | ✅ |
| 3.2 PAW Enforcement | ✅ | ✅ | ✅ | ✅ | ✅ |
| 4.1 Multi Admin Approval | ✅ | ✅ | ✅ | - | - |
| 4.2 MAA Exclusion Governance | ✅ | ✅ | ✅ | - | - |
| 5.1 Wipe Permission Restriction | ✅ | ✅ | ✅ | - | - |
| 5.2 Wipe Rate Alerting | - | - | - | - | ✅ |
| 6.1 Session Replay Defense | - | - | - | ✅ | ✅ |
| 6.2 Token Theft Response | - | - | - | - | ✅ |
| 7.1 Audit Logging Export | ✅ | ✅ | ✅ | - | - |
| 7.2 Detection Rules | - | - | - | - | ✅ |

**Notes on this table:**

- **4.1 / 4.2 — Multi Admin Approval requires only Intune Plan 1.** It is not gated behind Intune Plan 2 or the Intune Suite; Plan 2 adds Remote Help and Advanced Endpoint Analytics, neither of which MAA depends on. The real licensing constraint is that participating administrators hold an Intune license, unless the irreversible **Allow access to unlicensed admins** setting is enabled.
- **6.1** requires Entra ID P1 for the Conditional Access and authentication-context components, and P2 for the sign-in-risk condition in Step 4.
- Conditional Access controls (2.1, 6.1, and the admin-plane policies in the [Microsoft Entra ID guide](/guides/microsoft-entra-id/)) are licensed through Entra ID, not through any Intune plan.

---

## Appendix B: References

**Official Microsoft Documentation:**
- [Best Practices for Securing Microsoft Intune](https://techcommunity.microsoft.com/blog/intunecustomersuccess/best-practices-for-securing-microsoft-intune/4502117)
- [Microsoft Intune Role-Based Access Control](https://learn.microsoft.com/en-us/intune/fundamentals/role-based-access-control/)
- [Use Multi Admin Approval in Intune](https://learn.microsoft.com/en-us/intune/intune-service/fundamentals/multi-admin-approval)
- [Use Multi Admin Approval with the Microsoft Graph API](https://learn.microsoft.com/en-us/intune/fundamentals/role-based-access-control/multi-admin-approval-graph-api)
- [Wipe a device with Microsoft Intune](https://learn.microsoft.com/en-us/intune/device-management/actions/wipe)
- [Audit changes and events in Microsoft Intune](https://learn.microsoft.com/en-us/intune/governance/monitor-audit-logs)
- [Route logs to Azure Monitor using Microsoft Intune](https://learn.microsoft.com/en-us/intune/governance/integrate-azure-monitor)
- [Graph API: List auditEvents](https://learn.microsoft.com/en-us/graph/api/intune-auditing-auditevent-list)
- [Privileged Identity Management for Microsoft Entra Roles](https://learn.microsoft.com/en-us/entra/id-governance/privileged-identity-management/pim-configure)
- [Conditional Access: Require Authentication Strength](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-conditional-access-grant#require-authentication-strength)
- [Authentication Flows as a Condition in Conditional Access Policy](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-authentication-flows)
- [Plan for Mandatory Microsoft Entra Multifactor Authentication](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-mandatory-multifactor-authentication)
- [How Token Protection Enhances Conditional Access Policies](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-token-protection)
- [Protecting Tokens in Microsoft Entra ID](https://learn.microsoft.com/en-us/entra/identity/devices/protecting-tokens-microsoft-entra-id)
- [Token Theft Playbook](https://learn.microsoft.com/en-us/security/operations/token-theft-playbook) — companion [decision tree](https://aka.ms/tokentheftworkflow)

**Stryker Breach Reporting:**
- [Krebs on Security: Iran-Backed Hackers Claim Wiper Attack on Medtech Firm Stryker](https://krebsonsecurity.com/2026/03/iran-backed-hackers-claim-wiper-attack-on-medtech-firm-stryker/)
- [TechCrunch: Stryker says it's restoring systems after pro-Iran hackers wiped thousands of employee devices](https://techcrunch.com/2026/03/17/stryker-says-its-restoring-systems-after-pro-iran-hackers-wiped-thousands-of-employee-devices/)
- [Cybersecurity Dive: Stryker attack raises concerns about role of device management tool](https://www.cybersecuritydive.com/news/stryker-attack-device-management-microsoft-iran/814816/)
- [SecurityWeek: Iranian Hackers Likely Used Malware-Stolen Credentials in Stryker Breach](https://www.securityweek.com/iranian-hackers-likely-used-malware-stolen-credentials-in-stryker-breach/)

**Threat Intelligence:**
- [Check Point Research: Handala Hack — Unveiling Group's Modus Operandi](https://research.checkpoint.com/2026/handala-hack-unveiling-groups-modus-operandi/)
- [Palo Alto Unit 42: Increased Risk of Wiper Attacks](https://unit42.paloaltonetworks.com/handala-hack-wiper-attacks/)
- [Coalition: How Infostealers May Have Opened the Door to the Stryker Wipe](https://www.coalitioninc.com/blog/security-labs/how-infostealers-may-have-opened-door-stryker-wipe)
- [CISA/FBI Engagement with Stryker](https://www.nextgov.com/cybersecurity/2026/03/cisa-fbi-have-engaged-stryker-staff-after-cyberattack-official-says/412192/)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.3.0 | draft | Platform breakout: reframed as a product guide under the Microsoft Common Controls hub (platform frontmatter, hub pointer, moved-controls note). Admin-plane Conditional Access consolidated into the Entra ID guide — former 2.2 (admin portals, with its PowerShell pack migrated to Entra 2.3) and former 2.3 (device code flow, merged into Entra 2.6) deleted here with pointers. 2.1 slimmed to the Intune-scoped MFA application (mandatory-MFA phase table moved to the hub), 3.1 slimmed to the Intune role set (break-glass guidance moved to the hub), 7.1 framed as the third audit plane. 15 controls → 13 | Claude Code (Opus 4.8) |
| 2026-08-08 | 0.2.0 | draft | Currency pass: MAA now enforces on Graph app-auth calls and requires only Intune Plan 1 (4.1 corrected); added 4.2 MAA exclusion governance and 2.3 device code flow block; replaced unimplementable Token Protection mechanism in 6.1 with documented admin-plane replay defenses; remapped 6.2 to Microsoft's Token Theft Playbook; corrected audit-log retention and diagnostics paths (5.2, 7.1); covered built-in wipe-capable roles (1.1, 5.1); refreshed legacy `/mem/intune/` links | `Claude Code (Opus 4.8)` |
| 2026-03-19 | 0.1.0 | draft | Initial guide focused on Stryker/Handala TTP defense | `Claude Code (Opus 4.6)` |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)

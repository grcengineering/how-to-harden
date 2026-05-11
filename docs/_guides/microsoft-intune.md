---
layout: guide
title: "Microsoft Intune Hardening Guide"
vendor: "Microsoft Intune"
slug: "microsoft-intune"
tier: "1"
category: "IT Operations"
description: "Endpoint management hardening for Microsoft Intune — defending against admin-plane abuse, credential theft, and destructive wipe attacks"
version: "0.1.0"
maturity: "draft"
last_updated: "2026-03-19"
---

## Overview

Microsoft Intune is a cloud-based endpoint management platform used by **hundreds of thousands of organizations** to manage Windows, macOS, iOS, Android, and Linux devices. As the central authority for device configuration, compliance enforcement, and remote actions, Intune wields enormous destructive potential if compromised. The **March 2026 Stryker breach** proved this decisively: Iranian threat actors (Handala / Void Manticore) used a single compromised admin account to issue native Intune remote-wipe commands across **200,000+ devices in 79 countries** — no malware required.

This guide focuses on hardening the Intune administrative plane against the specific TTPs used in the Stryker attack and similar credential-based admin-abuse scenarios. Every control maps directly to a stage of the Stryker kill chain.

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
This guide covers Microsoft Intune administrative security: RBAC, authentication hardening, Privileged Identity Management, Multi-Admin Approval, device wipe protection, token protection, and detection of admin-plane abuse. Device-level compliance policies and application management are covered where they relate to preventing destructive attacks. Entra ID and Microsoft 365 hardening are covered in their respective guides.

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

**Step 2: Create Scoped Custom Roles**
1. Navigate to: **Roles** → **All roles** → **Create**
2. Create function-specific roles:
   - **Help Desk Operator**: Read devices, initiate remote assistance (no wipe)
   - **App Manager**: Manage app deployments (no device actions)
   - **Compliance Viewer**: Read compliance policies and reports (read-only)
   - **Endpoint Security Manager**: Manage security baselines and policies
3. For each role, explicitly **exclude** destructive permissions: Wipe, Retire, Delete, Reset
4. Assign scope tags limiting visibility to specific regions, business units, or device platforms

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

#### Description
Require phishing-resistant multi-factor authentication (FIDO2 security keys, Windows Hello for Business, or certificate-based authentication) for every user with Intune administrative privileges. Disable weaker MFA methods (SMS, phone call, push notification) for privileged accounts.

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

**Step 1: Enable FIDO2 as an Authentication Method**
1. Navigate to: **Microsoft Entra admin center** → **Protection** → **Authentication methods** → **Policies**
2. Click **FIDO2 security key** → **Enable** → Set target to **All users** or a security group containing all Intune admins
3. Under **Configure**, enable:
   - Enforce attestation: **Yes**
   - Enforce key restrictions: **Yes** (restrict to approved key AAGUIDs)
   - Allow self-service set up: **Yes**

**Step 2: Create Conditional Access Policy for Intune Admins**
1. Navigate to: **Microsoft Entra admin center** → **Protection** → **Conditional Access** → **Create new policy**
2. **Name:** `HTH-Require-PhishResistant-MFA-IntuneAdmins`
3. **Assignments:**
   - Users: Include **Directory roles** → Select: Intune Administrator, Global Administrator, Security Administrator
   - Cloud apps: Include → **Microsoft Intune**, **Microsoft Intune Enrollment**, **Microsoft Graph**
4. **Grant:** Require authentication strength → **Phishing-resistant MFA**
5. **Session:** Sign-in frequency → **Every time**
6. Enable policy: **On**

**Step 3: Disable Weak MFA Methods for Admins**
1. Navigate to: **Authentication methods** → **Policies**
2. For each weaker method (SMS, Voice call, Microsoft Authenticator push):
   - Set **Target** to exclude the Intune admin group
3. Verify only FIDO2 and Windows Hello remain available for admin accounts

**Time to Complete:** ~45 minutes

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

### 2.2 Enforce Conditional Access for Admin Portals

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.4 |
| NIST 800-53 | AC-7, AC-11 |

#### Description
Create dedicated Conditional Access policies that govern access to the Intune admin center and Microsoft Graph API. Require compliant devices, trusted locations, and risk-based controls for all administrative sessions.

#### Rationale
**Why This Matters:**
- Conditional Access is the policy engine that determines whether a sign-in is permitted — without dedicated policies for admin portals, attackers with valid credentials face no additional barriers
- Requiring a compliant, managed device for admin access means stolen credentials alone are insufficient
- The Stryker attackers authenticated from an unmanaged device outside the corporate network — device compliance and location policies would have blocked the sign-in

**Attack Prevented:** Credential abuse from unmanaged devices, access from adversary infrastructure

#### Prerequisites
- Microsoft Entra ID P1 or P2 license
- Named locations configured for corporate networks
- Device compliance policies configured in Intune

#### ClickOps Implementation

**Step 1: Create Admin Portal Conditional Access Policy**
1. Navigate to: **Microsoft Entra admin center** → **Protection** → **Conditional Access** → **Create new policy**
2. **Name:** `HTH-AdminPortal-ComplianceRequired`
3. **Assignments:**
   - Users: Include **Directory roles** → Intune Administrator, Global Administrator, Security Administrator, Helpdesk Administrator
   - Cloud apps: **Microsoft Intune**, **Microsoft Admin Portals**, **Microsoft Graph**
4. **Conditions:**
   - Locations: Exclude → Named locations (corporate offices, VPN egress)
5. **Grant:** Require **compliant device** AND **phishing-resistant MFA**
6. **Session:** Sign-in frequency → **1 hour** (re-authenticate hourly)
7. Enable policy: **On**

**Step 2: Block Legacy Authentication**
1. Create a second policy: `HTH-BlockLegacyAuth-Admins`
2. **Assignments:** Same admin roles
3. **Conditions:** Client apps → **Exchange ActiveSync clients**, **Other clients**
4. **Grant:** **Block access**
5. Enable policy: **On**

**Time to Complete:** ~30 minutes

#### Code Implementation

{% include pack-code.html vendor="microsoft-intune" section="2.2" %}

#### Validation & Testing
**How to verify the control is working:**
1. Attempt Intune admin sign-in from a non-compliant device — should be blocked
2. Attempt sign-in from an untrusted location without compliant device — should be blocked
3. Confirm admin sessions require re-authentication after 1 hour

**Expected result:** Admin access requires both a compliant device and phishing-resistant MFA; sessions expire after 1 hour

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical and physical access controls |
| **NIST 800-53** | AC-7 | Unsuccessful logon attempts |
| **ISO 27001** | A.8.5 | Secure authentication |
| **PCI DSS** | 8.2.7 | Accounts used by third parties monitored |

---

## 3. Privileged Access Management

### 3.1 Enable Privileged Identity Management (PIM) for Intune Roles

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.8 |
| NIST 800-53 | AC-2(1), AC-6(2) |

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
- **Break-glass scenarios**: Maintain 1-2 emergency access accounts with permanent active assignment, protected by FIDO2 and monitored continuously
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
1. Update the admin portal Conditional Access policy (Section 2.2)
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
Require a second authorized administrator to approve high-impact actions before they execute. This includes device wipe, device retire, script deployment, and RBAC role changes. Multi-Admin Approval ensures no single compromised or rogue admin can cause tenant-wide destruction.

#### Rationale
**Why This Matters:**
- The Stryker attack succeeded because a single admin credential was sufficient to wipe 200,000+ devices
- Multi-Admin Approval would have required a second, independent admin to approve each wipe action — stopping the attack entirely
- This is the single most effective control against Intune admin-plane abuse
- Microsoft released this feature specifically in response to the Stryker-class attack scenario

**Attack Prevented:** Single-admin mass wipe (T1485), unauthorized RBAC changes, malicious script deployment

**Real-World Incidents:**
- **March 2026 Stryker breach**: Single compromised admin account issued mass wipe — Multi-Admin Approval would have blocked every wipe action pending a second approval

#### Prerequisites
- Intune Service Administrator or Global Administrator role
- At least 2 designated approvers identified
- Microsoft Intune Plan 2 or Intune Suite license

#### ClickOps Implementation

**Step 1: Enable Multi-Admin Approval**
1. Navigate to: **Microsoft Intune admin center** → **Tenant administration** → **Multi-admin approval**
2. Click **Create access protection policy**
3. Configure protection scope (start with highest-impact actions):
   - **Device actions:** Wipe, Retire, Delete
   - **Scripts:** PowerShell script deployment, remediation scripts
   - **RBAC:** Role assignment changes, role definition changes

**Step 2: Define Approvers**
1. Add approver group: Select a security group containing at least 2 senior IT/security personnel
2. Set approval threshold: Minimum **1 approver** (not the requestor)
3. Set approval timeout: **4 hours** (requests expire if not approved)

**Step 3: Expand Scope (Phase 2)**
After initial deployment stabilizes, extend Multi-Admin Approval to:
- Compliance policy changes affecting all devices
- Security baseline modifications
- Conditional Access policy changes
- Changes with broad (All Users / All Devices) assignment scope

**Time to Complete:** ~30 minutes

#### Code Implementation

{% include pack-code.html vendor="microsoft-intune" section="4.1" %}

#### Validation & Testing
**How to verify the control is working:**
1. Attempt a device wipe — verify it enters "pending approval" state
2. Approve the wipe with a second admin account — verify it executes
3. Let a wipe request expire — verify it is auto-denied after timeout
4. Verify the original requestor cannot approve their own request

**Expected result:** All protected actions require a second admin's approval before execution

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

**Step 2: Remove Wipe from All Other Roles**
1. Review each custom role → **Permissions**
2. Ensure **Remote tasks > Wipe**, **Retire**, and **Factory reset** are set to **No**
3. This ensures only the Device Recovery Operator role can initiate wipe actions

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
2. Activate Device Recovery Operator via PIM, initiate wipe — should enter Multi-Admin Approval queue
3. Verify wipe executes only after second admin approval

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
1. Navigate to: **Intune admin center** → **Tenant administration** → **Diagnostics settings**
2. Enable sending audit logs and operational logs to:
   - Log Analytics workspace (for Sentinel)
   - Event Hub (for third-party SIEM)
3. Ensure **DeviceActions** category is included

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

### 6.1 Enable Token Protection and Continuous Access Evaluation

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-11 |

#### Description
Enable token protection policies that bind authentication tokens to the device that requested them, preventing token theft and replay attacks. Enable Continuous Access Evaluation (CAE) to instantly revoke access when risk conditions change.

#### Rationale
**Why This Matters:**
- Attackers who steal session tokens can bypass MFA entirely — the token acts as proof of completed authentication
- Token binding ensures a stolen token cannot be replayed from a different device
- CAE ensures that if a user's risk level changes (e.g., account flagged as compromised), active sessions are terminated within minutes rather than waiting for token expiry

**Attack Prevented:** Token theft and replay (T1528), session hijacking, persistent unauthorized access

#### Prerequisites
- Microsoft Entra ID P2 license
- Windows devices enrolled in Intune with TPM 2.0

#### ClickOps Implementation

**Step 1: Enable Token Protection via Conditional Access**
1. Navigate to: **Microsoft Entra admin center** → **Protection** → **Conditional Access** → **Create new policy**
2. **Name:** `HTH-TokenProtection-Admins`
3. **Assignments:** Target admin directory roles
4. **Session:** Require token protection for sign-in sessions
5. Enable policy: **On**

**Step 2: Enable Continuous Access Evaluation**
1. Navigate to: **Microsoft Entra admin center** → **Protection** → **Conditional Access** → **Continuous access evaluation**
2. Set to: **Enabled** (or **Strictly enforce** for highest security)

**Time to Complete:** ~30 minutes

#### Code Implementation

{% include pack-code.html vendor="microsoft-intune" section="6.1" %}

#### Validation & Testing
**How to verify the control is working:**
1. Sign in on a managed device, verify token protection is enforced in sign-in logs
2. Simulate a risk event (e.g., impossible travel) and verify session is revoked within minutes via CAE

**Expected result:** Admin tokens are device-bound and sessions are revoked in near-real-time when risk conditions change

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
Establish a documented investigation and response procedure for token theft alerts. Integrate signals from Microsoft Entra ID Protection, Microsoft Defender XDR, and Microsoft Defender for Cloud Apps to detect and respond to token theft targeting Intune admins.

#### Rationale
**Why This Matters:**
- Token theft is a primary technique for bypassing MFA
- Microsoft Entra ID Protection can detect anomalous token usage (different IP, device, location)
- Without a defined response procedure, alerts go unactioned

**Attack Prevented:** Token theft (T1528), session hijacking, unauthorized admin access

#### ClickOps Implementation

**Step 1: Enable Risky Sign-In Detection**
1. Navigate to: **Microsoft Entra admin center** → **Protection** → **Identity Protection** → **Sign-in risk policy**
2. Set to target admin users/groups
3. Risk level: **Medium and above** → Require MFA or block access
4. Enable **anomalous token** detection

**Step 2: Create Investigation Playbook**
1. Document the response procedure:
   - Revoke all sessions for the affected admin account
   - Disable the account
   - Review Intune audit logs for unauthorized actions during the compromised session
   - Reverse any unauthorized device actions (if possible)
   - Reset credentials and re-provision FIDO2 keys
2. Assign ownership to the Security Operations team

**Time to Complete:** ~2 hours (including playbook documentation)

#### Code Implementation

{% include pack-code.html vendor="microsoft-intune" section="6.2" %}

#### Validation & Testing
**How to verify the control is working:**
1. Trigger a simulated risky sign-in and verify alert is generated
2. Walk through the investigation playbook in a tabletop exercise
3. Verify session revocation completes within 5 minutes

**Expected result:** Token theft alerts trigger automated response and SOC investigation within defined SLAs

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

#### Description
Enable and export all Intune audit and operational logs to a SIEM or Log Analytics workspace. Audit logs capture every administrative action — they are the forensic record for investigating incidents like the Stryker attack.

#### Rationale
**Why This Matters:**
- Audit logs are the primary evidence source for understanding what an attacker did and when
- Without SIEM integration, logs may be retained for only 30 days in Intune
- Real-time log export enables automated detection rules

**Attack Prevented:** Detection of unauthorized admin activity, forensic evidence preservation

#### Prerequisites
- Log Analytics workspace or SIEM (Microsoft Sentinel, Splunk, etc.)
- Intune diagnostic settings permissions

#### ClickOps Implementation

**Step 1: Configure Diagnostic Settings**
1. Navigate to: **Microsoft Intune admin center** → **Tenant administration** → **Diagnostics settings**
2. Click **Add diagnostic setting**
3. Name: `HTH-IntuneAuditExport`
4. Select log categories:
   - **AuditLogs** (all admin actions)
   - **OperationalLogs** (device actions, compliance changes)
   - **DeviceComplianceOrg** (compliance state changes)
5. Destination: Send to **Log Analytics workspace** and/or **Event Hub**
6. Save

**Step 2: Verify Log Flow**
1. Perform a test action (e.g., modify a configuration profile)
2. Navigate to Log Analytics → query: `IntuneAuditLogs | take 10`
3. Verify the test action appears within 5 minutes

**Time to Complete:** ~30 minutes

#### Code Implementation

{% include pack-code.html vendor="microsoft-intune" section="7.1" %}

#### Validation & Testing
**How to verify the control is working:**
1. Perform admin actions and verify they appear in the SIEM within 15 minutes
2. Verify all log categories are flowing (Audit, Operational, Compliance)
3. Confirm log retention meets organizational requirements (minimum 90 days, recommended 365 days)

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
| CC6.1 | RBAC least-privilege, phishing-resistant MFA, Conditional Access | 1.1, 2.1, 2.2 |
| CC6.3 | Scope tags, PIM role-based authorization | 1.2, 3.1 |
| CC7.2 | Audit logging, mass wipe detection | 7.1, 7.2 |
| CC7.3 | Token theft investigation, Stryker-pattern detections | 6.2, 7.2 |
| CC8.1 | Multi-Admin Approval for changes | 4.1 |

### NIST 800-53 Rev 5 Mapping

| Control | Intune Control | Guide Section |
|---------|------------------|---------------|
| AC-2(1) | PIM automated role management | 3.1 |
| AC-3(4) | Multi-Admin Approval (dual authorization) | 4.1 |
| AC-6(1) | Least-privilege RBAC roles | 1.1 |
| AU-2 | Comprehensive audit logging | 7.1 |
| IA-2(1) | Phishing-resistant MFA | 2.1 |
| IA-2(6) | Separate device for authentication | 2.1 |
| IR-4 | Token theft investigation playbook | 6.2 |
| SI-4 | Mass wipe alerting, anomaly detection | 5.2, 7.2 |

### ISO 27001:2022 Mapping

| Control | Intune Control | Guide Section |
|---------|------------------|---------------|
| A.5.24 | Incident response for token theft | 6.2 |
| A.8.2 | Privileged access via PIM | 3.1 |
| A.8.3 | Wipe permission restriction, Multi-Admin Approval | 4.1, 5.1 |
| A.8.5 | Phishing-resistant MFA, token protection | 2.1, 6.1 |
| A.8.15 | Audit logging to SIEM | 7.1 |
| A.8.16 | Monitoring and detection rules | 7.2 |

### PCI DSS v4.0 Mapping

| Control | Intune Control | Guide Section |
|---------|------------------|---------------|
| 7.1 | Least-privilege RBAC roles | 1.1 |
| 7.2.1 | Role-based access through PIM | 3.1 |
| 8.4.2 | Phishing-resistant MFA for admin access | 2.1 |
| 10.2 | Audit logging implementation | 7.1 |

---

## Appendix A: Edition/Tier Compatibility

| Control | Intune Plan 1 | Intune Plan 2 | Intune Suite | Entra ID P1 | Entra ID P2 |
|---------|:---:|:---:|:---:|:---:|:---:|
| 1.1 RBAC Roles | ✅ | ✅ | ✅ | - | - |
| 1.2 Scope Tags | ✅ | ✅ | ✅ | - | - |
| 2.1 Phishing-Resistant MFA | - | - | - | ✅ | ✅ |
| 2.2 Conditional Access | - | - | - | ✅ | ✅ |
| 3.1 PIM | - | - | - | - | ✅ |
| 3.2 PAW Enforcement | ✅ | ✅ | ✅ | ✅ | ✅ |
| 4.1 Multi-Admin Approval | - | ✅ | ✅ | - | - |
| 5.1 Wipe Permission Restriction | ✅ | ✅ | ✅ | - | - |
| 5.2 Wipe Rate Alerting | - | - | - | - | ✅ |
| 6.1 Token Protection | - | - | - | - | ✅ |
| 6.2 Token Theft Response | - | - | - | - | ✅ |
| 7.1 Audit Logging Export | ✅ | ✅ | ✅ | - | - |
| 7.2 Detection Rules | - | - | - | - | ✅ |

---

## Appendix B: References

**Official Microsoft Documentation:**
- [Best Practices for Securing Microsoft Intune](https://techcommunity.microsoft.com/blog/intunecustomersuccess/best-practices-for-securing-microsoft-intune/4502117)
- [Microsoft Intune Role-Based Access Control](https://learn.microsoft.com/en-us/mem/intune/fundamentals/role-based-access-control)
- [Multi-Admin Approval in Intune](https://learn.microsoft.com/en-us/mem/intune/fundamentals/multi-admin-approval)
- [Privileged Identity Management for Microsoft Entra Roles](https://learn.microsoft.com/en-us/entra/id-governance/privileged-identity-management/pim-configure)
- [Conditional Access: Require Authentication Strength](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-conditional-access-grant#require-authentication-strength)
- [Protecting Tokens in Microsoft Entra](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-token-protection)

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
| 2026-03-19 | 0.1.0 | draft | Initial guide focused on Stryker/Handala TTP defense | `Claude Code (Opus 4.6)` |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)

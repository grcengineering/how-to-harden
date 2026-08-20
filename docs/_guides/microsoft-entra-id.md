---
layout: guide
title: "Microsoft Entra ID Hardening Guide"
vendor: "Microsoft Entra ID"
slug: "microsoft-entra-id"
platform: "Microsoft"
platform_slug: "microsoft-365"
product: "Microsoft Entra ID"
tier: "1"
category: "Identity"
description: "Microsoft Entra ID hardening for the identity control plane — authentication methods and strengths, Conditional Access policy authoring, PIM role settings, access reviews, restricted management administrative units, and identity log export."
version: "0.3.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---

## Overview

Microsoft Entra ID (formerly Azure Active Directory) is the cloud identity platform for over **720 million users** across enterprises worldwide. As the authentication backbone for Microsoft 365, Azure, and thousands of SaaS applications, Entra ID security is foundational to Zero Trust architecture. The **January 2024 Midnight Blizzard breach** of Microsoft's corporate environment demonstrated how a single misconfigured test account without MFA can cascade into widespread compromise.

This is a **product guide within the [Microsoft platform](/guides/microsoft-365/)**. Tenant-wide requirements — that MFA is required, that legacy authentication is blocked, that break-glass accounts exist and are monitored, that PIM governs admin roles, that OAuth consent is restricted, and that the unified audit log is on — live in the Microsoft 365 **Common Controls** hub and are referenced here rather than restated. Everything below is the identity control plane itself: the policy objects an administrator authors in the Entra admin center to make those requirements real, plus the identity-only controls the hub does not reach.

The two layers fail independently, which is why both exist. The hub decides **what the tenant requires**; this guide decides **what the identity system actually enforces** — and a tenant policy that says "require MFA" enforces nothing stronger than SMS if the authentication methods policy still has SMS enabled for everyone.

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
This guide covers the Entra ID admin surface: the authentication methods policy and authentication strengths, Conditional Access policy authoring, Privileged Identity Management role settings, access reviews and restricted management administrative units, application registration and legacy-API governance, and identity log export. Tenant-wide policy requirements are in the [Microsoft 365 Common Controls guide](/guides/microsoft-365/); Intune's admin plane is in the [Microsoft Intune guide](/guides/microsoft-intune/). Azure infrastructure is covered separately.

**Automation surface:** every Conditional Access, PIM, and emergency-access control below ships Terraform in a single interdependent module (`packs/microsoft-entra-id/terraform/`) plus Microsoft Graph PowerShell. Diagnostic-settings export requires the `azurerm` provider rather than `azuread`, and PIM *role settings* (activation duration, approval chain) are admin-center or Graph-beta only — the controls below say so where it applies.

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

### 1.1 Configure Authentication Methods and Authentication Strengths

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 6.5 |
| NIST 800-53 | IA-2(1), IA-2(6) |

> **Tenant requirement:** that MFA is required for all users is [Microsoft 365 §1.1](/guides/microsoft-365/#11-enforce-phishing-resistant-mfa-for-all-users), which also carries Microsoft's mandatory-MFA enforcement timeline. This control is what makes that requirement mean something stronger than SMS.

#### Description
Enable the authentication methods your tenant will accept and disable the ones it will not, then author the reusable **authentication strength** that Conditional Access policies reference. The authentication methods policy is the Entra-native object that decides which factors can ever satisfy an MFA prompt; a Conditional Access policy that grants on "require multifactor authentication" accepts whatever this policy leaves enabled.

#### Rationale
**Why This Matters:**
- A tenant-wide "require MFA" policy is satisfied by SMS or voice if those methods are still enabled — the requirement and the factor strength are configured in two different places
- SMS and voice are defeated by SIM swapping and by real-time phishing proxies (Evilginx, Modlishka); FIDO2 and Windows Hello for Business are origin-bound and cannot be relayed
- Authentication strengths are reusable objects: author "Phishing-Resistant MFA" once and every admin-scoped Conditional Access policy can grant on it, instead of each policy re-specifying factors

**Attack Prevented:** Real-time phishing proxy relay, SIM swap, MFA fatigue, downgrade to a weak second factor

**Real-World Incidents:**
- **Midnight Blizzard (2024):** Test account without MFA led to Microsoft corporate email compromise

#### Prerequisites
- Microsoft Entra ID P1 or P2 license
- FIDO2 security keys provisioned for privileged users
- Authentication Policy Administrator, Security Administrator, or Global Administrator role

#### ClickOps Implementation

**Step 1: Configure Authentication Methods**
1. Navigate to: **Protection** → **Authentication methods** → **Policies**
2. Enable the methods you intend to accept:
   - **Passkey (FIDO2):** Enable for all users. Under **Configure**, set **Enforce attestation** to **Yes** and **Enforce key restrictions** to **Yes**, restricting to your approved key AAGUIDs
   - **Microsoft Authenticator:** Enable with number matching and application/location context displayed
   - **Temporary Access Pass:** Enable for onboarding and key-replacement scenarios
3. Disable the methods you do not: set **SMS** and **Voice call** to **Disabled**, or target them to a named recovery group only

**Step 2: Create the Phishing-Resistant Authentication Strength**
1. Navigate to: **Protection** → **Authentication methods** → **Authentication strengths**
2. Click **+ New authentication strength**
3. Name: "Phishing-Resistant MFA"
4. Select:
   - Passkey (FIDO2)
   - Windows Hello for Business
   - Certificate-based authentication (CBA)
5. Save — Conditional Access policies grant on this object by name

**Step 3: Retire Security Defaults if Still Enabled**
1. Navigate to: **Identity** → **Overview** → **Properties** → **Manage security defaults**
2. Security Defaults and Conditional Access are mutually exclusive. Tenants with P1/P2 should run Conditional Access; leave Security Defaults enabled only where no Conditional Access policy exists yet, and turn it off in the same change that enables the tenant MFA policy

**Time to Complete:** ~45 minutes

#### Code Implementation

{% include pack-code.html vendor="microsoft-entra-id" section="1.1" %}

#### Validation & Testing
**How to verify the control is working:**
1. As a test user, attempt to register SMS as a method — it should be unavailable
2. Sign in against a policy that grants on the "Phishing-Resistant MFA" strength using a passkey — it should succeed; using Authenticator push — it should fail
3. Review **Monitoring** → **Sign-in logs** → the **Authentication Details** tab and confirm the satisfying method is the one you intended
4. Check the **Authentication methods** activity report for users still registered on disabled methods

**Expected result:** Only phishing-resistant factors can satisfy admin sign-in; weak methods cannot be registered or used

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | IA-2(1), IA-2(6) | Multi-factor authentication |
| **ISO 27001** | A.9.4.2 | Secure log-on procedures |
| **CIS M365 Foundations** | v7.0.0 | MFA enforcement (see benchmark for current IDs) |

---

### 1.2 Maintain the Emergency Access Exclusion Group

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.1 |
| NIST 800-53 | AC-2 |

> **Tenant requirement:** creating the break-glass accounts, registering their phishing-resistant credentials, storing the credentials offline, and alerting on their use are [Microsoft 365 §1.4](/guides/microsoft-365/#14-configure-break-glass-emergency-access-accounts). This control is the Conditional Access half — the exclusion group every policy in §2 references.

#### Description
Place the emergency access accounts in a dedicated security group and exclude that group — never individual user objects — from every Conditional Access policy in the tenant. Excluding a group means a new policy needs one exclusion entry rather than a per-account lookup, and it makes "is break-glass excluded from this policy?" a single verifiable condition.

#### Rationale
**Why This Matters:**
- The most common way to lock every administrator out of a tenant is a Conditional Access policy authored without a break-glass exclusion — and the person who can fix it is the person who just got locked out
- Excluding accounts individually does not scale: each new policy is a new chance to forget one, and Microsoft-managed policies ([2.5](#25-review-microsoft-managed-conditional-access-policies-and-retire-per-user-mfa)) auto-enable on a timer whether or not anyone remembered
- A named group is auditable — you can enumerate every policy and assert the exclusion, which you cannot do reliably against a list of UPNs

**Attack Prevented:** Self-inflicted tenant lockout that delays incident response; loss of recovery path during an active intrusion

#### Prerequisites
- Emergency access accounts created per [Microsoft 365 §1.4](/guides/microsoft-365/#14-configure-break-glass-emergency-access-accounts)
- Global Administrator or Conditional Access Administrator role

#### ClickOps Implementation

**Step 1: Create the Exclusion Group**
1. Navigate to: **Microsoft Entra admin center** → **Groups** → **All groups** → **+ New group**
2. Type: **Security**, name it explicitly (e.g., "Emergency Access Accounts")
3. Add both emergency accounts as direct members — not dynamic membership, which depends on a rule that can itself break

**Step 2: Exclude the Group From Every Policy**
1. Navigate to: **Protection** → **Conditional Access** → **Policies**
2. Edit each policy — including every policy labeled **Created by: Microsoft**
3. Under **Users** → **Exclude** → **Users and groups**, add the emergency access group
4. Save

**Step 3: Re-verify After Every Policy Change**
1. Treat "is the emergency group excluded?" as a required review item on any new or edited Conditional Access policy
2. Re-run the check after Microsoft introduces a managed policy — those appear without an admin creating them

**Time to Complete:** ~20 minutes

#### Code Implementation

The Terraform module provisions the emergency accounts and the exclusion group together, and every Conditional Access resource in this guide references that group.

{% include pack-code.html vendor="microsoft-entra-id" section="1.2" %}

#### Validation & Testing
1. Enumerate all Conditional Access policies and confirm each excludes the emergency access group
2. Sign in with an emergency account and confirm no Conditional Access policy applies (check the **Conditional Access** tab of the sign-in log entry, not just that sign-in succeeded)
3. Confirm the alert configured in [Microsoft 365 §1.4](/guides/microsoft-365/#14-configure-break-glass-emergency-access-accounts) fired for that sign-in
4. Immediately rotate the password after any test sign-in

---

## 2. Conditional Access

### 2.1 Block Legacy Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.2 |
| NIST 800-53 | IA-2, AC-17 |

> **Tenant requirement:** the org-wide decision to retire legacy authentication — including Microsoft's firm EWS and SMTP AUTH end dates and the Exchange-side SMTP AUTH disablement — is [Microsoft 365 §1.2](/guides/microsoft-365/#12-block-legacy-authentication-protocols). This control is the Conditional Access policy that enforces it at the identity layer.

#### Description
Author the Conditional Access policy that blocks the legacy client app types (`exchangeActiveSync` and `other`) tenant-wide. Conditional Access is the only place a legacy-auth block applies across every workload at once; per-service switches such as SMTP AUTH still have to be set in Exchange Online.

#### Rationale
**Why This Matters:**
- Legacy protocols authenticate with a password alone, so no MFA policy can apply to them — blocking the client app type is the enforcement, not a supplement to it
- A tenant that disables SMTP AUTH in Exchange but leaves the Conditional Access block unauthored is still reachable over the other legacy client types
- Report-only mode on this policy is the cheapest inventory of which applications still depend on legacy auth, before the vendor cutover forces the issue

**Attack Prevented:** Password spray via legacy protocols, credential replay against MFA-incapable endpoints

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

> **Tenant requirement:** the requirement itself, its rationale, and Microsoft's mandatory-MFA enforcement phases are [Microsoft 365 §1.1](/guides/microsoft-365/#11-enforce-phishing-resistant-mfa-for-all-users). This control is the baseline policy object; the factors it will accept come from [1.1](#11-configure-authentication-methods-and-authentication-strengths).

#### Description
Author the baseline Conditional Access policy that requires multifactor authentication for all users against all cloud applications. This is the tenant floor that every narrower policy — admin roles, risk conditions, device compliance — sits on top of.

#### Rationale
**Why This Matters:**
- Microsoft's platform-level mandatory MFA covers the admin portals and Azure Resource Manager, not every cloud application your users sign in to — this policy covers the rest
- Scoping to **All cloud apps** rather than an application list removes the weakest-link app as an entry point, and means a newly onboarded SaaS integration is covered on day one
- Authoring it as an explicit policy (rather than relying on Security Defaults or the Microsoft-managed equivalent) is what lets you exclude the emergency access group deliberately and keep the exclusion auditable

**Attack Prevented:** Password spray, credential stuffing, phishing, account takeover against non-portal applications

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

#### Validation & Testing
1. Sign in as a standard user to a non-portal cloud application and confirm the MFA prompt appears
2. Open the sign-in log entry → **Conditional Access** tab and confirm this policy is listed as applied, not "Not applied"
3. Confirm the emergency access group is excluded ([1.2](#12-maintain-the-emergency-access-exclusion-group)) and that a member of it sees no applied policy

**Expected result:** Every interactive sign-in to every cloud app satisfies MFA, with the emergency access group as the only exclusion

---

### 2.3 Require Compliant Devices for Admins

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1, 6.4 |
| NIST 800-53 | AC-2(11), AC-6(1) |

#### Description
Require privileged users to reach the admin portals, Microsoft Graph, and the Intune service only from Intune-compliant or Microsoft Entra hybrid joined devices, with a phishing-resistant authentication strength and a short sign-in frequency. This is the single admin-plane Conditional Access policy for the platform — it governs Entra, Microsoft 365, and Intune administration alike.

#### Rationale
**Why This Matters:**
- Admin credentials used from unmanaged or personal devices expose the tenant to malware, keyloggers, and token theft
- Restricting admin access to managed, compliant devices ensures endpoint controls (disk encryption, EDR, patch state) are enforced before any privileged action
- A stolen admin password is useless to an attacker without an enrolled, compliant device to sign in from
- In the March 2026 Stryker attack, the intruders authenticated to the endpoint-management plane from an unmanaged device outside the corporate network — a compliant-device requirement on **Microsoft Intune** and **Microsoft Graph** would have blocked the sign-in that issued 200,000+ device wipes ([Microsoft Intune guide](/guides/microsoft-intune/))

**Attack Prevented:** Token theft, credential replay from untrusted endpoints, privilege escalation via compromised personal devices, admin-plane abuse from adversary infrastructure

> **Do not treat this policy as redundant with tenant-level mandatory MFA.** Microsoft's mandatory-MFA enforcement is scoped to the admin portals and to Azure Resource Manager (`https://management.azure.com/`); Microsoft states that **Microsoft Graph APIs are generally not in scope** ([mandatory MFA FAQ](https://learn.microsoft.com/en-us/entra/identity/authentication/concept-mandatory-multifactor-authentication)). Since virtually all administrative automation and every scripted admin action runs through Graph, the **Microsoft Graph** target below is the only thing enforcing compliant-device and phishing-resistant MFA on that surface. Removing it opens an unauthenticated-by-strength path to the same destructive actions.

#### Prerequisites
- Microsoft Entra ID P1 or P2 license
- Device compliance policies configured in Intune, and admin workstations already enrolled and compliant — enabling this policy before that is how you lock yourself out
- The "Phishing-Resistant MFA" authentication strength from [1.1](#11-configure-authentication-methods-and-authentication-strengths)

#### ClickOps Implementation

**Step 1: Create the Admin-Plane Policy**
1. Navigate to: **Protection** → **Conditional Access** → **Policies** → **+ New policy**
2. **Name:** `HTH-AdminPortal-ComplianceRequired`
3. **Assignments:**
   - **Users:** Include **Directory roles** → Global Administrator, Security Administrator, Intune Administrator, Helpdesk Administrator, and any other role that can change tenant or device state
   - **Users** → **Exclude:** the emergency access group ([1.2](#12-maintain-the-emergency-access-exclusion-group))
   - **Target resources:** **Microsoft Admin Portals**, **Microsoft Intune**, **Microsoft Graph**
4. **Grant:** Require **device to be marked as compliant** (or Microsoft Entra hybrid joined) **AND** require authentication strength → **Phishing-Resistant MFA**
5. **Session:** Sign-in frequency → **1 hour**, so a stolen session token expires in an hour rather than a day
6. Enable in **Report-only** first, confirm your own admin devices satisfy it, then set to **On**

**Time to Complete:** ~30 minutes plus a report-only observation window

#### Code Implementation

{% include pack-code.html vendor="microsoft-entra-id" section="2.3" %}

#### Validation & Testing
1. Attempt an admin sign-in from a non-compliant device — it should be blocked
2. Attempt a scripted Graph call (`Connect-MgGraph`) as an admin from a non-compliant device — it should also be blocked, which is the point of including Graph as a target
3. Confirm admin sessions re-prompt after one hour
4. Confirm the emergency access group is excluded and can still sign in

**Expected result:** Administrative access to the portals, Intune, and Graph requires a compliant device and a phishing-resistant factor; sessions expire hourly

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

- Microsoft classifies device code flow as **"a high-risk authentication method that can be part of a phishing attack or used to access corporate resources on unmanaged devices"** and recommends blocking it wherever possible ([Authentication flows as a condition in Conditional Access policy](https://learn.microsoft.com/en-us/entra/identity/conditional-access/concept-authentication-flows))
- It sidesteps device-compliance expectations too, because the token lands on whatever machine started the flow rather than the machine the administrator is sitting at — which is why blocking it closes a gap that [2.3](#23-require-compliant-devices-for-admins) alone does not

**Attack Prevented:** Device code phishing (Storm-2372), MFA-bypassing token theft, token acquisition on unmanaged adversary infrastructure

#### Prerequisites
- Microsoft Entra ID P1 or P2 license
- Sign-in log review to identify legitimate device code flow usage before enforcing (shared devices, conference-room hardware, headless enrollment)

#### ClickOps Implementation

**Step 1: Inventory Existing Device Code Flow Usage**
1. Navigate to: **Microsoft Entra admin center** → **Monitoring & health** → **Sign-in logs**
2. Add the **Authentication protocol** filter → select **Device code**
3. Record which users, devices, and resources legitimately depend on the flow — conference-room and digital-signage devices are the common genuine cases

**Step 2: Create the Authentication-Flows Policy in Report-Only Mode**
1. Navigate to: **Protection** → **Conditional Access** → **Policies** → **+ New policy**
2. Configure:
   - **Name:** Block device code flow
   - **Users:** All users (exclude the emergency access group and any inventoried device-login service accounts)
   - **Target resources:** All resources (or scope to the resources your admins touch)
   - **Conditions** → **Authentication flows** → set **Configure** to **Yes** → check **Device code flow**
   - **Grant:** Block access
3. Enable policy: **Report-only**, and leave it there long enough to cover a normal work cycle

**Step 3: Exempt Device Registration Service If You Target All Resources**
1. If the policy targets **All resources** and your organization uses device code flow for device registration, exempt that service or enrollment will break
2. Navigate to the policy → **Target resources** → **Exclude** → **Select excluded cloud apps** → **Device Registration Service**
3. Via API, exclude client ID `01cb2876-7ebd-4aa4-9cc9-d28bd4d359a9`
4. Confirm the dependency first by filtering sign-in logs on that resource ID with the **Device code** authentication protocol

**Step 4: Enforce**
1. After report-only shows no legitimate usage beyond your exclusions, set the policy to **On**

> **Protocol tracking — the non-obvious side effect.** Once a session uses device code flow, Microsoft Entra marks it *protocol tracked*, and that state **persists through subsequent token refreshes**. A later sign-in in the same session that used a completely different authentication flow can still be blocked by this policy. Expect error `AADSTS530036` on refresh tokens invalidated this way, and expect that possible impact includes full device sign-out. Microsoft documents this as expected behavior with no remediation while the policy is `enabled` — which is exactly why Step 2 runs report-only first.

**Time to Complete:** ~30 minutes (plus report-only observation period)

#### Validation & Testing
1. Attempt a device-code sign-in (`az login --use-device-code`) as a standard user — it should be blocked
2. In **Sign-in logs**, open the blocked event → **Conditional Access** tab → confirm this policy is the one that applied
3. Confirm device enrollment still succeeds if you configured the Device Registration Service exclusion
4. Check the **Original transfer method** property in **Activity details** on any unexpected block to confirm whether protocol tracking, rather than a live device code sign-in, caused it

**Expected result:** Device code flow blocked tenant-wide except for scoped exceptions; legitimate device-registration flows continue to work. ([Microsoft Storm-2372 advisory](https://www.microsoft.com/en-us/security/blog/2025/02/13/storm-2372-conducts-device-code-phishing-campaign/))

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

> **Tenant requirement:** the decision to run a PIM program and convert standing admin to eligible is [Microsoft 365 §1.3](/guides/microsoft-365/#13-implement-privileged-identity-management-pim). This control is the per-role settings work in Identity Governance; the Intune role set and its destructive-action profile are in [Microsoft Intune §3.1](/guides/microsoft-intune/#31-enable-privileged-identity-management-pim-for-intune-roles).

#### Description
Configure the PIM role settings themselves — activation duration, MFA and justification requirements, approval chain, and eligibility expiry — and convert permanent assignments to eligible. The tenant decision is "no standing admin"; this control is the set of per-role knobs that decides how much friction an attacker who holds a valid admin credential actually meets.

#### Rationale
**Why This Matters:**
- PIM is only as strong as its role settings: an eligible assignment that activates in one click with no MFA, no justification, and an 8-hour window barely slows a credential thief down
- Approval-on-activation for the highest-privilege roles turns privilege escalation into an event a second human sees in real time, which is the detection opportunity standing privilege never gives you
- Eligibility expiry forces re-justification on a clock, so the eligible-assignment list does not quietly become the old permanent-admin list

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

> **Tenant requirement:** the consent posture, the admin approval workflow, and blocking user app registration are [Microsoft 365 §3.1](/guides/microsoft-365/#31-restrict-user-consent-to-applications). This control is the Entra authorization-policy object that carries the setting.

#### Description
Set the tenant authorization policy so the default user role holds no permission-grant policy — the object-level expression of "users cannot consent to applications." The setting defaults to permissive in every new tenant, and it is the single Graph object an attacker's consent-phishing lure depends on.

#### Rationale
**Why This Matters:**
- Consent phishing needs no credential theft and no MFA bypass: the victim authenticates legitimately and authorizes the attacker's application, and the resulting token survives a password reset
- The authorization policy is tenant-wide and takes effect immediately, so it is the fastest containment lever during an active consent-phishing campaign
- Because it is a single Graph object, it is also easy to regress silently — audit it rather than assuming it stayed set

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

> Blocking user **app registration** is a separate setting on a separate blade and is covered in [Microsoft 365 §3.1](/guides/microsoft-365/#31-restrict-user-consent-to-applications) — restricting consent does not stop a user from registering application objects.

**Time to Complete:** ~15 minutes

#### Code Implementation

{% include pack-code.html vendor="microsoft-entra-id" section="4.1" %}

---

### 4.2 Review and Restrict Application Permissions

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.6 |
| NIST 800-53 | AC-6 |

> **Tenant requirement:** the recurring review of enterprise application permissions and the revocation workflow are [Microsoft 365 §3.2](/guides/microsoft-365/#32-review-and-revoke-overprivileged-app-permissions). This control is the Entra-side enumeration — the service principal and app registration inventory the review runs against.

#### Description
Enumerate service principals and app registrations and flag the Graph permissions that grant tenant-wide reach. Terraform data sources make the inventory reproducible; the judgment call on each grant is the review in the hub control.

#### Rationale
**Why This Matters:**
- OAuth applications holding broad Graph permissions can read mail, files, and directory data across the entire tenant, and their tokens are unaffected by password resets or MFA
- App registrations and service principals accumulate from forgotten pilots and departed vendors — nothing expires them, so only enumeration finds them
- The permissions that matter are a short, known list (`Mail.ReadWrite`, `Directory.ReadWrite.All`, `RoleManagement.ReadWrite.Directory`, `full_access_as_app`), which makes the inventory automatable even though the remediation is not

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
1. In your SIEM (see [5.1](#51-export-entra-id-sign-in-and-audit-logs)), alert on directory audit events where the initiating actor pairs a first-party service display name (Exchange, SharePoint) with a user UPN — the CVE-2025-55241 signature

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

### 5.1 Export Entra ID Sign-In and Audit Logs

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2, AU-3, AU-6 |

> **Tenant requirement:** the Microsoft 365 unified audit log — workload activity across Exchange, SharePoint, Teams, and Purview — is [Microsoft 365 §5.1](/guides/microsoft-365/#51-enable-unified-audit-logging). Intune's audit surface is [Microsoft Intune §7.1](/guides/microsoft-intune/#71-enable-comprehensive-intune-audit-logging). This control covers the identity plane, which none of the others contain.

#### Description
Configure Entra ID diagnostic settings to export the identity log categories — `SignInLogs`, `AuditLogs`, `NonInteractiveUserSignInLogs`, and `ServicePrincipalSignInLogs` — to a Log Analytics workspace, Event Hub, or storage account. These logs are not part of the Microsoft 365 unified audit log and are not retained past the Entra default without this export.

#### Rationale
**Why This Matters:**
- Sign-in telemetry is the only record of *how* an account authenticated — which Conditional Access policies applied, which factor satisfied MFA, which IP and device the session came from — and it lives only in this plane
- `ServicePrincipalSignInLogs` and `NonInteractiveUserSignInLogs` are off by default in many export configurations, and they are exactly where OAuth-application and token-replay abuse shows up rather than in interactive sign-ins
- Entra's built-in retention is short (7-30 days depending on license); an intrusion discovered a quarter later is investigated entirely from what was exported at the time

**Attack Prevented:** Undetected intrusion, delayed breach discovery, audit-trail gaps in the identity plane

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
| CC6.1 | Authentication methods & strengths | [1.1](#11-configure-authentication-methods-and-authentication-strengths) |
| CC6.1 | Block legacy auth | [2.1](#21-block-legacy-authentication) |
| CC6.2 | Privileged Identity Management | [3.1](#31-enable-just-in-time-access-for-admin-roles) |
| CC6.3 | Application consent controls | [4.1](#41-restrict-user-consent-to-applications) |
| CC7.2 | Identity log export | [5.1](#51-export-entra-id-sign-in-and-audit-logs) |

### NIST 800-53 Rev 5 Mapping

| Control | Entra ID Control | Guide Section |
|---------|------------------|---------------|
| IA-2(1) | Baseline MFA Conditional Access policy | [2.2](#22-require-mfa-for-all-users) |
| IA-2(6) | Phishing-resistant authentication strength | [1.1](#11-configure-authentication-methods-and-authentication-strengths) |
| AC-2(7) | Privileged account management | [3.1](#31-enable-just-in-time-access-for-admin-roles) |
| AC-2(3) | Access reviews | [3.2](#32-configure-access-reviews) |
| AU-2 | Identity log export | [5.1](#51-export-entra-id-sign-in-and-audit-logs) |

### CIS Microsoft 365 Foundations Benchmark Mapping

> **Benchmark note:** Entra ID identity controls (MFA, legacy authentication, Conditional Access, consent, PIM) live in the **CIS Microsoft 365 Foundations Benchmark** — not the CIS Azure Foundations Benchmark this guide previously cited. CIS M365 Foundations **v7.0.0** (May 2026) added 21 controls and rehomed 12 identity recommendations from the Azure benchmark; consult the [current benchmark](https://www.cisecurity.org/benchmark/microsoft_365) for exact recommendation IDs, which shift across major versions.

| Benchmark Area | Entra ID Control | Guide Section |
|---------------|------------------|---------------|
| MFA enforcement | Phishing-resistant authentication strength | [1.1](#11-configure-authentication-methods-and-authentication-strengths) |
| Legacy authentication | Block legacy auth | [2.1](#21-block-legacy-authentication) |
| Privileged access | PIM just-in-time roles | [3.1](#31-enable-just-in-time-access-for-admin-roles) |
| Emergency access | Break-glass Conditional Access exclusion | [1.2](#12-maintain-the-emergency-access-exclusion-group) |
| Application consent | Restrict user consent | [4.1](#41-restrict-user-consent-to-applications) |

### CISA SCuBA Secure Configuration Baseline (Entra ID) Mapping

The [CISA SCuBA baseline for Entra ID](https://github.com/cisagov/ScubaGear/blob/main/PowerShell/ScubaGear/baselines/aad.md) (assessable with the ScubaGear tool) maps to this guide:

| SCuBA Policy Area | Guide Section |
|-------------------|---------------|
| Block legacy authentication (MS.AAD.1) | [2.1](#21-block-legacy-authentication) |
| Risk-based Conditional Access (MS.AAD.2) | [2.4](#24-block-high-risk-sign-ins) |
| Phishing-resistant MFA & secure registration (MS.AAD.3) | [1.1](#11-configure-authentication-methods-and-authentication-strengths) |
| Centralized logging to SOC (MS.AAD.4) | [5.1](#51-export-entra-id-sign-in-and-audit-logs) |
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
| 2026-08-08 | 0.3.0 | draft | Platform breakout: reframed as a product guide under the Microsoft Common Controls hub (platform frontmatter, hub pointer, scope rewrite). Six duplicated controls slimmed to their Entra admin-surface residue with hub pointers — 1.1 retitled to authentication methods and strengths, 1.2 retitled to the emergency access exclusion group, 2.1, 2.2, 3.1, 4.1, 4.2, and 5.1 retitled to identity log export. Consolidated from the Intune guide: admin-plane Conditional Access including the Microsoft Graph out-of-scope warning (2.3, gained the migrated PowerShell pack) and device code flow report-only staging, Device Registration Service exclusion, and protocol-tracking side effect (2.6) | Claude Code (Opus 4.8) |
| 2026-08-03 | 0.2.0 | draft | Currency update: mandatory-MFA enforcement floor, Microsoft-managed CA policies + per-user MFA retirement (2.5), block device code flow / Storm-2372 (2.6), Restricted Management AUs (3.3), app-registration restriction (4.1), retire Azure AD Graph + CVE-2025-55241 detection (4.3); remap compliance from CIS Azure to CIS M365 Foundations v7.0.0; add CISA SCuBA mapping | Claude Code (Sonnet 5) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with authentication, Conditional Access, PIM, and monitoring | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)

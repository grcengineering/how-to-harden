---
layout: guide
title: "AWS IAM Identity Center Hardening Guide"
vendor: "Amazon Web Services"
slug: "aws-iam-identity-center"
tier: "1"
category: "Identity"
description: "AWS identity management hardening for IAM Identity Center including MFA, permission sets, and account access"
version: "0.2.0"
maturity: "draft"
last_updated: "2026-08-08"
---

## Overview

AWS IAM Identity Center (formerly AWS SSO) is the recommended service for managing workforce access to AWS accounts and applications. As the central identity service for AWS Organizations, IAM Identity Center security configurations directly impact cloud access security.

### Intended Audience
- Security engineers managing AWS access
- Cloud administrators configuring IAM Identity Center
- Platform engineers managing AWS Organizations
- GRC professionals assessing cloud identity

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers AWS IAM Identity Center security including MFA enforcement, permission sets, identity sources, and session policies.

---

## Table of Contents

1. [Authentication & MFA](#1-authentication--mfa)
2. [Identity Source Configuration](#2-identity-source-configuration)
3. [Permission Management](#3-permission-management)
4. [Monitoring & Compliance](#4-monitoring--compliance)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

---

## 1. Authentication & MFA

### 1.1 Enforce Multi-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all IAM Identity Center users — enforced natively when the identity source is the Identity Center directory, AWS Managed Microsoft AD, or AD Connector, and enforced **at the external IdP** when one is connected.

> **Correction (2026-08-08) — where MFA is actually enforced.** AWS documents that IAM Identity Center's native MFA configuration is **"currently not supported for external identity providers."** If your identity source is an external IdP (see [2.1](#21-configure-external-identity-provider)), the MFA settings described below do not apply to those users and **MFA must be enforced in the IdP itself**. Earlier revisions of this guide recommended both native MFA enforcement (1.1) and an external IdP (2.1) as L1 controls without noting that the first is inert under the second — implement whichever matches your identity source, and treat 2.1 as carrying the MFA obligation when an external IdP is in use. Sources: [Enable MFA](https://docs.aws.amazon.com/singlesignon/latest/userguide/enable-mfa.html) · [Configure MFA](https://docs.aws.amazon.com/singlesignon/latest/userguide/mfa-configure.html)

#### Rationale
**Why This Matters:**
- MFA adds a second factor beyond the password, so a phished or stolen credential alone cannot reach the AWS access portal
- IAM Identity Center is the single front door to every account in the organization — one MFA-less login compromise can expose the entire AWS estate
- FIDO2 security keys and authenticator apps resist phishing and SIM-swap attacks that defeat SMS-delivered codes
- Enforcing MFA on every sign-in closes the gap where long-lived sessions skip re-verification

**Attack Prevented:** Credential theft, phishing, credential stuffing, MFA bypass, account takeover

#### Prerequisites
- IAM Identity Center enabled in management account
- AWS Organizations configured
- Admin access to IAM Identity Center

#### ClickOps Implementation

**Step 0: Determine Which Path Applies**
1. Navigate to: **IAM Identity Center** → **Settings** → **Identity source**
2. If the source is **Identity Center directory**, **AWS Managed Microsoft AD**, or **AD Connector**, continue with Steps 1-3 below
3. If the source is an **external identity provider**, stop here — configure MFA in that IdP instead, and record the IdP's enforcement policy as the evidence for this control

**Step 1: Access MFA Settings**
1. Navigate to: **IAM Identity Center** → **Settings** → **Authentication**
2. Find MFA configuration — note that MFA is **on by default** for directory users, so the task is usually verification and tightening rather than initial enablement

**Step 2: Configure MFA Requirement**
1. Select **Require MFA**
2. Configure enforcement:
   - Every sign-in (recommended)
   - Context-aware
3. Save changes

**Step 3: Configure MFA Types**
1. Enable authenticator apps
2. Enable hardware TOTP devices
3. Enable FIDO2 security keys (recommended)
4. Disable SMS if possible
5. Note the per-user registration ceiling: a user may register a **maximum of 8 MFA devices**

**Time to Complete:** ~30 minutes

---

### 1.2 Configure Session Duration

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-12 |

#### Description
Configure session duration limits across the three distinct session types IAM Identity Center maintains — interactive (portal) sessions, permission-set role sessions, and application sessions — recognizing that they expire independently of each other.

#### Rationale
**Why This Matters:**
- Shorter sessions shrink the window in which a hijacked token or unattended session can be abused
- Long-lived portal and permission-set sessions let a stolen session token stay valid long after a user leaves, undermining deprovisioning
- Tighter durations on privileged permission sets force frequent re-authentication for the highest-blast-radius access
- The three session types are **independent** — revoking one does not terminate the others, so a single "disable the user" action does not immediately cut access

**Attack Prevented:** Session hijacking, token replay, unattended-workstation abuse, standing access after offboarding

#### The Three Session Types

| Session type | Documented maximum | Behavior on user revocation |
|--------------|--------------------|-----------------------------|
| **Interactive (AWS access portal) session** | Up to **90 days** | Ends when the interactive session is terminated |
| **Permission-set role session (AWS account access)** | Up to **12 hours** | **Not affected** — revoking, disabling, or deleting the user does **not** end an existing account session |
| **Application session** | Refreshed automatically about every **1 hour**; ends roughly **30 minutes** after the interactive session ends | Ends shortly after the interactive session |

> **The 12-hour exposure window.** AWS documents that removing a user's access — including disabling or deleting the user — does **not** terminate permission-set role sessions already in flight. Those sessions run to their configured duration, which can be as long as 12 hours. Offboarding and incident response therefore require an explicit step beyond user deletion: shorten permission-set session durations in advance, and on suspected compromise revoke the active sessions and/or apply a deny policy to the assumed role rather than assuming user deletion is sufficient.

> **Kiro and long interactive sessions.** AWS documents that Kiro sessions extend the interactive session duration to **90 days**, and that depending on when your organization enabled the relevant capability this may be **enabled by default**. Verify the current interactive session setting rather than assuming a short default.

> **No SAML Single Logout.** IAM Identity Center supports SAML Single Logout in **neither direction** — signing out of the external IdP does not sign the user out of the AWS access portal, and signing out of the portal does not sign them out of the IdP. Do not treat IdP logout as a session-termination control.

Source: [IAM Identity Center — Authentication concepts](https://docs.aws.amazon.com/singlesignon/latest/userguide/authconcept.html)

#### ClickOps Implementation

**Step 1: Configure the Interactive (Portal) Session**
1. Navigate to: **Settings** → **Authentication**
2. Read the current **session duration** value before changing it — it may already be set to a long duration
3. Reduce it to the shortest duration your workforce can tolerate; a 90-day interactive session is rarely defensible outside of specific tooling requirements

**Step 2: Configure Permission Set Sessions**
1. Edit each permission set
2. Set session duration — the maximum is 12 hours
3. Apply materially shorter durations (1 hour or less) to administrative and other high-blast-radius permission sets, since these sessions survive user deletion

**Step 3: Document the Revocation Procedure**
1. Record that user deletion alone leaves account sessions live for up to their configured duration
2. Define the incident step that actually cuts access — terminating the active sessions and/or attaching a deny policy to the affected role
3. Test the procedure so responders are not discovering the gap during an incident

---

### 1.3 Configure Attribute-Based Access Control

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.8 |
| NIST 800-53 | AC-3 |

#### Description
Enable ABAC for fine-grained access control.

#### Rationale
**Why This Matters:**
- ABAC scopes access by matching user and session attributes (department, project, environment) to resource tags, enforcing least privilege dynamically
- Tag-based conditions stop users from reaching resources outside their team or environment even when they hold a broad permission set
- Attribute-driven policies scale without spawning an ever-growing set of bespoke permission sets per team or project

**Attack Prevented:** Lateral movement, over-broad access, privilege creep, cross-environment resource access

#### ClickOps Implementation

**Step 1: Enable ABAC**
1. Navigate to: **Settings** → **Attributes for access control**
2. Enable attributes
3. Configure attribute mappings

**Step 2: Use in Permission Sets**
1. Create ABAC-aware policies
2. Reference user attributes
3. Implement tag-based access

---


{% include pack-code.html vendor="aws-iam-identity-center" section="1.3" %}

## 2. Identity Source Configuration

### 2.1 Configure External Identity Provider

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Connect to external IdP for centralized identity.

#### Rationale
**Why This Matters:**
- Centralizing authentication in your corporate IdP enforces MFA, conditional access, and password policy consistently on every AWS login
- The built-in Identity Center directory lacks the risk-based and conditional-access controls a dedicated IdP provides
- A single source of truth means offboarding in the IdP immediately cuts AWS access, eliminating orphaned local accounts
- SAML federation removes locally stored AWS credentials that are a prime target for theft

**Attack Prevented:** Credential theft, orphaned-account access, inconsistent MFA enforcement, identity sprawl

> **This control carries the MFA obligation.** IAM Identity Center's native MFA configuration is not supported for external identity providers ([enable-mfa](https://docs.aws.amazon.com/singlesignon/latest/userguide/enable-mfa.html)). Once you connect an external IdP, the settings in [1.1](#11-enforce-multi-factor-authentication) no longer govern those users — MFA, conditional access, and session policy must all be enforced in the IdP, and that is what an assessor should be shown as evidence.

#### ClickOps Implementation

**Step 1: Change Identity Source**
1. Navigate to: **Settings** → **Identity source**
2. Click **Change identity source**
3. Select external identity provider

**Step 2: Configure SAML/SCIM**
1. Configure SAML 2.0 settings
2. Enable automatic provisioning (SCIM)
3. Configure attribute mappings

**Step 3: Test and Migrate**
1. Test authentication
2. Migrate users from Identity Center directory
3. Verify access preserved

---

### 2.2 Configure Automatic Provisioning

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Enable SCIM for automatic user provisioning.

#### Rationale
**Why This Matters:**
- SCIM automatically deprovisions departed users and updates group membership, eliminating standing access from stale accounts
- Manual provisioning drifts over time, leaving orphaned users and incorrect group assignments that widen the attack surface
- Group sync keeps permission-set assignments aligned with IdP and HR reality, enforcing least privilege as roles change

**Attack Prevented:** Orphaned-account access, privilege creep, offboarding gaps, unauthorized standing access

#### ClickOps Implementation

**Step 1: Enable SCIM**
1. Navigate to: **Settings** → **Identity source**
2. Enable automatic provisioning
3. Generate SCIM endpoint and token

**Step 2: Configure IdP**
1. Configure SCIM in identity provider
2. Map user attributes
3. Enable group sync

---

### 2.3 Restrict Account Instances of IAM Identity Center

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1, 6.8 |
| NIST 800-53 | CM-7, AC-3 |

#### Description
Prevent member accounts in your AWS Organization from standing up their own *account instances* of IAM Identity Center, which would create identity sources outside the organization instance your security team governs.

> **Changed default.** AWS documents that for organizations that enabled IAM Identity Center **after 2023-11-15**, the ability for member accounts to create their own account instances is **enabled by default**. Organizations that enabled Identity Center before that date have it disabled by default. Check which side of that line you are on rather than assuming. Source: [Enable IAM Identity Center](https://docs.aws.amazon.com/singlesignon/latest/userguide/enable-identity-center.html)

> **Changed enablement options (August 2026).** New IAM Identity Center enablement now offers **Single-Region**, **Multi-Region**, and **Custom** configurations. Two consequences worth deciding deliberately rather than accepting:
>
> - Choosing **Multi-Region** automatically creates a **multi-Region customer managed KMS key**, and **AWS KMS charges apply** — this interacts directly with [4.3](#43-use-a-customer-managed-kms-key-for-identity-center-data), including its lockout risk
> - **Multi-account permissions** is now an **optional capability that is enabled by default**. If your deployment uses IAM Identity Center only for application authentication and never for AWS account access, **disable it** — leaving it on keeps an unused account-access surface live
>
> Sources: [Enable IAM Identity Center](https://docs.aws.amazon.com/singlesignon/latest/userguide/enable-identity-center.html) · [IAM Identity Center document history](https://docs.aws.amazon.com/singlesignon/latest/userguide/doc-history.html)

#### Rationale
**Why This Matters:**
- An account instance created in a member account is a separate identity source with its own users, assignments, and applications — invisible to the controls applied to the organization instance
- A team that stands up its own instance can grant application access on identities the central security team never provisioned, deprovisions, or reviews (a shadow-IdP problem, not merely a duplicate-tooling problem)
- Because this is enabled by default for organizations onboarded after 2023-11-15, the exposure is usually inherited rather than deliberately chosen
- Centralizing on the organization instance is what makes MFA policy, session policy, and access reviews actually complete

**Attack Prevented:** Shadow identity provider creation, ungoverned application access grants, identity sprawl outside central review, bypass of organization-wide access policy

#### Prerequisites
- AWS Organizations with all features enabled
- Service control policy (SCP) authoring permissions in the management account
- An inventory of any existing account instances

#### ClickOps Implementation

**Step 1: Inventory Existing Account Instances**
1. Determine whether any member account has already created an account instance of IAM Identity Center
2. For each one found, identify its owner, its identity source, and the applications assigned through it
3. Plan migration of any legitimate use onto the organization instance before restricting creation

**Step 2: Restrict Creation via Service Control Policy**
1. In the management account, navigate to: **AWS Organizations** → **Policies** → **Service control policies**
2. Create or edit an SCP that denies the Identity Center instance-creation action for member accounts
3. Attach the SCP to the organizational units that should never host their own instance (in most estates, all of them)

**Step 3: Confirm the Restriction**
1. From a member account, attempt to create an account instance and confirm it is denied
2. Record the SCP as the compensating control in your access-management documentation

#### Validation & Testing
1. Re-run the account-instance inventory and confirm no new instances appear
2. Verify the SCP is attached to every relevant OU, including newly created ones
3. Confirm new-account provisioning automation attaches the SCP by default

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Logical access is restricted to authorized identity sources |
| **NIST 800-53** | CM-7 | Least functionality — unnecessary service capability disabled |
| **NIST 800-53** | AC-3 | Access enforcement through a governed identity source |
| **CIS Controls v8** | 4.1 | Secure configuration process for enterprise assets and software |

---

## 3. Permission Management

### 3.1 Configure Permission Sets

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Create least-privilege permission sets.

#### Rationale
**Why This Matters:**
- Least-privilege permission sets limit what any assigned user can do, shrinking the blast radius of a compromised login
- Permissions boundaries cap the maximum permissions a set can grant, blocking privilege-escalation paths even via inline policies
- Broadly assigned permissive sets (such as AdministratorAccess) turn any account takeover into full organizational compromise

**Attack Prevented:** Privilege escalation, lateral movement, blast-radius expansion, excessive standing permissions

#### ClickOps Implementation

**Step 1: Review Permission Sets**
1. Navigate to: **Permission sets**
2. Review existing permission sets
3. Identify overly permissive sets

**Step 2: Create Least-Privilege Sets**
1. Create custom permission sets
2. Use AWS managed policies where possible
3. Apply inline policies for restrictions

**Step 3: Configure Permissions Boundary**
1. Apply permissions boundaries
2. Limit maximum permissions
3. Prevent privilege escalation

---


{% include pack-code.html vendor="aws-iam-identity-center" section="3.1" %}

### 3.2 Configure Account Assignments

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Assign access to AWS accounts.

#### Rationale
**Why This Matters:**
- Assigning users only the accounts they need contains a compromised identity to a limited scope rather than the whole organization
- Group-based assignments make access auditable and revocable in one place instead of scattered per-user grants
- Regular reviews catch accumulated and unnecessary cross-account access before an attacker can exploit it

**Attack Prevented:** Lateral movement across accounts, excessive access, privilege creep, unauthorized account access

#### ClickOps Implementation

**Step 1: Review Assignments**
1. Navigate to: **AWS accounts**
2. Review current assignments
3. Identify unnecessary access

**Step 2: Apply Least Privilege**
1. Assign minimum required accounts
2. Use groups for assignments
3. Regular access reviews

---


{% include pack-code.html vendor="aws-iam-identity-center" section="3.2" %}

### 3.3 Protect Privileged Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Additional controls for privileged access.

#### Rationale
**Why This Matters:**
- Administrative permission sets carry the highest blast radius, so per-session MFA and short durations limit how a stolen admin session can be abused
- Separating admin sets from day-to-day access enforces deliberate, auditable elevation instead of always-on privilege
- Restricting and reviewing admin assignments prevents the privilege accumulation that gives attackers a high-value target

**Attack Prevented:** Privileged account takeover, admin session hijacking, standing admin privilege, privilege escalation

#### ClickOps Implementation

**Step 1: Create Privileged Permission Sets**
1. Create separate admin permission sets
2. Apply shorter session duration
3. Require MFA for every session

**Step 2: Limit Admin Assignments**
1. Restrict admin access to required users
2. Use groups for admin access
3. Regular privileged access reviews

---

### 3.4 Govern the `sso:account:access` Scope on Customer Managed Applications

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 6.8 |
| NIST 800-53 | AC-6, AC-3, SC-28 |

#### Description
Treat the `sso:account:access` scope — added for customer managed applications on **2026-06-19** — as a privileged grant, because it cannot be narrowed once given. Restrict which applications may request it, and enforce strict handling of the tokens it produces.

#### Rationale
**Why This Matters:**
- AWS documents that this scope grants the application access to **all AWS accounts and roles available to the authenticated user** — it is not scopable to a subset, so the only meaningful control is deciding which applications receive it at all
- Because the grant is all-or-nothing, an application that needs one account effectively receives the user's entire account footprint, converting a narrow integration into a broad standing capability
- Only the **management account or a delegated administrator account** can configure this, which makes the configuration itself a high-value target
- The resulting bearer tokens are the actual credential — leaking one in a log, a URL, or browser-accessible storage hands an attacker the same breadth of access

**Attack Prevented:** Over-broad application access grants, token theft and replay, cross-account privilege escalation via a compromised integration, credential exposure through logs and URLs

#### Prerequisites
- Management account or delegated administrator access
- An inventory of customer managed applications configured in IAM Identity Center

#### ClickOps Implementation

**Step 1: Inventory Applications Requesting the Scope**
1. Navigate to: **IAM Identity Center** → **Applications** → **Customer managed**
2. For each application, review whether account access is enabled and which scopes it requests
3. Record the business justification for each application holding `sso:account:access`

**Step 2: Apply an Approval Gate**
1. Require documented security review before enabling account access for any customer managed application — there is no narrower alternative to fall back on
2. Restrict who can perform this configuration to a small named group in the management or delegated administrator account
3. Remove the scope from any application that cannot justify organization-wide account reach

**Step 3: Enforce Token-Handling Requirements**
1. Store tokens **server-side only** — never in browser local storage, session storage, or anywhere client-accessible
2. Never write tokens to application logs, error messages, or telemetry
3. Pass the token in the **`x-amz-sso_bearer_token`** header, never as a URL query parameter (URLs land in proxy logs, referrer headers, and browser history)
4. Monitor CloudTrail for the associated authorization and account-access events (see [4.1](#41-configure-cloudtrail-logging))

#### Validation & Testing
1. Confirm the application inventory lists a reviewed justification for every holder of the scope
2. Grep application logs and log-aggregation indexes for bearer-token patterns to confirm none are being written
3. Verify tokens are transmitted only in the documented header by inspecting the integration's outbound requests
4. Confirm CloudTrail records the account-access events and that they are alertable

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Logical access restricted to authorized applications |
| **SOC 2** | CC6.3 | Access grants are reviewed and justified |
| **NIST 800-53** | AC-6 | Least privilege for application access grants |
| **NIST 800-53** | SC-28 | Protection of credentials at rest and in transit |
| **CIS Controls v8** | 5.4 | Restrict administrator privileges to dedicated accounts |

Source: [Enable account access for customer managed applications](https://docs.aws.amazon.com/singlesignon/latest/userguide/enable-account-access-customer-managed-apps.html)

---

## 4. Monitoring & Compliance

### 4.1 Configure CloudTrail Logging

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable CloudTrail for IAM Identity Center events.

#### Rationale
**Why This Matters:**
- CloudTrail records authentication events, permission changes, and account assignments, providing the audit trail needed to detect and investigate misuse
- Without comprehensive logging, attacker activity such as new admin assignments or anomalous sign-ins goes undetected
- Retained logs support forensic reconstruction after an incident and meet compliance evidence requirements

**Attack Prevented:** Undetected privilege changes, unnoticed unauthorized access, delayed breach detection, audit gaps

#### ClickOps Implementation

**Step 1: Verify CloudTrail**
1. Ensure organization trail enabled
2. Verify IAM Identity Center events captured
3. Configure log retention

**Step 2: Monitor Key Events**
1. Authentication events
2. Permission changes
3. Account assignments

---


{% include pack-code.html vendor="aws-iam-identity-center" section="4.1" %}

### 4.2 Configure Access Analyzer

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Use IAM Access Analyzer for policy validation.

#### Rationale
**Why This Matters:**
- Access Analyzer surfaces policies that grant unintended external or cross-account access before an attacker finds them
- Automated policy validation catches over-permissive grants and misconfigurations that manual review routinely misses
- Continuous findings let teams remediate excessive access proactively rather than after an incident

**Attack Prevented:** Unintended external access, cross-account exposure, policy misconfiguration, excessive permissions

#### ClickOps Implementation

**Step 1: Enable Access Analyzer**
1. Create analyzer for organization
2. Review findings
3. Remediate external access

---


{% include pack-code.html vendor="aws-iam-identity-center" section="4.2" %}

### 4.3 Use a Customer Managed KMS Key for Identity Center Data

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12, SC-13, SC-28 |

#### Description
Encrypt IAM Identity Center data with a customer managed AWS KMS key (CMK) instead of the AWS-owned key used by default. Released **2025-09-17**, this gives you key-level audit trails and revocation — and, in exchange, a hard operational dependency you must plan for.

#### Rationale
**Why This Matters:**
- The default is an **AWS-owned key**, which produces no key policy you control and no key usage record in your own account
- A CMK gives you CloudTrail visibility into every decrypt operation against Identity Center data, plus a key policy you can scope and a revocation path you own
- Regulated environments frequently require customer-controlled key material and demonstrable key lifecycle governance for identity data
- The trade-off is real and must be accepted knowingly: the key becomes a single point of failure for authentication itself

> **Lockout warning — read before enabling.** AWS states that if the KMS key is **deleted, or disabled, or its permissions are altered such that IAM Identity Center can no longer use it, administrators and users are locked out** of IAM Identity Center. This is not a degraded mode; it is loss of access to the service that fronts every AWS account. Pair this control with an explicit key-deletion restriction and a documented break-glass path before enabling it.

**Attack Prevented:** Unaudited access to identity data at rest, inability to revoke access to encrypted data, non-compliance with customer-managed-key requirements

#### Prerequisites
- The key must be a **symmetric** KMS key
- The key must be in the **same Region** as the IAM Identity Center instance
- The key must be created in the **management account**
- If you plan to operate multi-Region, the key must be a **multi-Region key** — a single-Region key **cannot be converted** to multi-Region later, so this decision is effectively permanent
- Verify application compatibility: **not all managed applications support customer managed keys**

#### ClickOps Implementation

**Step 1: Create the Key**
1. In the management account, in the Identity Center Region, navigate to: **KMS** → **Customer managed keys** → **Create key**
2. Select **Symmetric**, and select **Multi-Region key** if multi-Region operation is plausible — this cannot be changed afterward
3. Author a key policy granting IAM Identity Center the operations it requires and no more

**Step 2: Protect the Key Before You Depend On It**
1. Attach an SCP or key policy statement denying `kms:ScheduleKeyDeletion` and `kms:DisableKey` on this key to everyone except a narrowly scoped break-glass principal
2. Enable key rotation and confirm CloudTrail is recording KMS events for the key
3. Alert on any disable, deletion-schedule, or policy-change event against the key at critical severity

**Step 3: Document the Break-Glass Path**
1. Write down exactly what happens and who does what if the key becomes unusable — administrators will not be able to log in to fix it through Identity Center
2. Identify an out-of-band administrative path into the management account that does not depend on IAM Identity Center
3. Test that path before enabling the CMK, not after

**Step 4: Enable the Key on Identity Center**
1. Navigate to: **IAM Identity Center** → **Settings**
2. Configure the encryption setting to use your customer managed key
3. Validate that managed applications in use still authenticate correctly — compatibility is not universal

#### Validation & Testing
1. Confirm CloudTrail shows Identity Center decrypt operations against your key, proving the CMK is in use
2. Confirm the deletion/disable restriction is enforced by attempting the action with a non-break-glass principal
3. Re-test each managed application after enabling and after any key policy change
4. Rehearse the break-glass path on a schedule

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| **SOC 2** | CC6.1 | Logical access to encrypted identity data is controlled |
| **NIST 800-53** | SC-12 | Cryptographic key establishment and management |
| **NIST 800-53** | SC-13 | Use of validated cryptographic mechanisms |
| **NIST 800-53** | SC-28 | Protection of information at rest |
| **CIS Controls v8** | 3.11 | Encrypt sensitive data at rest |

Source: [Customer managed keys for IAM Identity Center](https://docs.aws.amazon.com/singlesignon/latest/userguide/identity-center-customer-managed-keys.html)

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | IAM Identity Center Control | Guide Section |
|-----------|----------------------------|---------------|
| CC6.1 | MFA enforcement | [1.1](#11-enforce-multi-factor-authentication) |
| CC6.2 | Permission sets | [3.1](#31-configure-permission-sets) |
| CC6.6 | Session duration | [1.2](#12-configure-session-duration) |
| CC7.2 | CloudTrail logging | [4.1](#41-configure-cloudtrail-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | IAM Identity Center Control | Guide Section |
|---------|----------------------------|---------------|
| IA-2(1) | MFA | [1.1](#11-enforce-multi-factor-authentication) |
| IA-8 | External IdP | [2.1](#21-configure-external-identity-provider) |
| AC-2 | SCIM provisioning | [2.2](#22-configure-automatic-provisioning) |
| AC-6 | Permission sets | [3.1](#31-configure-permission-sets) |
| AC-6 | `sso:account:access` scope governance | [3.4](#34-govern-the-ssoaccountaccess-scope-on-customer-managed-applications) |
| CM-7 | Account-instance restriction | [2.3](#23-restrict-account-instances-of-iam-identity-center) |
| SC-12, SC-28 | Customer managed KMS key | [4.3](#43-use-a-customer-managed-kms-key-for-identity-center-data) |
| AU-2 | CloudTrail | [4.1](#41-configure-cloudtrail-logging) |

---

## Appendix A: References

**Official AWS Documentation:**
- [IAM Identity Center User Guide](https://docs.aws.amazon.com/singlesignon/latest/userguide/what-is.html)
- [IAM Identity Center Security](https://docs.aws.amazon.com/singlesignon/latest/userguide/security.html)
- [Authentication concepts (session types and durations)](https://docs.aws.amazon.com/singlesignon/latest/userguide/authconcept.html)
- [Enable MFA](https://docs.aws.amazon.com/singlesignon/latest/userguide/enable-mfa.html) · [Configure MFA](https://docs.aws.amazon.com/singlesignon/latest/userguide/mfa-configure.html)
- [Enable IAM Identity Center (instance types and account instances)](https://docs.aws.amazon.com/singlesignon/latest/userguide/enable-identity-center.html)
- [Enable account access for customer managed applications](https://docs.aws.amazon.com/singlesignon/latest/userguide/enable-account-access-customer-managed-apps.html)
- [Customer managed keys for IAM Identity Center](https://docs.aws.amazon.com/singlesignon/latest/userguide/identity-center-customer-managed-keys.html)
- [IAM Identity Center document history](https://docs.aws.amazon.com/singlesignon/latest/userguide/doc-history.html)
- [Security Best Practices in IAM](https://docs.aws.amazon.com/IAM/latest/UserGuide/best-practices.html)
- [Security Reference Architecture - IAM Identity Center](https://docs.aws.amazon.com/prescriptive-guidance/latest/security-reference-architecture/workplace-iam-identity-center.html)
- [AWS IAM Best Practices](https://aws.amazon.com/iam/resources/best-practices/)

**API & Developer Tools:**
- [IAM Identity Center API Reference](https://docs.aws.amazon.com/singlesignon/latest/APIReference/welcome.html)
- [AWS CLI - SSO Admin Commands](https://docs.aws.amazon.com/cli/latest/reference/sso-admin/)
- [AWS SDKs](https://aws.amazon.com/tools/) (Boto3, JavaScript, Go, Java, .NET, etc.)
- [AWS CloudFormation IAM Identity Center Resources](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/AWS_SSO.html)
- [GitHub Organization (aws)](https://github.com/aws)

**Compliance Frameworks:**
- SOC 1/2/3 Type II (12-month audit periods) — via [AWS Artifact](https://aws.amazon.com/artifact/)
- ISO/IEC 27001:2022, ISO 27017:2015, ISO 27018:2019 — via [AWS ISO Certified](https://aws.amazon.com/compliance/iso-certified/)
- FedRAMP (High, Moderate baselines) — via [AWS Compliance Programs](https://aws.amazon.com/compliance/programs/)
- PCI DSS Level 1, HIPAA, HITRUST, DoD SRG, CSA STAR
- [Full Compliance Programs List](https://aws.amazon.com/compliance/programs/)

**Security Incidents:**
- **2025 — IAM Eventual Consistency Exploitation Research:** Researchers disclosed that AWS IAM's eventual consistency model creates a 3-4 second window where deleted access keys remain functional, enabling persistence techniques. AWS applied development fixes and documentation updates in April 2025. ([GBHackers Report](https://gbhackers.com/attackers-abuse-aws-iams/))
- **November 2025 — Compromised IAM Credentials Mining Campaign:** Attackers used compromised IAM user credentials with admin-like privileges to conduct large-scale crypto mining across EC2 instances, detected by GuardDuty. ([The Hacker News Report](https://thehackernews.com/2025/12/compromised-iam-credentials-power-large.html))
- Note: These are AWS-wide IAM incidents, not specific to IAM Identity Center itself. AWS manages infrastructure patching for Identity Center as a managed service.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass. Corrections: 1.1 now states that native MFA configuration is not supported for external identity providers, resolving the contradiction between 1.1 and 2.1 — with an external IdP, MFA must be enforced at the IdP; added the MFA-on-by-default note for directory users and the 8-device registration ceiling; 2.1 gained the matching cross-reference. Rewrote 1.2 around the real three-session model (interactive up to 90 days, permission-set role sessions up to 12 hours and independent of user revocation, application sessions ~1h refresh ending ~30min after the interactive session), including the 12-hour post-deletion exposure window, the Kiro 90-day extension, and the absence of SAML Single Logout in either direction. New controls: 2.3 restrict member-account instances of IAM Identity Center via SCP (enabled by default for orgs enabled after 2023-11-15) with the August 2026 enablement-option changes (Single/Multi-Region/Custom; Multi-Region auto-creates a multi-Region CMK with KMS charges; multi-account permissions now an optional capability enabled by default); 3.4 govern the `sso:account:access` scope on customer managed applications (2026-06-19, grants all accounts and roles of the authenticated user, non-restrictable, management/delegated-admin only) with token-handling requirements; 4.3 customer managed KMS key (2025-09-17) with its requirements, the administrator/user lockout warning, and break-glass planning. Removed the CIS AWS Foundations Benchmark from this vendor's `hardening_docs` — v5.0.0 covers IAM users, root, and access keys, not IAM Identity Center. Tier 3/4 not surveyed this pass. | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with MFA, permission sets, and monitoring | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)

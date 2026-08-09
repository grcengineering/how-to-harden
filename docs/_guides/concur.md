---
layout: guide
title: "SAP Concur Hardening Guide"
vendor: "SAP"
slug: "concur"
tier: "2"
category: "HR/Finance"
description: "Travel and expense management platform hardening for SAP Concur including SAML SSO enforcement, sign-in settings, API and integration security, expense policies, and audit controls"
version: "0.2.0"
maturity: "draft"
last_updated: "2026-08-08"
---

## Overview

SAP Concur is a leading travel, expense, and invoice management platform serving **millions of users** worldwide. As a platform handling financial transactions and travel data, Concur security configurations directly impact expense integrity and compliance.

### Intended Audience
- Security engineers managing expense systems
- IT administrators configuring Concur
- Finance administrators managing travel and expense
- GRC professionals assessing financial platform security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers SAP Concur security including SAML SSO enforcement, sign-in settings (password policy, lockout, session, QR sign-in), user provisioning, API and integration security, expense policies, approval workflows, and audit controls.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Expense Policies](#3-expense-policies)
4. [Monitoring & Compliance](#4-monitoring--compliance)
5. [API & Integration Security](#5-api--integration-security)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

---

## 1. Authentication & SSO

### 1.1 Configure SAML Single Sign-On

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO to centralize authentication for Concur users, then set the **SSO Setting** to **SSO Required** so native Concur passwords are actually blocked — configuring SSO alone does not disable them.

#### Rationale
**Why This Matters:**
- Centralizes Concur authentication in your corporate IdP, enforcing MFA, conditional access, and consistent password policy on every login
- Native Concur passwords bypass IdP controls and are prime targets for credential stuffing and phishing campaigns that impersonate the expense portal
- Centralized SSO enables immediate deprovisioning when employees leave, eliminating orphaned accounts that retain access to financial data and reimbursement workflows
- Concur holds employee travel itineraries, corporate card data, and reimbursement banking details — a single compromised login can expose all of it

**Attack Prevented:** Credential theft, phishing, password reuse, orphaned-account access, SSO bypass via a surviving native password

> **The setting that decides whether SSO is a control or a convenience.** SAP Concur's **SSO Setting** has two values. Under **SSO Optional**, users can sign in *either* through SSO *or* with their existing Concur username and password — every native credential in the tenant stays live, including those held by travel management companies (TMCs), administrators, and web services users. Under **SSO Required**, those native sign-ins are blocked and SSO becomes the only path in. SAP recommends **SSO Optional** only *during* rollout, so users are not locked out mid-migration; leaving a tenant on Optional after cutover means every phished or stuffed legacy password still works. Sources: [SSO Setting: SSO Optional vs. SSO Required](https://help.sap.com/docs/SAP_CONCUR/36206b085b2f4919af6c9ac5a595eef9/7b5063d58270483d94080750c0e00649.html), [Manage Single Sign-On](https://help.sap.com/docs/SAP_CONCUR/8b1fb4bc53c843c080bcfc4b965366a1/c9450e3659b244ddbbccb4dbd772c056.html).

#### Prerequisites
- SAP Concur admin access
- SAP Cloud Identity Services or external IdP
- SAML 2.0 configuration details

#### ClickOps Implementation

**Step 1: Access SSO Configuration**
1. Navigate to: **Administration** → **Company** → **Authentication Admin**
2. Select **SSO** configuration

**Step 2: Configure Identity Provider**
1. Upload IdP metadata
2. Configure Entity ID
3. Configure SSO URL
4. Upload IdP certificate

**Step 3: Configure Attribute Mapping**
1. Map SAML attributes to Concur fields
2. Configure user identifier
3. Configure company assignment

**Step 4: Test Under SSO Optional, Then Set SSO Required**
1. With the **SSO Setting** on **SSO Optional**, test SSO authentication end to end and verify user provisioning and attribute mapping
2. Confirm every population that signs in — employees, approvers, administrators, TMC agents, and any web services users — can authenticate through the IdP
3. Change the **SSO Setting** to **SSO Required**. This is the step that blocks native Concur username/password sign-in; without it the tenant remains on Optional and every legacy password stays usable
4. Re-test after the change, including at least one account that previously used a native password, to confirm the native path is closed

**Time to Complete:** ~2 hours

#### Validation & Testing
- Attempt a native username/password sign-in with a known-good legacy credential; under **SSO Required** it must be rejected
- Confirm the **SSO Setting** value in **Authentication Admin** reads **SSO Required**, not **SSO Optional**
- Re-check the setting after any migration, tenant change, or support-assisted configuration change — a temporary return to Optional during troubleshooting must be reverted

---

### 1.2 Enforce Multi-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all Concur users — at the identity provider for SSO users, and via SAP Concur's own two-factor authentication for any account that can still sign in natively.

#### Rationale
**Why This Matters:**
- Adds a second authentication factor so a stolen or guessed password alone cannot grant access to expense and travel data
- Expense approvers can authorize payments and reimbursements — phishing-resistant MFA on these accounts blocks attackers who target approval authority
- IdP-enforced MFA only covers logins that actually traverse the IdP; under **SSO Optional** (see [1.1](#11-configure-saml-single-sign-on)) native sign-ins bypass it entirely, which is exactly the gap SAP Concur's native two-factor authentication closes
- Mobile app PIN/biometric and remote wipe protect cached expense data if a device is lost or stolen
- Concur is frequently impersonated in credential-phishing lures; MFA defeats the reused-credential step of those campaigns

**Attack Prevented:** Credential stuffing, phishing, account takeover, payment fraud via compromised approver, MFA bypass through a native sign-in path

> **Concur ships native two-factor authentication.** SAP Concur provides an administrator-enabled two-factor authentication feature: enrolled users register a TOTP authenticator by scanning a QR code or entering a manual key, and an administrator can reset a user's two-factor enrollment. Treat this as the required control for any account not covered by **SSO Required** — TMC agents, service and web services users, and break-glass administrators. Source: [Two Factor Authentication](https://help.sap.com/docs/SAP_CONCUR/4215d4303173498f9d3d0e5a46385976/1b8cf3f86caf101489c4fc8cefb38ee1.html).

#### ClickOps Implementation

**Step 1: Configure via IdP**
1. Enable MFA in identity provider
2. All SSO users subject to IdP MFA
3. Use phishing-resistant methods for approvers

**Step 2: Enable Concur Two-Factor Authentication for Non-SSO Accounts**
1. Enable two-factor authentication for the tenant in the Concur administration settings
2. Enrol every account that can sign in natively — administrators, TMC agents, service and web services users, and break-glass accounts
3. Have users register a TOTP authenticator by scanning the displayed QR code (or entering the manual key)
4. Document the administrator-initiated reset path so a lost authenticator is recovered through a controlled process rather than by disabling the control

**Step 3: Mobile Device Security**
1. Configure SAP Concur mobile app security
2. Require device PIN/biometric
3. Enable remote wipe capability

#### Validation & Testing
- Inventory accounts that are not covered by **SSO Required** and confirm each has two-factor enrollment
- Confirm a native sign-in prompts for the second factor
- Confirm two-factor resets are logged and follow an identity-verification procedure

---

### 1.3 Configure Session Security

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-12 |

#### Description
Configure the session timeout on the Sign-In Settings page so idle Concur sessions expire on a bounded schedule.

#### Rationale
**Why This Matters:**
- Idle session timeouts limit the window an attacker has to hijack an authenticated session on an unattended or shared device
- Finance and approver workstations often sit unlocked in shared offices — short timeouts reduce exposure of expense and banking data
- Bounded session lifetimes force periodic re-authentication, shrinking the value of stolen session tokens
- Concur sessions can submit and approve reimbursements, so an abandoned live session is a direct path to fraudulent payments

**Attack Prevented:** Session hijacking, unauthorized access via unattended sessions, session token replay

> **Correction — where this setting lives.** Session timeout is configured on the **Sign-In Settings** page under **Authentication Admin**, not under Company Admin. The same page carries the password policy and the failed-login lockout threshold covered in [1.4](#14-set-password-policy-and-lockout-threshold). Source: [Sign-In Settings](https://help.sap.com/docs/SAP_CONCUR/07b42204a5e542b7a72062c97801935c/1b879fc46caf10149df4a2f18534a0d6.html).

#### ClickOps Implementation

**Step 1: Configure Timeout**
1. Navigate to: **Administration** → **Company** → **Authentication Admin** → **Sign-In**
2. Open the **Sign-In Settings** page and configure the session timeout
3. Balance security with usability, and set the shortest interval your approver and finance populations can work with

#### Validation & Testing
- Leave an authenticated session idle past the configured interval and confirm re-authentication is required
- Confirm the value is reviewed alongside the password and lockout settings on the same page ([1.4](#14-set-password-policy-and-lockout-threshold))

---

### 1.4 Set Password Policy and Lockout Threshold

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.2, 6.2 |
| NIST 800-53 | IA-5, AC-7 |

#### Description
Set the password length and complexity requirements and the failed-login lockout threshold on the Sign-In Settings page, so any account that can still authenticate natively is governed by an explicit policy rather than the shipped defaults.

#### Rationale
**Why This Matters:**
- Under **SSO Optional**, or for accounts excluded from **SSO Required**, the Concur password policy is the only thing standing between a password-spray campaign and an account that can approve reimbursements
- The default minimum password length is the lowest value SAP Concur allows, so a tenant that has never touched this page is running at the floor of the permitted range
- A lockout threshold bounds how many guesses an attacker gets per account; the shipped default is more permissive than most password-spray detection thresholds assume
- Password policy, lockout, and session timeout all live on the same page — reviewing them together prevents the common gap where one is hardened and the others are left at default

**Attack Prevented:** Password spraying, brute-force credential guessing, weak-password account takeover, unbounded authentication attempts

> **Documented ranges and defaults.** SAP Concur's Sign-In Settings page documents a password minimum length of **8** characters, a maximum of **255**, and a **default of 8**; the failed-login lockout threshold accepts a minimum of **3** and a maximum of **20**, with a **default of 5**. Set both deliberately rather than accepting the defaults. Sources: [Sign-In Settings](https://help.sap.com/docs/SAP_CONCUR/07b42204a5e542b7a72062c97801935c/1b879fc46caf10149df4a2f18534a0d6.html), [Password and Lockout Settings](https://help.sap.com/docs/SAP_CONCUR/07b42204a5e542b7a72062c97801935c/1b888c256caf1014b135a21a2e0c8cca.html).

#### ClickOps Implementation

**Step 1: Open Sign-In Settings**
1. Navigate to: **Administration** → **Company** → **Authentication Admin** → **Sign-In**

**Step 2: Set the Password Policy**
1. Raise the minimum password length above the default of 8 to match your corporate standard
2. Configure the available complexity requirements
3. Record the chosen values in your baseline documentation so drift is detectable

**Step 3: Set the Lockout Threshold**
1. Set the failed-login lockout threshold within the documented range of 3–20, below the default of 5 only if your support process can absorb the lockout volume
2. Confirm the unlock path is a controlled, identity-verified procedure

#### Validation & Testing
- Attempt to set a password shorter than the configured minimum and confirm rejection
- Trigger the configured number of failed sign-ins against a test account and confirm lockout occurs at the expected count
- Re-verify all three Sign-In Settings values (password, lockout, session timeout) after any tenant migration

---

### 1.5 Decide On QR-Code Sign-In

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3 |
| NIST 800-53 | IA-2, AC-12 |

#### Description
Make an explicit accept-or-disable decision about SAP Concur's QR-code sign-in, which lets an authenticated web session mint a mobile session by scanning a code and is enabled by default.

#### Rationale
**Why This Matters:**
- QR-code sign-in converts an authenticated browser session into a new authenticated mobile session without a second credential presentation, so the security of the mobile session inherits whatever the web session's assurance was
- The feature is **on by default**, meaning tenants acquire the behaviour without an administrative decision — the risk is not that the feature is unsafe, it is that nobody chose it
- QR-code-driven session transfer is a known social-engineering pattern: a user persuaded to scan a code, or to display one, can hand an attacker a live session
- Organizations that enforce device-bound or conditional-access policies at the IdP should confirm those policies still apply to the session created through this path, or disable it

**Attack Prevented:** Session transfer to an attacker-controlled device, conditional-access bypass on the mobile session, QR-based social engineering

> **Live since 2026-07-30 and on by default.** SAP Concur's QR-code sign-in allows a signed-in web session to authenticate the mobile app by scanning a QR code. It is enabled by default and administrators opt out at **Administration** → **Company** → **Authentication Admin** → **Sign-In**. Source: [Sign In with QR Code](https://help.sap.com/docs/SAP_CONCUR/c5d6d15e7ecb4b4d8238b383d59ac2f4/af197062a5694e6b84a07eb27ef404e8.html).

#### ClickOps Implementation

**Step 1: Review the Current State**
1. Navigate to: **Administration** → **Company** → **Authentication Admin** → **Sign-In**
2. Locate the QR-code sign-in setting and record whether it is enabled

**Step 2: Decide and Document**
1. If your mobile access model depends on IdP conditional access or device compliance, verify those controls still gate the session created via QR sign-in
2. If they do not, or the verification is inconclusive, disable the setting
3. Record the decision and its rationale in your baseline so the default is not silently re-adopted

#### Validation & Testing
- Attempt a QR-code sign-in from an unmanaged device and confirm the outcome matches your intended policy
- Re-check the setting after tenant changes — a default-on feature reverts silently

---

### 1.6 Track Certificate and IdP Metadata Rotation

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.10 |
| NIST 800-53 | SC-12, SC-17 |

#### Description
Track SAP Concur's published certificate rotation schedule and your own SAML IdP metadata renewals so an expiring certificate does not break authentication or integrations.

#### Rationale
**Why This Matters:**
- SAP Concur rotates the TLS certificate for its `*.concursolutions.com` domain on a published schedule; the rotation is transparent to ordinary clients but breaks any integration that pins the certificate
- SAML federation depends on IdP signing certificates embedded in metadata that expires independently of the vendor's own certificates — SAP flags IdP metadata rotation as an ongoing operational task, not a one-time setup step
- An expired signing certificate fails authentication for the entire tenant at once, and the failure surfaces as a login outage rather than an obvious certificate error
- Knowing which of your integrations pin certificates is the difference between a scheduled non-event and an unplanned outage

**Attack Prevented:** Authentication outage from expired credentials, insecure workarounds adopted under outage pressure (pinning disabled, validation relaxed), stale trust material left in place

> **Current published rotation — verify before acting.** SAP Concur's certificate notice lists the `*.concursolutions.com` certificate as expiring **2026-09-18** with renewal scheduled for **2026-08-26**; only clients that pin the certificate need to take action. SAP separately flags SAMLv2 IdP metadata rotation as an **ongoing** task. These notices carry dates that have not always been updated in step with the schedule they describe, so treat the values as indicative and re-read the source page before planning a change window. Sources: [Certificate Renewal Notice](https://help.sap.com/docs/SAP_CONCUR/c5d6d15e7ecb4b4d8238b383d59ac2f4/cda53ba799934cee90b7f0aafc2963bb.html), [SAMLv2 IdP Metadata Rotation](https://help.sap.com/docs/SAP_CONCUR/c5d6d15e7ecb4b4d8238b383d59ac2f4/d29608bca5c04189b0887efe01621778.html).

#### ClickOps Implementation

**Step 1: Inventory Pinning Clients**
1. Identify every integration that connects to `*.concursolutions.com` and determine whether it pins the certificate or validates against the public trust store
2. Record the owners of any pinning client — they are the only parties who must act on a rotation

**Step 2: Track IdP Metadata Expiry**
1. Record the expiry date of your IdP's SAML signing certificate and the metadata refresh procedure
2. Set a renewal reminder well ahead of expiry, and verify the updated metadata is loaded in **Authentication Admin**

**Step 3: Subscribe to the Notice**
1. Add SAP Concur's certificate notice page to your change-monitoring list and re-read it before each planned rotation window

#### Validation & Testing
- After any rotation, confirm SSO sign-in and each pinning integration still succeed
- Confirm your IdP metadata in Concur matches the current metadata published by your IdP

---

## 2. Access Controls

### 2.1 Configure Role-Based Access Control

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Concur's role model.

#### Rationale
**Why This Matters:**
- Assigns only the permissions each user needs, so a compromised employee account cannot reach approver or administrator functions
- Separating Employee, Expense Approver, Invoice Approver, and Administrator roles enforces separation of duties across the expense lifecycle
- Least privilege contains the blast radius of any single account compromise, limiting access to financial data and payment workflows
- Over-broad roles let ordinary users alter policies or approve their own spend, undermining expense controls

**Attack Prevented:** Privilege escalation, lateral movement, insider abuse, expense fraud

#### ClickOps Implementation

**Step 1: Review Roles**
1. Navigate to: **Administration** → **Company** → **Company Admin**
2. Review roles:
   - Employee
   - Expense Approver
   - Invoice Approver
   - Administrator
3. Understand role capabilities

**Step 2: Assign Minimum Necessary Access**
1. Apply least-privilege principle
2. Separate employee and approver roles
3. Limit admin access

---

### 2.2 Limit Admin Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect administrator accounts.

#### Rationale
**Why This Matters:**
- Administrator accounts can change authentication settings, policies, and approval workflows — restricting their number shrinks the highest-value attack surface
- Requiring MFA and monitoring on admin accounts makes compromise harder and detectable
- Fewer admins means fewer credentials that, if stolen, could disable security controls or reroute reimbursements
- Unmonitored admin access enables silent tampering with expense policy and audit configuration

**Attack Prevented:** Admin account takeover, privilege abuse, security control tampering, undetected configuration changes

> **Use the SSO Manager role to decouple SSO administration.** SAP Concur provides an **SSO Manager** role that grants access to single sign-on configuration without conferring general Company Administrator rights. Assign it to the identity-provider operators who need to manage SSO, rather than granting them full Company Admin — it keeps the population that can change authentication settings separate from the population that can change expense configuration. Source: [SSO Manager Role](https://help.sap.com/docs/SAP_CONCUR/c5d6d15e7ecb4b4d8238b383d59ac2f4/4314e18350a34c3e92078458fb05deab.html).

#### ClickOps Implementation

**Step 1: Inventory Admin Users**
1. Review admin accounts
2. Document admin privileges
3. Identify unnecessary access

**Step 2: Apply Restrictions**
1. Limit admin to 2-3 users
2. Require MFA for admins
3. Monitor admin activity

**Step 3: Assign Purpose-Specific Roles**
1. Grant IdP operators the **SSO Manager** role instead of Company Administrator
2. Review who holds SSO Manager on the same cadence as the administrator review
3. Remove Company Administrator from anyone whose only requirement was SSO configuration

---

### 2.3 Configure Delegate Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Control delegate access for expense management.

#### Rationale
**Why This Matters:**
- Delegates act on another user's behalf, so uncontrolled delegate grants can quietly expand who can submit or approve expenses
- Limiting and approving delegate setup preserves accountability and separation of duties in the approval chain
- Auditing delegate actions ensures every expense action ties back to an authorized, identifiable person
- Unrestricted delegation lets a single account aggregate approval authority and obscure fraudulent activity

**Attack Prevented:** Authorization sprawl, separation-of-duties bypass, accountability evasion, delegated expense fraud

#### ClickOps Implementation

**Step 1: Configure Delegate Policies**
1. Define who can have delegates
2. Limit delegate permissions
3. Require approval for delegate setup

**Step 2: Monitor Delegate Usage**
1. Audit delegate actions
2. Review delegate assignments
3. Regular access reviews

---

### 2.4 Automate Provisioning and Deprovisioning

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.1, 5.3 |
| NIST 800-53 | AC-2, AC-2(4) |

#### Description
Provision and deprovision Concur users automatically from your authoritative identity source using SAP Cloud Identity Services Identity Provisioning, configured from Company Admin.

#### Rationale
**Why This Matters:**
- Manual user administration is where orphaned accounts come from: a departing employee removed from the IdP but not from Concur retains an account that can still submit or approve expenses if any native sign-in path survives
- Automated deprovisioning makes offboarding a single action in the authoritative source rather than a per-SaaS checklist item that gets skipped under load
- Provisioning from an authoritative source keeps role and manager attributes accurate, which is what the approval hierarchy in [3.2](#32-configure-approval-workflows) depends on to route expenses correctly
- Automated provisioning gives you a reviewable record of who was granted access and when, replacing ad-hoc account creation

**Attack Prevented:** Orphaned-account access after offboarding, stale entitlements, approval routing to departed staff, unaudited account creation

#### ClickOps Implementation

**Step 1: Configure Identity Provisioning**
1. Navigate to: **Administration** → **Company Admin** → **SAP Cloud Identity Services** → **Configure**
2. Connect Concur to SAP Cloud Identity Services Identity Provisioning with your authoritative identity source as the system of record ([SAP Cloud Identity Services configuration](https://help.sap.com/docs/SAP_CONCUR/c5d6d15e7ecb4b4d8238b383d59ac2f4/4db37bdc08374ea39e1781b1d2cebee1.html))

**Step 2: Map Attributes and Lifecycle Events**
1. Map the attributes the approval hierarchy relies on, including manager and cost-center data
2. Confirm the deprovisioning action on termination is a disable or delete, not a no-op

**Step 3: Reconcile**
1. Periodically compare the Concur user list against the authoritative source and investigate every account that exists only in Concur

#### Validation & Testing
- Terminate a test identity in the authoritative source and confirm the Concur account is disabled within the expected sync interval
- Confirm no active Concur account lacks a corresponding active identity in the source system

---

## 3. Expense Policies

### 3.1 Configure Expense Policy Rules

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-5 |

#### Description
Configure expense policies for compliance.

#### Rationale
**Why This Matters:**
- Encoded spending limits, receipt requirements, and per diem rates automatically flag out-of-policy spend before reimbursement
- Automated policy enforcement reduces reliance on manual review, catching violations that busy approvers might miss
- Consistent policy rules support audit readiness and regulatory compliance for travel and expense spend
- Without enforced policies, inflated, duplicate, or non-compliant expenses pass through undetected

**Attack Prevented:** Expense fraud, policy circumvention, inflated and duplicate claims, compliance gaps

#### ClickOps Implementation

**Step 1: Define Expense Types**
1. Configure expense categories
2. Set spending limits
3. Define receipt requirements

**Step 2: Configure Policy Rules**
1. Set per diem rates
2. Configure mileage rates
3. Define approval thresholds

**Step 3: Enable Policy Enforcement**
1. Configure policy violations
2. Set up notifications
3. Enable automated checks

---

### 3.2 Configure Approval Workflows

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-5 |

#### Description
Configure expense approval workflows.

#### Rationale
**Why This Matters:**
- Multi-level approval chains ensure no expense is reimbursed without independent review proportional to its amount
- Preventing submitters from approving their own expenses enforces separation of duties, a core anti-fraud control
- Escalation rules and approval limits route high-value spend to appropriate authority, preventing unauthorized large payments
- An audit trail of approvals creates accountability and supports investigation of suspicious reimbursements

**Attack Prevented:** Self-approval fraud, separation-of-duties bypass, unauthorized payments, collusion concealment

#### ClickOps Implementation

**Step 1: Configure Approval Chains**
1. Define approval hierarchy
2. Configure approval limits
3. Set escalation rules

**Step 2: Enforce Separation of Duties**
1. Submitters cannot approve own expenses
2. Configure multi-level approval
3. Enable audit trail

---

### 3.3 Configure Receipt Requirements

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Require receipts for expense documentation.

#### Rationale
**Why This Matters:**
- Mandatory receipts provide verifiable evidence that claimed expenses are real, deterring fabricated or inflated claims
- Receipt imaging and OCR validation catch mismatches between submitted amounts and supporting documentation
- Documented receipts create the audit trail needed for tax, regulatory, and internal compliance reviews
- Without receipt requirements, expenses can be claimed with no proof, enabling reimbursement fraud

**Attack Prevented:** Fabricated expense claims, inflated reimbursements, fraud through missing documentation, audit failures

#### ClickOps Implementation

**Step 1: Configure Receipt Policies**
1. Set receipt threshold
2. Define required receipt types
3. Configure itemization requirements

**Step 2: Enable Receipt Verification**
1. Enable receipt imaging
2. Configure OCR validation
3. Flag missing receipts

---

## 4. Monitoring & Compliance

### 4.1 Configure Audit Logging

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor audit logs.

#### Rationale
**Why This Matters:**
- Audit logs of submissions, approvals, policy violations, and admin changes provide the evidence needed to detect and investigate abuse
- Monitoring approval actions and admin changes surfaces unauthorized or anomalous behavior before it becomes systemic fraud
- Retained logs support forensic reconstruction after an incident and satisfy compliance evidence requirements
- Without auditing, fraudulent expenses and configuration tampering go unnoticed and unprovable

**Attack Prevented:** Undetected fraud, configuration tampering, repudiation, forensic and compliance gaps

#### ClickOps Implementation

**Step 1: Enable Auditing**
1. Configure audit trail
2. Set retention period
3. Enable monitoring

**Step 2: Monitor Events**
1. Expense submissions
2. Approval actions
3. Policy violations
4. Admin changes

---

### 4.2 Configure Expense Reports

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.11 |
| NIST 800-53 | AU-6 |

#### Description
Configure compliance reports.

#### Rationale
**Why This Matters:**
- Scheduled policy-violation and spend-analytics reports turn raw audit data into reviewable signals of misuse
- A regular review cadence (weekly, monthly, quarterly) ensures anomalies are caught promptly rather than discovered late
- Compliance reports give management and auditors evidence that expense controls are operating effectively
- Without reporting, policy violations and unusual spend patterns remain buried in logs and escape oversight

**Attack Prevented:** Undetected policy violations, slow fraud detection, oversight gaps, compliance reporting failures

#### ClickOps Implementation

**Step 1: Configure Reports**
1. Enable policy violation reports
2. Configure spend analytics
3. Set up audit reports

**Step 2: Schedule Reviews**
1. Weekly policy violation review
2. Monthly spend analysis
3. Quarterly audits

---

## 5. API & Integration Security

### 5.1 Govern API Credentials, Grants, and Token Lifetimes

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.2, 6.6 |
| NIST 800-53 | IA-5, AC-2 |

#### Description
Inventory every application registered against the SAP Concur API, record which OAuth 2.0 grant type each one uses, and manage credentials against the documented token lifetimes rather than assuming tokens are short-lived.

#### Rationale
**Why This Matters:**
- SAP Concur access tokens default to a **one hour** lifetime, but refresh tokens are valid for **six months** — the refresh token, not the access token, is the credential that matters, and a leaked one grants half a year of programmatic access to expense, travel, and reimbursement data ([Authentication: Getting Started](https://developer.concur.com/api-reference/authentication/getting-started.html))
- SAP Concur supports a **password grant** among its grant types; an application using it holds a user's actual credentials, which defeats SSO enforcement and MFA for that access path and cannot be revoked independently of the user's password
- Each registered application is issued a **geolocation-specific base URI** — calls must be directed to the application's own base URI, and an inventory that records it prevents integrations from being pointed at the wrong data region
- Without an application inventory, credential rotation is impossible to scope: you cannot rotate what you have not enumerated, and six-month refresh tokens make un-rotated credentials a long-lived exposure

**Attack Prevented:** Long-lived refresh-token abuse, SSO and MFA bypass through password-grant applications, unrevoked integration access after staff departure, misdirected API traffic

#### ClickOps Implementation

**Step 1: Inventory Registered Applications**
1. Enumerate every application registered against your SAP Concur tenant and record its owner, purpose, grant type, and geolocation base URI
2. Flag any application using the password grant for migration to a grant type that does not require holding user credentials

**Step 2: Manage Token Lifetimes**
1. Document that access tokens expire in one hour and refresh tokens in six months, and set a rotation cadence shorter than the refresh-token lifetime
2. Store refresh tokens in a secrets manager with access logging — treat them as the high-value credential they are
3. Revoke and reissue application credentials on owner departure, vendor change, or suspected exposure

**Step 3: Bind Applications to the Right Region**
1. Confirm each integration calls its application's assigned geolocation base URI

#### Validation & Testing
- Confirm every registered application appears in your credential inventory with a named owner and a documented rotation date
- Confirm no production integration uses the password grant
- Attempt an API call with a rotated-out credential and confirm rejection

---

### 5.2 Constrain API Scopes to the Minimum

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3, 6.8 |
| NIST 800-53 | AC-6, AC-6(1) |

#### Description
Request only the SAP Concur API scopes each application genuinely needs, using the documented `{resource}.{subresource}.{action}` scope model, and verify the effective access against the user context the application operates in.

#### Rationale
**Why This Matters:**
- SAP Concur scopes follow a `{resource}.{subresource}.{action}` structure, so read and write access to a given resource are separable — an integration that only reads expense reports should never hold a write scope
- SAP documents that **scopes apply to applications only**: a scope grants an application the ability to request an operation, it does not by itself confer data access, and the application's effective access **never exceeds the permissions of the user** whose context it operates in ([Scopes](https://developer.concur.com/api-reference/authentication/scopes.html))
- That interaction means scope minimization and user-permission minimization are both required — a tightly scoped application running under an over-privileged user still reaches too much data
- Over-scoped applications are the standard blast-radius multiplier in a SaaS compromise: the attacker inherits everything the integration was granted, not what it actually used

**Attack Prevented:** Over-scoped integration access, write access granted to read-only integrations, blast-radius expansion after application credential compromise, privilege inheritance from an over-privileged service user

#### ClickOps Implementation

**Step 1: Map Required Scopes**
1. For each application, list the API operations it actually performs and derive the minimum `{resource}.{subresource}.{action}` scopes from that list
2. Remove write actions from any application whose function is read-only

**Step 2: Constrain the User Context**
1. Identify the user whose context each application operates in and confirm that user's Concur permissions are themselves minimized — the application cannot exceed them, but it will inherit all of them
2. Prefer a purpose-built service user over a human administrator's account

**Step 3: Re-review on Change**
1. Re-derive required scopes whenever an integration's functionality changes, and remove scopes that are no longer used

#### Validation & Testing
- Compare each application's granted scopes against its documented operation list and remove any scope with no corresponding operation
- Attempt an operation outside the granted scope and confirm rejection
- Confirm the operating user's permissions are reviewed in the same access review as the application's scopes

---

## 6. Compliance Quick Reference

### SAP Concur Security Recommendations Baseline

SAP publishes an identified set of security recommendations for SAP Concur — each carrying a recommendation ID (for example, the `CON-AUT-0001` authentication series), a Priority, and a Secure Operations Map category — in **Protect Your SAP Concur Cloud**. Its recommendations include applying the principle of least privilege across roles and administrative access. Use these IDs as the vendor-side baseline reference alongside the framework mappings below: [Protect Your SAP Concur Cloud — Security Recommendations](https://help.sap.com/docs/SAP_CONCUR_SECURITY/b92b8c7fc75a4c8faf62a6584077b022/80a4fbd48e7d4337ad80171f0ca52cf9.html).

### SOC 2 Trust Services Criteria Mapping

| Control ID | Concur Control | Guide Section |
|-----------|----------------|---------------|
| CC6.1 | SSO/MFA | [1.1](#11-configure-saml-single-sign-on), [1.2](#12-enforce-multi-factor-authentication) |
| CC6.2 | User provisioning and deprovisioning | [2.4](#24-automate-provisioning-and-deprovisioning) |
| CC6.3 | RBAC and approval workflows | [2.1](#21-configure-role-based-access-control), [3.2](#32-configure-approval-workflows) |
| CC6.6 | API credential and scope governance | [5.1](#51-govern-api-credentials-grants-and-token-lifetimes), [5.2](#52-constrain-api-scopes-to-the-minimum) |
| CC7.2 | Audit logging | [4.1](#41-configure-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | Concur Control | Guide Section |
|---------|----------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | MFA | [1.2](#12-enforce-multi-factor-authentication) |
| IA-5 | Password policy and API credentials | [1.4](#14-set-password-policy-and-lockout-threshold), [5.1](#51-govern-api-credentials-grants-and-token-lifetimes) |
| AC-2 | Account provisioning and deprovisioning | [2.4](#24-automate-provisioning-and-deprovisioning) |
| AC-5 | Separation of duties | [3.2](#32-configure-approval-workflows) |
| AC-6 | RBAC | [2.1](#21-configure-role-based-access-control) |
| AC-6(1) | Least-privilege API scopes | [5.2](#52-constrain-api-scopes-to-the-minimum) |
| AC-7 | Failed-login lockout | [1.4](#14-set-password-policy-and-lockout-threshold) |
| AC-12 | Session termination | [1.3](#13-configure-session-security) |
| SC-12 | Certificate and key rotation | [1.6](#16-track-certificate-and-idp-metadata-rotation) |
| AU-2 | Audit logging | [4.1](#41-configure-audit-logging) |

---

## Appendix A: References

**Official SAP Concur Hardening and Administration Documentation:**
- [Protect Your SAP Concur Cloud — Security Recommendations](https://help.sap.com/docs/SAP_CONCUR_SECURITY/b92b8c7fc75a4c8faf62a6584077b022/80a4fbd48e7d4337ad80171f0ca52cf9.html) — SAP's identified security-recommendation baseline (recommendation IDs, Priority, Secure Operations Map)
- [SSO Setting: SSO Optional vs. SSO Required](https://help.sap.com/docs/SAP_CONCUR/36206b085b2f4919af6c9ac5a595eef9/7b5063d58270483d94080750c0e00649.html)
- [Manage Single Sign-On](https://help.sap.com/docs/SAP_CONCUR/8b1fb4bc53c843c080bcfc4b965366a1/c9450e3659b244ddbbccb4dbd772c056.html)
- [Two Factor Authentication](https://help.sap.com/docs/SAP_CONCUR/4215d4303173498f9d3d0e5a46385976/1b8cf3f86caf101489c4fc8cefb38ee1.html)
- [Sign-In Settings](https://help.sap.com/docs/SAP_CONCUR/07b42204a5e542b7a72062c97801935c/1b879fc46caf10149df4a2f18534a0d6.html)
- [Password and Lockout Settings](https://help.sap.com/docs/SAP_CONCUR/07b42204a5e542b7a72062c97801935c/1b888c256caf1014b135a21a2e0c8cca.html)
- [Sign In with QR Code](https://help.sap.com/docs/SAP_CONCUR/c5d6d15e7ecb4b4d8238b383d59ac2f4/af197062a5694e6b84a07eb27ef404e8.html)
- [SSO Manager Role](https://help.sap.com/docs/SAP_CONCUR/c5d6d15e7ecb4b4d8238b383d59ac2f4/4314e18350a34c3e92078458fb05deab.html)
- [SAP Cloud Identity Services Configuration](https://help.sap.com/docs/SAP_CONCUR/c5d6d15e7ecb4b4d8238b383d59ac2f4/4db37bdc08374ea39e1781b1d2cebee1.html)
- [Certificate Renewal Notice](https://help.sap.com/docs/SAP_CONCUR/c5d6d15e7ecb4b4d8238b383d59ac2f4/cda53ba799934cee90b7f0aafc2963bb.html)
- [SAMLv2 IdP Metadata Rotation](https://help.sap.com/docs/SAP_CONCUR/c5d6d15e7ecb4b4d8238b383d59ac2f4/d29608bca5c04189b0887efe01621778.html)
- [SAP Concur Help Portal (product index)](https://help.sap.com/docs/SAP_CONCUR)

**API Documentation:**
- [Authentication: Getting Started](https://developer.concur.com/api-reference/authentication/getting-started.html) — grant types, token lifetimes, geolocation base URIs
- [Scopes](https://developer.concur.com/api-reference/authentication/scopes.html) — scope model and the application-only scope semantics
- [SAP Concur Developer Center](https://developer.concur.com)
- [Concur API Reference](https://developer.concur.com/api-reference/)

**Compliance Frameworks:**
- SAP publishes SAP Concur's certification and audit posture (SOC 1, SOC 2 Type II, ISO 27001) through the SAP Trust Center. Those pages describe SAP's own attestations rather than administrator-configurable controls, so this guide does not cite them as hardening sources. Request the current reports and certificates from SAP directly and validate their scope and period against your own control requirements.
- For vendor-side hardening recommendations with stable identifiers, use **Protect Your SAP Concur Cloud** (linked above) rather than compliance-marketing pages.

**Unmapped Surface (flagged for a future pass):**
- SAP has introduced Joule AI agents that act inside SAP Concur (including Expense Report Validation, Booking, AI audit-rule creation, and AI Search). No Tier 1 administrator page documenting how to disable or scope these agents was located during this pass, so this guide states no control over them. Treat the agent surface as unmapped rather than absent, and re-check before assuming there is nothing to configure: [Joule for SAP Concur](https://help.sap.com/docs/SAP_CONCUR_SECURITY/e956b5b6a0d2423cac014094834b5b3c/88f6db5018df4437a411be9d1742fd46.html).

**Security Incidents:**
- **2020 — SAP cloud product security standards gap.** SAP disclosed that some cloud products, including SAP Concur, did not meet certain contractually agreed IT security standards. Approximately 40,000 customers were potentially impacted. No customer data was believed compromised, and remediation patches were applied in Q2 2020.
- No major public data breaches specific to SAP Concur have been identified. The platform is a common target for credential phishing impersonation campaigns.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass against help.sap.com and developer.concur.com. Corrected 1.1 to require setting the SSO Setting to **SSO Required** — the prior "enable for all users" step left tenants on SSO Optional, where every native password (TMCs, admins, web services users) stays live. Corrected 1.2: SAP Concur ships native admin-enabled two-factor authentication, so the IdP-only framing was wrong. Corrected 1.3: session timeout lives on the Sign-In Settings page under Authentication Admin, not Company Admin. Added 1.4 (password policy and lockout threshold, with documented ranges and defaults), 1.5 (QR-code sign-in, live 2026-07-30 and on by default), 1.6 (certificate and IdP metadata rotation), 2.4 (provisioning/deprovisioning via SAP Cloud Identity Services), and a new Section 5 (API & Integration Security: credential/grant/token governance and scope minimization) — compliance moved to Section 6. Added the SSO Manager role to 2.2. Mapped SAP's identified security-recommendations baseline and corrected its title to "Protect Your SAP Concur Cloud". Purged SAP Trust Center and concur.com marketing links from Appendix A. Flagged the Joule agent surface inside SAP Concur as unmapped — no Tier 1 admin disable/scope page located this pass. Tier 2 bodies (CIS, DISA STIG, CISA SCuBA) confirmed to publish no SAP Concur baseline; Tier 3/4 research not surveyed this pass. | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, RBAC, and expense policies | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)

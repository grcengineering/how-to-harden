---
layout: guide
title: "Vanta Hardening Guide"
vendor: "Vanta"
slug: "vanta"
tier: "2"
category: "Security"
description: "Compliance automation platform hardening for Vanta including access controls, integration security, and continuous monitoring"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---

## Overview

Vanta is a leading AI-powered compliance and trust management platform automating **up to 90% of compliance work** for SOC 2, HIPAA, ISO 27001, PCI DSS, and GDPR certifications. As a centralized compliance management system, Vanta contains sensitive evidence, control data, and organizational security configurations that require proper protection.

### Intended Audience
- Security engineers managing compliance programs
- GRC professionals configuring Vanta
- IT administrators integrating systems
- Compliance managers overseeing audit readiness

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Vanta platform security including access controls, integration security, continuous monitoring configuration, and vendor risk management.

---

## Table of Contents

1. [Access & Authentication](#1-access--authentication)
2. [Integration Security](#2-integration-security)
3. [Continuous Monitoring](#3-continuous-monitoring)
4. [Vendor Risk Management](#4-vendor-risk-management)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

---

## 1. Access & Authentication

### 1.1 Configure SSO Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO to centralize authentication and enforce organizational security policies.

#### Rationale
**Why This Matters:**
- Centralizes Vanta authentication in your corporate IdP, applying conditional access, session policies, and centralized logging to every login
- Local password logins bypass IdP controls and are prime targets for credential stuffing and phishing
- SSO enables instant deprovisioning — disabling a departed employee's IdP account immediately revokes their Vanta access
- Vanta holds compliance evidence, control mappings, and security configuration that a single compromised login could expose or alter

**Attack Prevented:** Credential theft, phishing, password reuse, orphaned-account access

> **SSO here is not enforceable on its own — magic-link login is on by default.** Vanta's magic link (an emailed sign-in link) authenticates users without passing through your identity provider, so every conditional-access, session, and MFA policy configured below is bypassable until it is turned off. Disabling it requires a connected SSO method first, which is why it is a separate follow-on control — see [1.5](#15-disable-magic-link-login). — [Disabling the magic link](https://help.vanta.com/en/articles/11345383-disabling-the-magic-link)

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Settings** → **Login and security**
2. Configure the SAML SSO connection for your identity provider

**Step 2: Configure SAML**
1. Select identity provider
2. Configure SAML settings:
   - IdP SSO URL
   - Certificate
   - Entity ID
3. Download Vanta SP metadata

**Step 3: Configure IdP**
1. Create SAML application in your IdP
2. Configure attribute mappings
3. Assign users/groups

**Step 4: Enforce SSO**
1. Test authentication
2. Enable SSO enforcement
3. Configure backup admin access

**Time to Complete:** ~1 hour

---

### 1.2 Enforce Multi-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require MFA for all users accessing Vanta.

#### Rationale
**Why This Matters:**
- Vanta contains sensitive compliance data — audit evidence, control mappings, and integration credentials
- MFA prevents unauthorized access from credential theft, phishing, and password reuse
- Enforcing MFA at the identity provider covers every Vanta login path your IdP actually sees, and is what Vanta's own implementation guidance recommends alongside disabling magic links
- Required for compliance with most frameworks

**Attack Prevented:** Credential stuffing, phishing-driven account takeover, password reuse, single-factor session hijacking

#### ClickOps Implementation

**Step 1: Configure MFA Requirement**
1. Navigate to: **Settings** → **Login and security**
2. Review the authentication methods enabled for the workspace
3. Enforce MFA through your SSO/IdP (recommended — see [1.1](#11-configure-sso-authentication)) and disable magic-link login (see [1.5](#15-disable-magic-link-login))

**Step 2: Verify Enrollment**
1. Check user MFA enrollment status
2. Follow up with non-compliant users
3. Set enrollment deadline

---

### 1.3 Implement Role-Based Access Control

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Assign Vanta's built-in and scoped roles to implement least privilege across the workspace.

#### Rationale
**Why This Matters:**
- Default broad access lets any team member view or modify compliance evidence, control statuses, and integration settings beyond their role
- Least-privilege roles ensure auditors receive read-only views while only GRC staff can change control mappings
- Limiting Admin to a small group shrinks the blast radius if any single account is compromised
- Over-privileged accounts make both insider mistakes and account takeover far more damaging to audit integrity

**Attack Prevented:** Privilege escalation, insider data tampering, unauthorized evidence modification

#### ClickOps Implementation

**Step 1: Review Roles**
1. Navigate to: **Settings** → **Access** → **Roles**
2. Review the built-in roles Vanta actually ships:
   - **Admin:** full access, including user and security settings
   - **View-only Admin:** administrative visibility without change rights
   - **Editor:** can modify compliance content but not workspace administration
   - **Collaborator:** limited contribution access
   - **Employee:** the default role automatically assigned to every person Vanta discovers
3. Note the scoped roles available for narrower grants: **Access Admin**, **Audit Limited Editor**, **Privacy Manager**, **Trust Admin**, and **Trust Collaborator** (see the table in [1.4](#14-restrict-administrative-privileges))

**Step 2: Assign Appropriate Roles**
1. Limit Admin to essential personnel (2-3)
2. Use Editor for the GRC team that maintains controls and evidence
3. Use View-only Admin or a scoped role such as Audit Limited Editor for auditors rather than a full Admin grant
4. Leave everyone else on the default Employee role — it is assigned automatically and grants no administrative capability

**Step 3: Regular Access Review**
1. Quarterly review of access at **Settings** → **Access** → **User permissions**
2. Remove inactive users
3. Document access decisions

---

### 1.4 Restrict Administrative Privileges

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Follow Essential Eight recommendations for admin privilege restriction.

#### Rationale
**Why This Matters:**
- Admin accounts can alter security configuration, control scoping, and integration credentials — the highest-value target in the platform
- Minimizing the number of admins and validating each one's business need reduces the standing privilege attackers seek
- Requiring MFA and hardware keys for admins and logging every admin action raises the cost of account takeover and preserves forensic evidence
- Separating admin accounts from daily-use accounts prevents routine phishing or malware from immediately yielding admin control

**Attack Prevented:** Admin account takeover, privilege abuse, lateral movement, unlogged configuration tampering

#### ClickOps Implementation

**Step 1: Audit Admin Access**
1. Navigate to: **Settings** → **Access** → **User permissions**
2. Identify every user holding **Admin**, then validate business need
3. Reduce to minimum necessary, downgrading to the narrowest role that still does the job

**Step 2: Choose the Narrowest Role That Works**

| Role | Type | Grant it to |
|------|------|-------------|
| Admin | Built-in | The 2-3 people who must change workspace, user, and security settings |
| View-only Admin | Built-in | Leadership and reviewers who need administrative visibility but no change rights |
| Editor | Built-in | GRC staff maintaining controls, policies, and evidence |
| Collaborator | Built-in | Contributors who supply evidence for a narrow slice of the program |
| Employee | Built-in (default) | Everyone else — assigned automatically, no administrative capability |
| Access Admin | Scoped | Staff who run access reviews without needing full Admin |
| Audit Limited Editor | Scoped | External auditors and assessors working an active audit |
| Privacy Manager | Scoped | Privacy program owners handling data-protection workflows |
| Trust Admin | Scoped | Owners of the Trust Center's configuration and published documents |
| Trust Collaborator | Scoped | Staff who contribute Trust Center content without controlling access to it |

**Step 3: Enhanced Admin Security**
1. Require MFA at every login (see [1.2](#12-enforce-multi-factor-authentication))
2. Consider hardware keys for admins
3. Include privileged Vanta access in your recurring access reviews — Vanta's own implementation guidance calls this out explicitly

**Step 4: Implement Separation**
1. Separate admin from daily accounts
2. Use dedicated admin sessions
3. Review admin activity in the Event Log regularly (see [3.5](#35-review-the-vanta-event-log))

---

### 1.5 Disable Magic-Link Login

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 6.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Turn off Vanta's magic-link sign-in so that every interactive login is forced through the identity provider configured in [1.1](#11-configure-sso-authentication).

#### Rationale
**Why This Matters:**
- Magic-link login is enabled by default and authenticates a user from possession of an email message alone, with no IdP involvement
- While it is on, SSO enforcement is advisory rather than actual — conditional access, device checks, session lifetime, and IdP MFA are all skippable
- An attacker with access to a mailbox (or to a forwarding rule, or a compromised mail client) can sign into the compliance platform without ever touching your IdP
- Vanta's own secure implementation guidance pairs "enforce SSO and MFA" with "disable Magic Links" — the two are one control in practice

**Attack Prevented:** SSO bypass, mailbox-compromise account takeover, MFA and conditional-access evasion, unlogged IdP-independent sign-in

#### Prerequisites
- An SSO method must already be connected — Vanta will not let you disable the magic link before one exists
- Confirm your break-glass plan first: the admin performing the change is automatically added to the exemption list, and at least one exempt user should remain so the workspace stays reachable if the IdP fails

#### ClickOps Implementation

**Step 1: Confirm SSO Is Connected**
1. Navigate to: **Settings** → **Login and security**
2. Verify the SAML SSO connection from [1.1](#11-configure-sso-authentication) is present and working

**Step 2: Disable the Magic Link**
1. In **Settings** → **Login and security**, disable the magic-link login option
2. Note that the admin making this change is added to the exemption list automatically

**Step 3: Curate the Exemption List**
1. Keep at least one exempt break-glass account so an IdP outage cannot lock the organization out
2. Remove every other exemption, and document who remains and why
3. Re-review the exemption list on the same cadence as your admin access review

#### Validation & Testing
1. From a browser with no active session, request a login for a non-exempt user and confirm no magic link is issued
2. Confirm the same user can still authenticate through the IdP
3. Confirm the break-glass account still works as expected

> **Partner and auditor access is unaffected.** External auditor and partner access does not run through this setting and cannot be added to the exemption list — do not plan around exempting an auditor here. — [Disabling the magic link](https://help.vanta.com/en/articles/11345383-disabling-the-magic-link)

---

### 1.6 Configure Idle Session Timeout

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.3 |
| NIST 800-53 | AC-11, AC-12 |

#### Description
Set an idle session timeout so unattended Vanta sessions are terminated rather than left authenticated indefinitely.

#### Rationale
**Why This Matters:**
- A Vanta session left open on an unlocked or shared workstation is a fully authenticated path into compliance evidence, control configuration, and integration settings
- Idle timeout bounds how long a stolen or abandoned session remains usable, which matters most for the small set of Admin accounts that can change security settings
- Session lifetime is one of the few login-security parameters Vanta exposes directly rather than delegating to the IdP, so it applies even to access paths your IdP does not see
- Shorter timeouts for administrator populations are a standard expectation in SOC 2 and ISO 27001 access-control testing

**Attack Prevented:** Session hijacking, unattended-workstation access, shared-device session reuse, prolonged post-compromise session validity

#### ClickOps Implementation

**Step 1: Open Security Settings**
1. Navigate to: **Settings** → **Login and Security**
2. Select the **Security** tab

**Step 2: Set the Timeout**
1. Choose a value from the **Idle Session Timeout** dropdown
2. Pick the shortest interval your administrators can work with, and document the choice as a deliberate decision
3. Apply the same reasoning you use for other privileged consoles rather than accepting whatever is preselected

#### Validation & Testing
1. Sign in, leave the session idle past the configured interval, and confirm re-authentication is required
2. Re-check the setting after any workspace migration or major Vanta release

---

### 1.7 Govern Vanta AI Features

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3, 15.1 |
| NIST 800-53 | AC-6, SA-9 |

#### Description
Make an explicit, documented decision about whether Vanta AI is enabled, since enabling it allows third-party services to process your tenant's data.

#### Rationale
**Why This Matters:**
- Enabling Vanta AI permits third-party services to process data held in your Vanta workspace — which for a compliance platform means policies, evidence, control narratives, and findings
- The setting is controlled by admins and editors on behalf of every user in the workspace, so an individual user cannot opt themselves out of a decision made once at the top
- Disabling it stops that third-party processing immediately, making this a reversible control worth exercising deliberately rather than by default
- Where Workspaces are enabled the setting is per-workspace, so a single organization-wide assumption about AI processing can be wrong for a subsidiary or regulated business unit

**Attack Prevented:** Unreviewed third-party data processing, inadvertent disclosure of compliance evidence to external services, subprocessor-scope drift, per-workspace policy inconsistency

#### ClickOps Implementation

**Step 1: Review the Current State**
1. Click the **gear** icon
2. Open the **AI** tab and record whether Vanta AI is currently enabled

**Step 2: Decide and Apply**
1. Decide based on your data-processing agreements, customer commitments, and regulatory scope
2. Enable or disable accordingly, and record the decision and its owner
3. If Workspaces are enabled, repeat the review for **every** workspace — the setting does not inherit

**Step 3: Keep It Under Review**
1. Re-confirm the setting whenever your subprocessor list, DPA, or regulatory scope changes
2. Include it in the vendor review you run for Vanta itself (see [4.1](#41-configure-vendor-security-reviews))

#### Validation & Testing
1. Re-open the **AI** tab and confirm the recorded state matches the documented decision
2. For multi-workspace organizations, confirm each workspace individually rather than sampling one

---

## 2. Integration Security

### 2.1 Configure Integrations with Least Privilege

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-6 |

#### Description
Connect integrations with minimum required permissions.

#### Rationale
**Why This Matters:**
- Vanta connects to 300+ systems, so the platform's aggregate integration scope is broader than any single application it monitors
- Each integration accesses sensitive data, and an over-scoped connection turns a Vanta compromise into a compromise of the connected system
- Excessive permissions increase risk exposure and are rarely revisited once an integration is working
- Vanta's own implementation guidance adds two operational rules that belong in this control: generate and use API keys only from company-managed devices on trusted networks, and reconnect failed integrations promptly — a disconnected integration is a monitoring blind spot, not a neutral state

**Attack Prevented:** Over-scoped integration abuse, lateral movement into connected systems, API key theft from unmanaged devices, silent monitoring gaps from unreconnected integrations

#### ClickOps Implementation

**Step 1: Review Integration Requirements**
1. Navigate to: **Integrations**
2. Before connecting, review required permissions
3. Document permission requirements

**Step 2: Connect with Minimum Access**
1. Grant only required permissions
2. Use read-only access when possible
3. Create dedicated service accounts

**Step 3: Regular Integration Audit**
1. Review connected integrations quarterly
2. Remove unused integrations
3. Verify permissions remain appropriate

---

### 2.2 Secure Cloud Infrastructure Integrations

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-6 |

#### Description
Securely configure AWS, Azure, and GCP integrations.

#### Rationale
**Why This Matters:**
- Cloud integrations grant Vanta visibility into your AWS, Azure, and GCP accounts, so an over-scoped or root-credential connection becomes a path into your entire cloud estate
- Dedicated IAM roles with cross-account external IDs prevent confused-deputy attacks and avoid sharing long-lived root keys
- Read-only, minimally scoped permissions ensure a compromise of the integration cannot modify or delete cloud resources
- Managed identities and workload identity federation eliminate static secrets that could be exfiltrated and reused elsewhere

**Attack Prevented:** Cloud account compromise, confused-deputy attacks, credential exfiltration, infrastructure privilege escalation

#### ClickOps Implementation

**Step 1: AWS Integration**
1. Create dedicated IAM role
2. Use Vanta's recommended policy
3. Enable cross-account access with external ID
4. Avoid using root credentials

**Step 2: Azure Integration**
1. Create dedicated app registration
2. Grant minimum required permissions
3. Use managed identities where possible

**Step 3: GCP Integration**
1. Create service account
2. Grant minimum required roles
3. Use workload identity federation

---

### 2.3 Secure Identity Provider Integration

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3 |
| NIST 800-53 | IA-2 |

#### Description
Configure identity provider integration for compliance monitoring.

#### Rationale
**Why This Matters:**
- The IdP integration reads sensitive directory data — user accounts, MFA status, and group memberships — so it must be granted read-only, least-privilege access
- Monitoring MFA enrollment and offboarding through the IdP closes compliance gaps where departed users retain access
- An over-permissioned IdP connection could allow modification of the identity data that underpins every access decision
- Continuous provisioning and offboarding alerts catch orphaned accounts before they become an attacker's entry point

**Attack Prevented:** Orphaned-account access, directory data tampering, MFA-gap exploitation, offboarding failures

#### ClickOps Implementation

**Step 1: Connect IdP**
1. Navigate to: **Integrations** → **Identity Providers**
2. Connect Okta, Microsoft Entra, Google Workspace
3. Grant read access for user data

**Step 2: Enable Compliance Monitoring**
1. Configure MFA status monitoring
2. Enable user provisioning alerts
3. Monitor offboarding compliance

---

## 3. Continuous Monitoring

### 3.1 Configure Automated Tests

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CA-7 |

#### Description
Configure Vanta's 1,200+ automated tests for continuous compliance visibility.

#### Rationale
**Why This Matters:**
- Automated tests run continuously, so drift is caught between audits rather than discovered during one
- Identifies compliance drift close to real time, while the misconfiguration that caused it is still cheap to fix
- Reduces manual evidence collection, which lowers the chance of stale or fabricated evidence entering the audit record
- Custom-role scoping matters here: Vanta's implementation guidance recommends least-privilege custom roles specifically for who may modify risks, vulnerabilities, and tests, because whoever can edit a test can silently redefine what "passing" means

**Attack Prevented:** Undetected security drift, silent control failure, evidence tampering through test redefinition, stale audit evidence

#### ClickOps Implementation

**Step 1: Enable Automated Tests**
1. Navigate to: **Controls**
2. Connect required integrations
3. Enable automated tests per control

**Step 2: Configure Custom Controls**
1. Use out-of-the-box controls where applicable
2. Create custom controls for unique requirements
3. Map custom controls to automated tests

**Step 3: Configure Thresholds**
1. Set passing thresholds
2. Configure tolerance levels
3. Define exception criteria

---

### 3.2 Configure Alerts and Notifications

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.11 |
| NIST 800-53 | SI-4 |

#### Description
Configure continuous monitoring alerts for compliance issues.

#### Rationale
**Why This Matters:**
- Without timely alerts, failing controls, integration disconnections, and evidence gaps can persist undetected until an audit or incident
- Routing alerts to Slack, Teams, and email ensures the right owners see compliance drift while it is still cheap to fix
- Escalation timeframes and secondary recipients prevent a single missed notification from leaving a control silently broken
- Fast notification of integration disconnections catches monitoring blind spots that would otherwise hide real security regressions

**Attack Prevented:** Undetected compliance drift, monitoring blind spots, silent control failure, delayed incident response

#### ClickOps Implementation

**Step 1: Configure Alert Channels**
1. Navigate to: **Settings** → **Notifications**
2. Configure Slack/Teams integration
3. Set up email notifications

**Step 2: Configure Alert Rules**
1. Enable alerts for:
   - Failing controls
   - Integration disconnections
   - Evidence gaps
   - Policy acknowledgment due
2. Set priority levels

**Step 3: Configure Escalation**
1. Set escalation timeframes
2. Configure secondary recipients
3. Define critical alert handling

---

### 3.3 Monitor Security Dashboard

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CA-7 |

#### Description
Use security insights dashboard for threat visibility.

#### Rationale
**Why This Matters:**
- The dashboard aggregates compliance posture and security insights into a single view, making emerging risks visible before they escalate
- Integrating CloudWatch and similar event sources surfaces threats that originate in connected infrastructure rather than in Vanta itself
- Tracking remediation through assigned owners and resolution times prevents identified issues from stalling unaddressed
- Regular review establishes a baseline so anomalous drops in security posture are noticed quickly

**Attack Prevented:** Unnoticed posture degradation, delayed threat detection, stalled remediation

#### ClickOps Implementation

**Step 1: Review Dashboard**
1. Navigate to: **Dashboard**
2. Monitor compliance posture
3. Review security insights

**Step 2: Integrate with CloudWatch (AWS)**
1. Configure AWS CloudWatch integration
2. Enable security event monitoring
3. Set up threat alerts

**Step 3: Track Remediation**
1. Use remediation workflows
2. Assign issue owners
3. Track resolution times

---

### 3.4 Configure Remediation Workflows

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CA-5 |

#### Description
Configure automated remediation workflows for fast resolution.

#### Rationale
**Why This Matters:**
- Detected control failures are only valuable if they get fixed; automated workflows assign owners and due dates so issues do not languish
- Integrating with Jira or Linear ties remediation into existing engineering processes, improving completion rates and accountability
- Escalations on overdue items ensure a single unresponsive owner cannot leave a security gap open indefinitely
- Documented resolution status produces the audit trail needed to prove timely corrective action to assessors

**Attack Prevented:** Persistent unremediated findings, prolonged exposure windows, accountability gaps

#### ClickOps Implementation

**Step 1: Configure Workflows**
1. Navigate to: **Settings** → **Workflows**
2. Configure remediation assignments
3. Set due dates and escalations

**Step 2: Enable Ticket Integration**
1. Integrate with Jira/Linear
2. Configure automatic ticket creation
3. Track resolution status

---

### 3.5 Review the Vanta Event Log

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2, 8.11 |
| NIST 800-53 | AU-2, AU-6, AU-11 |

#### Description
Use Vanta's Event Log as the audit trail for changes made inside the platform, and build a review cadence around it since there is no documented streaming export.

#### Rationale
**Why This Matters:**
- The Event Log is the record of who changed what inside Vanta — people, policies, vulnerabilities, integrations, tests, documents, and logins — and without reviewing it, evidence and control tampering leaves no examined trace
- Login events recorded here are the detection surface for the account-takeover scenarios that [1.1](#11-configure-sso-authentication), [1.2](#12-enforce-multi-factor-authentication), and [1.5](#15-disable-magic-link-login) are designed to prevent
- Integration and test events reveal when monitoring coverage was reduced, which is the quiet precursor to a control silently failing
- Retention is at least one year, which is long enough to support an audit period but short enough that an unreviewed log eventually ages out of usefulness

**Attack Prevented:** Undetected evidence tampering, unnoticed privilege changes, silent integration removal, unreviewed anomalous logins

#### Prerequisites
- Admin visibility — the Event Log is available to administrators

#### ClickOps Implementation

**Step 1: Open the Event Log**
1. Click the **user** icon
2. Select **Event log**

**Step 2: Scope Your Review**
1. Filter to the event categories that matter for your review: **People**, **Policies**, **Vulnerabilities**, **Integrations**, **Tests**, **Documents**, and **Login**
2. Prioritize Login, People, and Integrations events — role grants, new admins, and removed integrations are the highest-signal changes
3. Record what was reviewed and by whom, so the review itself is auditable

**Step 3: Plan Around the Retention and Coverage Limits**
1. Events are retained for at least one year — align your review cadence and any evidence exports to that window
2. The log is not retroactive before **2022-10-28**; do not expect coverage of earlier activity
3. Vanta does not document a SIEM export or event-streaming capability for the Event Log, so treat this as a console-reviewed control rather than something your SIEM will correlate automatically — plan the manual review rather than assuming coverage

#### Validation & Testing
1. Make a benign change (for example, a role assignment in a test account) and confirm it appears in the Event Log with the expected actor
2. Confirm your documented review cadence has produced dated evidence for the current audit period

---

## 4. Vendor Risk Management

### 4.1 Configure Vendor Security Reviews

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 15.1 |
| NIST 800-53 | SA-9 |

#### Description
Use Vanta's vendor risk management for third-party security assessment.

#### Rationale
**Why This Matters:**
- Third-party vendors often hold or process your data, so an unassessed vendor extends your attack surface beyond your own controls
- Structured questionnaires and risk tiering ensure high-risk vendors receive proportionate scrutiny before and during engagement
- Continuous monitoring of vendor posture catches compliance changes — like a lapsed SOC 2 or breach disclosure — that signal new risk
- Documented vendor reviews satisfy the supply-chain requirements in SOC 2, ISO 27001, and similar frameworks

**Attack Prevented:** Supply-chain compromise, unvetted third-party data exposure, vendor risk blind spots

#### ClickOps Implementation

**Step 1: Enable VRM**
1. Navigate to: **Vendor Risk**
2. Configure vendor categories
3. Set risk assessment criteria

**Step 2: Configure Security Questionnaires**
1. Use automated questionnaire distribution
2. Configure response tracking
3. Set review deadlines

**Step 3: Monitor Vendor Compliance**
1. Track vendor security posture
2. Monitor for compliance changes
3. Configure vendor alerts

---

### 4.2 Manage Trust Center

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 15.2 |
| NIST 800-53 | SA-9 |

#### Description
Configure Trust Center for secure compliance documentation sharing.

#### Rationale
**Why This Matters:**
- The Trust Center publishes compliance documentation externally, so misconfigured access could leak sensitive reports such as SOC 2 audits or pen-test results
- Separating public from private documents and gating sensitive files behind access controls prevents oversharing with unvetted parties
- An NDA workflow with digital signatures ensures confidential evidence is released only to parties who have accepted legal obligations
- Tracking document access creates an audit trail of who viewed sensitive compliance materials

**Attack Prevented:** Sensitive document leakage, unauthorized evidence disclosure, oversharing of audit reports

#### ClickOps Implementation

**Step 1: Configure Trust Center**
1. Navigate to: **Trust Center**
2. Configure public/private documents
3. Set access controls

**Step 2: Configure NDA Workflow**
1. Enable NDA requirement for sensitive docs
2. Configure digital signature
3. Track document access

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Vanta Control | Guide Section |
|-----------|---------------|---------------|
| CC6.1 | SSO/MFA | [1.1](#11-configure-sso-authentication) |
| CC6.2 | RBAC | [1.3](#13-implement-role-based-access-control) |
| CC6.6 | Integration security | [2.1](#21-configure-integrations-with-least-privilege) |
| CC7.2 | Continuous monitoring | [3.1](#31-configure-automated-tests) |
| CC9.2 | Vendor risk | [4.1](#41-configure-vendor-security-reviews) |

### NIST 800-53 Rev 5 Mapping

| Control | Vanta Control | Guide Section |
|---------|---------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-sso-authentication) |
| IA-2(1) | MFA | [1.2](#12-enforce-multi-factor-authentication) |
| AC-6 | Least privilege | [1.3](#13-implement-role-based-access-control) |
| CA-7 | Continuous monitoring | [3.1](#31-configure-automated-tests) |
| SA-9 | Vendor management | [4.1](#41-configure-vendor-security-reviews) |

---

## Appendix A: References

**Official Vanta Documentation:**
- [Using Vanta: Secure Implementation Guidelines](https://help.vanta.com/en/articles/12069112-using-vanta-secure-implementation-guidelines) — Vanta's own hardening guidance for customer workspaces
- [Managing user roles](https://help.vanta.com/en/articles/11345385-managing-user-roles)
- [Disabling the magic link](https://help.vanta.com/en/articles/11345383-disabling-the-magic-link)
- [Configure idle session timeout](https://help.vanta.com/en/articles/11345384-configure-idle-session-timeout)
- [Event log](https://help.vanta.com/en/articles/11345419-event-log)
- [Enabling or disabling Vanta AI](https://help.vanta.com/en/articles/11345365-enabling-or-disabling-vanta-ai)
- [Vanta Help Center](https://help.vanta.com)
- [Product updates](https://help.vanta.com/en/articles/11345422-product-updates) — the changelog surface to watch for currency
- [Vanta API Reference](https://developer.vanta.com/reference/overview)
- [Security Compliance Guide](https://www.vanta.com/collection/grc/security-compliance)
- [Automated Compliance](https://www.vanta.com/products/automated-compliance)
- [Security Resources](https://www.vanta.com/all-categories/security)
- [Vanta Control Set (GitHub)](https://github.com/VantaInc/vanta-control-set)

**API Documentation:**
- [REST API Reference](https://developer.vanta.com/reference/overview)

**Compliance Frameworks:**
- Vanta automates compliance for 35+ frameworks including SOC 2, ISO 27001, HIPAA, PCI DSS, and GDPR. Vanta itself maintains SOC 2 Type II compliance for its own platform.

**Security Incidents:**
- **May 2025 -- Cross-Customer Data Exposure:** A code update removed a safety filter that separates customer data, causing a subset of data from fewer than 20% of third-party integrations to be exposed to other Vanta customers. Fewer than 4% of customers (out of 10,000+) were affected. No API keys, credentials, or external intrusion were involved. The issue was identified May 26 and remediated by June 4, 2025.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass against Vanta's Tier 1 help center. Corrected the role model in 1.3 to Vanta's actual built-in roles (Admin, View-only Admin, Editor, Collaborator, Employee) plus the scoped roles, and added a role-selection table to 1.4; corrected stale console paths in 1.1/1.2/1.3 (**Settings → Login and security** for authentication, **Settings → Access** for roles); added a changed-default callout to 1.1 covering magic-link login. New controls: 1.5 disable magic-link login, 1.6 idle session timeout, 1.7 govern Vanta AI, 3.5 review the Event Log. Added **Attack Prevented** to 1.2, 2.1, and 3.1, and folded Vanta's "Secure Implementation Guidelines" into the 1.4/2.1/3.1 rationales. Appendix A: removed the vanta.com/security marketing redirect, fixed the API reference URL, and added the product-updates currency surface. Tier 3/4 research out of scope for this pass. | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with access controls, monitoring, and VRM | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)

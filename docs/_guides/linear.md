---
layout: guide
title: "Linear Hardening Guide"
vendor: "Linear"
slug: "linear"
tier: "3"
category: "DevOps"
description: "Issue tracking platform hardening for Linear including SAML SSO, workspace access, and team permissions"
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---

## Overview

Linear is a modern issue tracking and project management platform designed for software teams. As a platform managing development workflows and project data, Linear security configurations directly impact operational security and intellectual property protection.

### Intended Audience
- Security engineers managing engineering tools
- IT administrators configuring Linear
- Engineering managers managing workspaces
- GRC professionals assessing development security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Linear security including SAML SSO, workspace access, team permissions, and integration security.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Access Controls](#2-access-controls)
3. [Integration Security](#3-integration-security)
4. [Monitoring & Compliance](#4-monitoring--compliance)
5. [Compliance Quick Reference](#5-compliance-quick-reference)

---

## 1. Authentication & SSO

### 1.1 Configure SAML Single Sign-On

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML SSO to centralize authentication for Linear users.

#### Rationale
**Why This Matters:**
- Centralizing Linear authentication in your corporate IdP enforces MFA, conditional access, and session policies on every login
- Local email/password logins bypass IdP controls and are prime targets for credential stuffing and phishing
- SSO enables automatic deprovisioning when employees leave, eliminating orphaned accounts with standing access to roadmaps and issues
- Linear workspaces hold product roadmaps, security issues, and internal planning, so a single compromised login can expose sensitive engineering intelligence

**Attack Prevented:** Credential theft, phishing, account takeover, orphaned-account access

#### Prerequisites
- Linear workspace admin access
- Enterprise tier
- SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Settings** → **Security** → **SAML SSO**
2. Enable SAML SSO

**Step 2: Configure SAML**
1. Configure IdP settings:
   - SSO URL
   - Entity ID
   - Certificate
2. Download Linear metadata for IdP
3. Configure attribute mapping

**Step 3: Test and Enforce**
1. Test SSO authentication
2. Enable SSO enforcement
3. Configure admin fallback

**Time to Complete:** ~1-2 hours

---

### 1.2 Enforce Two-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for all Linear users.

#### Rationale
**Why This Matters:**
- Passwords alone are routinely compromised through reuse, phishing, and database breaches; a second factor blocks the vast majority of automated account-takeover attempts
- Requiring 2FA workspace-wide closes the gap left by individual users who would otherwise opt out
- Phishing-resistant factors for admins protect the accounts that can change workspace-wide security settings
- Linear issues and projects can reveal unreleased features and security work that attackers actively seek

**Attack Prevented:** Credential stuffing, password reuse attacks, phishing, account takeover

**Verify this setting before relying on it.** The workspace-level **Require two-factor authentication** toggle described below could not be re-verified against Linear's current public documentation (checked 2026-08); the live security documentation covers personal account security rather than workspace-wide enforcement. Confirm the setting exists in your own workspace settings before treating it as an enforced control.

**Prefer passkeys as the second factor.** Linear documents passkey support for account sign-in. Passkeys are bound to the origin they were registered against, so unlike TOTP codes they cannot be relayed to an attacker's proxy — make passkeys the named factor for admins and anyone with access to sensitive projects. ([Security and access](https://linear.app/docs/security-and-access))

#### ClickOps Implementation

**Step 1: Enable 2FA Requirement**
1. Navigate to: **Settings** → **Security**
2. Enable **Require two-factor authentication**
3. All members must configure 2FA

**Step 2: Register Passkeys**
1. Have each member add a passkey from their account security settings
2. Prioritize admins and members with access to restricted projects
3. Retain a documented recovery path before enforcing

**Step 3: Configure via IdP**
1. Enable MFA in identity provider
2. Use phishing-resistant methods for admins
3. All SSO users subject to IdP MFA

---

### 1.3 Configure Allowed Domains

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Restrict sign-up to approved email domains.

#### Rationale
**Why This Matters:**
- Restricting sign-up to corporate domains prevents personal or attacker-controlled email addresses from joining the workspace
- Blocking public email providers stops unauthorized outsiders from self-provisioning access to internal projects
- Domain allowlists keep workspace membership aligned with your identity provider and HR-managed accounts
- Without domain controls, a leaked invite link or open join setting can let unintended parties view engineering data

**Attack Prevented:** Unauthorized workspace access, rogue account creation, data exposure to outsiders

**Verify this setting before relying on it.** The **Allowed Domains** workspace setting described below could not be re-verified against Linear's current public documentation (checked 2026-08); the live security documentation covers personal account security rather than workspace domain restrictions. Confirm the setting exists in your own workspace settings before treating it as an enforced control.

#### ClickOps Implementation

**Step 1: Configure Allowed Domains**
1. Navigate to: **Settings** → **Security**
2. Configure allowed email domains
3. Block public email providers

---

## 2. Access Controls

### 2.1 Configure Team Permissions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using Linear teams.

#### Rationale
**Why This Matters:**
- Scoping members to only the teams they need limits how much of the workspace any single compromised account can reach
- Least-privilege roles (Admin, Member, Guest) prevent ordinary users from changing settings or accessing unrelated projects
- Function-based teams contain the blast radius of a phished or insider account to a narrow slice of issues
- Regular access reviews catch privilege creep before it becomes a standing risk

**Attack Prevented:** Privilege escalation, lateral movement, insider data access, over-permissioned accounts

#### ClickOps Implementation

**Step 1: Create Teams**
1. Navigate to: **Settings** → **Teams**
2. Create teams by function
3. Configure team visibility

**Step 2: Configure Member Roles**
1. Review workspace roles:
   - Admin
   - Member
   - Guest
2. Assign minimum necessary role
3. Regular access reviews

---

### 2.2 Configure Project Visibility

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Control project and issue visibility.

#### Rationale
**Why This Matters:**
- Restricting sensitive projects to the teams that own them keeps confidential initiatives out of view for the broader workspace
- Default-open visibility means every member can read security issues, business plans, or unreleased features unless explicitly restricted
- Controlling cross-team access enforces need-to-know on the most sensitive work
- A compromised low-privilege account can only see what visibility settings expose to it

**Attack Prevented:** Unauthorized data access, information disclosure, insider snooping

#### ClickOps Implementation

**Step 1: Configure Team Privacy**
1. Set team visibility settings
2. Control cross-team access
3. Restrict sensitive projects

**Step 2: Configure Issue Access**
1. Review default visibility
2. Restrict sensitive issues
3. Audit access patterns

---

### 2.3 Limit Admin Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect administrator accounts.

#### Rationale
**Why This Matters:**
- Admins can change SSO, 2FA, domain, and membership settings, making every admin account a high-value target
- Keeping admins to a small, documented set shrinks the attack surface for workspace takeover
- Requiring SSO and 2FA on admin accounts protects the controls every other user depends on
- Monitoring admin activity surfaces unauthorized configuration changes quickly

**Attack Prevented:** Workspace takeover, privilege abuse, unauthorized configuration changes

#### ClickOps Implementation

**Step 1: Inventory Admins**
1. Review workspace admins
2. Document admin access
3. Identify unnecessary privileges

**Step 2: Apply Restrictions**
1. Limit admin to 2-3 users
2. Require 2FA/SSO for admins
3. Monitor admin activity

---

## 3. Integration Security

### 3.1 Configure Integration Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Control third-party integrations.

#### Rationale
**Why This Matters:**
- Each connected integration is granted access to workspace data and expands the supply-chain attack surface
- Removing unused integrations eliminates dormant OAuth grants that attackers can abuse if the vendor is compromised
- Limiting integration scopes enforces least privilege on machine-to-machine data access
- A breached third-party app with broad permissions can read or exfiltrate issues without touching a user account

**Attack Prevented:** Supply-chain compromise, OAuth token abuse, data exfiltration via third parties

#### ClickOps Implementation

**Step 1: Review Integrations**
1. Navigate to: **Settings** → **Integrations**
2. Review all integrations
3. Remove unused integrations

**Step 2: Configure Permissions**
1. Review integration scopes
2. Limit data access
3. Audit integration usage

---

### 3.2 Configure API Tokens

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Review and prune everything that holds standing credentials to a Linear account — personal API keys, active sessions, and authorized OAuth applications — from the account **Security & access** page.

#### Rationale
**Why This Matters:**
- Personal API keys act as long-lived credentials that bypass interactive SSO and 2FA prompts
- Keys leaked in code, logs, or CI configs grant direct programmatic access to workspace data
- Authorized OAuth applications hold delegated access that persists after the tool stops being used, so an unrevoked grant is a live path into the workspace if the third party is breached
- Active sessions are recorded with location and date, which makes an unrecognized session the earliest visible sign of account takeover
- Documenting key purposes makes it possible to spot and revoke credentials that no longer have an owner

**Attack Prevented:** Credential leakage, token theft, unauthorized API access, OAuth grant abuse, persistent access via stale tokens and sessions

#### ClickOps Implementation

**Step 1: Review Personal API Keys**
1. Open the account **Security & access** page in Linear settings
2. Review every personal API key and document its purpose and owner
3. Revoke keys with no documented owner or purpose

**Step 2: Revoke Stale Sessions**
1. On the same page, review **active sessions** — each is listed with its location and date
2. Revoke any session from an unrecognized location, an old device, or a departed contractor
3. Treat an unexplained session as a suspected compromise: revoke it, then rotate the account's API keys

**Step 3: Review Authorized OAuth Applications**
1. Review the list of **authorized OAuth applications** on the same page
2. Revoke every application the member no longer actively uses
3. Re-review after any third-party breach disclosure affecting a connected vendor

Source: [Security and access](https://linear.app/docs/security-and-access)

---

## 4. Monitoring & Compliance

### 4.1 Configure Audit Logs

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Review Linear's workspace audit log and stream it to your SIEM, because Linear retains audit events for only 90 days — anything you need beyond that window has to be exported while it still exists.

#### Rationale
**Why This Matters:**
- The audit log is the workspace's record of who did what, and each entry carries the actor's IP address and country, which is what makes an anomalous login or a session from an unexpected jurisdiction visible
- Linear retains audit log events for **90 days only**, so an intrusion discovered on a typical breach-detection timeline can easily predate the oldest available evidence — exporting to a SIEM is what preserves the trail, not a nice-to-have
- Monitoring authentication, permission, and integration events surfaces account compromise and insider abuse early
- Retained audit records support SOC 2, GDPR, and HIPAA evidence requirements, which generally demand retention well beyond 90 days

**Attack Prevented:** Undetected intrusion, insider abuse, repudiation, delayed incident response, evidence loss through log expiry

#### Prerequisites
- Enterprise plan
- Workspace **Owner** role — the audit log is restricted to workspace owners

#### ClickOps Implementation

**Step 1: Access the Audit Log**
1. Open the audit log from workspace settings as a workspace owner
2. Review entries — actor, action, IP address, and country
3. Confirm the 90-day retention window against your own evidence requirements

**Step 2: Stream Logs to Your SIEM**
1. In workspace settings, use **Stream logs** to configure a webhook endpoint
2. Point the webhook at your SIEM's HTTP collector so events are captured continuously rather than exported by hand
3. Verify events are arriving, then set retention in the SIEM to match your compliance obligation

**Step 3: Query Programmatically**
1. The audit log is queryable through Linear's GraphQL API for point-in-time investigation and periodic extraction
2. Use it to reconcile SIEM coverage gaps before the 90-day window closes

**Key Events to Monitor:**
- Authentication events and sessions from unexpected countries
- Permission and role changes
- Integration and OAuth application changes
- Membership additions and removals

Source: [Audit log](https://linear.app/docs/audit-log)

---

### 4.2 Choose Data Residency at Workspace Creation

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | SA-9 |

#### Description
Linear lets you choose whether a workspace's data is hosted in the **US** or the **EU** region, and that choice is made **only at workspace creation** — it cannot be changed afterward, so regulated teams must decide before the workspace exists.

#### Rationale
**Why This Matters:**
- Data residency is irreversible in Linear: pick the wrong region and the only remedy is creating a new workspace and migrating the data, which is expensive and disruptive once issues, projects, and integrations have accumulated
- Teams subject to GDPR, national data-localization rules, or customer contracts with residency clauses need the EU region selected up front to keep issue content, attachments, and comments inside the required jurisdiction
- Issue trackers accumulate personal data incidentally — customer names in bug reports, screenshots, support transcripts — so residency obligations apply even when the workspace was never intended to hold regulated data
- Documenting which region a workspace runs in gives auditors and vendor-risk reviewers a verifiable answer instead of an assumption

**Attack Prevented:** Regulatory exposure from cross-border data transfer, residency-clause breach, unplanned data migration

#### ClickOps Implementation

**Step 1: Decide Region Before Creating the Workspace**
1. Confirm your residency obligation (GDPR, customer contract, internal policy) before anyone provisions the workspace
2. Select the **EU** region at creation if any obligation requires EU hosting; otherwise select **US**
3. Record the chosen region in your vendor inventory — it cannot be changed later

**Step 2: Verify Existing Workspaces**
1. Determine which region each existing workspace was created in
2. Where a workspace is in the wrong region, plan a migration to a new correctly-provisioned workspace rather than expecting a setting change
3. Document the outcome for audit evidence

#### Validation & Testing
Confirm the workspace's region with Linear and check that it matches the region recorded in your data-processing inventory. Since the setting is fixed at creation, validation is a one-time attestation rather than a recurring config check.

Source: [Security](https://linear.app/docs/security)

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Linear Control | Guide Section |
|-----------|----------------|---------------|
| CC6.1 | SSO/2FA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | Team permissions | [2.1](#21-configure-team-permissions) |
| CC7.2 | Audit logs | [4.1](#41-configure-audit-logs) |

### NIST 800-53 Rev 5 Mapping

| Control | Linear Control | Guide Section |
|---------|----------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | 2FA | [1.2](#12-enforce-two-factor-authentication) |
| AC-6 | Team permissions | [2.1](#21-configure-team-permissions) |
| AU-2 | Audit logs | [4.1](#41-configure-audit-logs) |

---

## Appendix A: References

**Official Linear Documentation:**
- [Linear Documentation](https://linear.app/docs)
- [Security](https://linear.app/docs/security)
- [Security and access](https://linear.app/docs/security-and-access)
- [Audit log](https://linear.app/docs/audit-log)
- [Team Management](https://linear.app/docs/teams)

*SAML/SCIM configuration documentation was not publicly resolvable during this pass (2026-08) — the previously cited `linear.app/docs/saml-sso` returns 404 and no replacement slug could be located. See the Administration section of [linear.app/docs](https://linear.app/docs) for current SSO and provisioning guidance.*

**API & Developer Resources:**
- [Linear API Documentation](https://developers.linear.app/docs)
- [Linear GraphQL API](https://developers.linear.app/docs/graphql/working-with-the-graphql-api)
- [Linear SDKs](https://developers.linear.app/docs/sdk/getting-started)

**Compliance Frameworks:**
- SOC 2 Type II, GDPR, HIPAA (Enterprise plan with BAA) -- see [Linear Security documentation](https://linear.app/docs/security)

**Security Incidents:**
- No major public security breaches identified as of this writing.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass, scope-limited: only three Linear documentation pages (security, security-and-access, audit-log) were publicly reachable this pass, so findings outside them soften rather than assert. Rewrote 4.1 audit log (Enterprise, workspace owners only, 90-day retention, GraphQL queryable, webhook streaming to SIEM, actor IP/country); added 4.2 data residency (US/EU, fixed at workspace creation); added passkeys to 1.2 and OAuth-grant/session review to 3.2; annotated 1.2 and 1.3 as unverifiable against current public docs; removed the 404 SAML SSO link and the Trust Center/security marketing links in favor of linear.app/docs/security | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, teams, and integrations | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)

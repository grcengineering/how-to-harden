---
layout: guide
title: "PagerDuty Hardening Guide"
vendor: "PagerDuty"
slug: "pagerduty"
tier: "2"
category: "IT Operations"
description: "Incident management platform hardening for PagerDuty including SSO configuration, user provisioning, and access controls"
version: "0.2.0"
maturity: "draft"
last_updated: "2026-08-08"
---

## Overview

PagerDuty is a leading incident management platform used by **thousands of organizations** for on-call management, incident response, and operational intelligence. As a critical tool for incident response and system alerting, PagerDuty security configurations directly impact operational resilience.

### Intended Audience
- Security engineers managing incident platforms
- IT administrators configuring PagerDuty
- DevOps/SRE teams securing on-call workflows
- GRC professionals assessing operational security

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers PagerDuty security including SAML SSO, user provisioning, role-based access, and account security.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [User Management](#2-user-management)
3. [Access Controls](#3-access-controls)
4. [Monitoring & Security](#4-monitoring--security)
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
Configure SAML SSO to centralize authentication for PagerDuty users.

#### Rationale
**Why This Matters:**
- Eliminates need for separate PagerDuty credentials
- Enables on-demand user provisioning
- Simplifies access revocation

**Attack Prevented:** Credential theft against standalone PagerDuty passwords, phishing of local logins, orphaned-account access after IdP deprovisioning

#### Prerequisites
- A plan that includes SSO — PagerDuty documents SSO availability on Professional, Business, Enterprise for Incident Management, and the legacy Digital Operations plan
- A SAML 2.0, OIDC, or Google OAuth compatible IdP

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. Navigate to: **Account Settings** → **Single Sign-On**
2. Click **Configure SSO**

**Step 2: Configure Identity Provider**
1. PagerDuty documents SSO via SAML 2.0, OIDC, and Google OAuth, with named integrations including:
   - Microsoft ADFS
   - Okta
   - OneLogin
   - Ping Identity
   - SecureAuth
2. Create the SAML, OIDC, or Google OAuth application in your IdP

**Step 3: Enter IdP Settings**
1. Enter IdP SSO URL
2. Upload IdP certificate
3. Configure attribute mappings

**Step 4: Test and Enable**
1. Test SSO authentication
2. Verify user provisioning
3. Enable SSO for account

**Time to Complete:** ~1 hour

**Source:** [PagerDuty Single Sign-On documentation](https://support.pagerduty.com/main/docs/sso)

---

### 1.2 Manage SSO Certificate Rotation

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Maintain SAML certificate validity.

#### Rationale
**Why This Matters:**
- PagerDuty rotates SAML certificates annually
- Expired certificates break SSO authentication

**Attack Prevented:** SSO outage forcing a fallback to weaker password login, service disruption to incident response during certificate expiry

#### ClickOps Implementation

**Step 1: Monitor Certificate Expiration**
1. PagerDuty sends communications about rotation
2. Note certificate expiration dates

**Step 2: Update Certificates**
1. Download new PagerDuty certificate
2. Update IdP configuration
3. Test SSO after update

---

### 1.3 Configure Account Owner Fallback

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Understand and protect Account Owner fallback access.

#### Rationale
**Why This Matters:**
- The Account Owner's email/password login is a permanent bypass of your SSO and MFA controls and exists on every PagerDuty account whether you protect it or not
- During an IdP or SSO outage this account is the only way to restore incident-response access, so its credentials must be both recoverable and rigorously protected in a vault
- Because the Account Owner can re-enable password login for every user, compromise of this single account collapses the entire SSO security model
- Incident management is a critical operational function — an attacker who seizes the Account Owner can suppress or reroute alerts during an active attack

**Attack Prevented:** SSO/MFA bypass, account takeover, credential theft, alert suppression during incident

#### ClickOps Implementation

**Step 1: Protect Account Owner Credentials**
1. Account Owners retain email/password login (cannot be disabled)
2. Use strong password (20+ characters)
3. Store in password vault

**Step 2: Document Recovery Procedure**
1. Account Owner can log in during SSO outage
2. Can temporarily enable password login for all users

---

### 1.4 Configure Session Timeouts

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.3 |
| NIST 800-53 | AC-11, AC-12 |

#### Description
Set an idle session timeout and an absolute session timeout for the account so PagerDuty web sessions expire rather than persisting indefinitely on a user's browser.

#### Rationale
**Why This Matters:**
- An idle timeout ends sessions left open on unattended laptops and shared incident-response workstations, which are common in on-call environments
- An absolute timeout caps the total lifetime of any session regardless of activity, bounding how long a stolen session cookie remains usable even against an actively-used session
- Without either timeout, a session persists until the user explicitly logs out, so session theft yields effectively permanent access to on-call schedules, escalation policies, and incident data
- Short session lifetimes force re-authentication through your IdP, reapplying MFA and conditional access

**Attack Prevented:** Session hijacking, session-cookie replay, unattended-workstation access, indefinite session persistence

#### Prerequisites
- Admin or Account Owner permissions
- API access — PagerDuty documents session timeouts as configurable through the API only; there is no console page for these settings

#### ClickOps Implementation

> **No console surface:** PagerDuty documents session timeouts as an API-only configuration. There is no Account Settings page for them — an admin or Account Owner must set them through the REST API. Treat this control as automation-only.

**Step 1: Choose Timeout Values**
1. **Idle timeout:** configurable within a documented range of 60 seconds to 180 days — pick the shortest interval responders can tolerate mid-incident
2. **Absolute timeout:** configurable within a documented range of 10 minutes to 210 days — set it to at most your standard workday or shift length

**Step 2: Apply via the API**
1. Authenticate with an account-level API key held by an admin or the Account Owner (see [3.3](#33-govern-api-access-keys))
2. Set the idle and absolute session timeout values for the account
3. Record the configured values in your control evidence — since there is no console page, the API response is the only proof of the setting

#### Validation & Testing
- Read the session-timeout settings back through the API and confirm they match the intended values
- Leave a session idle past the idle timeout and confirm re-authentication is required
- Keep a session continuously active past the absolute timeout and confirm it still terminates

**Source:** [PagerDuty session timeouts](https://support.pagerduty.com/main/docs/session-timeouts)

---

## 2. User Management

### 2.1 Configure User Provisioning

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Configure automatic user provisioning via SSO.

#### Rationale
**Why This Matters:**
- On-demand provisioning ensures only users your IdP has authorized can create a PagerDuty account, keeping the user directory tied to corporate identity
- Centralizing account creation in the IdP removes manual invite workflows that are easy to misconfigure or abuse to seed rogue accounts
- Because SAML attributes are applied only at initial creation and do not later sync, understanding this behavior prevents stale role assignments that silently grant more access than intended
- Tying account creation to IdP group membership shrinks the pool of accounts an attacker can phish or target

**Attack Prevented:** Unauthorized account creation, privilege drift, orphaned accounts

#### ClickOps Implementation

**Step 1: Enable On-Demand Provisioning**
1. With SSO enabled, users created on first login
2. Access granted via IdP assignment

**Step 2: Configure SAML Attributes**
1. Configure IdP to send email, name, role
2. Note: Attributes only used at initial creation
3. Changes in IdP don't sync to PagerDuty

---

### 2.2 Configure SCIM Provisioning

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Configure SCIM for automated user lifecycle management.

#### Rationale
**Why This Matters:**
- SCIM automatically deprovisions departed employees, closing the gap that on-demand SSO provisioning leaves open when access is revoked only in the IdP
- Automated lifecycle management eliminates orphaned PagerDuty accounts that retain standing access to on-call schedules and incident data
- Centralizing create, update, and deactivate operations in the IdP keeps PagerDuty roles synchronized with current job function
- Removing manual offboarding steps reduces the window during which a former insider could still receive or act on production alerts

**Attack Prevented:** Orphaned-account access, insider threat, privilege creep, delayed offboarding

#### Prerequisites
- PagerDuty documents SCIM user provisioning as available on all plans
- An IdP that supports SCIM provisioning
- A PagerDuty API key to authenticate the IdP's SCIM connector

#### ClickOps Implementation

> **Correction:** SCIM is configured **in your identity provider**, not in PagerDuty. There is no Account Settings → SCIM page and no separate SCIM token — the IdP's SCIM connector authenticates with a standard PagerDuty API key. ([PagerDuty SCIM user provisioning](https://support.pagerduty.com/main/docs/scim-user-provisioning))

**Step 1: Create the API Key PagerDuty's SCIM Connector Will Use**
1. Create an account-level API access key with the permissions the connector requires (see [3.3](#33-govern-api-access-keys))
2. Copy the key at creation — PagerDuty displays it only once
3. Store it in a secrets manager

**Step 2: Configure SCIM in Your IdP**
1. Add the PagerDuty SCIM application or connector in your IdP
2. Supply the PagerDuty SCIM base URL and the API key from Step 1
3. Enable deprovisioning so IdP removals deactivate the PagerDuty user

**Step 3: Verify Lifecycle Operations**
1. Provision a test user from the IdP and confirm it appears in PagerDuty
2. Deprovision the test user and confirm the PagerDuty account is deactivated
3. Confirm the deactivated user no longer appears in on-call schedules or escalation paths

**Source:** [PagerDuty SCIM user provisioning](https://support.pagerduty.com/main/docs/scim-user-provisioning)

---

## 3. Access Controls

### 3.1 Configure Role-Based Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege using PagerDuty roles.

#### Rationale
**Why This Matters:**
- Assigning the least-privileged role that fits each user's job limits what a compromised account can change, exfiltrate, or destroy
- Restricting Account Owner and Global Admin to a small group shrinks the high-value attack surface that grants account-wide control
- Granular base roles prevent on-call engineers from holding administrative power they never need
- Proper role scoping protects integration keys, escalation policies, and audit settings from accidental or malicious modification

**Attack Prevented:** Privilege escalation, lateral movement, configuration tampering, blast-radius expansion

#### Prerequisites
- PagerDuty documents Advanced Permissions — including the Observer role — as available from the Professional plan upward

#### ClickOps Implementation

**Step 1: Review Available Base Roles**

PagerDuty's documented base roles are:

| Base Role | Scope |
|-----------|-------|
| Account Owner | Full account control; exactly one per account |
| Global Admin | Account-wide administration |
| Manager | Manage the objects and teams they are granted |
| Responder | Respond to and act on incidents |
| Observer | View-only across the objects they can see |
| Full Stakeholder | Business-stakeholder visibility into incidents |
| Limited Stakeholder | Narrower stakeholder visibility |
| Restricted Access | No visibility by default |

> **Correction:** "Admin" and "Limited User" are not PagerDuty base roles. The account-wide administrative role is **Global Admin**. **Restricted Access** is the most-restricted base role, and a user assigned it sees nothing until they are additionally granted explicit Team roles or object-level roles — assigning Restricted Access alone is not a working configuration, it is an empty one. ([PagerDuty Advanced Permissions](https://support.pagerduty.com/main/docs/advanced-permissions))

**Step 2: Assign Appropriate Roles**
1. Limit Global Admin to essential personnel (2-3)
2. Use Manager for team leads
3. Use Responder for on-call engineers
4. Use Observer for auditors and read-only reviewers
5. Use Full or Limited Stakeholder for business users who need incident visibility but no operational capability
6. When using Restricted Access, grant the specific Team and object roles the user needs — otherwise they will have no access at all

**Source:** [PagerDuty Advanced Permissions](https://support.pagerduty.com/main/docs/advanced-permissions)

---

### 3.2 Limit Admin Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect Global Admin and Account Owner accounts.

#### Rationale
**Why This Matters:**
- Global Admin accounts can modify integrations, escalation policies, and security settings, so each one is a high-value target whose compromise affects the whole account
- Reducing the number of account-wide administrators to the minimum directly shrinks the attack surface exposed to phishing and credential theft
- Using the Manager role for routine team administration avoids handing out account-wide power for day-to-day tasks
- Fewer privileged accounts make anomalous admin activity easier to detect and investigate in audit logs

**Attack Prevented:** Admin account takeover, privilege escalation, unauthorized configuration changes

#### ClickOps Implementation

**Step 1: Inventory Administrative Users**
1. Navigate to: **People** → **Users**
2. Filter by the **Global Admin** base role, and identify the single Account Owner
3. Document all administrators

**Step 2: Apply Least Privilege**
1. Reduce Global Admins to minimum (2-3)
2. Use Manager role for team administration
3. Downgrade anyone holding Global Admin purely for visibility to Observer

---

### 3.3 Govern API Access Keys

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11, 5.4 |
| NIST 800-53 | AC-6, IA-5 |

#### Description
Inventory and constrain PagerDuty API credentials — account-level API access keys and personal user tokens — using read-only keys wherever a integration only needs to read.

#### Rationale
**Why This Matters:**
- API keys bypass the interactive login entirely, so they are not covered by SSO, MFA, or conditional access — a leaked key is standing access to the account
- Account-level keys can be created read-only, which is the single most effective constraint available for reporting, monitoring, and export integrations that never need to write
- Personal user tokens inherit the permissions of the user who created them, so a token issued by a Global Admin carries account-wide power and silently outlives that person's role changes
- PagerDuty displays a key exactly once at creation, so a key that was not captured into a secrets manager becomes an unmanaged credential nobody can inventory
- There is no rotation primitive — rotating means creating a replacement key and deleting the old one, which has to be planned as a cutover rather than assumed

**Attack Prevented:** API key theft, unauthorized write access via over-scoped keys, standing access that survives offboarding, untraceable programmatic changes

#### Prerequisites
- Admin or Account Owner permissions to view and manage account-level API access keys

#### ClickOps Implementation

**Step 1: Inventory Account-Level API Access Keys**
1. Navigate to: **Integrations** → **Developer Tools** → **API Access Keys**
2. Record every key, its description, and its owner
3. Delete keys with no identified owner or no current use

**Step 2: Prefer Read-Only Keys**
1. When creating a key, select the **read-only** option unless the integration provably needs to write
2. Capture the key at creation — it is displayed only once — and store it in a secrets manager

**Step 3: Constrain Personal User Tokens**
1. Personal user tokens inherit the creating user's permissions, so a token created by a Global Admin is an account-wide credential
2. Have integrations use account-level keys rather than tokens tied to an individual, so access survives personnel changes without inheriting personal privilege
3. Review personal tokens when a user's role changes or they leave

**Step 4: Plan Rotation as Replace-and-Delete**
1. PagerDuty provides no in-place rotation — create a replacement key, cut the integration over, then delete the old key
2. Schedule rotation and treat any key exposure as requiring immediate deletion

#### Validation & Testing
- Confirm every key in the API Access Keys list maps to a documented integration and owner
- Confirm read-only keys fail on a write call
- Confirm a deleted key is rejected by the API

**Source:** [PagerDuty API access keys](https://support.pagerduty.com/main/docs/api-access-keys)

---

## 4. Monitoring & Security

### 4.1 Configure Audit Logging

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Monitor administrative and security events.

#### Rationale
**Why This Matters:**
- Audit records provide the evidence trail needed to detect unauthorized changes to users, roles, integrations, and SSO settings
- Exporting events to a SIEM enables correlation with other systems and near-real-time alerting on suspicious PagerDuty activity
- Without comprehensive logging, account compromise and insider misuse can go undetected and forensic investigation becomes impossible
- Retained audit logs satisfy compliance evidence requirements for SOC 2, ISO 27001, and similar frameworks

**Attack Prevented:** Undetected intrusion, insider misuse, untraceable tampering, compliance evidence gaps

#### ClickOps Implementation

**Step 1: Access Audit Records**
1. Navigate to: **Account Settings** → **Audit Records**
2. Review logged events

**Step 2: Export Logs**
1. Export audit records for analysis
2. Integrate with SIEM

**Source:** [PagerDuty audit trail reporting](https://support.pagerduty.com/main/docs/audit-trail-reporting)

---

### 4.2 Govern PagerDuty Advance AI Access and Data Sources

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.8 |
| NIST 800-53 | CM-7, AC-3 |

#### Description
Decide deliberately whether PagerDuty Advance is enabled, which teams may use it, and which external data sources it may read — rather than leaving the AI feature at its default state.

#### Rationale
**Why This Matters:**
- PagerDuty Advance reads incident context to generate summaries and assistance, so its data-source toggles determine what an AI feature can see and surface across your incident record
- Connecting data sources such as GitHub or Amazon Q widens the AI's reach beyond PagerDuty into your source control and cloud tooling, so each connection is an access-scope decision, not a convenience toggle
- Enforcing per-team access means only teams with a genuine need — and appropriate data sensitivity — can invoke the assistant
- A full disable switch exists, so organizations with policy or regulatory constraints on AI processing can turn the capability off entirely rather than managing it setting by setting
- PagerDuty states that customer data is not used to train its models; that vendor statement should be captured in your vendor-risk record rather than assumed

**Attack Prevented:** Unintended data exposure through AI summarization, over-broad third-party data-source access, ungoverned AI feature enablement

#### Prerequisites
- Admin, Global Admin, or Account Owner permissions

#### ClickOps Implementation

**Step 1: Review AI Settings**
1. Navigate to: **AI** → **AI Settings**
2. Record the current enablement state before changing anything

**Step 2: Decide Enablement**
1. If your policy prohibits AI processing of incident data, use the **Disable PagerDuty Advance** option to turn the capability off account-wide
2. Otherwise, enable it only with the team and data-source constraints below in place

**Step 3: Enforce Per-Team Access**
1. Restrict PagerDuty Advance access to the specific teams approved to use it
2. Exclude teams handling incidents with regulated or especially sensitive data unless explicitly approved

**Step 4: Constrain Data Sources**
1. Review the available data-source connections, including GitHub and Amazon Q
2. Enable only the sources with a documented need, and record who approved each connection
3. Re-review connected sources whenever the connected system's scope changes

#### Validation & Testing
- Confirm the enablement state in **AI → AI Settings** matches your approved policy
- Confirm a user on a non-approved team cannot invoke PagerDuty Advance
- Confirm only approved data sources appear as connected

**Source:** [PagerDuty Advance](https://support.pagerduty.com/main/docs/pagerduty-advance)

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | PagerDuty Control | Guide Section |
|-----------|-------------------|---------------|
| CC6.1 | SSO/SAML | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | RBAC | [3.1](#31-configure-role-based-access) |
| CC7.2 | Audit logging | [4.1](#41-configure-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | PagerDuty Control | Guide Section |
|---------|-------------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| AC-11, AC-12 | Session timeouts | [1.4](#14-configure-session-timeouts) |
| AC-2 | User provisioning | [2.1](#21-configure-user-provisioning) |
| AC-6 | Least privilege | [3.1](#31-configure-role-based-access) |
| IA-5 | API access keys | [3.3](#33-govern-api-access-keys) |
| CM-7 | AI feature governance | [4.2](#42-govern-pagerduty-advance-ai-access-and-data-sources) |
| AU-2 | Audit logging | [4.1](#41-configure-audit-logging) |

---

## Appendix A: Plan Compatibility

Plan names per PagerDuty's documentation: Free, Professional, Business, and **Enterprise for Incident Management**. Accounts on the legacy **Digital Operations** plan retain their own feature set.

| Feature | Free | Professional | Business | Enterprise for Incident Management |
|---------|------|--------------|----------|------------------------------------|
| SSO/SAML, OIDC, Google OAuth | ❌ | ✅ | ✅ | ✅ |
| SCIM user provisioning | ✅ | ✅ | ✅ | ✅ |
| Teams | ❌ | ❌ | ✅ | ✅ |
| Advanced Permissions | ❌ | ✅ | ✅ | ✅ |
| Observer Role | ❌ | ✅ | ✅ | ✅ |

SCIM is documented as available on all plans and is configured in the identity provider using a PagerDuty API key ([SCIM user provisioning](https://support.pagerduty.com/main/docs/scim-user-provisioning)). Advanced Permissions, including the Observer role, are documented from Professional upward ([Advanced Permissions](https://support.pagerduty.com/main/docs/advanced-permissions)).

---

## Appendix B: References

**Official PagerDuty Hardening Documentation:**
- [Security Hygiene for Current Cyber Threats](https://support.pagerduty.com/main/docs/security-hygiene-for-the-current-cyber-threat-landscape)
- [Single Sign-On (SSO)](https://support.pagerduty.com/main/docs/sso)
- [Advanced Permissions](https://support.pagerduty.com/main/docs/advanced-permissions)
- [API Access Keys](https://support.pagerduty.com/main/docs/api-access-keys)
- [Session Timeouts](https://support.pagerduty.com/main/docs/session-timeouts)
- [SCIM User Provisioning](https://support.pagerduty.com/main/docs/scim-user-provisioning)
- [Audit Trail Reporting](https://support.pagerduty.com/main/docs/audit-trail-reporting)
- [PagerDuty Advance](https://support.pagerduty.com/main/docs/pagerduty-advance)
- [Support Center](https://support.pagerduty.com/)
- [Okta SSO Configuration](https://saml-doc.okta.com/SAML_Docs/How-to-Configure-SAML-2.0-for-PagerDuty.html)

**API Documentation:**
- [PagerDuty API Reference](https://developer.pagerduty.com/api-reference)

**Third-Party Baselines:**
- No CIS Benchmark, DISA STIG, or CISA SCuBA baseline for PagerDuty was established in this pass — the Tier 2 indexes were not surveyed, so absence is not confirmed.

**Not Documented:**
- PagerDuty's documentation does not describe a native multi-factor authentication setting for the platform itself; MFA is expected to be enforced at the identity provider (see [1.1](#11-configure-saml-single-sign-on)). No native-MFA control is asserted here because no vendor documentation supports one.

**Security Incidents:**
- **August 2025:** Attackers exploited a vulnerability in Drift's OAuth integration with Salesforce (via Salesloft), potentially gaining unauthorized access to PagerDuty's Salesforce account. No PagerDuty credentials were exposed and no evidence of access to PagerDuty's core platform or internal systems. — [SecurityWeek Report](https://www.securityweek.com/pagerduty-warns-customers-data-breach/)
- **April 2024:** Vendor compromise at Sisense; PagerDuty reset credentials per CISA guidance as a precaution, but found no impact on PagerDuty or its customers. — [PagerDuty Advisory](https://support.pagerduty.com/main/docs/sisense-compromise)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Correct base roles to the documented set (Global Admin, Restricted Access, Stakeholder tiers — "Admin" and "Limited User" do not exist); correct SCIM to all-plans and IdP-configured with a standard API key; correct plan names and Advanced Permissions/Observer availability to Professional+; add 1.4 session timeouts (API-only), 3.3 API access keys, 4.2 PagerDuty Advance AI governance; fix audit-doc link; add Attack Prevented to 1.1 and 1.2; drop the marketing security page. No native-MFA control added — PagerDuty documents none | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, user management, and access controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)

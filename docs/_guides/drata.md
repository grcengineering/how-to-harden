---
layout: guide
title: "Drata Hardening Guide"
vendor: "Drata"
slug: "drata"
tier: "2"
category: "Security"
description: "Compliance automation platform hardening for Drata including access controls, integration security, and monitoring configuration"
version: "0.2.0"
maturity: "draft"
last_updated: "2026-08-08"
---

## Overview

Drata is a leading compliance automation platform helping **thousands of organizations** achieve and maintain SOC 2, ISO 27001, HIPAA, and other compliance certifications. As a central repository for compliance evidence, security controls, and organizational policies, Drata security configurations directly impact the integrity of compliance programs and sensitive audit data.

### Intended Audience
- Security engineers managing compliance programs
- GRC professionals configuring Drata
- IT administrators integrating systems with Drata
- Compliance managers overseeing audit readiness

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Drata platform security including access controls, integration security, policy management, and monitoring configuration.

---

## Table of Contents

1. [Access & Authentication](#1-access--authentication)
2. [Integration Security](#2-integration-security)
3. [Policy & Control Management](#3-policy--control-management)
4. [Monitoring & Auditing](#4-monitoring--auditing)
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
Enable the Drata SSO connection so every login — including administrators — is authenticated by your corporate identity provider rather than by Drata's built-in login.

#### Rationale
**Why This Matters:**
- Centralizes Drata authentication in your corporate IdP so MFA, conditional access, and session policies apply to every login
- Drata's non-SSO login path is a passwordless email one-time code, which inherits none of your IdP's conditional access, device posture, or phishing-resistant factor requirements
- Drata holds compliance evidence, audit data, and security control configurations — a single compromised login can expose or alter the integrity of the entire program

**Attack Prevented:** Credential theft, phishing, mailbox-compromise-driven account takeover, unauthorized access to compliance data

#### Prerequisites
- An IdP integration (Okta, Microsoft Entra ID, Google Workspace, etc.) must be **connected first** — the SSO option stays disabled on the Connections page until an identity provider connection exists
- Drata brokers SSO through WorkOS, so the SAML/OIDC application is configured against WorkOS rather than against a Drata-owned endpoint

#### ClickOps Implementation

**Step 1: Connect the Identity Provider**
1. Navigate to: **Connections**
2. Connect your identity provider (Okta, Microsoft Entra ID, Google Workspace, etc.)
3. Confirm the connection is healthy and personnel are syncing

**Step 2: Add the SSO Connection**
1. On the **Connections** page, select **Single Sign-On** (enabled only once an IdP connection exists)
2. Follow the guided WorkOS setup for your IdP type, supplying the IdP metadata, certificate, and ACS/Entity values it requests
3. Complete the setup in your IdP: create the application, map attributes, and assign the users and groups that should reach Drata

**Step 3: Verify Enforcement Behavior**
1. Once the SSO connection is enabled, **all** logins — administrators included — are routed through the IdP; there is no separate "require SSO" toggle to set
2. Access is restricted to users synced from the IdP, so confirm every intended administrator is present in the synced set **before** enabling
3. Test an administrator login through the IdP, then confirm the non-SSO email-code path no longer grants access

**Time to Complete:** ~1 hour

#### Validation & Testing
- From a private browser session, attempt a login as an administrator: authentication must redirect to the IdP.
- Attempt a login as a user who exists in Drata but is not synced from the IdP — access should be refused.

> **Enforcement is all-or-nothing.** Because enabling the connection forces every login through the IdP and limits access to IdP-synced users, a mis-scoped IdP assignment locks administrators out. Validate the synced user set first, and keep a documented recovery path with Drata Support (see [1.5](#15-govern-drata-support-remote-access)).

**Source:** [Single Sign-On Connection](https://help.drata.com/en/articles/5209416-single-sign-on-connection)

---

### 1.2 Enforce Multi-Factor Authentication at the Identity Provider

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Because Drata exposes no in-product MFA toggle, multi-factor authentication is enforced by enabling the SSO connection and applying an MFA policy in the identity provider that fronts it.

#### Rationale
**Why This Matters:**
- MFA blocks account takeover even when the first factor is phished, leaked, or intercepted
- Drata accounts can read evidence from connected production systems and modify control and policy state, making them high-value targets
- Without SSO, Drata's login is a passwordless one-time code emailed by `auth.drata.com` — a single compromised mailbox is then sufficient to authenticate, with no second factor available to stop it

**Attack Prevented:** Mailbox-compromise account takeover, credential phishing, adversary-in-the-middle code relay

#### ClickOps Implementation

**Step 1: Understand the Available Surface**
1. Drata provides **no local MFA setting** — there is nothing to enable under Settings for password or code-based logins
2. Non-SSO sign-in is passwordless: the user submits an email address and `auth.drata.com` sends a one-time code
3. Therefore MFA exists for Drata only when logins are brokered by an identity provider

**Step 2: Enforce MFA in the Identity Provider**
1. Complete the SSO connection in [1.1](#11-configure-sso-authentication)
2. In your IdP, scope an MFA / authentication policy to the Drata application
3. Require phishing-resistant factors (FIDO2/WebAuthn or platform passkeys) for administrators

**Step 3: Verify Coverage**
1. Confirm every Drata user is inside the IdP group assigned to the Drata application
2. Review the IdP's factor-enrollment report for that group and remediate unenrolled users
3. Re-verify after each access review, since new personnel sync in from the IdP

#### Validation & Testing
- Sign in as a test administrator and confirm the IdP challenges for the required factor before Drata loads.
- Confirm no login path reaches Drata without traversing the IdP.

**Sources:** [Signing in to Drata (New Experience)](https://help.drata.com/en/articles/13801611-signing-in-to-drata-new-experience) · [Settings Page](https://help.drata.com/en/articles/13563975-settings-page)

---

### 1.3 Implement Role-Based Access Control

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Assign Drata's function-scoped roles so each user holds only the permissions their compliance responsibilities require, and drive assignment from identity-provider groups so entitlements revoke automatically on offboarding.

#### Rationale
**Why This Matters:**
- Drata contains sensitive compliance evidence, control state, and risk records that a broadly-privileged account can read or rewrite wholesale
- Drata roles are **additive** — a user can hold several at once — so entitlement creep is silent unless assignments are reviewed against a documented baseline
- Mapping roles to IdP groups means a departure in the IdP revokes Drata access without a separate manual step, closing the orphaned-account window

**Attack Prevented:** Privilege escalation, insider evidence tampering, orphaned-account persistence, excessive blast radius from a compromised account

> **The role model changed.** Drata's New Experience role set replaced the earlier Owner / Admin / Compliance Manager / Viewer model. It is applied automatically to customers who joined Drata on or after **2026-02-24**; existing customers migrate on Drata's schedule. Verify which model your workspace is running before writing access-review procedures against it. — [Roles and Permissions Overview (New Experience)](https://help.drata.com/en/articles/13578465-roles-and-permissions-overview-new-experience)

#### ClickOps Implementation

**Step 1: Review Available Roles**
1. Navigate to: **Settings** → **Role administration**
2. Review the function-scoped roles, which include:
   - **Admin** — broad administrative access to the workspace
   - **Access Reviewer**, **Control Manager**, **DevOps Engineer**, **Information Security Lead**, **Knowledge Base**, **Personnel Compliance Manager**, **Policy Manager**, **Risk Manager**, **Risk Register Owner**, **Workspace Manager**
   - **Trust Center Manager** and **Trust Center Reviewer** for the public trust page
   - **Guest Administrator** and **Service User** for external and machine access
   - Read-only and restricted-view variants of several of the above, for users who need visibility without change rights
3. Note two structural rules: roles are **additive** (a user may hold several), and **Workspace Manager cannot be combined with any other role**

**Step 2: Assign Least Privilege**
1. Define the intended role set per job function and document it — with additive roles, "what should this person hold" must be written down to be auditable
2. Grant **Admin** and **Information Security Lead** only to the small set of people who administer the program
3. Use the read-only and restricted-view variants for auditors, stakeholders, and anyone who only consumes evidence
4. Use **Service User** for machine access rather than assigning a human role to an integration identity

**Step 3: Automate Assignment and Revocation**
1. Navigate to: **Settings** → **Role administration** → **IdP Group Mappings**
2. Map identity-provider groups to Drata roles so SCIM provisioning assigns and revokes roles as group membership changes
3. Treat the IdP group as the source of truth; avoid one-off manual grants that the mapping will not clean up

**Step 4: Regular Access Reviews**
1. Review role assignments quarterly, checking the full additive set per user rather than a single "role" field
2. Confirm departures in the IdP have propagated to Drata role removal
3. Document access decisions and exceptions

#### Validation & Testing
- Export the user list from **Settings** → **Role administration** and reconcile every additive role combination against the documented baseline.
- Remove a test user from a mapped IdP group and confirm the corresponding Drata role is revoked.

**Sources:** [Roles and Permissions Overview (New Experience)](https://help.drata.com/en/articles/13578465-roles-and-permissions-overview-new-experience) · [Map IdP Groups to Drata Roles](https://help.drata.com/en/articles/15235029-map-idp-groups-to-drata-roles)

---

### 1.4 Restrict Admin Privileges

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Follow CIS Control recommendations for admin privilege management.

#### Rationale
**Why This Matters:**
- Admin accounts can reconfigure controls, integrations, and security settings across the entire compliance program
- Minimizing the number of admins shrinks the attack surface and the blast radius of any single compromised credential
- Stronger authentication such as hardware keys plus active monitoring on admins detects and contains abuse faster

**Attack Prevented:** Privilege escalation, insider abuse, lateral movement via over-privileged accounts

#### ClickOps Implementation

**Step 1: Limit Admin Accounts**
1. Identify all users with admin access
2. Reduce to minimum necessary (2-3 admins)
3. Document business justification

**Step 2: Implement MFA for Admins**
1. Ensure all admins have MFA enabled
2. Consider stronger MFA (hardware keys) for admins
3. Verify MFA at every admin login

**Step 3: Monitor Admin Actions**
1. Review admin activity logs regularly
2. Set up alerts for sensitive admin actions
3. Document and analyze admin activities

---

### 1.5 Govern Drata Support Remote Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2, 6.8 |
| NIST 800-53 | AC-2(3), MA-4 |

#### Description
Grant Drata Support access to your workspace only for the duration of an open ticket, at the lowest sufficient level, and verify the grant is withdrawn afterward.

#### Rationale
**Why This Matters:**
- An account-access grant lets Drata Support staff view — and, at the higher level, change — your compliance evidence, control state, and configuration
- The **Allowed to make changes** level permits modification of the record auditors rely on, so an open-ended grant is standing third-party write access to your audit trail
- Time-bounding the grant to a specific ticket makes any support-session activity attributable to a business justification you can produce during an audit

**Attack Prevented:** Standing third-party access, supply-chain access abuse via the vendor's support channel, unattributed changes to compliance evidence

#### Prerequisites
- Only the **Admin**, **Information Security Lead**, and **Workspace Manager** roles can grant or revoke support access

#### ClickOps Implementation

**Step 1: Grant Only Against an Open Ticket**
1. Navigate to: **Settings** → **Organization** → **Account access**
2. Confirm a support ticket exists and record its reference alongside the grant
3. Select the access level:
   - **View only** — the default choice; sufficient for the majority of troubleshooting
   - **Allowed to make changes** — only when Support must reconfigure something you cannot reach yourself

**Step 2: Bound the Window**
1. Set the shortest expiry that covers the support interaction
2. Do not grant access speculatively or leave a standing grant between tickets

**Step 3: Verify Revocation**
1. After the ticket closes, return to **Settings** → **Organization** → **Account access**
2. Confirm the setting reads **No access**
3. Review the Events page ([4.1](#41-review-and-export-the-events-audit-trail)) for actions taken during the window

#### Validation & Testing
- Spot-check **Account access** on a schedule; any state other than **No access** without a matching open ticket is a finding.
- Confirm support-session activity appears in Events with the expected actor and timeframe.

**Source:** [Grant Remote Access to Drata Support](https://help.drata.com/en/articles/13604233-grant-remote-access-to-drata-support)

---

## 2. Integration Security

### 2.1 Configure Integrations with Least Privilege

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-6 |

#### Description
Configure Drata integrations with minimum necessary permissions.

#### Rationale
**Why This Matters:**
- Drata integrates with 200+ systems
- Each integration receives API access to source systems
- Excessive permissions increase risk

**Attack Prevented:** Lateral movement into connected systems via a compromised integration, over-privileged service-account abuse

#### ClickOps Implementation

**Step 1: Review Integration Permissions**
1. Navigate to: **Integrations** → **Connected**
2. Review each integration's permissions
3. Document required permissions

**Step 2: Configure Minimum Permissions**
1. When connecting integrations:
   - Grant only read permissions when possible
   - Avoid admin-level access unless required
   - Use dedicated service accounts

**Step 3: Regular Integration Audit**
1. Quarterly review of connected integrations
2. Remove unused integrations
3. Re-validate permission requirements

---

### 2.2 Secure Cloud Provider Integrations

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-6 |

#### Description
Securely configure cloud provider (AWS, GCP, Azure) integrations.

#### Rationale
**Why This Matters:**
- Cloud integrations grant Drata standing access to read configuration across your AWS, GCP, or Azure environments
- A dedicated, least-privilege IAM role scoped with an external ID prevents the confused-deputy problem and limits what a compromised connection can reach
- Read-only scoping ensures the integration can never modify or delete cloud resources even if abused

**Attack Prevented:** Confused-deputy attacks, over-privileged cross-account access, cloud resource tampering

#### ClickOps Implementation

**Step 1: Use Dedicated IAM Roles**
1. Create dedicated IAM role for Drata
2. Grant minimum required permissions
3. Enable cross-account access with external ID

**Step 2: AWS Integration Example**
1. Create IAM role with Drata policy
2. Configure trust relationship with Drata account
3. Use external ID for security

**Step 3: Monitor Integration Health**
1. Review integration status regularly
2. Address connection issues promptly
3. Rotate credentials if required

---

### 2.3 Secure Identity Provider Integration

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3 |
| NIST 800-53 | IA-2 |

#### Description
Securely configure identity provider integrations for user sync and compliance monitoring.

#### Rationale
**Why This Matters:**
- The IdP integration reads user, group, and MFA-status data that drives access reviews and compliance evidence
- Granting read-only access prevents Drata from being able to alter identity data or user entitlements
- Accurate IdP sync ensures departed users are detected and orphaned-account findings are surfaced

**Attack Prevented:** Identity data tampering, orphaned-account persistence, excessive integration permissions

#### ClickOps Implementation

**Step 1: Configure IdP Integration**
1. Navigate to: **Integrations** → **Identity Providers**
2. Connect Okta, Microsoft Entra, Google Workspace, etc.
3. Grant read-only access for user data

**Step 2: Configure User Sync**
1. Enable user synchronization
2. Configure group mappings
3. Set sync frequency

**Step 3: Verify MFA Monitoring**
1. Ensure Drata can read MFA status
2. Configure alerts for MFA compliance
3. Review MFA coverage reports

---

### 2.4 Prefer Scoped OAuth Applications Over Long-Lived API Keys

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11, 5.2 |
| NIST 800-53 | IA-5, SC-12 |

#### Description
Authenticate programmatic access to the Drata API with short-lived, per-resource-scoped OAuth application tokens instead of long-lived API keys, using a separate application per environment.

#### Rationale
**Why This Matters:**
- A long-lived API key is a bearer credential with no natural expiry — once leaked in a repository, log, or CI variable it remains usable until someone notices and rotates it
- OAuth applications issue short-lived tokens with per-resource read/create/update/delete scopes, so a leaked token is both time-bounded and limited to the operations it was granted
- A separate application per environment means a compromised non-production credential cannot read or alter production compliance evidence
- Drata itself recommends OAuth applications over API keys for API access

**Attack Prevented:** Leaked-credential replay, over-scoped programmatic access, cross-environment blast radius, stale-key abuse

#### ClickOps Implementation

**Step 1: Create the Application**
1. Navigate to: **Settings** → **OAuth Applications**
2. Create a distinct application per consumer **and** per environment (for example, one for production evidence sync, a separate one for a staging pipeline)

**Step 2: Scope It Down**
1. Grant only the per-resource scopes the consumer needs, choosing read over create, update, or delete wherever the workflow allows
2. Set a custom expiration rather than accepting the longest available lifetime

**Step 3: Handle the Secret Correctly**
1. The client secret is displayed **once at creation** — capture it directly into your secret manager, never into a ticket, chat message, or source file
2. Record the application's owner and purpose so an unexplained application can be identified during review

**Step 4: Review and Retire**
1. Review OAuth applications and any remaining API keys quarterly
2. Delete applications whose consumer is decommissioned
3. Migrate remaining long-lived API-key consumers onto scoped applications

#### Validation & Testing
- Attempt an out-of-scope API call with the issued token and confirm it is rejected.
- Confirm no API key or client secret appears in source control, CI configuration, or logs.

**Source:** [Set Up OAuth for the Drata API](https://help.drata.com/en/articles/13521519-set-up-oauth-for-the-drata-api)

---

### 2.5 Govern Drata MCP Server OAuth Scopes

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3, 5.2 |
| NIST 800-53 | AC-6, AC-6(1) |

#### Description
Restrict the scopes granted to AI clients connecting through Drata's remote MCP server, defaulting to read-only and always setting an expiration date.

#### Rationale
**Why This Matters:**
- Drata's remote MCP server lets an AI client both **query and act on** compliance data — the available scopes include creating and updating Evidence, creating and updating Controls, and updating Personnel
- Write and delete scopes on evidence and control objects are direct authority over the audit record, so an over-scoped or prompt-injected AI client can alter what auditors will rely on
- Effective access is the **intersection** of the granted scope and the connecting user's Drata role, so scope discipline and role discipline ([1.3](#13-implement-role-based-access-control)) must both hold — neither alone is sufficient
- A configuration without an expiration date is a standing grant to an AI client that may outlive the project that justified it

**Attack Prevented:** AI-client compromise or prompt injection escalating into evidence tampering, over-scoped machine access, standing unreviewed automation grants

#### Prerequisites
- Drata operates the MCP server at regional endpoints (`mcp.drata.com`, `mcp-euc1`, `mcp-apse2`); connect clients only to the endpoint matching your data region

#### ClickOps Implementation

**Step 1: Create the Configuration**
1. Navigate to: **Settings** → **MCP OAuth Configuration**
2. Supply a name and a description that identifies the specific AI client and its business purpose

**Step 2: Default to Read-Only**
1. Grant read scopes only, unless a documented workflow genuinely requires the client to write
2. Treat **create/update Evidence**, **create/update Controls**, and **update Personnel** as privileged — approve them individually, with a named owner, and never as a convenience default

**Step 3: Always Set an Expiration**
1. Set an expiration date on every configuration; do not leave it open-ended
2. Re-approve rather than auto-extend when the date arrives

**Step 4: Constrain the Connecting Identity**
1. Connect the MCP client as a user whose Drata role is already least-privileged, since access is the intersection of scope and role
2. Avoid connecting MCP clients as **Admin** or **Information Security Lead**

#### Validation & Testing
- Review **Settings** → **MCP OAuth Configuration** quarterly; every entry must have a named owner, an expiration date, and a justified scope set.
- With a read-only configuration, attempt a write through the MCP client and confirm it is refused.
- Confirm MCP-originated changes are attributable on the Events page ([4.1](#41-review-and-export-the-events-audit-trail)).

**Source:** [Drata MCP Setup & Usage Guide](https://help.drata.com/en/articles/13379899-drata-mcp-setup-usage-guide)

---

## 3. Policy & Control Management

### 3.1 Manage Policy Templates

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | PL-1 |

#### Description
Properly manage policy templates and maintain version control.

#### Rationale
**Why This Matters:**
- Policies are the documented source of truth auditors rely on, so unauthorized or undocumented changes undermine their integrity
- Version history and tracked approvals create an audit trail proving who changed what and when
- Assigned owners and review schedules keep policies current and prevent silent drift out of compliance

**Attack Prevented:** Unauthorized policy tampering, audit-trail gaps, stale or repudiated policy changes

#### ClickOps Implementation

**Step 1: Configure Policies**
1. Navigate to: **Policies**
2. Review pre-built policy templates
3. Customize policies for your organization

**Step 2: Implement Version Control**
1. Use Drata's built-in version history
2. Document policy changes
3. Track policy approvals

**Step 3: Assign Policy Owners**
1. Assign owner to each policy
2. Configure review schedules
3. Track acknowledgments

---

### 3.2 Configure Control Monitoring

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CA-7 |

#### Description
Configure continuous control monitoring for real-time compliance visibility.

#### Rationale
**Why This Matters:**
- Continuous automated tests catch control failures and configuration drift in near real time rather than at audit time
- Mapping controls to integrations replaces point-in-time manual checks with ongoing automated evidence collection
- Assigned owners and remediation deadlines ensure failures are actioned instead of accumulating silently

**Attack Prevented:** Undetected control failure, compliance drift, evidence gaps at audit time

#### ClickOps Implementation

**Step 1: Map Controls**
1. Navigate to: **Controls**
2. Review framework-specific controls
3. Map controls to integrations

**Step 2: Configure Tests**
1. Enable automated tests for controls
2. Configure test frequency
3. Set passing thresholds

**Step 3: Configure Remediation**
1. Assign control owners
2. Configure exception workflows
3. Set remediation deadlines

---

### 3.3 Implement Exception Management

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CA-2 |

#### Description
Properly manage control exceptions and evidence gaps.

#### Rationale
**Why This Matters:**
- Exceptions are deliberate gaps in coverage, and without approval workflows they become unmonitored holes in the program
- Required justification, expiration dates, and compensating controls keep exceptions time-bound and accountable
- Tracked remediation prevents temporary exceptions from quietly becoming permanent, unreviewed risk acceptance

**Attack Prevented:** Unapproved risk acceptance, indefinite control bypass, unmonitored coverage gaps

#### ClickOps Implementation

**Step 1: Configure Exception Workflow**
1. Navigate to: **Settings** → **Workflows**
2. Configure exception approval workflow
3. Set up required approvers

**Step 2: Document Exceptions**
1. Require justification for exceptions
2. Set expiration dates
3. Configure compensating controls

**Step 3: Track Remediation**
1. Monitor exception remediation
2. Send reminders for approaching deadlines
3. Report on exception trends

---

## 4. Monitoring & Auditing

### 4.1 Review and Export the Events Audit Trail

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Use Drata's top-level Events page as the audit trail for workspace activity, and pull events into your own retention tier via the public API, since Drata provides no streaming SIEM connector.

#### Rationale
**Why This Matters:**
- Events records the actor — including Drata's own system processes — with a timestamp, category, originating connection, result, and the raw JSON payload behind each entry, which is what an investigation actually needs to reconstruct a change
- Because system-process actors are logged alongside human ones, Events distinguishes an automated evidence refresh from a person editing control state — the difference between noise and a finding
- Drata offers **no native streaming integration to a SIEM**, so retention beyond the platform and correlation with other telemetry only happen if you build the pull yourself
- Without an owned copy of the trail, a disputed or malicious change to compliance evidence may be unattributable by the time it is noticed

**Attack Prevented:** Undetected evidence tampering, repudiation of control or policy changes, post-incident evidence loss

#### ClickOps Implementation

**Step 1: Review Events**
1. Navigate to: **Events** (top-level page, not nested under Settings)
2. Filter by category, connection, actor, or result to scope an investigation
3. Open an individual event to inspect the raw JSON evidence behind it

**Step 2: Export Individual Events**
1. From an open event, export it as **PDF** or **TXT** for an audit or incident file

**Step 3: Bulk Export via the Public API**
1. Create a **read-scoped** credential for the export job — prefer a scoped OAuth application ([2.4](#24-prefer-scoped-oauth-applications-over-long-lived-api-keys))
2. Pull from the public API's event-data endpoint on a schedule into your log platform
3. Respect the documented rate limit of **500 requests per minute per source IP** when designing the job's paging and retry behavior

> **No native SIEM streaming.** Drata does not offer a push/streaming connector to a SIEM. Any real-time alerting on Drata events must be built on top of a scheduled API pull — plan the collection job and its failure alerting accordingly. — [Get Event Data From Drata](https://help.drata.com/en/articles/7213411-drata-public-api-get-event-data-from-drata)

**Key Events to Monitor:**
- Role assignments and IdP group mapping changes
- Policy modifications and approvals
- Connection (integration) configuration changes
- Control status changes
- Exception approvals
- Account access grants to Drata Support ([1.5](#15-govern-drata-support-remote-access))
- OAuth application and MCP configuration creation or scope changes

#### Validation & Testing
- Make a benign configuration change and confirm it appears in Events with the expected actor, category, and result.
- Confirm the API export job has run inside its expected window and that a gap in collection raises an alert.

**Sources:** [Events Overview](https://help.drata.com/en/articles/13557370-events-overview) · [Drata Public API — Get Event Data From Drata](https://help.drata.com/en/articles/7213411-drata-public-api-get-event-data-from-drata)

---

### 4.2 Configure Alert Notifications

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.11 |
| NIST 800-53 | SI-4 |

#### Description
Configure alerts for compliance and security events.

#### Rationale
**Why This Matters:**
- Alerts turn passive logs into timely signals so control failures and integration outages are noticed immediately
- Routing notifications to owners and escalation paths shortens the window between a failure and its remediation
- Detecting evidence gaps and disconnected integrations early prevents silent compliance degradation

**Attack Prevented:** Delayed incident response, silent integration failure, unnoticed compliance drift

#### ClickOps Implementation

**Step 1: Configure Alerts**
1. Navigate to: **Settings** → **Notifications**
2. Configure alerts for:
   - Control failures
   - Integration disconnections
   - Evidence gaps
   - Policy acknowledgment due

**Step 2: Configure Recipients**
1. Set notification recipients
2. Configure escalation paths
3. Integrate with Slack/Teams

---

### 4.3 Monitor Compliance Dashboard

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.1 |
| NIST 800-53 | CA-7 |

#### Description
Regularly monitor compliance dashboard for drift and issues.

#### Rationale
**Why This Matters:**
- The dashboard surfaces failing controls and posture trends so drift is caught before it becomes an audit finding
- Reviewing trends reveals recurring issues that point to systemic gaps rather than isolated one-off failures
- Maintaining audit-ready evidence and reviewing auditor access reduces scramble and limits exposure during audits

**Attack Prevented:** Compliance drift, recurring control failures, excessive auditor access exposure

#### ClickOps Implementation

**Step 1: Review Dashboard**
1. Navigate to: **Dashboard**
2. Review compliance posture
3. Identify failing controls

**Step 2: Track Trends**
1. Monitor compliance score trends
2. Identify recurring issues
3. Prioritize remediation efforts

**Step 3: Prepare for Audits**
1. Use evidence collection
2. Export audit packages
3. Review auditor access

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Drata Control | Guide Section |
|-----------|---------------|---------------|
| CC6.1 | SSO/MFA | [1.1](#11-configure-sso-authentication) |
| CC6.2 | RBAC | [1.3](#13-implement-role-based-access-control) |
| CC6.3 | Programmatic access scoping | [2.4](#24-prefer-scoped-oauth-applications-over-long-lived-api-keys) |
| CC6.6 | Integration security | [2.1](#21-configure-integrations-with-least-privilege) |
| CC7.2 | Audit trail | [4.1](#41-review-and-export-the-events-audit-trail) |
| CC7.3 | Control monitoring | [3.2](#32-configure-control-monitoring) |
| CC9.2 | Vendor support access | [1.5](#15-govern-drata-support-remote-access) |

### NIST 800-53 Rev 5 Mapping

| Control | Drata Control | Guide Section |
|---------|---------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-sso-authentication) |
| IA-2(1) | MFA (enforced at the IdP) | [1.2](#12-enforce-multi-factor-authentication-at-the-identity-provider) |
| AC-6 | Least privilege | [1.3](#13-implement-role-based-access-control), [2.5](#25-govern-drata-mcp-server-oauth-scopes) |
| AU-2 | Audit trail | [4.1](#41-review-and-export-the-events-audit-trail) |
| CA-7 | Continuous monitoring | [3.2](#32-configure-control-monitoring) |
| IA-5 | Credential management | [2.4](#24-prefer-scoped-oauth-applications-over-long-lived-api-keys) |
| MA-4 | Nonlocal maintenance access | [1.5](#15-govern-drata-support-remote-access) |

---

## Appendix A: References

**Official Drata Documentation:**
- [Drata Help Center](https://help.drata.com/en/)
- [Roles and Permissions Overview (New Experience)](https://help.drata.com/en/articles/13578465-roles-and-permissions-overview-new-experience)
- [Map IdP Groups to Drata Roles](https://help.drata.com/en/articles/15235029-map-idp-groups-to-drata-roles)
- [Single Sign-On Connection](https://help.drata.com/en/articles/5209416-single-sign-on-connection)
- [Signing in to Drata (New Experience)](https://help.drata.com/en/articles/13801611-signing-in-to-drata-new-experience)
- [Settings Page](https://help.drata.com/en/articles/13563975-settings-page)
- [Grant Remote Access to Drata Support](https://help.drata.com/en/articles/13604233-grant-remote-access-to-drata-support)
- [Events Overview](https://help.drata.com/en/articles/13557370-events-overview)
- [System Access Control Policy Guidance](https://help.drata.com/en/articles/7211097-system-access-control-policy-guidance)
- [Platform Overview](https://drata.com/platform)
- [CIS v8.1 Framework Overview](https://help.drata.com/en/articles/11145651-cis-v8-1-framework-overview)

**API & Developer Documentation:**
- [Drata API Documentation](https://developers.drata.com/api-docs/)
- [Set Up OAuth for the Drata API](https://help.drata.com/en/articles/13521519-set-up-oauth-for-the-drata-api)
- [Drata Public API — Get Event Data From Drata](https://help.drata.com/en/articles/7213411-drata-public-api-get-event-data-from-drata)
- [Drata MCP Setup & Usage Guide](https://help.drata.com/en/articles/13379899-drata-mcp-setup-usage-guide)

**Security Incidents:**
- No major public security incidents identified affecting the Drata platform.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass: correct 1.1 (SSO is a WorkOS-brokered Connections-page connection requiring a prior IdP connection; enforcement is implicit), 1.2 (no local MFA toggle — non-SSO login is a passwordless email code, MFA lives at the IdP), 1.3 (New Experience additive role model replacing Owner/Admin/Compliance Manager/Viewer, plus IdP group mapping), and 4.1 (top-level Events page; export via per-event PDF/TXT or read-scoped public API — no native SIEM streaming). Add 1.5 support remote-access governance, 2.4 scoped OAuth applications, 2.5 MCP OAuth scope governance. Purge Trust Center and marketing security page from references. Tier 3/4 research sweep out of scope for this pass (search budget) | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with access controls, integrations, and monitoring | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)

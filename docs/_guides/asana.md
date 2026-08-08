---
layout: guide
title: "Asana Hardening Guide"
vendor: "Asana"
slug: "asana"
tier: "2"
category: "Productivity"
description: "Project management platform hardening for Asana including SAML SSO, admin console controls, and mobile security"
version: "0.2.0"
maturity: "draft"
last_updated: "2026-08-08"
---

## Overview

Asana is a leading project management platform used by **millions of users** for task management, project tracking, and team collaboration. As a repository for project plans and business operations data, Asana security configurations directly impact operational security and data protection.

### Intended Audience
- Security engineers managing project management platforms
- IT administrators configuring Asana Enterprise
- GRC professionals assessing collaboration security
- Organization administrators managing access controls

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Asana Admin Console security including SAML SSO, authentication policies, data protection, and mobile security.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Admin Console Controls](#2-admin-console-controls)
3. [Data Protection](#3-data-protection)
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
Configure SAML SSO to centralize authentication for Asana users.

#### Rationale
**Why This Matters:**
- Routing Asana logins through your corporate IdP enforces MFA, conditional access, and device posture checks on every authentication
- Local Asana password logins bypass IdP controls and are prime targets for credential stuffing and phishing
- Centralized authentication lets you instantly revoke access across all sessions when an employee leaves or a credential is compromised
- Asana holds project plans, roadmaps, and business operations data — a single unprotected login can expose sensitive planning information

**Attack Prevented:** Credential theft, phishing, password reuse, unauthorized access

#### Prerequisites
- A paid Asana plan — SAML SSO and Google SSO are listed as available on Starter, Advanced, Enterprise, and Enterprise+ ([Admin & Security Features](https://asana.com/features/admin-security))
- SAML 2.0 compatible IdP (Okta, Azure AD, Google Workspace)
- Super Admin access

#### ClickOps Implementation

**Step 1: Access Admin Console**
1. Navigate to: **Admin Console** → **Security**
2. Select **Authentication** section
3. Access SSO configuration

**Step 2: Configure SAML Settings**
1. Asana uses HTTP POST binding (not HTTP REDIRECT)
2. Configure IdP with HTTP POST bindings
3. Note: Asana does not support single logout (SLO)

**Step 3: Configure Identity Provider**
1. Create SAML application in IdP
2. Configure attribute mappings
3. Assign users/groups

**Step 4: Enforce SSO**
1. Enable SAML-based SSO
2. Enforce SSO with Google or SAML
3. Set password requirements for fallback

**Time to Complete:** ~1 hour

---

### 1.2 Enforce Two-Factor Authentication

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Require 2FA for all organization members.

#### Rationale
**Why This Matters:**
- A second authentication factor blocks account takeover even when a password is phished, leaked, or reused from another breach
- Without enforced 2FA, any member relying on a password alone is a single weak link into the entire workspace
- Admins and accounts with broad project visibility are high-value targets that warrant phishing-resistant factors
- Project management data and connected integrations increase the blast radius of any single compromised account

**Attack Prevented:** Credential stuffing, password reuse, account takeover, phishing

#### ClickOps Implementation

**Step 1: Enable 2FA Requirement**
1. Navigate to: **Admin Console** → **Security** → **Authentication**
2. Enable **Require two-factor authentication**
3. All members must configure 2FA

**Step 2: Configure via IdP**
1. Enable MFA in your identity provider
2. All SSO users subject to IdP MFA policies
3. Use phishing-resistant methods for admins

**Plan availability:** Two-factor authentication and organization-wide password strength requirements are listed as available on Starter, Advanced, Enterprise, and Enterprise+ — not Enterprise-only ([Admin & Security Features](https://asana.com/features/admin-security)).

---

### 1.3 Configure Session Timeout

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.2 |
| NIST 800-53 | AC-12 |

#### Description
Configure session timeout for security.

#### Rationale
**Why This Matters:**
- Bounded session lifetimes limit how long a stolen or hijacked session token remains usable to an attacker
- Automatic logout protects accounts left open on shared, lost, or unattended devices
- Shorter timeouts reduce the window for session-replay and cookie-theft attacks against active sessions
- Forcing periodic re-authentication ensures revoked or disabled accounts lose access promptly

**Attack Prevented:** Session hijacking, token replay, unattended-device access

#### ClickOps Implementation

**Step 1: Access Session Settings**
1. Navigate to: **Admin Console** → **Security**
2. Find session timeout settings

**Step 2: Configure SAML Session Timeout**
1. Set timeout between 1 hour and 30 days
2. Members automatically logged out after timeout
3. Balance security with usability

**Plan availability:** Session duration limits are listed as available on Starter, Advanced, Enterprise, and Enterprise+ ([Admin & Security Features](https://asana.com/features/admin-security)).

---

### 1.4 Configure SAML Group Mapping

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Use SAML groups for license assignment.

#### Rationale
**Why This Matters:**
- Driving Asana roles and licenses from IdP group membership keeps access decisions in one authoritative source of truth
- Group-based mapping eliminates manual per-user provisioning errors that lead to over-privileged or orphaned accounts
- Access is automatically adjusted when a user changes teams or leaves, enforcing least privilege as roles evolve
- Centralized group control makes access reviews and audits far easier to perform and evidence

**Attack Prevented:** Privilege creep, orphaned access, manual provisioning errors

#### ClickOps Implementation

**Step 1: Configure Group Mapping**
1. Configure IdP to send group claims
2. Map IdP groups to Asana roles
3. Control access via IdP group assignment

**Step 2: Test Mapping**
1. Verify group membership sync
2. Test role assignment
3. Document group mappings

---

## 2. Admin Console Controls

### 2.1 Configure Admin Roles

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement role-based access for administration.

#### Rationale
**Why This Matters:**
- Limiting Super Admin accounts shrinks the number of high-value targets that can reconfigure security settings or export all data
- Least-privilege admin roles ensure team leads can manage their scope without holding org-wide control
- Fewer privileged accounts mean a smaller blast radius if any single admin credential is compromised
- Regular admin review catches stale or unnecessary privileged access before it can be abused

**Attack Prevented:** Privilege escalation, admin account takeover, insider misuse

#### ClickOps Implementation

**Step 1: Review Admin Roles**
1. Navigate to: **Admin Console** → **Members**
2. Review Super Admin accounts
3. Document all administrators

**Step 2: Apply Least Privilege**
1. Limit Super Admins to 2-3 users
2. Use Admin roles for team management
3. Remove unnecessary admin access

**Step 3: Protect Admin Accounts**
1. Require MFA for all admins
2. Monitor admin activity
3. Review access quarterly

**Step 4: Use Custom Roles and Password Policy**
1. Asana lists custom (role-based) admin roles as available on Starter, Advanced, Enterprise, and Enterprise+ — build roles scoped to what each administrator actually needs instead of granting Super Admin ([Admin & Security Features](https://asana.com/features/admin-security))
2. Set the organization-wide password strength requirement, also listed across all paid plans, so members who authenticate with an Asana password rather than SSO are still held to a policy
3. Review custom role definitions on the same cadence as the admin roster — a role that accumulates permissions is as dangerous as an extra Super Admin

---

### 2.2 Configure Domain Management

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Control organization membership through domain management.

#### Rationale
**Why This Matters:**
- Verifying and claiming corporate domains ensures only sanctioned accounts can join the organization under central control
- Domain management prevents shadow accounts created outside IT governance from holding company data
- Claiming existing accounts brings personal or unmanaged sign-ups under enterprise security policy and SSO enforcement
- Restricting membership to trusted domains reduces the risk of unauthorized external users gaining standing access

**Attack Prevented:** Shadow IT, unauthorized account creation, account sprawl

#### ClickOps Implementation

**Step 1: Verify Domains**
1. Navigate to: **Admin Console** → **Settings**
2. Add and verify organization domains
3. Claim existing accounts

**Step 2: Configure Membership Rules**
1. Control who can join organization
2. Configure automatic membership
3. Restrict to corporate domains

---

### 2.3 Configure SCIM Provisioning

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Configure SCIM for automated user lifecycle management.

#### Rationale
**Why This Matters:**
- Automated provisioning and deprovisioning removes departed users immediately, eliminating orphaned accounts with standing access
- SCIM keeps roles and group memberships in sync with the IdP, preventing privilege drift over time
- Removing manual lifecycle steps eliminates human error and delays that leave access active after offboarding
- Centralized lifecycle management produces a consistent, auditable record of who has access and why

**Attack Prevented:** Orphaned-account access, offboarding gaps, privilege drift

#### ClickOps Implementation

**Step 1: Enable SCIM**
1. Navigate to: **Admin Console** → **Apps**
2. Configure SCIM integration
3. Supported: Okta, Microsoft Azure AD

**Step 2: Configure Sync**
1. Automate group setup
2. Synchronize profile updates
3. Enable deprovisioning

**Step 3: Authenticate SCIM With a Service Account**
1. Asana's SCIM implementation authenticates with a Service Account personal access token, and service accounts are available only to organizations on an Enterprise domain ([SCIM](https://developers.asana.com/docs/scim.md))
2. Treat that token as a non-human identity with its own owner, storage, and rotation schedule (see [2.7](#27-govern-service-accounts-as-non-human-identities))
3. Map SCIM Groups to Asana teams so IdP group membership drives team membership rather than manual invitation

**Step 4: Deprovision Deterministically**
1. Deprovisioning is performed either by setting `active` to `false` on the SCIM user or by issuing a SCIM `DELETE` for that user — pick one and make it the documented offboarding path
2. Verify after each offboarding batch that the user is no longer active in Asana rather than assuming the IdP push succeeded
3. Reconcile the SCIM-managed user list against the member roster periodically; users created outside SCIM will not be deprovisioned by it

**Plan availability:** SCIM user provisioning is listed as available on Starter, Advanced, Enterprise, and Enterprise+ ([Admin & Security Features](https://asana.com/features/admin-security)); the service account required to authenticate it is an Enterprise-domain capability.

---

### 2.4 Restrict Access by IP Address

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17, SC-7 |

#### Description
Configure IP allowlisting so Asana is reachable only from your organization's approved networks. Asana lists IP allowlisting as an Enterprise and Enterprise+ capability ([Admin & Security Features](https://asana.com/features/admin-security)).

#### Rationale
**Why This Matters:**
- Network-level restriction blocks a valid but stolen credential when the attacker connects from their own infrastructure, which is where credential-stuffing and phishing follow-on traffic originates
- It is the one control in this guide that does not depend on user behavior, password strength, or whether a member completed 2FA enrollment
- Constraining access to corporate ranges and VPN egress keeps project plans, roadmaps, and connected integration data off the open internet
- Allowlisting narrows the population of sessions an incident responder has to triage, because anything from outside the approved ranges should not exist at all

**Attack Prevented:** Credential reuse from attacker-controlled infrastructure, unauthorized remote access, session establishment from unmanaged networks

#### Prerequisites
- Asana Enterprise or Enterprise+
- Super Admin access
- A stable, documented inventory of corporate egress and VPN IP ranges

#### ClickOps Implementation

**Step 1: Inventory Approved Ranges**
1. Collect every egress range members legitimately connect from: offices, VPN concentrators, and any managed cloud workspace
2. Confirm the ranges are static — dynamic residential addresses cannot be allowlisted safely
3. Record an owner for the list so it is updated when network changes ship

**Step 2: Apply the Allowlist**
1. Configure the IP allowlist in the Asana admin console with the approved ranges
2. Verify access succeeds from an approved range before enforcing broadly
3. Document a break-glass procedure — an allowlist that locks out every administrator during a network change is an outage

**Step 3: Maintain**
1. Review the allowlist whenever network egress changes
2. Remove ranges belonging to decommissioned offices or retired VPN endpoints
3. Re-verify after each change that legitimate access still works

#### Validation & Testing
1. Attempt authentication from an address outside the allowlist and confirm it is refused
2. Confirm authentication from each approved range still succeeds
3. Confirm mobile and integration traffic paths are accounted for, so enforcement does not silently break a sanctioned workflow

#### Compliance Mappings

| Framework | Control | Mapping |
|-----------|---------|---------|
| CIS Controls v8 | 13.5 | Manage access control for remote assets |
| NIST 800-53 Rev 5 | AC-17 | Remote access |
| NIST 800-53 Rev 5 | SC-7 | Boundary protection |
| SOC 2 | CC6.6 | Logical access controls for external users |

---

### 2.5 Control Third-Party Apps and Integrations

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.3, 2.7 |
| NIST 800-53 | CM-7, SA-9, AC-20 |

#### Description
Use Asana's app management to block unapproved integrations and switch to app approval mode, so a member cannot connect a third-party application to organization data without review. App blocking and app approval mode are listed as available on Starter, Advanced, Enterprise, and Enterprise+ ([Admin & Security Features](https://asana.com/features/admin-security)).

#### Rationale
**Why This Matters:**
- An OAuth-connected app holds a durable grant to organization data that survives the connecting user's password change and is not covered by session timeout or 2FA
- Default-allow app connection means the organization's real data perimeter is set by whichever member clicked "Authorize", not by security
- Integration compromise is the supply-chain path into a collaboration platform: the attacker never touches Asana's authentication at all, they compromise a vendor that already holds a token
- Approval mode converts app connection from a silent user action into a reviewable decision with a record of who requested what and why

**Attack Prevented:** Supply-chain compromise via third-party integrations, OAuth token abuse, silent data egress to unvetted vendors, shadow IT

#### Prerequisites
- A paid Asana plan
- Super Admin access
- A defined review path for integration requests

#### ClickOps Implementation

**Step 1: Inventory Connected Apps**
1. Review the applications currently connected to the organization
2. For each, record the business owner, the data it reaches, and whether it is still in use
3. Remove apps with no identifiable owner — an unowned integration is standing access nobody is monitoring

**Step 2: Enable App Approval Mode**
1. Switch app management from default-allow to approval mode so new integrations require administrator action
2. Publish the request path so the change does not simply push members toward unmanaged workarounds
3. Record approval decisions, including denials, as part of the vendor review trail

**Step 3: Block What Fails Review**
1. Block specific applications that fail review rather than relying on members to avoid them
2. Re-review approved apps on a fixed cadence; a vendor's risk profile changes after acquisition or a breach
3. Revoke on offboarding of the app's business owner

#### Validation & Testing
1. Attempt to connect a test application as a non-admin member and confirm it is held for approval rather than connected
2. Confirm a blocked application cannot be connected
3. Reconcile the connected-app list against the approved-app register and investigate any difference

#### Compliance Mappings

| Framework | Control | Mapping |
|-----------|---------|---------|
| CIS Controls v8 | 2.3 | Address unauthorized software |
| CIS Controls v8 | 2.7 | Allowlist authorized scripts and applications |
| NIST 800-53 Rev 5 | CM-7 | Least functionality |
| NIST 800-53 Rev 5 | SA-9 | External system services |
| NIST 800-53 Rev 5 | AC-20 | Use of external systems |
| SOC 2 | CC6.1 | Logical access to third-party integrations is authorized |

---

### 2.6 Govern MCP Server Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.3, 2.7 |
| NIST 800-53 | CM-7, SA-9 |

#### Description
Control which Model Context Protocol clients may connect to Asana. Administrators on Enterprise+ and Legacy Enterprise can allow or block MCP clients individually through app management; organizations on other tiers must have a super admin request access to the beta v1 app through Asana support. The v2 server authenticates with OAuth over Streamable HTTP ([Using Asana's MCP server](https://developers.asana.com/docs/using-asanas-mcp-server.md)).

#### Rationale
**Why This Matters:**
- An MCP client is an AI agent acting with a user's Asana access; unlike a conventional integration it composes its own sequence of reads and writes, so what it will touch is not knowable from the grant alone
- Per-client allow and block is the difference between governing which agents reach organization data and discovering after the fact that any client a member installed could
- Asana's own June 2025 MCP server logic bug exposed project names, task descriptions, and metadata across roughly 1,000 customers' organizations (see Appendix B) — per-client control is the mitigation that did not exist when that bug shipped
- Tiers without per-client control obtain the MCP app only through a super admin support request, which is itself a governance checkpoint worth using deliberately rather than routinely

**Attack Prevented:** Unsanctioned AI agent access to organization data, cross-tenant data exposure through a compromised or buggy MCP client, prompt-injection-driven data egress via an unreviewed agent

#### Prerequisites
- Enterprise+ or Legacy Enterprise for per-client allow/block via app management
- Super Admin access
- A decision on which MCP clients, if any, are sanctioned

#### ClickOps Implementation

**Step 1: Decide the Sanctioned Client List**
1. Determine which MCP clients the organization permits, and treat everything else as denied
2. Apply the same vendor review you would apply to any integration that reads all of a user's accessible content
3. Record the decision and its owner

**Step 2: Enforce Per-Client Control (Enterprise+ / Legacy Enterprise)**
1. Allow or block each MCP client individually through app management
2. Block first and allow explicitly, so a newly released client does not gain access by default
3. Re-review the allow list when a client ships a major version

**Step 3: Control Access on Other Tiers**
1. On tiers without per-client control, access to the beta v1 app requires a super admin to request it through Asana support — do not treat that request as routine
2. Prefer the v2 server, which authenticates with OAuth over Streamable HTTP, so access is a revocable grant rather than a static credential
3. Revoke the grant when the sanctioned use case ends

#### Validation & Testing
1. Confirm a non-sanctioned MCP client cannot connect to the organization
2. Confirm the sanctioned client's grant appears in the connected-app inventory with a named owner
3. Review audit events for app-category activity after enabling a client, and confirm the access pattern matches the intended use

#### Compliance Mappings

| Framework | Control | Mapping |
|-----------|---------|---------|
| CIS Controls v8 | 2.3 | Address unauthorized software |
| CIS Controls v8 | 2.7 | Allowlist authorized applications |
| NIST 800-53 Rev 5 | CM-7 | Least functionality |
| NIST 800-53 Rev 5 | SA-9 | External system services |
| SOC 2 | CC6.1 | Logical access to integrations is authorized |

---

### 2.7 Govern Service Accounts as Non-Human Identities

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 6.2 |
| NIST 800-53 | AC-2, IA-5, AC-6 |

#### Description
Asana service accounts hold the personal access tokens that authenticate SCIM provisioning and the Audit Log API. Inventory them as non-human identities with named human owners, stored secrets, and a rotation schedule. Service accounts require an Enterprise domain ([SCIM](https://developers.asana.com/docs/scim.md), [Audit log events](https://developers.asana.com/docs/audit-log-events.md)).

#### Rationale
**Why This Matters:**
- A service account token authenticates with a bearer credential and no second factor, so it bypasses the SSO and 2FA that protect every human login in this guide
- These specific accounts hold provisioning and audit-retrieval rights — the two capabilities an attacker most wants, because one grants access and the other reveals or conceals what was done with it
- Service accounts have no natural owner and no offboarding event, so without an explicit inventory their tokens outlive the projects and the people that created them
- A token embedded in a SCIM connector or a SIEM collector is readable by everyone who can read that system's configuration, which is a much larger group than the account's nominal owner

**Attack Prevented:** MFA bypass via service-account tokens, orphaned non-human credentials, unauthorized provisioning of accounts, tampering with or suppression of audit collection

#### Prerequisites
- Enterprise domain (required for service accounts)
- Super Admin access
- A secret manager and a credential inventory

#### ClickOps Implementation

**Step 1: Inventory Service Accounts**
1. List every service account and the personal access token issued from it
2. For each, record the named human owner, the consuming system (SCIM connector, SIEM collector), and the issue date
3. Disable service accounts that no system claims

**Step 2: Separate by Purpose**
1. Use distinct service accounts for SCIM provisioning and Audit Log API retrieval so a compromise of the log collector does not also grant provisioning rights
2. Grant each only the access its function requires
3. Never reuse a service account token across environments or vendors

**Step 3: Store and Rotate**
1. Store tokens in the organization's secret manager, never in repositories, connector screenshots, or tickets
2. Rotate on a defined schedule and immediately on owner departure or suspected exposure
3. Plan rotation as a change — replacing a SCIM or audit token without coordination breaks provisioning or log collection silently

#### Validation & Testing
1. Reconcile authenticated API callers against the service-account inventory; an unexplained caller is an unmanaged credential
2. Confirm the previous token no longer authenticates after a rotation
3. Confirm audit collection and SCIM provisioning both still function after each rotation, so a broken pipeline is caught immediately rather than at the next incident

#### Compliance Mappings

| Framework | Control | Mapping |
|-----------|---------|---------|
| CIS Controls v8 | 5.4 | Restrict administrator privileges to dedicated accounts |
| CIS Controls v8 | 6.2 | Establish an access revoking process |
| NIST 800-53 Rev 5 | AC-2 | Account management (including non-human accounts) |
| NIST 800-53 Rev 5 | AC-6 | Least privilege |
| NIST 800-53 Rev 5 | IA-5 | Authenticator management |
| SOC 2 | CC6.1 | Credentials for system accounts are managed |

---

## 3. Data Protection

### 3.1 Configure Sharing Controls

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Control how content is shared inside and outside the organization.

#### Rationale
**Why This Matters:**
- Restricting external sharing prevents project plans and task data from being exposed to unauthorized outside parties
- Controlling guest access limits what non-employees can see and do inside the workspace
- Tight sharing defaults reduce the risk of accidental data leakage through over-broad or public links
- Monitoring and limiting guest activity helps detect and contain misuse of external collaboration

**Attack Prevented:** Data leakage, oversharing, unauthorized external access

#### ClickOps Implementation

**Step 1: Configure External Sharing**
1. Navigate to: **Admin Console** → **Security** → **Sharing**
2. Control sharing outside the organization
3. Restrict as appropriate

**Step 2: Configure Guest Access**
1. Control guest permissions
2. Limit guest capabilities
3. Monitor guest activity

---

### 3.2 Configure Export Controls

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | AC-3 |

#### Description
Control ability to export data from Asana.

#### Rationale
**Why This Matters:**
- Restricting bulk export limits the ability of a compromised or malicious account to exfiltrate large volumes of project data
- Controlling who can export dashboards and reports keeps sensitive aggregated data in authorized hands
- Limiting file attachment types reduces the risk of malware delivery and unwanted data movement
- Export restrictions provide a key control point for data loss prevention and regulatory compliance

**Attack Prevented:** Data exfiltration, bulk data theft, malware delivery via attachments

#### ClickOps Implementation

**Step 1: Configure Export Settings**
1. Navigate to: **Admin Console** → **Security**
2. Restrict dashboard/reporting exports
3. Control who can export data

**Step 2: Configure Attachment Controls**
1. Specify allowable file types
2. Restrict file attachments if needed
3. Control integration access

**Step 3: Connect DLP and CASB**
1. Asana lists DLP integration and CASB integration as available on Enterprise and Enterprise+ ([Admin & Security Features](https://asana.com/features/admin-security)) — connect them so exfiltration is inspected by the same tooling that covers the rest of the estate rather than only by Asana's own export toggles
2. Use the CASB integration to bring Asana session and data activity into the organization's existing visibility and policy plane
3. Use the DLP integration to detect regulated or classified content placed into tasks and attachments, which native export restrictions alone will not catch

---

### 3.3 Configure Mobile Security

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.7 |
| NIST 800-53 | AC-19 |

#### Description
Configure mobile device security settings.

#### Rationale
**Why This Matters:**
- Mobile controls protect Asana data on devices that are easily lost, stolen, or used outside corporate networks
- Enforcing biometric login prevents access from an unlocked or shared device
- Disabling screenshots and copy-paste reduces leakage of sensitive task data to unmanaged apps
- MDM integration such as Intune extends enterprise policy and remote wipe to the mobile app

**Attack Prevented:** Lost-device data exposure, mobile data leakage, unauthorized mobile access

#### ClickOps Implementation

**Step 1: Enable Mobile Controls**
1. Navigate to: **Admin Console** → **Security** → **Mobile**
2. Configure mobile security settings

**Step 2: Configure Restrictions**
1. Enforce biometric login
2. Disable screenshots and copy-paste
3. Restrict file attachments
4. Integrate with Intune on iOS

**Plan availability:** Mobile security controls are listed as available on Advanced, Enterprise, and Enterprise+ — not Enterprise-only ([Admin & Security Features](https://asana.com/features/admin-security)).

---

### 3.4 Govern AI Studio and AI Features

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3, 14.1 |
| NIST 800-53 | AC-3, SA-9, SC-7 |

#### Description
Decide deliberately whether AI Studio is enabled for the organization and understand where the data goes. AI Studio is admin-enabled from the console across Starter through Enterprise+, and Asana states that its AI partners do not train on customer data, are required to delete data after each query, and that AI partner servers are located in the United States ([Asana AI](https://asana.com/product/ai)).

#### Rationale
**Why This Matters:**
- Enabling AI features sends task content — the same project plans and roadmaps the rest of this guide restricts — to a third-party model provider, which is a data-flow decision that belongs to security rather than to whoever discovers the toggle
- Because the setting is admin-controlled, leaving it at its default is itself a choice; there is no state in which the organization has not decided
- The vendor's stated guarantees (no training on customer data, deletion after each query) are the assurances the decision rests on, so they should be recorded in the vendor review rather than assumed
- AI partner servers being located in the United States is a concrete residency consideration for organizations with EU or other regional data-residency obligations, and it applies regardless of where the Asana tenant itself is hosted

**Attack Prevented:** Unreviewed data egress to third-party model providers, data-residency violation, exposure of sensitive project content through AI features enabled without review

#### Prerequisites
- Super Admin access
- A completed data-flow and residency review for the AI partner arrangement

#### ClickOps Implementation

**Step 1: Make the Enablement Decision Explicitly**
1. Determine whether AI Studio is enabled for the organization, and record the decision, its owner, and its date
2. Where AI features are not needed, leave them disabled rather than enabled-and-unused — an unused enabled feature is still an open data path
3. Re-confirm the decision when Asana ships new AI capabilities, since scope can expand under an existing toggle

**Step 2: Record the Vendor Assurances**
1. Capture Asana's stated position in the vendor file: AI partners do not train on customer data, and are required to delete data after each query
2. Note that AI partner servers are located in the United States, and confirm this is compatible with the organization's data-residency commitments before enabling
3. For EU-resident data, treat residency as the deciding factor rather than the training and deletion guarantees alone

**Step 3: Scope What AI Can Reach**
1. AI features operate on the content the invoking user can already see, so the permission work in [3.1](#31-configure-sharing-controls) and [2.1](#21-configure-admin-roles) determines the AI blast radius
2. Tighten over-broad membership before enabling, not after
3. Review AI-related activity in the audit log alongside other access events (see [4.1](#41-configure-audit-logging))

#### Validation & Testing
1. Confirm the organization's AI Studio setting matches the recorded decision
2. Confirm the residency review is on file and current before AI features remain enabled
3. Confirm that a user with restricted project access cannot obtain restricted content through an AI feature

#### Compliance Mappings

| Framework | Control | Mapping |
|-----------|---------|---------|
| CIS Controls v8 | 3.3 | Configure data access control lists |
| CIS Controls v8 | 14.1 | Establish a security awareness program (AI usage expectations) |
| NIST 800-53 Rev 5 | AC-3 | Access enforcement |
| NIST 800-53 Rev 5 | SA-9 | External system services |
| NIST 800-53 Rev 5 | SC-7 | Boundary protection |
| SOC 2 | CC6.1 | Logical access to data processed by third parties |

---

## 4. Monitoring & Compliance

### 4.1 Configure Audit Logging

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Monitor activity through the Asana Audit Log API. The API is authenticated with a Service Account personal access token and retains events for 90 days, so anything the organization needs beyond that window must be exported to a SIEM ([Audit log events](https://developers.asana.com/docs/audit-log-events.md)).

#### Rationale
**Why This Matters:**
- Audit logs provide the visibility needed to detect suspicious activity such as mass exports, permission changes, or unusual logins
- Events are retained for 90 days, so a breach discovered later than that quarter is investigated against data Asana no longer holds — forwarding to a SIEM is what preserves the evidence, not an optional enhancement
- Streaming events to a SIEM enables correlation, alerting, and retention beyond the platform's native window
- Without comprehensive logging, account compromise and insider misuse can go undetected and unattributable
- Detailed records of admin and sharing actions are essential for incident response and compliance evidence

**Attack Prevented:** Undetected compromise, insider misuse, delayed incident response, loss of evidence past the retention window

#### Prerequisites
- A Service Account to authenticate the API (see [2.7](#27-govern-service-accounts-as-non-human-identities))
- A SIEM or log store to receive events

**Plan availability — Tier 1 sources disagree.** Asana's developer documentation states the Audit Log API is available to organizations with Service Accounts on Enterprise+, Legacy Enterprise, or with the Compliance add-on ([Audit log events](https://developers.asana.com/docs/audit-log-events.md)). Asana's Admin & Security Features page lists the audit log API as an Enterprise and Enterprise Plus capability ([Admin & Security Features](https://asana.com/features/admin-security)). Both are first-party statements and both are recorded here rather than silently reconciled; confirm entitlement against your own contract before designing a collection pipeline around it.

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Use the Audit Log API, authenticated with a Service Account personal access token
2. Integrate with a SIEM via the Audit Log API — Asana's Tier 1 documentation describes the API as the integration surface and does not name a specific SIEM product
3. Monitor compliance-related activities

**Step 2: Configure SIEM Integration**
1. Build the collection against the Audit Log API and forward events to the SIEM on a schedule shorter than the 90-day retention window
2. Monitor key events
3. Set up alerting

**Key Event Categories to Monitor** (as documented by Asana):
- Logins
- User updates
- Admin settings
- Roles
- Content export
- Access control
- Apps
- Creation
- Deletion

---

### 4.2 Monitor Security Compliance

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.11 |
| NIST 800-53 | CA-7 |

#### Description
Continuously monitor security posture.

#### Rationale
**Why This Matters:**
- Continuous monitoring surfaces configuration drift and policy gaps before attackers can exploit them
- Reviewing authentication patterns helps detect credential attacks, anomalous logins, and brute-force attempts early
- Regular posture reviews ensure security controls remain enforced as the organization and platform evolve
- Documented monitoring provides ongoing assurance and evidence for audits and compliance frameworks

**Attack Prevented:** Configuration drift, undetected anomalies, control regression

#### ClickOps Implementation

**Step 1: Review Security Dashboard**
1. Access Admin Console security metrics
2. Review authentication patterns
3. Monitor for anomalies

**Step 2: Regular Reviews**
1. Weekly security review
2. Address findings promptly
3. Document security posture

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Asana Control | Guide Section |
|-----------|---------------|---------------|
| CC6.1 | SSO/2FA | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | Admin roles | [2.1](#21-configure-admin-roles) |
| CC6.6 | Session timeout | [1.3](#13-configure-session-timeout) |
| CC6.6 | IP allowlisting | [2.4](#24-restrict-access-by-ip-address) |
| CC6.7 | Mobile security | [3.3](#33-configure-mobile-security) |
| CC6.1 | Third-party app control | [2.5](#25-control-third-party-apps-and-integrations) |
| CC6.1 | MCP client governance | [2.6](#26-govern-mcp-server-access) |
| CC6.1 | Service account governance | [2.7](#27-govern-service-accounts-as-non-human-identities) |
| CC6.1 | AI governance | [3.4](#34-govern-ai-studio-and-ai-features) |
| CC7.2 | Audit logging | [4.1](#41-configure-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | Asana Control | Guide Section |
|---------|---------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | 2FA | [1.2](#12-enforce-two-factor-authentication) |
| AC-2 | SCIM provisioning | [2.3](#23-configure-scim-provisioning) |
| AC-3 | Sharing controls | [3.1](#31-configure-sharing-controls) |
| AC-17 | IP allowlisting | [2.4](#24-restrict-access-by-ip-address) |
| CM-7 | Third-party app control | [2.5](#25-control-third-party-apps-and-integrations) |
| SA-9 | MCP client governance | [2.6](#26-govern-mcp-server-access) |
| IA-5 | Service account governance | [2.7](#27-govern-service-accounts-as-non-human-identities) |
| SA-9 | AI governance | [3.4](#34-govern-ai-studio-and-ai-features) |
| AU-2 | Audit logging | [4.1](#41-configure-audit-logging) |

---

## Appendix A: Plan Compatibility

Per Asana's [Admin & Security Features](https://asana.com/features/admin-security) page:

| Feature | Starter | Advanced | Enterprise | Enterprise+ |
|---------|---------|----------|------------|-------------|
| Admin Console | ✅ | ✅ | ✅ | ✅ |
| SAML SSO | ✅ | ✅ | ✅ | ✅ |
| Google SSO | ✅ | ✅ | ✅ | ✅ |
| Two-factor authentication | ✅ | ✅ | ✅ | ✅ |
| Org-wide password strength | ✅ | ✅ | ✅ | ✅ |
| Session duration limits | ✅ | ✅ | ✅ | ✅ |
| SCIM | ✅ | ✅ | ✅ | ✅ |
| Guest invite restrictions | ✅ | ✅ | ✅ | ✅ |
| Custom (RBAC) roles | ✅ | ✅ | ✅ | ✅ |
| App blocking | ✅ | ✅ | ✅ | ✅ |
| App approval mode | ✅ | ✅ | ✅ | ✅ |
| Mobile security | ❌ | ✅ | ✅ | ✅ |
| IP allowlisting | ❌ | ❌ | ✅ | ✅ |
| DLP integration | ❌ | ❌ | ✅ | ✅ |
| CASB integration | ❌ | ❌ | ✅ | ✅ |
| Audit Log API | ❌ | ❌ | ✅* | ✅* |

*Audit Log API entitlement — Tier 1 sources disagree. The Admin & Security Features page lists it for Enterprise and Enterprise Plus; the [Audit log events](https://developers.asana.com/docs/audit-log-events.md) developer documentation states it requires a Service Account on Enterprise+, Legacy Enterprise, or the Compliance add-on. Both are recorded; confirm against your contract (see [4.1](#41-configure-audit-logging)).

**Not tier-mapped in the table above:**

| Capability | Availability |
|------------|--------------|
| Service accounts | Enterprise domain ([SCIM](https://developers.asana.com/docs/scim.md)) |
| MCP per-client allow/block | Enterprise+ and Legacy Enterprise; other tiers require a super admin support request for the beta v1 app ([Using Asana's MCP server](https://developers.asana.com/docs/using-asanas-mcp-server.md)) |
| AI Studio | Admin-enabled, Starter through Enterprise+ ([Asana AI](https://asana.com/product/ai)) |

---

## Appendix B: References

**Official Asana Documentation:**
- [Admin & Security Features](https://asana.com/features/admin-security) — the plan-by-plan admin and security capability matrix
- [Asana Help Center](https://help.asana.com/s/)
- [Asana AI](https://asana.com/product/ai)
- [Asana Privacy](https://asana.com/privacy)

**Note:** Asana's help center is a JavaScript application whose article URLs could not be verified programmatically during this pass; the console navigation paths in sections 1–3 predate this revision and were left unchanged rather than re-asserted against an unfetchable source.

**API & Developer Tools:**
- [Asana Developer Portal](https://developers.asana.com/)
- [API Reference](https://developers.asana.com/docs)
- [Audit log events](https://developers.asana.com/docs/audit-log-events.md)
- [SCIM](https://developers.asana.com/docs/scim.md)
- [Using Asana's MCP server](https://developers.asana.com/docs/using-asanas-mcp-server.md)
- [Node.js SDK](https://github.com/Asana/node-asana)
- [Python SDK](https://github.com/Asana/python-asana)
- [Java SDK](https://github.com/Asana/java-asana)
- [GitHub Organization](https://github.com/Asana)

**Compliance Frameworks:**
- SOC 2 Type II + HIPAA Assessment (most recent period: February 2024 - January 2025); SOC 3 report publicly available — attested via Asana's trust center, a compliance-attestation surface rather than a hardening document
- ISO 27001:2022, ISO 27017, ISO 27018:2019, ISO 27701:2019 (publicly downloadable) — same source
- GDPR compliance — via [Asana Privacy](https://asana.com/privacy)

**Security Incidents:**
- **June 2025 — MCP Server Data Exposure Bug:** A logic bug in Asana's Model Context Protocol (MCP) server allowed approximately 1,000 customers to potentially see project names, task descriptions, and metadata from other Asana organizations between June 5-17, 2025. This was an internal logic flaw, not an external breach. ([UpGuard Report](https://www.upguard.com/blog/asana-discloses-data-exposure-bug-in-mcp-server)) Administrative mitigation now exists: see [2.6](#26-govern-mcp-server-access) for per-client MCP allow/block on Enterprise+ and Legacy Enterprise.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass against asana.com and developers.asana.com. Corrected the plan matrix (SSO, 2FA, password strength, session limits, SCIM, guest restrictions, custom roles, app blocking/approval are all paid tiers; mobile security is Advanced+). Rewrote 4.1 for the Audit Log API (Service Account PAT auth, 90-day retention, nine documented event categories, SIEM via API rather than a named Splunk integration). Added 2.4 IP allowlisting, 2.5 third-party app control, 2.6 MCP server governance, 2.7 service accounts as non-human identities, and 3.4 AI governance; expanded 2.1 (custom roles/password policy), 2.3 (service-account auth and SCIM deprovisioning), 3.2 (DLP/CASB). Documented the Audit Log API entitlement conflict between two Tier 1 sources as both-with-callout per SOURCES.md. Removed trust-center and security-standards links from Appendix B. Tier 2 (CIS/DISA/CISA SCuBA) publishes no Asana baseline; Tier 3/4 research not surveyed this pass. Help-center nav paths in sections 1–3 were left unchanged — help.asana.com is a JavaScript shell and could not be re-verified. | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, admin controls, and data protection | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)

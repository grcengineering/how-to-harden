---
layout: guide
title: "Notion Hardening Guide"
vendor: "Notion"
slug: "notion"
tier: "2"
category: "Productivity"
description: "Collaboration platform hardening for Notion including SAML SSO, workspace security, DLP, AI and MCP connection governance, and audit logging"
version: "0.2.1"
maturity: ["ai-drafted"]
last_updated: "2026-08-08"
---

## Overview

Notion is a leading collaboration and productivity platform used by **millions of users** for documentation, project management, and knowledge sharing. As a repository for organizational knowledge and sensitive business information, Notion security configurations directly impact data protection and information governance.

### Intended Audience
- Security engineers managing collaboration platforms
- IT administrators configuring Notion Enterprise
- GRC professionals assessing collaboration security
- Workspace administrators managing access controls

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Notion workspace and organization security including SAML SSO, SCIM provisioning, data protection, and workspace permissions.

---

## Table of Contents

1. [Authentication & SSO](#1-authentication--sso)
2. [Organization Security](#2-organization-security)
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
Configure SAML SSO to centralize authentication for Notion users.

#### Rationale
**Why This Matters:**
- Centralizing Notion logins in your corporate IdP applies MFA, conditional access, and session policy to every workspace member from a single control point
- Without SSO, each user keeps a separate Notion password that lives outside IdP oversight and can be phished or reused from a breached service
- Domain-verified SAML ties Notion identities to your authoritative directory so access decisions follow the same governance as the rest of your stack
- Workspaces hold product specs, roadmaps, contracts, and internal knowledge — a single account takeover can expose all of it

**Attack Prevented:** Credential stuffing, phishing, password reuse, MFA bypass

#### Prerequisites
- Notion Business or Enterprise plan
- At least one verified domain
- SAML 2.0 compatible IdP

#### ClickOps Implementation

**Step 1: Verify Domain**
1. Navigate to: **Settings** → **Identity** (Business) or **Organization Settings** → **General** (Enterprise)
2. Add and verify your organization's domain
3. Domain verification required before SSO setup

**Step 2: Access SSO Configuration**
1. For Business: Navigate to **Settings** → **Identity**
2. For Enterprise: Navigate to **Organization Settings** → **General** → **SAML Single sign-on (SSO)**

**Step 3: Configure SAML Settings**
1. Copy the **Assertion Consumer Service (ACS) URL**
2. Enter in your IdP portal
3. Configure IdP with:
   - ACS URL from Notion
   - Entity ID
4. Supported IdPs: Azure, Google, Gusto, Okta, OneLogin, Rippling

**Step 4: Enter IdP Details**
1. Provide either IdP URL or IdP metadata XML
2. Complete configuration
3. Test SSO authentication

**Time to Complete:** ~1 hour

---

### 1.2 Enforce SAML SSO

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3 |
| NIST 800-53 | IA-2 |

#### Description
Require SAML authentication for all workspace members.

#### Rationale
**Why This Matters:**
- Configuring SSO without enforcing it leaves email/password and social logins active as parallel paths that skip IdP controls
- Requiring "Only SAML SSO" closes those bypass routes so every member authenticates through your IdP's MFA and conditional access
- Attackers target the weakest enabled login method; removing alternatives shrinks the authentication attack surface to one governed path
- The deliberate owner email-login exception preserves break-glass recovery without re-opening daily logins to weaker methods

**Attack Prevented:** SSO bypass, credential stuffing, phishing, account takeover via fallback login

#### ClickOps Implementation

**Step 1: Configure Login Method**
1. Navigate to SSO settings
2. Default login method is **Any method**
3. Change to **Only SAML SSO**

**Step 2: Require SAML Authorization for Workspace Access (Enterprise)**
1. Enable **Require SAML SSO authorization for workspace access**
2. This mandates SAML authentication for workspace access *regardless of a user's email domain*, so it does not depend on domain verification and — in Notion's words — "enables safer external collaboration in your workspace"
3. Before enabling, confirm every member exists in your IdP; Notion warns explicitly that missing members are locked out of the workspace

**Step 3: Understand Exceptions**
1. Organization owners can still log in with email and password if the IdP has an outage, so they can modify or disable the SAML configuration
2. Protect those owner accounts accordingly — they are the standing bypass (see 2.3)
3. The configuration can be changed to re-enable other methods, so treat changes to it as an audited event (see 4.1)

#### Validation & Testing
Attempt a login with email/password as a non-owner member and confirm it is refused. Then test with an external collaborator on a non-verified domain and confirm they are routed through SAML — this is the behavior that supersedes the older guidance that external collaborators could not authenticate via SAML SSO. Source: [SAML SSO configuration](https://www.notion.com/help/saml-sso-configuration).

---

### 1.3 Configure SCIM Provisioning

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Configure SCIM for automated user lifecycle management.

#### Rationale
**Why This Matters:**
- Automated provisioning and deprovisioning grants access on hire and revokes it the moment a user is removed from the IdP
- Manual offboarding is slow and error-prone, leaving orphaned accounts that retain standing access to sensitive workspace content
- SCIM keeps Notion group and role membership synchronized with your directory, preventing privilege drift over time
- Suppressing SCIM invite emails lets security control rollout communication rather than auto-notifying every provisioned user

**Attack Prevented:** Orphaned-account access, privilege creep, insider misuse after offboarding

#### ClickOps Implementation

**Step 1: Enable SCIM**
1. Navigate to organization settings
2. Access SCIM provisioning section
3. Generate SCIM API token

**Step 2: Configure IdP SCIM**
1. Add Notion SCIM integration in IdP
2. Enter SCIM endpoint URL
3. Enter API token

**Step 3: Configure Provisioning Settings**
1. Turn on **Suppress invite emails from SCIM provisioning**
2. Control internal rollout communication
3. Test user synchronization
4. Supported IdPs include Okta, OneLogin, Rippling, and custom SCIM applications

**Step 4: Manage Token Hygiene**
1. Generate a **separate SCIM API token for each workspace** you manage via SCIM — tokens are workspace-scoped, not organization-wide
2. Owners can revoke a token at any time; revocation disables the SCIM integration and all provisioning depending on it until an active token replaces it
3. Store tokens as secrets in your existing secret manager, never in IdP notes or runbooks in plaintext

**Replace SCIM tokens BEFORE de-provisioning the admin who created them.** A token created by a workspace owner is automatically revoked when that owner leaves or changes role — Notion then notifies the remaining owners to replace it. If you offboard an admin first, provisioning breaks silently at exactly the moment you are relying on it to remove access. Sequence the change: issue a replacement token, repoint the IdP, verify a test sync, then de-provision the admin. Source: [Provision users and groups with SCIM](https://www.notion.com/help/provision-users-and-groups-with-scim).

#### Validation & Testing
Deactivate a test user in the IdP and confirm the Notion account is deprovisioned. After any admin change, run a sync and confirm it still succeeds rather than assuming it does.

---

## 2. Organization Security

### 2.1 Configure Workspace Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Control who can access workspaces and create accounts.

#### Rationale
**Why This Matters:**
- Restricting allowed email domains keeps workspace membership limited to corporate identities and blocks personal or attacker-controlled addresses
- Disabling automatic account creation prevents anyone who passes SSO from self-provisioning into the workspace without explicit approval
- Uncontrolled joining lets unauthorized or stale accounts accumulate, expanding who can read internal pages and databases
- Regular membership review enforces least privilege and removes users who no longer need access

**Attack Prevented:** Unauthorized account creation, rogue workspace access, membership sprawl

#### ClickOps Implementation

**Step 1: Configure Allowed Email Domains**
1. Navigate to: **Settings** → **General**
2. Configure **Allowed email domains**
3. Restrict to corporate domains only

**Step 2: Disable Automatic Account Creation**
1. Turn off **Automatic account creation**
2. Prevents users from creating accounts through SSO
3. Requires explicit provisioning

**Step 3: Configure Membership**
1. Review workspace membership
2. Remove unauthorized users
3. Apply least privilege

#### Code Implementation

{% include pack-code.html vendor="notion" section="2.1" %}

---

### 2.2 Configure Team Spaces

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Organize content using team spaces for access control.

#### Rationale
**Why This Matters:**
- Team spaces partition content so each team sees only the pages relevant to its function rather than the entire workspace
- Segmentation limits the blast radius of a compromised account to a single team space instead of all organizational knowledge
- Per-space sharing and export restrictions let sensitive teams such as legal, finance, and HR apply tighter controls than the default
- Without segmentation, broad default membership exposes confidential content to every member by accident

**Attack Prevented:** Lateral movement, over-broad data exposure, accidental cross-team disclosure

#### ClickOps Implementation

**Step 1: Create Team Spaces**
1. Organize by team or function
2. Configure team space permissions
3. Limit membership appropriately

**Step 2: Configure Team Space Security**
1. Enable security settings per team space
2. Configure sharing restrictions
3. Apply export controls selectively

---

### 2.3 Limit Admin Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Minimize and protect workspace owner accounts.

#### Rationale
**Why This Matters:**
- Workspace owners hold the highest privilege — they control SSO, security settings, membership, and export policy for the entire org
- Minimizing owners to a small, documented set reduces the number of high-value accounts an attacker can target for full takeover
- Excess admin accounts are often dormant and unmonitored, making them ideal footholds for privilege escalation
- Assigning regular users the member role enforces least privilege and keeps administrative power scoped to those who need it

**Attack Prevented:** Admin account takeover, privilege escalation, unauthorized configuration changes

#### ClickOps Implementation

**Step 1: Inventory Workspace Owners**
1. Navigate to: **Settings** → **People**
2. Review workspace owners
3. Document all administrators

**Step 2: Apply Least Privilege**
1. Limit workspace owners to 2-3 users
2. Use member roles for regular users
3. Remove unnecessary admin access

---

## 3. Data Protection

### 3.1 Configure Sharing Controls

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3 |

#### Description
Control how content can be shared internally and externally.

#### Rationale
**Why This Matters:**
- Default "Anyone with link" and public-page settings can silently expose internal content to the open internet and search engines
- Constraining guest permissions and link sharing ensures content is shared only with explicitly authorized people
- Auditing and disabling unneeded public pages closes accidental data leaks that bypass authentication entirely
- Notion pages frequently contain customer data, credentials, and strategy docs that must never be reachable by an anonymous link

**Attack Prevented:** Data leakage, unauthorized external access, public exposure of confidential pages

#### ClickOps Implementation

**Step 1: Configure Guest Access**
1. Navigate to: **Settings** → **Members**
2. Configure guest permissions
3. Limit guest capabilities

**Step 1b: Turn Guests Off Entirely (Enterprise)**
1. Enterprise workspace owners can enable **Disable guests**, which blocks external invitations outright — the cleanest control where external collaboration is not a business requirement
2. Where guests are occasionally needed, owners can instead allow members to send **guest invite requests**, converting ad-hoc external sharing into a reviewable request rather than a silent grant
3. Source: [Notion Enterprise security provisions](https://www.notion.com/help/guides/notion-enterprise-security-provisions)

**Step 2: Configure Public Pages**
1. Control who can publish pages publicly
2. Audit existing public pages
3. Disable if not needed

**Step 3: Configure Link Sharing**
1. Set default sharing permissions
2. Restrict "Anyone with link" access
3. Require explicit permissions

#### Code Implementation

{% include pack-code.html vendor="notion" section="3.1" %}

---

### 3.2 Disable Moving and Duplicating Pages to Other Workspaces

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | AC-3 |

#### Description
Turn on **Disable moving or duplicating pages to other workspaces** so members cannot relocate or copy pages into personal or external workspaces.

#### Rationale
**Why This Matters:**
- Page duplication to external or personal workspaces lets members copy sensitive content outside organizational control
- **Move to** is the path most policies miss: moving a page relocates the original rather than copying it, so a duplication-only control leaves the higher-impact action open
- Disabling both removes a low-friction exfiltration path that bypasses sharing and export restrictions
- Content moved or copied out leaves the source workspace's governance, making the loss hard to detect and impossible to revoke

**Attack Prevented:** Data exfiltration, content theft, unauthorized data movement out of the workspace

**Correction (2026-08): the setting is named "Disable moving or duplicating pages to other workspaces."** Earlier revisions of this guide referred to "Disable duplicating pages," which understates the control — the real setting also covers the **Move to** action. Source: [Notion Enterprise security provisions](https://www.notion.com/help/guides/notion-enterprise-security-provisions).

#### ClickOps Implementation

**Step 1: Enable the Control**
1. Navigate to: **Settings** → **Security**
2. Turn on **Disable moving or duplicating pages to other workspaces**
3. This blocks both the copy path and the move path out of the workspace

**Step 2: Review Exceptions**
1. Document any business need for moving or duplicating content externally
2. Consider enabling per team space if needed
3. Monitor for policy violations in the audit log (4.1)

#### Validation & Testing
As a test member, open a page's `•••` menu and confirm both **Duplicate to** and **Move to** offer no destination outside the workspace.

---

### 3.3 Configure Export Controls

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | AC-3 |

#### Description
Control ability to export content from Notion.

#### Rationale
**Why This Matters:**
- Bulk export to PDF, HTML, or Markdown can extract entire workspaces in a single action, a classic mass-exfiltration vector
- Disabling export by default and enabling it only where needed limits who can pull content out of Notion
- Reviewing export logs surfaces unusual or bulk activity that may signal a compromised account or departing insider
- Without export controls, a single compromised member can offload large volumes of intellectual property undetected

**Attack Prevented:** Mass data exfiltration, insider data theft, intellectual property loss

#### ClickOps Implementation

**Step 1: Configure Export Settings**
1. Navigate to: **Settings** → **Security**
2. Turn on **Disable export**
3. Enable only in team spaces that need it

**Step 2: Audit Export Activity**
1. Review export logs
2. Monitor for unusual patterns
3. Investigate bulk exports

---

### 3.4 Connect a Data Loss Prevention Provider

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.13 |
| NIST 800-53 | SI-4, AC-4, SC-7(10) |

#### Description
On Enterprise, connect a supported DLP provider so page and file content is scanned automatically for sensitive data — PII, PHI, and credentials — with detection and remediation handled outside Notion's own permission model. Notion documents **Nightfall AI** as available, with **Polymer** listed as coming soon.

#### Rationale
**Why This Matters:**
- Permission and sharing controls govern *who* can reach a page; they say nothing about *what* someone pasted into it — secrets and regulated data land in Notion pages routinely
- Automated scanning finds credentials committed into runbooks and PII pasted into project pages long before an audit or a breach would
- Automated remediation shortens exposure time compared with a quarterly manual review of a workspace that grows daily
- DLP is the control that makes broad internal sharing survivable: it addresses the content risk that team-space segmentation (2.2) does not

**Attack Prevented:** Credential exposure in workspace content, regulated-data (PII/PHI) sprawl, undetected sensitive-data accumulation, secondary compromise from secrets stored in documentation

#### Prerequisites
- Notion Enterprise plan
- A subscription with the DLP provider
- Workspace owner / organization owner role

#### ClickOps Implementation

**Step 1: Select and Connect the Provider**
1. Confirm which supported provider your organization uses — Nightfall AI is the currently available integration
2. As an organization owner, connect the provider from the Enterprise security settings
3. Authorize the connection with the scope the provider requires

**Step 2: Define Detection and Remediation Policy**
1. Configure the detectors that match your obligations (PII, PHI, payment data, API keys and other credentials)
2. Decide the remediation action per detector — alert, redact, or restrict — rather than accepting the provider default everywhere
3. Route alerts to the same queue that handles your other DLP findings, not to a Notion-only inbox

#### Validation & Testing
Paste a synthetic detector-triggering string (a test credential pattern) into a scratch page and confirm the provider raises a finding and applies the configured remediation. Source: [Notion Enterprise security provisions](https://www.notion.com/help/guides/notion-enterprise-security-provisions).

---

### 3.5 Govern Notion AI Settings

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3, CM-7, SC-7 |

#### Description
Review and set the workspace-level Notion AI controls under **Settings → Notion AI**: whether workspace data is shared to improve Notion AI, which AI Connectors to third-party apps are enabled, whether AI may make web requests and whether those requests require confirmation, which models members may use, image generation, and AI Meeting Notes audio and transcript retention.

#### Rationale
**Why This Matters:**
- AI features read workspace content to answer; the data-sharing toggle determines whether that content also feeds product improvement, which is a procurement and privacy decision, not a user preference
- AI Connectors extend Notion AI's reach into other systems (Slack, Google Drive and similar), so each connector widens the blast radius of a compromised Notion account beyond Notion
- Web search lets AI send workspace-derived context outbound; **Require confirmation for web requests** is the control that keeps a human in that loop
- AI Meeting Notes generate audio recordings and transcripts — durable, highly sensitive artifacts whose retention must be set deliberately rather than left at default
- Some models must be enabled by a workspace admin before members can select them, so the model roster is an admin decision that should follow your third-party AI review

**Attack Prevented:** Unintended workspace-content sharing for model improvement, outbound data leakage via AI web requests, over-broad AI reach into connected SaaS, indefinite retention of meeting audio and transcripts, use of models outside the approved roster

#### Prerequisites
- Workspace owner role
- Business or Enterprise plan for image generation

#### ClickOps Implementation

**Step 1: Set the Data-Sharing Posture**
1. Navigate to: **Settings** → **Notion AI**
2. Set **Share data to improve Notion AI** according to your data-handling policy — decide this explicitly rather than inheriting the default

**Step 2: Constrain External Reach**
1. Review each configured **AI Connector** to third-party apps and remove those without a business justification
2. Set **Enable web search for workspace** deliberately
3. Turn on **Require confirmation for web requests** so outbound requests are not silent

**Step 3: Govern Models and Generation**
1. Review which models are enabled for the workspace — certain models require workspace-admin enablement in Settings before members can select them
2. Enable or disable image generation (available on Business and Enterprise)
3. Review agent personalization settings (name, appearance, custom instructions) as part of the same review

**Step 4: Bound AI Meeting Notes Retention**
1. Configure audio storage and transcript deletion for AI Meeting Notes
2. Align the retention window with your recording and records-retention policy, not with the platform default

#### Validation & Testing
As a test member, trigger an AI action requiring a web request and confirm the confirmation prompt appears; then create an AI meeting note and confirm the audio and transcript are removed on the configured schedule. Sources: [Notion AI FAQs](https://www.notion.com/help/notion-ai-faqs), [Notion Agent](https://www.notion.com/help/notion-agent).

---

### 3.6 Govern Agent and MCP Connections

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3, 6.8 |
| NIST 800-53 | AC-3, AC-6, CM-7, SA-9 |

#### Description
Restrict which AI apps and MCP clients members may connect to the workspace, maintain the approved list, and keep human confirmation on non-read-only tools. Notion operates a remote MCP server it hosts, and agents acting through it carry the connecting user's full permissions.

#### Rationale
**Why This Matters:**
- Notion is explicit that an agent's reach equals the user's: "Notion Agent has the same permissions you do. If you can't view or edit specific content, your Agent can't either" — and for MCP, "MCP tools act with your full Notion permissions—they can access everything you can access." An over-permissioned user becomes an over-permissioned agent
- Because agents inherit permissions verbatim, least privilege at the user level (2.3) is what actually bounds agent capability; there is no separate agent permission ceiling to fall back on
- Without an approved list, any member can wire an arbitrary external AI client into the workspace, creating an unreviewed egress path for everything that member can read
- Notion states that custom MCP servers have not been reviewed by Notion — a workspace owner enabling one is accepting third-party risk on the organization's behalf
- Prompt-injected content in a page can steer an agent; keeping confirmation on non-read-only tools ensures an injected instruction cannot silently write, delete, or share

**Attack Prevented:** Data exfiltration through unapproved AI clients and MCP servers, prompt-injection-driven agent actions, over-broad agent access inherited from over-privileged users, unreviewed third-party tooling reaching workspace content

#### Prerequisites
- Enterprise plan for the approved-list restriction
- Workspace owner role

#### ClickOps Implementation

**Step 1: Restrict Which AI Apps Can Connect (Enterprise)**
1. Navigate to: **Settings** → **Connections** → **Permissions**
2. Under AI apps, set **Restrict AI apps members can connect** to **Only from approved list**
3. Use **Manage approved AI apps** and **Add approved AI apps** to curate that list — Notion blocks every call from any AI app or MCP client not on it
4. Use **Disconnect All Users** to revoke MCP connections workspace-wide during an incident

**Step 2: Keep Confirmation On**
1. Notion defaults to requesting human confirmation for tool calls on all non-read-only tools — leave that default in place
2. Where an agent only needs to read, enable only read-only tools for it

**Step 3: Scope Each Agent Narrowly**
1. Create agents for specific purposes rather than one agent with access to everything, and avoid granting unnecessary page or database access
2. Review each agent's enabled tools and resources after adding a connection, and disable what it does not need
3. Add only servers you trust; research the provider before integrating, and treat custom MCP servers as unreviewed by Notion

#### Validation & Testing
As a non-owner member, attempt to connect an AI client that is not on the approved list and confirm the connection is blocked. Then exercise a non-read-only tool through an approved agent and confirm the confirmation prompt appears. Sources: [Notion MCP](https://www.notion.com/help/notion-mcp), [Security best practices for agent connections](https://www.notion.com/help/security-best-practices-for-agent-connections), [Notion MCP (developer docs)](https://developers.notion.com/docs/mcp).

---

### 3.7 Manage API Connections and Integrations

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3, 6.8 |
| NIST 800-53 | AC-3, CM-7, SA-9 |

#### Description
On Enterprise, restrict which API connections members may install, maintain an approved connections list, review who has each connection installed, and control which pages a connection can reach and who may connect or disconnect it.

#### Rationale
**Why This Matters:**
- An installed connection holds a durable token to workspace content and keeps reading it long after the person who installed it stops paying attention
- An approved connections list converts integration adoption from a per-member decision into a reviewed organizational one
- Being able to see every member who has a given connection installed is what makes a vendor-compromise response tractable — you can enumerate and disconnect rather than guess
- Page-level access control keeps a connection scoped to the content it needs instead of the whole workspace
- Deciding whether all members or only workspace owners may manage a connection's page access prevents quiet scope expansion after approval

**Attack Prevented:** Supply-chain compromise via third-party integrations, shadow-IT connections, over-broad integration access to workspace content, unrevoked integration access after vendor incidents

#### Prerequisites
- Notion Enterprise plan for the restriction and approved list
- Workspace owner role

#### ClickOps Implementation

**Step 1: Restrict and Curate**
1. Navigate to: **Settings** → **Connections** → **Manage**
2. Restrict which connections members are allowed to install
3. Build and maintain the approved connections list

**Step 2: Review Installations**
1. For each connection, view all members who have it installed
2. Disconnect members from connections that are unused, unapproved, or belong to a vendor with an open security issue

**Step 3: Scope Page Access**
1. For each connection, select the specific pages it may access
2. Choose whether **all workspace owners and members** or only **Workspace owners** can manage that connection's page access — prefer owners-only for connections touching sensitive content

#### Validation & Testing
As a member, attempt to install a connection outside the approved list and confirm it is blocked. Then confirm an approved connection can only reach the pages you selected. Source: [Add and manage connections with the API](https://www.notion.com/help/add-and-manage-connections-with-the-api).

---

## 4. Monitoring & Compliance

### 4.1 Configure Audit Logging

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Enable and monitor the Notion audit log — available to organization owners on the Enterprise plan — and stream its events to a SIEM via custom webhook or a supported partner integration.

#### Rationale
**Why This Matters:**
- Audit logs provide the authoritative record of who did what and when across the organization's Notion activity
- Monitoring provisioning, permission changes, exports, and SSO configuration changes enables timely detection of misuse
- The log now includes a dedicated **Workers** event family covering agent and worker creation, deployment, runs, and secrets — the only telemetry that shows what automated actors did on your behalf (see 3.6)
- Exporting audit events to a SIEM correlates Notion activity with the rest of the security stack for centralized alerting, and preserves history beyond Notion's retention window

**Attack Prevented:** Undetected breaches, insider misuse, configuration tampering without accountability, unmonitored agent and worker activity

**Correction (2026-08): the audit log is not under Analytics, and its history has two hard boundaries.** The path is **Settings → Admin → Audit log**, reached from the workspace switcher — earlier revisions of this guide pointed at "Organization Settings → Analytics." Two limits matter operationally: history is retained up to **365 days**, and events are only recorded **from the date the organization upgraded to Enterprise** — there is no backfill of prior activity. Exports also capture data up to roughly two hours before the request. Treat regular export or streaming as the mechanism that preserves anything you need beyond a year. Source: [Audit log](https://www.notion.com/help/audit-log).

#### Prerequisites
- Notion Enterprise plan
- Organization owner role

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Open the workspace switcher → **Settings** → **Admin** section → **Audit log**
2. Filter by date, person or agent, event type, or related activity
3. Export as CSV (filters apply to the export) on a schedule if you are not streaming

**Step 2: Monitor Key Events**
1. Page events and teamspace events
2. Workspace events — including SSO and security configuration changes
3. Account events — provisioning, deprovisioning, and role changes
4. **Workers events** — agent/worker creation, deployment, runs, and secrets
5. Form events and data source events
6. Content exports and sharing changes

**Step 3: Stream to a SIEM**
1. Configure event streaming to your SIEM — Notion publishes partner guidance for **Splunk**, **Sumo Logic**, **Panther**, and **Datadog**
2. For anything else, use custom webhook streaming: one webhook endpoint per workspace, JSON payloads containing metadata only (never page content), with up to seven retry attempts over roughly 24 hours
3. Note that syslog is not supported — webhook delivery is the only streaming transport
4. Alert on delivery failure: with a single endpoint per workspace and a bounded retry window, a broken receiver loses events permanently

#### Validation & Testing
Trigger a known auditable action (a permission change, then an export) and confirm it appears in the audit log and arrives at the SIEM endpoint within your expected latency. Verify the retry behavior by taking the receiver offline briefly and confirming redelivery.

---

### 4.2 Configure Analytics

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | CA-7 |

#### Description
Use analytics to monitor workspace activity.

#### Rationale
**Why This Matters:**
- Workspace analytics reveal usage patterns that establish a behavioral baseline for normal activity
- Tracking guest access and sharing trends helps spot anomalous behavior such as sudden spikes in external sharing
- Reviewing member activity surfaces dormant or compromised accounts that deviate from expected patterns
- Analytics complement audit logs by turning raw events into trends that drive proactive security review

**Attack Prevented:** Undetected anomalous activity, unmonitored guest and sharing abuse, slow incident detection

#### ClickOps Implementation

**Step 1: Access Analytics**
1. Navigate to organization analytics
2. Review workspace usage
3. Monitor member activity

**Step 2: Review Security Metrics**
1. Track guest access patterns
2. Monitor sharing activity
3. Identify unusual behavior

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Notion Control | Guide Section |
|-----------|----------------|---------------|
| CC6.1 | SSO/SAML | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | Workspace permissions | [2.3](#23-limit-admin-access) |
| CC6.6 | Access controls | [2.1](#21-configure-workspace-access) |
| CC6.7 | Export controls | [3.3](#33-configure-export-controls) |
| CC7.2 | Audit logging | [4.1](#41-configure-audit-logging) |

### NIST 800-53 Rev 5 Mapping

| Control | Notion Control | Guide Section |
|---------|----------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| AC-2 | SCIM provisioning | [1.3](#13-configure-scim-provisioning) |
| AC-3 | Sharing controls | [3.1](#31-configure-sharing-controls) |
| AC-6 | Least privilege | [2.3](#23-limit-admin-access) |
| AU-2 | Audit logging | [4.1](#41-configure-audit-logging) |

---

## Appendix A: Plan Compatibility

| Feature | Free | Plus | Business | Enterprise |
|---------|------|------|----------|------------|
| SAML SSO (1.1) | ❌ | ❌ | ✅ | ✅ |
| Require SAML SSO authorization for workspace access (1.2) | ❌ | ❌ | ❌ | ✅ |
| SCIM (1.3) | ❌ | ❌ | ❌ | ✅ |
| Domain Verification | ❌ | ❌ | ✅ | ✅ |
| Export Controls (3.3) | ❌ | ❌ | ✅ | ✅ |
| Disable guests / guest invite requests (3.1) | ❌ | ❌ | ❌ | ✅ |
| DLP provider connection (3.4) | ❌ | ❌ | ❌ | ✅ |
| Notion AI image generation (3.5) | ❌ | ❌ | ✅ | ✅ |
| Restrict AI apps to approved list (3.6) | ❌ | ❌ | ❌ | ✅ |
| Restrict connections / approved connections list (3.7) | ❌ | ❌ | ❌ | ✅ |
| Audit Logs + SIEM streaming (4.1) | ❌ | ❌ | ❌ | ✅ |

**Note:** Audit log events are recorded only from the date the organization upgraded to Enterprise, and history is retained up to 365 days (see 4.1).

---

## Appendix B: References

**Official Notion Documentation:**
- [Help Center](https://www.notion.com/help)
- [Security Practices](https://www.notion.com/help/security-and-privacy)
- [Enterprise Security Provisions](https://www.notion.com/help/guides/notion-enterprise-security-provisions)
- [SAML SSO Configuration](https://www.notion.com/help/saml-sso-configuration)
- [Provision Users with SCIM](https://www.notion.com/help/provision-users-and-groups-with-scim)
- [Audit log](https://www.notion.com/help/audit-log)
- [Add and manage connections with the API](https://www.notion.com/help/add-and-manage-connections-with-the-api)
- [Notion MCP](https://www.notion.com/help/notion-mcp)
- [Security best practices for agent connections](https://www.notion.com/help/security-best-practices-for-agent-connections)
- [Notion AI FAQs](https://www.notion.com/help/notion-ai-faqs)
- [Notion Agent](https://www.notion.com/help/notion-agent)
- [Managing Organization in Notion](https://www.notion.com/help/guides/everything-about-setting-up-and-managing-an-organization-in-notion)

**API Documentation:**
- [Notion API Reference](https://developers.notion.com/)
- [Notion MCP (developer docs)](https://developers.notion.com/docs/mcp)

**Compliance Frameworks:**
- [HIPAA compliance and configuration guidance](https://www.notion.com/help/hipaa) — BAA eligibility requires the Enterprise plan; Notion may not be used to communicate with patients, plan members, or their families or employers

**Security Incidents:**
- No major breaches of Notion infrastructure identified. In 2025, security researchers disclosed prompt injection risks in Notion AI agents that could enable data exfiltration via crafted workspace content (CVE-2024-23745 also affected Notion Web Clipper 1.0.3). These are configuration and feature-level risks, not infrastructure compromises.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.1 | draft | Add first Code Packs (api, Notion REST API): 2.1 workspace-membership audit flagging members outside allowed email domains (GET /v1/users, requires user information capability), 3.1 published-page audit via the page object's public_url field (POST /v1/search) — both verified against developers.notion.com; wire Code Implementation includes into 2.1 and 3.1. SCIM pack skipped: base URL/endpoints/pagination are documented in the SCIM help article but the auth header mechanics are not, failing the verification bar; audit-log pull skipped: no documented REST endpoint (webhook streaming only) | Claude Code (Fable 5) |
| 2026-08-08 | 0.2.0 | draft | Currency pass: corrected the audit log path to Settings → Admin → Audit log with 365-day retention and no pre-upgrade backfill (was "Organization Settings → Analytics"), corrected 3.2 to the real setting name "Disable moving or duplicating pages to other workspaces", and replaced the stale "guests cannot use SAML SSO" note with the Enterprise "Require SAML SSO authorization for workspace access" option; added 3.4 DLP provider connections, 3.5 Notion AI admin settings, 3.6 agent/MCP connection governance, 3.7 API connection governance; added Workers audit events and SIEM webhook streaming to 4.1, guest disablement to 3.1, and SCIM token-hygiene sequencing to 1.3; rebuilt Appendix A and removed Trust Center / marketing sources from Appendix B (HIPAA claim rehomed to Notion's HIPAA configuration guidance). Notion's Privacy & Security category lists further articles (prompt-injection protections, custom-agent security, data residency, dormant accounts) not yet cited — their slugs must be discovered before citing, as a guessed slug 404'd. Tier 2: no CIS Benchmark, DISA STIG, or CISA SCuBA baseline exists for Notion (confirmed zero). Tier 3/4: not surveyed in this pass. | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | draft | Initial guide with SSO, organization security, and data protection | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)

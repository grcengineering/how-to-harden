---
layout: guide
title: "Miro Hardening Guide"
vendor: "Miro"
slug: "miro"
tier: "4"
category: "Productivity"
description: "Visual collaboration security for board sharing, app governance, classification guardrails, and AI controls"
version: "0.2.0"
maturity: "draft"
last_updated: "2026-08-08"
---


## Overview

Miro is a visual collaboration platform for whiteboards, diagrams, and design sessions. REST API, OAuth integrations, and public board sharing handle sensitive planning documents and architecture diagrams. Compromised access exposes strategic planning, product roadmaps, and internal processes.

### Intended Audience
- Security engineers managing collaboration tools
- Miro team administrators
- GRC professionals assessing visual collaboration security
- Third-party risk managers evaluating design tool integrations


### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries


### Scope
This guide covers Miro security configurations including authentication, access controls, and integration security.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Board & Content Security](#2-board--content-security)
3. [Integration Security](#3-integration-security)
4. [Monitoring & Detection](#4-monitoring--detection)

---

## 1. Authentication & Access Controls

### 1.1 Enforce SSO with MFA

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-2(1)

#### Description
Require SAML SSO with enforced multi-factor authentication for all Miro access, or 2FA where SSO is unavailable, so every login is brokered through the corporate identity provider. SAML SSO is available on both the **Business** and **Enterprise** plans and is configured by a Company Admin.

#### Rationale
**Why This Matters:**
- Centralizes Miro authentication in the corporate IdP, enforcing MFA and conditional access on every login
- Local password logins bypass IdP controls and are prime targets for credential stuffing and phishing
- Enforced SSO lets you deprovision departed users centrally, eliminating orphaned accounts with standing board access
- Boards hold architecture diagrams, roadmaps, and strategic planning — a single compromised login can expose all of it

**Attack Prevented:** Credential theft, phishing, MFA bypass, password reuse, orphaned-account access

**Enabling SSO removes the alternate login paths.** Miro documents that once SSO is enabled, "other login options will be disabled for users, including standard login + password, Google, Facebook, Slack, AppleID and O365." Existing sessions keep working until they expire or the user logs out, so plan the cutover around session expiry rather than expecting an instant change. Source: [Single sign-on (SSO)](https://help.miro.com/hc/en-us/articles/360017571414-Single-sign-on-SSO) (content verified via the vendor's help-center API, 2026-08).

**Who is actually forced through SSO:** SSO login is required for users on domains listed in your SSO settings. In an Enterprise organization, users on *verified* domains become managed users who must authenticate with SSO; users on unverified domains in the same organization still authenticate with email and password. Verify every domain you intend to govern, and use domain control (Enterprise) to restrict which teams those managed users can reach.

#### ClickOps Implementation

**Step 1: Configure SAML SSO (Business and Enterprise)**
1. Navigate to: **Company Settings → Security → SAML SSO**
2. Configure your SAML IdP using Miro's metadata
3. Verify each domain whose users must be governed by SSO
4. Enable: **Enforce SSO**

**Step 2: Add Additional Identity Providers (Enterprise only)**
1. Multi-IdP configuration is an Enterprise-only capability — Business plans support a single IdP
2. Navigate to: **Company Settings → Security → SAML SSO**
3. Add each additional provider and map its domains

**Step 3: Enable 2FA (Non-SSO)**
1. Navigate to: **Company Settings → Security**
2. Enable: **Require 2FA**

---

### 1.2 Team Access Controls

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-3, AC-6

#### Description
Define least-privilege team roles (Admin, Member, Guest) and configure member permissions and guest access policies so users receive only the board access their function requires.

#### Rationale
**Why This Matters:**
- Role separation limits how much any single account can do, containing the blast radius if it is compromised
- Unrestricted Admin or Member rights let any user reshare or export sensitive boards
- Scoping guests to specific boards confines external collaborators instead of exposing the whole team space
- Periodic review of roles catches privilege creep and stale guest access that should have been revoked

**Attack Prevented:** Privilege escalation, lateral movement, excessive access, insider data exposure

#### ClickOps Implementation

**Step 1: Define Team Roles**

| Role | Permissions |
|------|-------------|
| Admin | Full team management |
| Member | Create/edit boards |
| Guest | Board-specific access |

**Step 2: Configure Team Settings**
1. Navigate to: **Team Settings**
2. Configure member permissions
3. Set guest access policies

---

### 1.3 Enforce Idle Session Timeout

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-11, AC-12

#### Description
Enable Miro's Idle Session Timeout so inactive members and guests are automatically logged out of their Miro profile and must re-authenticate — through SSO where SSO is enforced — before reaching Enterprise board data. Enterprise plan, Company Admin.

#### Rationale
**Why This Matters:**
- Miro sessions persist indefinitely by default; an abandoned tab on an unlocked or shared device stays fully authenticated to every board the user can reach
- Automatic logoff bounds the window in which a stolen session cookie or a walk-up attacker can act
- The timeout applies to guests as well as members, closing the gap where external collaborators hold the longest-lived sessions
- Combined with enforced SSO, timeout forces re-authorization through the IdP, so revoked IdP access actually takes effect on live sessions

**Attack Prevented:** Session hijacking, unattended-device access, stolen-cookie replay, lingering access after IdP revocation

#### ClickOps Implementation

**Step 1: Enable the Timeout**
1. Navigate to: **Company settings → Security → Authentication → Idle Session Timeout**
2. Toggle on: **Automatically log out inactive users**
3. Set the **Timeout limit**

**Step 2: Choose a Defensible Duration**
1. First activation populates a 1-day default; the allowed range is 1 hour to 14 days (custom integer 1–9999 with minutes/hours/days units)
2. Miro recommends no less than 8 hours — shorter values log users out mid-board and drive workarounds
3. Note that inactivity means no mouse movement, clicks, or keystrokes anywhere in the app; users get a warning several minutes before logout
4. Where a user belongs to multiple organizations with different intervals, the shortest duration wins

#### Validation & Testing
Sign in as a test member, leave the session untouched past the configured limit, and confirm the warning appears and the session terminates. Source: [Idle Session Timeout](https://help.miro.com/hc/en-us/articles/360017571454-Idle-Session-Timeout) (content verified via the vendor's help-center API, 2026-08).

---

### 1.4 Automate Provisioning and Deprovisioning with SCIM

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-2, AC-2(1)

#### Description
Configure SCIM between your identity provider and Miro so accounts and group membership are created, updated, and deactivated automatically from the directory of record. Enterprise plan, set up by Company Admins; SAML SSO must already be working before SCIM is configured.

#### Rationale
**Why This Matters:**
- Manual offboarding leaves orphaned Miro accounts with standing access to boards long after the user left the organization
- SCIM-driven deactivation removes access at the same moment the IdP does, closing the gap between HR offboarding and tool offboarding
- Group synchronization keeps Miro user groups aligned with directory structure, preventing the privilege drift that manual membership edits create
- Miro's newer model maps a SCIM group to a Miro **user group** (not a team), so a single synced group can carry board and Space sharing across multiple teams

**Attack Prevented:** Orphaned-account access, privilege creep, delayed offboarding, unmanaged membership sprawl

#### Prerequisites
- Enterprise plan
- SAML SSO configured and functional
- Company Admin role

#### ClickOps Implementation

**Step 1: Enable SCIM**
1. Confirm SAML SSO is configured and working
2. In the admin console, generate the SCIM credentials for your organization
3. Migrate to the user-group synchronization model if you are still on the legacy team-mapped model

**Step 2: Configure the IdP**
1. Add the Miro SCIM application in your IdP (Okta and Entra ID have first-party guides)
2. Enable provisioning, updates, and **deactivation** — deactivation is the control that matters here
3. Optionally link IdP groups to Miro user groups for sharing and @mentions

#### Validation & Testing
Deactivate a test user in the IdP and confirm the corresponding Miro account loses access. Note Miro's SCIM email-change guardrails: updates are rejected with a 400 error when the current or target domain is claimed by a different organization. Source: [SCIM](https://help.miro.com/hc/en-us/articles/37593868431378-SCIM) (content verified via the vendor's help-center API, 2026-08).

---

## 2. Board & Content Security

### 2.1 Configure Sharing Defaults

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AC-21

#### Description
Control board sharing to prevent data exposure.

#### Rationale
**Attack Scenario:** Public boards containing architecture diagrams indexed by search engines; competitive intelligence exposed.

**Why This Matters:**
- Public and "anyone with the link" boards are reachable without authentication and can be indexed by search engines
- Default-open sharing leaks sensitive diagrams the moment a board is created, before anyone reviews permissions
- Domain restrictions keep boards inside the organization and block accidental external sharing
- Disabling public boards forces every share decision through an authenticated, auditable path

**Attack Prevented:** Unauthenticated data exposure, search-engine indexing of internal diagrams, competitive intelligence leakage, accidental oversharing

#### ClickOps Implementation

**Step 1: Disable Public Sharing**
1. Navigate to: **Company Settings → Security → Board sharing**
2. Disable: **Allow public boards**
3. Review existing public boards

**Step 2: Configure Default Permissions**
1. Set default share settings
2. Restrict external access
3. Configure domain restrictions

---

### 2.2 Board Copying and Export Controls

**Profile Level:** L2 (Walk)
**NIST 800-53:** AC-21

#### Description
Restrict who can copy and export board content — in particular whether non-team members (visitors and guests) may copy at all — and set a restrictive default for newly created boards, so board content cannot be duplicated or extracted outside Miro's access controls.

#### Rationale
**Why This Matters:**
- Copies and exports create offline duplicates that escape Miro's sharing permissions, audit logging, and revocation
- Allowing non-team members to copy hands visitors and guests a one-click path to take internal design content with them
- Setting the *default* copying permission for new boards closes the window where a freshly created board is permissive before anyone reviews it
- Restricting copying reduces the value of a compromised or over-shared board, since access cannot be turned into portable files

**Attack Prevented:** Data exfiltration, bulk content extraction, insider data theft, loss of access control over copied content

**Correction (2026-08): there is no "Export restrictions" or high-resolution export limit under Company Settings → Security.** The real control is the per-team **Copying Content** setting in the Admin Console, which governs copying *and* exporting of boards and content. Earlier revisions of this guide described a setting that does not exist. Source: [How to allow or restrict copying and exporting boards and content](https://help.miro.com/hc/en-us/articles/360018350399-How-to-allow-or-restrict-copying-and-exporting-boards-and-content) (content verified via the vendor's help-center API, 2026-08).

#### ClickOps Implementation

**Step 1: Set Team-Level Copying Permissions**
1. Navigate to: **Admin Console → Teams**
2. Click the row for **{Team name}**, then open the **Settings** tab
3. Scroll to **Content Security**
4. For **Copying Content**, specify whether only team members — or anyone in the organization — can copy board content
5. Set **Default setting for copying content** for newly created boards (settings save automatically)

**Step 2: Understand the Downstream Effect**
1. When non-team members are not allowed to copy, the **Anyone with board access** option disappears from individual board sharing settings, so visitors and guests cannot copy
2. Board owners and co-owners can still tighten (but not loosen beyond the admin setting) copying on a board via **Share → Sharing settings → Who can copy board content**
3. On Free plans, copying is enabled by default and cannot be modified — this control requires Starter or above

#### Validation & Testing
As a guest on a board, open **Share → Sharing settings** and confirm the copy option is absent; then attempt a copy and confirm it is blocked.

---

### 2.3 Classify Boards and Enforce Guardrails

**Profile Level:** L3 (Run)
**NIST 800-53:** RA-2, AC-16, AC-21

#### Description
Use Miro data classification to label boards by sensitivity, enable auto-classification and Microsoft Purview label import where applicable, and — with the Enterprise Guard add-on — attach Intelligent Guardrails so classified boards automatically lose the ability to be shared publicly, replicated, processed by Miro AI, or reached through the Miro MCP server.

#### Rationale
**Why This Matters:**
- Classification labels alone are advisory: Miro documents that a label "has no impact on the board sharing settings," so labels without guardrails do not stop anything
- Intelligent Guardrails turn a classification into enforcement — automatically restricting sharing at public, team, and organization level and blocking content replication on sensitive boards
- The **Block Miro AI usage** and **Block Miro MCP Access** guardrails close the newest exposure path, where AI agents and programmatic MCP clients read classified board content without the sharing controls applying
- Auto-classification and Purview label import keep coverage current instead of relying on every board owner to label correctly

**Attack Prevented:** Over-sharing of sensitive boards, content replication out of controlled boards, AI/agent exfiltration of classified content via Miro AI or MCP, drift between Miro labels and enterprise data classification

#### Prerequisites
- Enterprise plan for data classification (Company Admin role)
- Enterprise Guard add-on for Intelligent Guardrails, auto-classification, and MCP/AI blocking

#### ClickOps Implementation

**Step 1: Set Up Classification Labels**
1. Navigate to: **Admin Console → Settings → Classification** (with Enterprise Guard: **Settings → Enterprise Guard → Classification**)
2. Select **Set up classification** to activate labels for the organization
3. Select **Edit classification levels** to customize the four default labels or **Add level** (up to 30), setting Level, Name, Description, Badge color, and an optional **Link to guidelines**
4. Set a default label for all new boards, then click **Publish** — changes stay in draft until published

**Step 2: Define Guardrails**
1. In the Enterprise Guard settings, define guardrails per classification level: restrict sharing (public / team / organization), restrict content replication, **Block Miro AI usage**, **Block Miro MCP Access**
2. Choose the rollout mode: default mode leaves active sharing on existing boards untouched; **Apply guardrails in strict mode** overrides all active sharing options and can immediately remove access for some users
3. Configure auto-classification rules and, where you use Microsoft Purview, import Purview sensitivity labels so Miro classification follows the enterprise scheme

#### Validation & Testing
Classify a test board at your most restrictive level, then attempt to share it publicly, duplicate it, and invoke Miro AI on it — each should be blocked. Boards created before the feature was enabled show as not classified, so treat pre-existing boards as an explicit remediation backlog. Sources: [Data classification](https://help.miro.com/hc/en-us/articles/4417739162258-Data-classification), [Intelligent Guardrails overview](https://help.miro.com/hc/en-us/articles/14375998880018-Intelligent-Guardrails-overview), [Import Microsoft Purview sensitivity labels](https://help.miro.com/hc/en-us/articles/22161930709010-Import-Microsoft-Purview-sensitivity-labels) (content verified via the vendor's help-center API, 2026-08).

---

## 3. Integration Security

### 3.1 Manage Apps

**Profile Level:** L1 (Crawl)
**NIST 800-53:** CM-7

#### Description
Audit installed Miro apps, remove unused integrations, and require admin approval before new apps can be installed so third-party access to boards is reviewed and minimized.

#### Rationale
**Why This Matters:**
- Installed apps receive OAuth access to board content and can read or export data on a user's behalf
- Unvetted or abandoned apps expand the attack surface and may hold excessive permissions
- Requiring admin approval prevents users from granting third parties access without review
- Removing unused apps eliminates standing integration access that could be abused if the vendor is compromised

**Attack Prevented:** Malicious or over-permissioned OAuth apps, supply-chain compromise, unauthorized data access, shadow-IT integrations

**Correction (2026-08): app governance is plan-split, and the admin-approval workflow is Enterprise-only.** Below Enterprise, Team Admins get exactly one lever — whether non-admin team members may install apps at all. There is no approved-apps allowlist and no request/approval queue on Starter or Business, so "require admin approval" is not achievable there; the honest control on those plans is to disable non-admin installation and have an admin install a vetted set. Organization-level app management, the company-approved list, pre-adding/preauthorizing apps, and the App Request flow all require Enterprise. Sources: [App management](https://help.miro.com/hc/en-us/articles/4404659741458-App-management), [How to install apps](https://help.miro.com/hc/en-us/articles/360017731093-How-to-install-apps), [App request flow](https://help.miro.com/hc/en-us/articles/4592785249810-App-request-flow) (content verified via the vendor's help-center API, 2026-08).

#### ClickOps Implementation

**Step 1: Audit Installed Apps**
1. Navigate to: **Team settings → Apps & Integrations** for team-installed apps (Business and Enterprise)
2. Navigate to: **Company settings → Apps and integrations → Apps** for the organization view (Enterprise)
3. Review every installed app and its permissions; uninstall what is unused

**Step 2: Restrict Who Can Install (Business and Enterprise)**
1. As a Team Admin, configure whether non-admin team members are allowed to install apps
2. Note the coupled behavior: non-admin users cannot uninstall apps if they are not allowed to install them

**Step 3: Build an Approved-Apps List (Enterprise only)**
1. Navigate to: **Company settings → Apps and integrations → Apps → Manage apps**
2. Toggle on **Restrict members to add apps** so only company-approved apps can be added
3. Pre-add and preauthorize the approved set for all teams or specific teams
4. Review pending requests at **Company settings → Apps and integrations → Apps → App Requests** — all Company Admins are emailed on each request, and approving a request approves the app for other users too

#### Validation & Testing
As a non-admin test user, attempt to install an unapproved Marketplace app. On Enterprise with the restriction enabled, the install should convert into a request; on Business with non-admin installs disabled, it should be blocked outright.

---

### 3.2 API Token Security

**Profile Level:** L1 (Crawl)
**NIST 800-53:** IA-5

#### Description
Audit and revoke personal access tokens, review authorized OAuth apps, limit token scopes, and rotate credentials periodically to control programmatic access to Miro.

#### Rationale
**Why This Matters:**
- Access tokens are long-lived credentials that bypass interactive login and MFA if they leak
- Over-scoped tokens grant far more API access than the integration needs, widening the impact of a leak
- Unused or unrotated tokens accumulate as forgotten standing access that attackers can reuse
- Periodic rotation and revocation limit how long a stolen token remains valid

**Attack Prevented:** Token theft and replay, over-privileged API access, credential leakage via code or logs, persistent unauthorized access

**Prefer expiring access tokens.** Miro's OAuth documentation states that Miro recommends expiring access tokens: by default an access token is valid for 60 minutes and is issued with a refresh token valid for 60 days, and each refresh returns a new access token plus a new refresh token, resetting the 60-day window. The non-expiring token model does not age out on its own, so a leaked non-expiring token stays usable until someone notices and revokes it. Build integrations on the expiring model and treat any surviving non-expiring token as a rotation backlog item. Source: [Getting started with OAuth 2.0](https://developers.miro.com/docs/getting-started-with-oauth).

#### Implementation

**Step 1: Manage Access Tokens**
1. Navigate to: **Profile → Apps & integrations**
2. Audit personal access tokens
3. Revoke unused tokens

**Step 2: OAuth App Security**
1. Review authorized apps
2. Grant the minimum scopes the integration actually needs
3. Rotate tokens periodically, and migrate any non-expiring tokens to the expiring model

**Step 3: Watch the High-Impact Scopes**
1. Several Miro scopes grant capabilities that no control in this guide otherwise constrains — treat a grant of any of them as a privileged-access decision:

| Scope | What it grants | Availability |
|-------|----------------|--------------|
| `sessions:delete` | Ends all active Miro sessions across devices for a user | Enterprise |
| `boards:export` | Exports boards across the organization as PDF with comments and talktrack | Enterprise |
| `contentlogs:export` | Exports all activity on all boards in the organization | Enterprise Guard |
| `organizations:cases:management` | Accesses case and legal-hold information for eDiscovery | Enterprise Guard |
| `auditlogs:read` | Reads the organization's audit events (see 4.1) | Enterprise |

2. Review which registered apps hold these scopes and remove them where the integration's function does not require them

Source: [Permission scopes](https://developers.miro.com/docs/scopes).

---

### 3.3 Scope Miro AI Capabilities

**Profile Level:** L2 (Walk)
**NIST 800-53:** CM-7, AC-3

#### Description
Use the Miro AI admin controls in the Admin Console to decide which AI capability categories exist in the organization and who may use them — Everyone, No one, or Specific teams — and, where the Enterprise Guard or AI Workflows add-on is present, to make that decision per individual feature rather than per category.

#### Rationale
**Why This Matters:**
- AI capabilities read board content to produce their output, so enabling them broadly widens who and what can process sensitive diagrams and roadmaps
- Category-level and feature-level scoping lets you enable low-risk capabilities (for example text editing) while removing higher-risk ones, instead of an all-or-nothing decision
- Restricting to **Specific teams** confines AI processing to teams whose boards you have already reviewed, which is the practical way to pilot AI without exposing regulated content
- Admins can view which models power each AI feature, which is the input a third-party-risk review actually needs

**Attack Prevented:** Uncontrolled AI processing of sensitive board content, shadow AI usage inside sanctioned tooling, over-broad feature rollout without review

#### Prerequisites
- Enterprise plan, Company Admin role
- Enterprise Guard or Miro AI Workflows add-on for per-feature (rather than per-category) control

#### ClickOps Implementation

**Step 1: Set Capability Scope**
1. Navigate to: **Admin Console → Miro AI → Capabilities**
2. For each capability, choose **Everyone**, **No one** (confirm with **Remove access**), or **Specific teams** (select teams, then **Save**)
3. Note that **Everyone** overrides any team-level restriction, and deactivating all capabilities disables **Create with AI** on the board

**Step 2: Apply Per-Feature Control (add-on)**
1. Turn on the **Applied per feature** option for a capability
2. Enable or remove individual features inside the category — for example enable **Create images with AI** while disabling **Remove background**

**Step 3: Pair with Classification**
1. Where boards are classified, use the **Block Miro AI usage** guardrail (see 2.3) so classified content is excluded from AI interaction regardless of the capability scope

#### Validation & Testing
As a member of a team excluded from a capability, confirm the corresponding AI entry point is unavailable on a board. Sources: [Miro AI admin controls](https://help.miro.com/hc/en-us/articles/32486862599442-Miro-AI-admin-controls), [Miro AI granular admin controls](https://help.miro.com/hc/en-us/articles/27016283682578-Miro-AI-granular-admin-controls) (content verified via the vendor's help-center API, 2026-08).

---

## 4. Monitoring & Detection

### 4.1 Audit Logs (Enterprise)

**Profile Level:** L1 (Crawl)
**NIST 800-53:** AU-2, AU-3

#### Description
Enable Miro Enterprise audit logs, review activity events, and forward them to a SIEM so security-relevant actions across boards and the team space are recorded and monitored.

#### Rationale
**Why This Matters:**
- Audit logs provide the evidence trail needed to detect misuse, investigate incidents, and meet compliance requirements
- Without centralized logging, account compromise, mass sharing, or bulk exports go unnoticed
- SIEM forwarding enables alerting on anomalous activity in near real time instead of after the fact
- Retained logs support forensic reconstruction of what an attacker accessed or changed

**Attack Prevented:** Undetected account compromise, insider misuse, delayed breach detection, gaps in forensic evidence

**The audit API only reaches back 90 days — scheduled export is mandatory, not optional.** Miro's Enterprise audit logs endpoint "retrieves a page of audit events from the last 90 days"; anything older must come from a CSV export taken while it was still in window. A retention policy longer than 90 days therefore cannot be satisfied by querying the API on demand — you need a scheduled pull into the SIEM or archive. Source: [Get audit logs (Enterprise)](https://developers.miro.com/reference/enterprise-get-audit-logs).

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Navigate to: **Company Settings → Security → Audit logs**
2. Review activity events
3. Export CSV for any period you need beyond the API's 90-day window

**Step 2: Automate Export to the SIEM**
1. Register an app and grant the `auditlogs:read` scope (Enterprise)
2. Schedule a pull against the Enterprise audit logs endpoint on a cadence well inside 90 days — a daily or weekly job, not an ad-hoc query
3. Alert on job failure: a silently broken export means events age out of the API permanently

#### Detection Focus
- **Export-pipeline gaps:** alert when the scheduled audit pull returns zero events or fails, since the 90-day ceiling makes a lapsed job an unrecoverable evidence loss
- **Sharing and copying spikes:** bursts of board-share or content-copy events, especially involving guests or non-team members (see 2.2)
- **App and token activity:** new app installs, app approvals, and personal-token creation — correlate against the approved-apps list from 3.1
- **Authentication anomalies:** SSO configuration changes, 2FA disablement, and logins from users on unverified domains who bypass SSO enforcement

---

## Appendix A: Edition Compatibility

Miro's current plan tiers are **Free**, **Starter**, **Business**, and **Enterprise** — there is no "Team" plan. Verified against [Miro pricing](https://miro.com/pricing/), 2026-08.

| Control | Free | Starter | Business | Enterprise |
|---------|------|---------|----------|------------|
| SAML SSO (1.1) | ❌ | ❌ | ✅ | ✅ |
| Multiple identity providers (1.1) | ❌ | ❌ | ❌ | ✅ |
| Idle Session Timeout (1.3) | ❌ | ❌ | ❌ | ✅ |
| SCIM provisioning (1.4) | ❌ | ❌ | ❌ | ✅ |
| Domain control | ❌ | ❌ | ❌ | ✅ |
| Copying/export permissions (2.2) | ❌ | ✅ | ✅ | ✅ |
| Data classification (2.3) | ❌ | ❌ | ❌ | ✅ |
| Intelligent Guardrails / auto-classification (2.3) | ❌ | ❌ | ❌ | Enterprise Guard add-on |
| Team-level app management (3.1) | ❌ | ❌ | ✅ | ✅ |
| Approved-apps list + App Request flow (3.1) | ❌ | ❌ | ❌ | ✅ |
| Miro AI admin controls (3.3) | ❌ | ❌ | ❌ | ✅ |
| Per-feature Miro AI control (3.3) | ❌ | ❌ | ❌ | Enterprise Guard / AI Workflows add-on |
| Audit logs + audit API (4.1) | ❌ | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official Miro Documentation:**
- [Miro Help Center](https://help.miro.com/hc/en-us)
- [Single sign-on (SSO)](https://help.miro.com/hc/en-us/articles/360017571414-Single-sign-on-SSO)
- [Idle Session Timeout](https://help.miro.com/hc/en-us/articles/360017571454-Idle-Session-Timeout)
- [SCIM](https://help.miro.com/hc/en-us/articles/37593868431378-SCIM)
- [How to allow or restrict copying and exporting boards and content](https://help.miro.com/hc/en-us/articles/360018350399-How-to-allow-or-restrict-copying-and-exporting-boards-and-content)
- [Data classification](https://help.miro.com/hc/en-us/articles/4417739162258-Data-classification)
- [Intelligent Guardrails overview](https://help.miro.com/hc/en-us/articles/14375998880018-Intelligent-Guardrails-overview)
- [Import Microsoft Purview sensitivity labels](https://help.miro.com/hc/en-us/articles/22161930709010-Import-Microsoft-Purview-sensitivity-labels)
- [App management](https://help.miro.com/hc/en-us/articles/4404659741458-App-management)
- [How to install apps](https://help.miro.com/hc/en-us/articles/360017731093-How-to-install-apps)
- [App request flow](https://help.miro.com/hc/en-us/articles/4592785249810-App-request-flow)
- [Miro AI admin controls](https://help.miro.com/hc/en-us/articles/32486862599442-Miro-AI-admin-controls)
- [Miro AI granular admin controls](https://help.miro.com/hc/en-us/articles/27016283682578-Miro-AI-granular-admin-controls)
- [Enterprise Guard Deployment Guide](https://help.miro.com/hc/en-us/articles/17120515162386-Enterprise-Guard-Deployment-Guide-Introduction)
- [Miro pricing (plan tiers and feature matrix)](https://miro.com/pricing/)

Miro's help center returns HTTP 403 to non-browser fetchers. Every `help.miro.com` article above was content-verified through Miro's own first-party help-center API (`help.miro.com/api/v2/help_center/...`, published non-draft article bodies) in 2026-08; the human-readable article URLs are cited here.

**API Documentation:**
- [Miro Developer Portal](https://developers.miro.com/)
- [Miro REST API Reference](https://developers.miro.com/reference)
- [Getting started with OAuth 2.0](https://developers.miro.com/docs/getting-started-with-oauth)
- [Permission scopes](https://developers.miro.com/docs/scopes)
- [Get audit logs (Enterprise)](https://developers.miro.com/reference/enterprise-get-audit-logs)

**Compliance Frameworks:**
- [Miro security and compliance FAQ](https://help.miro.com/hc/en-us/articles/360012346599-Miro-security-and-compliance-FAQ) — current certification scope

**Security Incidents:**
- No major public security incidents identified for Miro as of this revision.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-08 | 0.2.0 | draft | Currency pass: corrected SAML SSO to Business+Enterprise (multi-IdP Enterprise-only), corrected 2.2 to the real Copying Content control (no "Export restrictions" setting exists), corrected 3.1 app governance plan split (no allowlist below Enterprise), corrected plan tiers (no "Team" plan; domain control Enterprise-only); added 1.3 Idle Session Timeout, 1.4 SCIM, 2.3 classification + Intelligent Guardrails, 3.3 Miro AI admin controls; added 90-day audit-API window and Detection Focus content; added expiring-OAuth-token guidance and high-impact scope table; rebuilt Appendix A and removed Trust Center / marketing sources from Appendix B. help.miro.com articles 403 non-browser fetchers and were content-verified via Miro's first-party help-center API. Tier 2: no CIS Benchmark, DISA STIG, or CISA SCuBA baseline exists for Miro (confirmed zero). Tier 3/4: not surveyed in this pass. | Claude Code (Opus 5) |
| 2026-06-29 | 0.1.1 | draft | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-12-14 | 0.1.0 | draft | Initial Miro hardening guide | Claude Code (Opus 4.5) |

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)

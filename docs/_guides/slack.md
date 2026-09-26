---
layout: guide
title: "Slack Hardening Guide"
vendor: "Slack"
slug: "slack"
tier: "1"
category: "Productivity"
description: "Enterprise security hardening for Slack workspaces, SSO, DLP, and data governance"
version: "0.3.0"
maturity: ["ai-drafted"]
last_updated: "2026-09-25"
---

## Overview

Slack is used by over **750,000 organizations** worldwide for business communication, with Enterprise Grid serving large enterprises requiring centralized security controls. As a repository of sensitive business communications, intellectual property, and credentials shared in messages, Slack security is critical for preventing data breaches and maintaining compliance.

### Intended Audience
- Security engineers managing Slack Enterprise deployments
- IT administrators configuring workspace security
- GRC professionals assessing collaboration tool compliance
- Third-party risk managers evaluating Slack integrations

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries (HIPAA, FINRA, FedRAMP)

### Scope
This guide covers Slack workspace and Enterprise Grid security configurations including SSO/SAML, data loss prevention, retention policies, app management, and external collaboration controls.

---

## Table of Contents

1. [Authentication & Access Controls](#1-authentication--access-controls)
2. [Network Access Controls](#2-network-access-controls)
3. [OAuth & Integration Security](#3-oauth--integration-security)
4. [Data Security](#4-data-security)
5. [Monitoring & Detection](#5-monitoring--detection)
6. [Third-Party Integration Security](#6-third-party-integration-security)
7. [Compliance Quick Reference](#7-compliance-quick-reference)

---

## 1. Authentication & Access Controls

### 1.1 Enable SAML Single Sign-On (SSO)

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.3, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Configure SAML-based SSO to authenticate Slack users through your corporate identity provider (Okta, Azure AD, OneLogin, Ping Identity). This centralizes authentication and enables MFA enforcement through your IdP.

#### Rationale
**Why This Matters:**
- Centralizes authentication management
- Enables Conditional Access, MFA, and risk-based policies
- Automatic deprovisioning when users leave the organization
- Eliminates standalone Slack passwords

**Attack Prevented:** Credential theft, password reuse, orphaned accounts

#### Prerequisites
- Slack Business+ or Enterprise plan (also Free and Pro when a Salesforce org is connected to Slack)
- SAML 2.0 compatible identity provider
- Workspace Owner (Business+) or Org Owner (Enterprise) access -- Org Admins can only manage SSO exclusions

#### ClickOps Implementation

**Step 1: Access SSO Settings**
1. **Business+:** click **Admin** in the sidebar → **Workspace settings** → **Security** → **SSO & authentication**, then next to **An identity provider or custom SAML** click **Configure SAML**
2. **Enterprise:** click your **organization name** in the sidebar → hover **Tools & settings** → **Organization settings** → **Security** → **SSO Settings**
3. See [Manage single sign-on settings](https://slack.com/help/articles/220403548-Manage-single-sign-on-settings)

**Step 2: Configure SAML Provider**
1. Enter your Identity Provider details:
   - **SAML SSO URL:** Your IdP's SSO endpoint
   - **Identity Provider Issuer:** IdP entity ID
   - **Public Certificate:** X.509 certificate from IdP
2. Configure options:
   - **Sign AuthnRequest:** Yes (recommended)
   - **Service Provider Issuer:** Your Slack workspace URL

**Step 3: Configure IdP (Example: Okta)**
1. In Okta Admin Console: **Applications** → **Add Application** → Search "Slack"
2. Configure SAML settings using Slack's metadata
3. Assign users/groups to the Slack application
4. Enable SCIM provisioning for automatic user management

**Step 4: Enforce SSO**
1. **Business+:** return to **SSO & authentication** and click **Edit** next to **Require SSO authentication**
2. **Enterprise:** in **SSO Settings**, keep **SSO member exclusions** and **SSO guest exclusions** to documented break-glass accounts only
3. Required SSO prevents password-based sign-in for everyone it covers

**Time to Complete:** ~1 hour (depending on IdP complexity)

#### Code Implementation

{% include pack-code.html vendor="slack" section="1.1" %}

#### Validation & Testing
**How to verify the control is working:**
1. Attempt to sign in - should redirect to IdP
2. Verify MFA prompt from IdP
3. Confirm password-only sign-in is blocked
4. Test user deprovisioning from IdP removes Slack access

**Expected result:** All users authenticate via SSO with MFA enforced by IdP

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | IA-2 | Identification and authentication |
| **ISO 27001** | A.9.4.2 | Secure log-on procedures |
| **HIPAA** | 164.312(d) | Person or entity authentication |

---

### 1.2 Configure SCIM User Provisioning

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Enable SCIM (System for Cross-domain Identity Management) to automatically provision and deprovision Slack users based on your identity provider directory.

#### Rationale
**Why This Matters:**
- Automatic user lifecycle management
- Immediate deprovisioning when employees leave
- Eliminates orphaned accounts
- Reduces manual administration

**Attack Prevented:** Orphaned account abuse, unauthorized access after termination

#### Prerequisites
- Slack Business+ or Enterprise plan (also Free and Pro when a Salesforce org is connected to Slack) -- see [Manage members with SCIM provisioning](https://slack.com/help/articles/212572638-Manage-members-with-SCIM-provisioning)
- SCIM-compatible identity provider with a Slack provisioning connector (Okta, Microsoft Entra, OneLogin, PingFederate, PingOne, or Google Workspace)
- Org Owner/Admin (Enterprise) or Workspace Owner/Admin (Business+) access

#### ClickOps Implementation

**Step 1: Authorize the IdP's SCIM Connector**
1. In your IdP, add Slack's SCIM provisioning connector app
2. Authorize it with a Slack Owner or Admin account -- during setup the IdP obtains the SCIM API token through Slack's OAuth 2.0 flow, so the setup is driven from the IdP side rather than from a Slack settings page
3. Use a dedicated administrative identity for that authorization so the token is not tied to a person who may leave

**Step 2: Configure IdP**
1. Confirm the connector's SCIM settings:
   - Base URL: `https://api.slack.com/scim/v1`
   - Authentication: the OAuth token from Step 1 (connector apps store it for you)
2. Enable provisioning features:
   - Create users
   - Update user attributes
   - Deactivate users
3. Map user attributes (email, displayName, etc.)

**Time to Complete:** ~30 minutes

#### Code Implementation

{% include pack-code.html vendor="slack" section="1.2" %}

#### Validation & Testing
1. Create user in IdP - verify appears in Slack
2. Update user in IdP - verify changes sync
3. Deactivate user in IdP - verify Slack access removed
4. Verify deprovisioned users cannot sign in

---

### 1.3 Restrict Workspace Admin Roles

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Limit Primary Owner, Owner, and Admin roles to essential personnel. Use Workspace Admins and, where the plan offers them, narrowly-scoped system roles (such as Users Admin or Channels Admin) for delegated administration.

#### Rationale
**Why This Matters:**
- Primary Owners have unrestricted access
- Admins can modify security settings
- Excessive admin privileges increase risk

**Attack Prevented:** Admin privilege abuse, unauthorized security setting modification via excessive admin roles

#### ClickOps Implementation

**Step 1: Audit Current Admins**
1. Navigate to: **Slack Admin** → **Manage members**
2. Filter by **Account type:** Owners and Admins
3. Document current assignments

**Step 2: Implement Least Privilege**
1. Remove unnecessary Owner and Admin assignments -- Workspace Owners hold the Primary Owner's permissions except deleting or transferring the workspace, while Workspace Admins manage members but cannot access billing
2. Delegate narrow tasks with system roles instead of Owner or Admin. On Enterprise plans that includes, for example, **Users Admin**, **Channels Admin**, **Security Admin**, **DLP Admin**, and **Integrations Admin**; Business+ offers only a few system roles and Pro only **Skills Manager**
3. Assign a system role: click **Admin** in the sidebar → **Workspace settings** → **Roles & permissions** → **Roles**, then the three dots next to the role → **Assign people** (Enterprise: **organization name** → **Tools & settings** → **Organization settings** → **Roles & permissions** → **Roles**). See [Types of roles in Slack](https://slack.com/help/articles/360018112273-Types-of-roles-in-Slack) and [Assign members to system roles](https://slack.com/help/articles/1500004132581-Assign-members-to-system-roles)

**Step 3: Restrict Who Can Assign Roles**
1. Keep the **Roles Admin** system role to a minimum -- it manages who is assigned every other system role
2. On Enterprise plans, assign system roles to IdP groups rather than individuals, so a role is revoked by changing the IdP group
3. Re-review role assignments quarterly and revoke any that are no longer needed

#### Code Implementation

Read-only audit of every Owner and Admin via `users.list` (any plan; a token with `users:read`).

{% include pack-code.html vendor="slack" section="1.3" %}

---

### 1.4 Configure Session Management

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 4.3 |
| NIST 800-53 | AC-11, AC-12 |

#### Description
Configure session duration controls to limit how long members stay signed in to Slack on desktop and mobile, or to sign them out whenever they close Slack.

#### Rationale
**Why This Matters:**
- Long-lived or never-expiring sessions let a stolen device, browser token, or unattended workstation retain authenticated Slack access indefinitely
- Signing members out when they close Slack, or after a bounded session lifetime, shrinks the window an attacker can ride a hijacked session
- Shorter session durations force re-validation against the IdP and its MFA / conditional-access policies on a regular cadence
- Mobile devices are easily lost or stolen, so capping mobile session length contains exposure of corporate conversations and files

**Attack Prevented:** Session hijacking, stolen-token reuse, unattended-device access, lost or stolen mobile device access

#### ClickOps Implementation

**Step 1: Configure Session Duration**
1. **Free, Pro, and Business+:** click **Admin** in the sidebar → **Workspace settings** → **Security**, then click **Edit** next to **Desktop session duration** or **Mobile session duration**
2. **Enterprise:** click your **organization name** in the sidebar → hover **Tools & settings** → **Organization settings** → **Security** → **Security settings**, then click **Edit** next to **Desktop session duration** or **Mobile session duration**
3. Choose to sign members out whenever they close Slack, or after a set period -- for example 24 hours or less on desktop in sensitive environments, and a bounded period on mobile
4. For desktop sessions, optionally notify members when they need to sign back in, then click **Save**. See [Manage session duration](https://slack.com/help/articles/115005223763-Manage-session-duration)

**Step 2: Plan the Rollout**
1. A new duration takes effect the day you save it and ends existing sessions gradually over the period you selected, so expect sign-outs to spread across that window
2. Members are warned two hours before their session expires and get a final reminder 15 minutes before sign-out
3. On Enterprise plans, use the session duration API to give a subset of members (for example, admins) a shorter duration than the org default

#### Code Implementation

Read-only audit of per-user session overrides via `admin.users.session.getSettings` (Enterprise; a user token with `admin.users:read`).

{% include pack-code.html vendor="slack" section="1.4" %}

**Automation:** the workspace or org default session duration is ClickOps only — Slack exposes no write interface for it; `admin.users.session.setSettings` overrides the duration for individual users, not the default ([admin.users.session.setSettings](https://docs.slack.dev/reference/methods/admin.users.session.setSettings), 2026-09-24).

---

### 1.5 Create Information Barriers Between Groups

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3, 6.8 |
| NIST 800-53 | AC-3, AC-4, SC-7(21) |

#### Description
Configure Slack Information Barriers to block direct messages and huddles between defined groups of users, enforcing regulatory "ethical walls" (for example, between research and trading desks, or between an acquiring and acquired business unit) directly inside Slack. Barriers are defined against groups synced from your identity provider, so membership follows the IdP rather than manual Slack lists. See [Create information barriers in Slack](https://slack.com/help/articles/360056171734-Create-information-barriers-in-Slack).

#### Rationale
**Why This Matters:**
- Regulated industries (FINRA, SEC, MiFID II) require enforced separation between functions that must not exchange material non-public information; policy documents alone are not an enforced control
- Slack DMs and huddles are the least-observed channels in a workspace, making them the natural path for informal information leakage between segregated groups
- Binding barriers to IdP-synced groups means a role change or transfer automatically re-scopes what a user can reach, closing the gap between HR reality and Slack reality
- During M&A or divestiture, barriers keep two organizations inside one Enterprise Grid without exposing each side's deal-sensitive conversations to the other

**Attack Prevented:** Insider information leakage across regulated boundaries, MNPI exchange between segregated desks, collusion via unmonitored DMs and huddles, cross-entity data exposure during M&A integration

#### Prerequisites
- Slack Enterprise plan (Enterprise Grid / Enterprise+)
- Org Owner or Org Admin access
- IdP groups that accurately represent the populations to be separated, synced into Slack

#### ClickOps Implementation

**Step 1: Prepare the Group Definitions**
1. In your identity provider, confirm the groups that define each side of the barrier (for example, `Research-Analysts` and `Trading-Desk`)
2. Verify the groups are syncing into Slack and that membership is current
3. Document the regulatory basis for each barrier before creating it

**Step 2: Create the Barrier**
1. Navigate to: **Tools & settings** → **Organization settings** → **Security** → **Information Barriers**
2. Click **Create Barrier**
3. Select the first group, then select the group or groups it must be barred from
4. Review the direction and scope of the restriction, then save

**Step 3: Communicate and Monitor**
1. Notify affected users that DMs and huddles across the barrier are blocked by policy
2. Record the barrier in your compliance control inventory with an owner and review cadence
3. Re-review barriers whenever the underlying IdP groups are restructured

**Time to Complete:** ~45 minutes (excluding IdP group preparation)

#### Code Implementation

Read-only inventory of every barrier via `admin.barriers.list` (Enterprise; a user token with `admin.barriers:read`).

{% include pack-code.html vendor="slack" section="1.5" %}

#### Validation & Testing
**How to verify the control is working:**
1. As a member of Group A, attempt to open a direct message with a member of Group B -- the user should not be selectable or the DM should be blocked
2. Attempt to start a huddle with a barred user and confirm it fails
3. Move a test user between IdP groups and confirm the barrier applies to their new group after sync
4. Confirm that users outside both groups are unaffected

**Expected result:** Direct messages and huddles between barred groups are prevented, and enforcement follows IdP group membership automatically

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.3 | Access is restricted based on role and segregation of duties |
| **NIST 800-53** | AC-4 | Information flow enforcement |
| **ISO 27001** | A.5.15 | Access control |
| **FINRA** | 3110 | Supervision and internal controls over communications |

---

## 2. Network Access Controls

### 2.1 Configure Approved IP Ranges

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 13.5 |
| NIST 800-53 | AC-17, SC-7 |

#### Description
Restrict Slack access to approved IP ranges (corporate network, VPN) to prevent unauthorized access from unknown locations.

#### Rationale
**Why This Matters:**
- IP allowlisting makes the workspace reachable only from trusted corporate egress points or the VPN, not from arbitrary internet locations
- Even if credentials or a session token are phished or stolen, an attacker outside the approved ranges cannot use them to reach Slack
- Network-layer restriction is independent of authentication, so a single failed control does not by itself grant access
- Confines exposure of sensitive business communications, files, and shared secrets to managed, monitored network paths

**Attack Prevented:** Credential-stuffing from unknown locations, stolen-token reuse off-network, account takeover from untrusted networks

#### Prerequisites
- Slack Enterprise plan
- Org Owner or Org Admin access
- Known corporate egress IP ranges, including the one the admin making the change is using

#### ClickOps Implementation

**Step 1: Configure IP Allowlist**
1. Click your **organization name** in the sidebar → **Tools & settings** → **Organization settings** → **Security** → **Security Settings**
2. Next to **IP allowlist**, click **Edit**
3. Add your own current egress range first -- enabling the allowlist immediately signs out anyone using Slack from an IP address outside it, including the admin making the change
4. Check **Enable IP allowlist for this organization**, enter the approved ranges or click **Upload CSV** to add them in bulk, then click **Save**. See [Manage access to Slack with IP allowlists](https://slack.com/help/articles/55052468755347-Manage-access-to-Slack-with-IP-allowlists)

**Step 2: Document the Approved Ranges**
1. Record each range with its owner (office egress, VPN concentrator) and a review cadence
2. Remove a range when the office or VPN endpoint behind it is retired

**Automation:** ClickOps only — Slack exposes no write interface for this setting ([Manage access to Slack with IP allowlists](https://slack.com/help/articles/55052468755347-Manage-access-to-Slack-with-IP-allowlists); no IP-allowlist method among the [Web API methods](https://docs.slack.dev/reference/methods), 2026-09-24).

---

## 3. OAuth & Integration Security

### 3.1 Restrict App Installation and Approval

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.5 |
| NIST 800-53 | AC-3, CM-7 |

#### Description
Control which Slack apps and integrations can be installed. Require admin approval for new app installations and regularly audit existing apps.

#### Rationale
**Why This Matters:**
- Slack apps can access messages, files, and user data
- Malicious apps can exfiltrate sensitive information
- OAuth tokens provide persistent access
- Slack now enforces a platform-level throttle that favors vetted apps: since **May 29, 2025**, newly created commercially distributed apps that are not approved for the Slack Marketplace -- and new installations of existing ones -- are limited to **1 request per minute** and **15 objects per call** on `conversations.history` and `conversations.replies` (existing installations of those apps, and internal customer-built apps, are not subject to the new limits). Slack introduced this explicitly to curb bulk conversation-history exfiltration by unvetted apps, so preferring Marketplace-listed apps both raises the vetting bar and preserves usable API throughput -- see [Rate limit changes for non-Marketplace apps](https://docs.slack.dev/changelog/2025/05/29/rate-limit-changes-for-non-marketplace-apps/) and [Rate limits](https://docs.slack.dev/apis/web-api/rate-limits)

**Attack Prevented:** Malicious app installation, bulk conversation-history exfiltration, unauthorized integrations

#### Prerequisites
- Any Slack plan (app approval is available on all plans) -- see [Manage app approval for your workspace](https://slack.com/help/articles/222386767-Manage-app-approval-for-your-workspace)
- Workspace Owner access (only Workspace Owners can enable app approval)
- App approval workflow defined
- For the API audit below: an Enterprise org and an app holding `admin.apps:read`, installed org-wide

#### ClickOps Implementation

**Step 1: Require App Approval**
1. Click **Admin** in the sidebar → **Apps and workflows** (opens the Slack Marketplace) → **App Management Settings**
2. Click **Edit** next to **Require approved apps**
3. Check **Only allow pre-approved apps**, then click **Save**
4. Pre-approve vetted apps: **Admin** → **Apps and workflows** → **Browse** → select the app → **Approve**; use **Restrict** for apps that must never be installed

**Step 2: Review Existing Apps**
1. From **Admin** → **Apps and workflows**, review the apps already installed to the workspace
2. For each app, review:
   - Requested permissions/scopes
   - Data access level
   - Last used date
3. Uninstall unused or risky apps -- restricting an app does not remove an existing installation, so members keep using it until it is uninstalled

**Step 3: Configure the App Request Workflow**
1. In **App Management Settings**, click **Edit** next to **Require approved apps**
2. Check **Allow members to request apps for approval** (optionally require a comment with each request)
3. Below **Select App Managers**, choose **Workspace Owners and selected members or groups** and add your security reviewers
4. Optionally configure automation rules that approve, restrict, dismiss, or flag requests for human review
5. Set up app review criteria -- include a preference for Slack Marketplace-listed apps, which pass Slack's review process and are exempt from the non-Marketplace conversation-history rate limits

**Time to Complete:** ~45 minutes

#### Code Implementation

{% include pack-code.html vendor="slack" section="3.1" %}

#### Validation & Testing
1. Attempt to install unapproved app - verify blocked
2. Submit app approval request - verify workflow triggers
3. Verify pre-approved apps can be installed
4. Audit existing apps for excessive permissions

---

### 3.2 Manage Slack Connect (External Collaboration)

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-22, SC-7 |

#### Description
Control Slack Connect channels that enable collaboration with external organizations. Require approval for external connections and define allowed organizations.

#### Rationale
**Why This Matters:**
- Slack Connect enables data sharing with external parties
- Unauthorized connections can lead to data leakage
- External parties may have different security postures

**Attack Prevented:** Data leakage to unauthorized external organizations via unapproved Slack Connect channels

#### Prerequisites
- A paid Slack plan (Pro, Business+, or Enterprise)
- Workspace Owner (Pro and Business+) or Org Owner / Org Admin (Enterprise) access

#### ClickOps Implementation

**Step 1: Restrict Who Can Send Slack Connect Invitations**
1. **Pro and Business+:** click **Admin** in the sidebar → **Workspace settings** → **Permissions** tab → next to **Slack Connect Channels** click **Expand**; below **Inviting people from outside [your organization]**, turn each invitation type on or off and choose who can send it, then click **Save**
2. **Enterprise:** click your **organization name** in the sidebar → **Tools & settings** → **Organization settings** → **Slack Connect** → **Settings** → **Channels** tab → next to **Sending channel invitations** click **Edit**; set each invitation type and who may send it, then click **Save Setting**
3. Prefer **Permission only to post** over **Permission to post, invite, and more** for external people. See [Manage Slack Connect channel invitation settings and permissions](https://slack.com/help/articles/1500012572621-Manage-Slack-Connect-channel-invitation-settings-and-permissions)

**Step 2: Require Approval for External Connections**
1. **Pro and Business+:** in the same **Slack Connect Channels** section, choose who can approve requests, when approval is required, and where requests are sent
2. **Enterprise:** **Slack Connect** → **Settings** → **Channels** tab → under **Approvals**, choose a setting and click **Edit**
3. Customize per partner organization on Enterprise: **Slack Connect** → **Connections** → three dots next to the organization → **Channels** → **Customize for [organization name]**
4. Review pending requests from **Tools & settings** → **Manage Slack Connect Invitations** → **Open requests**. See [Manage Slack Connect channel approval settings and invitation requests](https://slack.com/help/articles/115005912706-Manage-Slack-Connect-channel-approval-settings-and-invitation-requests)

**Step 3: Configure Data Loss Prevention for Connect**
1. Apply DLP rules to Slack Connect channels
2. Block sensitive data sharing to external channels

**Step 4: Configure Guest Access**
1. Navigate to: **Settings** → **Guest access**
2. Configure guest account restrictions
3. Limit guest access to specific channels

#### Code Implementation

Read-only inventory of connected external organizations via `team.externalTeams.list` (Enterprise; a bot token with `conversations.connect:manage` and `team:read`).

{% include pack-code.html vendor="slack" section="3.2" %}

---

### 3.3 Govern Slack MCP Server and AI Agent Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.5, 3.3 |
| NIST 800-53 | AC-3, AC-6, CM-7 |

#### Description
Treat AI agents that reach Slack through Slack's official remote MCP (Model Context Protocol) server as first-class app-directory decisions. The MCP server lets third-party AI assistants and agents query Slack data over OAuth, and it honors the requesting user's existing permissions -- it grants no new visibility, but it does give an external model programmatic reach into everything that user can already see. Approve specific agents and scopes deliberately rather than allowing MCP connections by default. See [Secure data connectivity for the modern AI era](https://slack.dev/secure-data-connectivity-for-the-modern-ai-era/).

#### Rationale
**Why This Matters:**
- An MCP-connected agent inherits the full read surface of the user who authorized it, so a single broadly-permissioned employee can expose a wide slice of the workspace to an external model
- Permission inheritance is a floor, not a ceiling: the control question is not "can this agent see more than the user?" but "should this vendor's model process what the user can see?"
- AI agents retrieve at machine speed and breadth, turning a permission set that is acceptable for human browsing into a bulk-retrieval channel
- Agent-side prompt injection can redirect what an otherwise legitimate agent asks Slack for, so the approved scope is the real containment boundary
- Data handled by the agent leaves Slack's compliance perimeter and lands in the AI vendor's retention, logging, and training regime, which your DLP and eDiscovery tooling does not cover

**Attack Prevented:** Unvetted AI vendor access to workspace content, bulk data retrieval via agent automation, prompt-injection-driven data pulls, shadow AI integrations outside the app-approval process

#### Prerequisites
- App approval controls already enforced (see [3.1](#31-restrict-app-installation-and-approval))
- Workspace Owner, Admin, or Org Admin access
- A defined AI vendor review standard (data retention, training use, subprocessors, certifications)

#### ClickOps Implementation

**Step 1: Inventory Existing AI and MCP Connections**
1. Click **Admin** in the sidebar → **Apps and workflows** (the Slack Marketplace) and review the apps installed to the workspace
2. Identify apps that are AI assistants, agent platforms, or MCP clients
3. For each, record the vendor, the OAuth scopes granted, and which users authorized it
4. On Enterprise plans, also review the third-party app MCP servers approved for the organization -- the list is derived from the org's MCP server allowlist and still includes servers of apps that were uninstalled but not deleted (see the Code Pack below)

**Step 2: Set the Approval Standard**
1. Require every MCP-connected agent to go through the same admin approval workflow as any other app
2. Add AI-specific review criteria: whether workspace content is retained, whether it is used for model training, which subprocessors receive it, and where it is stored
3. Reject or restrict agents that cannot answer those questions in writing

**Step 3: Constrain Who Can Authorize Agents**
1. In **Apps and workflows** → **App Management Settings**, keep **Only allow pre-approved apps** enabled (see [3.1](#31-restrict-app-installation-and-approval)) so individual users cannot connect an agent unilaterally
2. Prefer authorizing agents under a purpose-built service account with deliberately narrow channel membership rather than a broadly-permissioned admin
3. Pair with Information Barriers (see [1.5](#15-create-information-barriers-between-groups)) and AI channel restrictions (see [4.5](#45-restrict-slack-ai-access-to-sensitive-channels-canvases-and-lists)) so sensitive spaces stay out of reach regardless of the authorizing identity

**Step 4: Monitor Agent Activity**
1. Track the approved agents' API activity in audit logs (see [5.1](#51-enable-audit-logs))
2. Alert on sudden increases in message or file retrieval volume by an app token
3. Re-review every AI agent authorization quarterly and revoke unused ones

**Time to Complete:** ~1 hour for initial inventory and standard

#### Code Implementation

Read-only audit of the org's approved MCP servers via `admin.apps.mcp.servers.list` (Enterprise; a user token with `admin.apps:read`).

{% include pack-code.html vendor="slack" section="3.3" %}

#### Validation & Testing
**How to verify the control is working:**
1. Attempt to connect an unapproved MCP client or AI agent as a standard user -- installation should be blocked pending admin approval
2. Authorize an approved agent and confirm it can only retrieve content the authorizing identity can already access, including that it cannot read private channels the identity is not in
3. Confirm the agent's retrievals appear in audit logs attributable to its app token
4. Revoke the agent's authorization and verify subsequent queries fail

**Expected result:** Only reviewed AI agents hold MCP access, each scoped to a deliberately limited identity, with all retrieval activity visible in audit logs

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls over third-party access |
| **SOC 2** | CC9.2 | Vendor and business partner risk management |
| **NIST 800-53** | AC-6 | Least privilege |
| **NIST 800-53** | CM-7 | Least functionality |
| **ISO 27001** | A.5.19 | Information security in supplier relationships |

---

## 4. Data Security

### 4.1 Enable Data Loss Prevention (DLP)

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1, 3.2 |
| NIST 800-53 | SC-8, SC-28 |

#### Description
Configure Slack's native DLP to detect and prevent sharing of sensitive information like credit card numbers, SSNs, API keys, and confidential documents.

#### Rationale
**Why This Matters:**
- Credentials and API keys are frequently shared in Slack
- Sensitive PII can be accidentally posted
- DLP provides automated protection

**Attack Prevented:** Credential, API key, and PII exposure in messages and shared files

**Limitations:**
- Native DLP scans message text, text-based file types, and canvases -- but it does **not** scan non-text files (images, video, audio), files larger than 100 MB, or externally hosted files (for example, Google Drive or Box links posted into a channel)
- Cannot redact portions of messages (only tombstone the entire message)
- Consider third-party DLP for advanced capabilities, especially image and binary file inspection

#### Prerequisites
- Slack Enterprise plan (native DLP is available on Enterprise plans; no GovSlack or separate Compliance add-on is required) -- see [Slack data loss prevention](https://slack.com/help/articles/12914005852819-Slack-data-loss-prevention)
- DLP Admin system role (assigned by the Org Primary Owner or a Roles Admin)

#### ClickOps Implementation

**Step 1: Access DLP Settings**
1. Click your **organization name** in the sidebar → hover **Tools & settings** → **Organization settings** → **Security** → **Data loss prevention**
2. Click **Create Rule** in the top-right corner

**Step 2: Create DLP Rule**
1. Configure the rule:
   - **Rule name:** Block credit card sharing
   - **Detection:** choose a preconfigured rule from the drop-down, or click **Use custom regular expression** and enter a PCRE (PHP) regex
   - **Action to take:** **Display DLP dashboard alert only**, **Show a warning** to the member, or **Hide** ("tombstone") the message or file until it is reviewed
   - **Scope:** whether the rule applies to Slack Connect conversations, specific workspaces, and specific conversation types
2. Click **Next**, then **Save Rule**

**Step 3: Enable Preconfigured Rules**
1. Add rules from Slack's preconfigured library:
   - Credit card numbers (each match is validated against the card network's number format)
   - National identifiers (several common government-issued IDs, check-digit validated where the ID has one)
   - Secrets -- API keys and tokens for major cloud and SaaS providers (AWS, GitHub, Stripe, and more)
2. Add custom-regex rules for organization-specific patterns (internal project names, token formats the library does not cover) -- see the Code Pack below

**Time to Complete:** ~1 hour

#### Code Implementation

{% include pack-code.html vendor="slack" section="4.1" %}

#### Validation & Testing
1. Send test message with fake credit card number
2. Verify DLP rule triggers
3. Confirm the violation appears under the **Alerts** tab of the DLP dashboard (DLP Admins also receive a daily summary of violations)
4. Test that legitimate content is not blocked

---

### 4.2 Configure Message Retention Policies

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.4 |
| NIST 800-53 | SI-12, AU-11 |

#### Description
Configure message and file retention policies to balance compliance requirements with data minimization. Enable legal holds for litigation preservation.

#### Rationale
**Why This Matters:**
- Regulatory compliance may require specific retention periods
- Data minimization reduces breach impact
- Legal holds prevent destruction of relevant evidence

**Attack Prevented:** Breach impact amplification from retained historical data, destruction of evidence under legal hold

#### Prerequisites
- Any Slack plan for workspace retention settings (the options differ by plan: paid plans keep data for the lifetime of the workspace by default, the Free plan offers 90 days or one year) -- see [Customize data retention in Slack](https://slack.com/help/articles/203457187-Customize-message-and-file-retention-policies)
- Legal holds require an Enterprise plan and the Legal Holds Admin system role
- Defined retention requirements per regulation

#### ClickOps Implementation

**Step 1: Configure Default Retention**
1. Click **Admin** in the sidebar → **Workspace settings** → next to **Data retention** click **Expand**, choose the message retention setting, click **Save**, then **Save** again to confirm
2. Next to **File history**, click **Expand**, choose the file retention setting, click **Save**, then **Confirm Settings**
3. On paid plans, choose between never deleting (with or without saving edits) and a custom timeline
4. **Enterprise:** org-level retention policies are set by contacting Slack Support; review them at **organization name** → **Tools & settings** → **Organization settings** → **Settings** → **History**
5. Consider compliance requirements:
   - **FINRA:** 3-6 years
   - **HIPAA:** 6 years
   - **SOX:** 7 years

**Step 2: Configure Per-Channel Retention**
1. On Business+ and Enterprise plans, admins can edit message retention for individual channels with channel management tools; only check **Let workspace members override these settings** if members may set their own retention for private channels and DMs -- see [Edit message retention settings for specific conversations](https://slack.com/help/articles/115005393586-Edit-message-retention-settings-for-specific-conversations)
2. Shorter retention for informal channels
3. Longer retention for compliance-relevant channels

**Step 3: Enable Legal Holds (Enterprise)**
1. Click your **organization name** in the sidebar → hover **Tools & settings** → **Organization settings** → **Security** → **Legal Holds** → **Create Legal Hold**
2. Name the hold, select which conversations to include and an optional date range, click **Add Custodians**, select the members, then click **Save**
3. A hold preserves messages and files regardless of retention settings or member edits and deletions; Slack Connect conversations are not included. See [Create and manage legal holds](https://slack.com/help/articles/4401830811795-Create-and-manage-legal-holds)

**Time to Complete:** ~30 minutes

#### Code Implementation

Read-only check of per-conversation retention via `admin.conversations.getCustomRetention` (Enterprise; a user token with `admin.conversations:read`).

{% include pack-code.html vendor="slack" section="4.2" %}

**Automation:** the workspace and org default retention settings are ClickOps only — Slack exposes no write interface for them; the Admin API sets retention per conversation (`admin.conversations.setCustomRetention`, `admin.conversations.removeCustomRetention`), and legal holds have their own Legal Holds API ([admin.conversations.setCustomRetention](https://docs.slack.dev/reference/methods/admin.conversations.setCustomRetention), [Legal Holds API](https://docs.slack.dev/admins/legal-holds-api), 2026-09-24).

---

### 4.3 Enable Enterprise Key Management (EKM)

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12, SC-28 |

#### Description
Deploy Slack Enterprise Key Management to use your own AWS KMS keys for encrypting Slack messages and files, providing customer-controlled encryption.

#### Rationale
**Why This Matters:**
- Customer-managed KMS keys give your organization, not the vendor, ultimate control over the keys that decrypt messages and files
- Revoking key access instantly cuts off decryption during an incident, insider-threat event, or contract termination
- AWS CloudTrail key-access logging provides granular visibility into when and how Slack content is decrypted
- Satisfies data-sovereignty and regulatory mandates that require customer-held encryption keys for sensitive or regulated data

**Attack Prevented:** Provider-side data exposure, insider misuse, inability to revoke access during an incident, compliance gaps for regulated data

#### Prerequisites
- Slack Enterprise plan with the EKM security add-on (Enterprise Grid and Enterprise+; included on GovSlack) -- see [Slack Enterprise Key Management](https://slack.com/help/articles/360019110974-Slack-Enterprise-Key-Management)
- AWS account with KMS
- Org Owner or Org Admin access

#### ClickOps Implementation

**Step 1: Set Up AWS KMS**
1. Create KMS key in AWS
2. Configure key policy for Slack access
3. Note key ARN

**Step 2: Enable EKM with Slack**
1. Contact Slack's Sales team to add the EKM security add-on -- Slack's EKM article routes onboarding through Sales and documents no self-serve console path for enrolling
2. On enrollment, existing data is encrypted with your customer-controlled keys
3. Confirm what EKM covers before relying on it: messages, canvases, snippets, files, and the search index use your keys, while member profiles, channel names, and file names stay under Slack-controlled keys

**Automation:** ClickOps only — Slack exposes no write interface for EKM configuration; its only EKM Web API method, `admin.conversations.ekm.listOriginalConnectedChannelInfo`, is read-only ([Slack Enterprise Key Management](https://slack.com/help/articles/360019110974-Slack-Enterprise-Key-Management), [admin.conversations.ekm.listOriginalConnectedChannelInfo](https://docs.slack.dev/reference/methods/admin.conversations.ekm.listOriginalConnectedChannelInfo), 2026-09-24).

---

### 4.4 Govern Slack AI Feature Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3, 4.8 |
| NIST 800-53 | AC-3, CM-7, SC-28 |

#### Description
Decide deliberately which Slack AI features are available in your workspace rather than accepting the defaults. Under **Feature access**, each AI capability -- conversation summaries, AI search answers, recaps, translations, and file summaries -- can be set independently to **Everyone** or **No one**. This is a workspace permission surface that exists regardless of whether you license DLP, so a DLP-free workspace still needs an explicit decision here. See [Manage access to AI features in Slack](https://slack.com/help/articles/28244420881555-Manage-access-to-AI-features-in-Slack).

#### Rationale
**Why This Matters:**
- AI features read across the content a user can access and re-present it in condensed, easily-copied form, which changes the practical exposure of material that was technically readable but buried
- Feature access is independent of DLP licensing, so organizations without native DLP have no compensating control if AI features are simply left on
- Enabling features one at a time lets you allow low-risk capabilities (translations) while withholding high-risk ones (cross-channel search answers) instead of making a single all-or-nothing choice
- In August 2024, PromptArmor disclosed that an indirect prompt injection planted in a **public** channel could cause Slack AI to surface data from a **private** channel to the attacker via a crafted Markdown link -- and Slack characterized public-channel-wide ingestion as intended behavior. That combination means AI feature scope, not just channel permissions, defines your real exposure. See [Data exfiltration from Slack AI via indirect prompt injection](https://www.promptarmor.com/resources/data-exfiltration-from-slack-ai-via-indirect-prompt-injection)
- Regulated content subject to retention, residency, or eDiscovery obligations may be summarized into surfaces your existing tooling does not inspect

**Attack Prevented:** Indirect prompt injection driving AI-assisted data exfiltration, over-broad AI summarization of sensitive content, unreviewed AI processing of regulated data, silent expansion of exposure through default-on features

#### Prerequisites
- Workspace Owner or Admin access (Org Admin for org-wide enforcement)
- A plan that includes the AI features in question (see Appendix A)
- A documented position on which AI capabilities are acceptable for your data classification

#### ClickOps Implementation

**Step 1: Review Current AI Feature State**
1. Navigate to: **Slack Admin** → **Workspace settings** → **Roles & permissions** → **Feature access** → **AI**
2. Record the current setting for each AI feature before changing anything
3. Note which features are on by default -- defaults change as Slack ships new capabilities

**Step 2: Set Each Feature Deliberately**
1. For each AI capability, set access to **Everyone** or **No one** based on your data classification:
   - **Conversation summaries and recaps:** highest condensation of channel content
   - **AI search answers:** broadest reach across the content a user can access
   - **File summaries:** extends AI processing to document contents
   - **Translations:** generally lowest risk
2. Default to **No one** for any feature you have not explicitly assessed
3. Save and record the rationale for each decision

**Step 3: Establish a Re-Review Cadence**
1. Re-check this page after every major Slack release, since new AI features arrive with their own defaults
2. Assign an owner responsible for evaluating new AI capabilities before they are left enabled
3. Pair with channel-level restrictions (see [4.5](#45-restrict-slack-ai-access-to-sensitive-channels-canvases-and-lists)) where the plan supports it

**Automation:** ClickOps only — Slack exposes no write interface for this setting ([Manage access to AI features in Slack](https://slack.com/help/articles/28244420881555-Manage-access-to-AI-features-in-Slack); no AI feature-access method among the [Web API methods](https://docs.slack.dev/reference/methods), 2026-09-24).

**Time to Complete:** ~30 minutes

#### Validation & Testing
**How to verify the control is working:**
1. As a standard user, confirm that features set to **No one** do not appear in the Slack UI and cannot be invoked
2. Confirm that features set to **Everyone** behave as expected for an ordinary user
3. Re-open the Feature access page after a Slack release and verify no new AI feature has been enabled without review
4. Confirm the recorded rationale matches the live configuration during periodic access reviews

**Expected result:** Every Slack AI feature has an explicit, documented on or off decision, and no feature is enabled purely by default

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls over data processing features |
| **SOC 2** | CC6.7 | Restriction of information transmission and disclosure |
| **NIST 800-53** | CM-7 | Least functionality |
| **ISO 27001** | A.8.11 | Data masking and restriction of data exposure |
| **GDPR** | Art. 25 | Data protection by design and by default |

---

### 4.5 Restrict Slack AI Access to Sensitive Channels, Canvases, and Lists

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3, 3.12 |
| NIST 800-53 | AC-3, AC-4, SC-28 |

#### Description
On Enterprise+ plans, exclude specific channels, canvases, and lists from Slack AI processing so that highly sensitive spaces -- legal, M&A, incident response, HR investigations -- are never ingested into summaries, recaps, or search answers. Restriction can be applied per-channel by its owner or centrally across the organization. See [Restrict AI access to certain channels, canvases and lists](https://slack.com/help/articles/47421816860947-Restrict-AI-access-to-certain-channels-canvases-and-lists).

#### Rationale
**Why This Matters:**
- Feature-level governance (see [4.4](#44-govern-slack-ai-feature-access)) is all-or-nothing per capability; channel-level restriction is what lets you keep AI broadly useful while carving out the handful of spaces where any AI processing is unacceptable
- The PromptArmor disclosure showed that content reachable by Slack AI can be surfaced through injected instructions the user never wrote, so removing a channel from AI's reach is a stronger guarantee than trusting the model's behavior. Restriction is the control that reduces that residual risk to zero for the spaces you designate
- Legal privilege, deal confidentiality, and investigation integrity depend on content not being reproduced into derived summaries visible to a wider audience
- Applying restriction centrally rather than relying on individual channel owners makes the control auditable and survives ownership changes

**Documented Limitation:** This setting restricts AI **read** access to the designated channel, canvas, or list. It is a scoping control over what AI ingests -- treat it as such, and do not assume it changes any other aspect of how the content is stored, retained, or shared.

**Attack Prevented:** Indirect prompt injection reaching privileged content, AI-derived leakage of legal or deal-sensitive material, exposure of investigation channels through summarization, residual AI ingestion after channel ownership changes

#### Prerequisites
- Slack Enterprise+ plan
- Org Owner or Org Admin access for organization-wide restriction
- A classified inventory of channels, canvases, and lists that must be excluded from AI

#### ClickOps Implementation

**Step 1: Identify Channels to Restrict**
1. Build the list of spaces that must never be AI-processed: legal and privileged channels, M&A and deal rooms, security incident channels, HR investigation channels, and any canvas or list holding regulated data
2. Confirm each has a named owner and a documented classification

**Step 2: Restrict at the Channel, Canvas, or List Level**
1. Open the channel, canvas, or list
2. Go to **Settings** → **AI use**
3. Select **Restrict** to exclude it from Slack AI processing
4. Repeat for each item on the inventory

**Step 3: Apply Organization-Wide Controls**
1. Navigate to: **Tools & settings** → **Organization settings** → **Roles & permissions**
2. Apply AI access restrictions centrally so the control does not depend on individual channel owners
3. Record the restricted inventory in your compliance control documentation

**Step 4: Maintain the Inventory**
1. Add AI restriction to the checklist for creating any new privileged or incident channel
2. Re-review the restricted list quarterly and whenever a new sensitive workstream begins
3. Verify restriction survives channel renames and ownership transfers

**Time to Complete:** ~1 hour for initial inventory and application

#### Code Implementation

Channels can be excluded from Slack AI in bulk through the Admin API (up to 100 per call). This pack **changes** the channels' AI setting; revert it by re-running with `EXCLUDE=false`.

{% include pack-code.html vendor="slack" section="4.5" %}

#### Validation & Testing
**How to verify the control is working:**
1. In a restricted channel, attempt to generate a summary or recap and confirm the AI feature is unavailable or returns nothing
2. From an AI search prompt, query for a distinctive phrase that exists only in a restricted channel and confirm it is not returned to a user who would otherwise have access
3. Confirm an unrestricted control channel still returns AI results, proving the restriction is targeted rather than global
4. Rename a restricted channel and re-run the checks to confirm the restriction persists

**Expected result:** Designated channels, canvases, and lists produce no AI summaries, recaps, or search answers, while the rest of the workspace retains AI functionality

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access controls over sensitive data |
| **SOC 2** | CC6.7 | Restriction of information transmission and disclosure |
| **NIST 800-53** | AC-4 | Information flow enforcement |
| **ISO 27001** | A.8.12 | Data leakage prevention |
| **HIPAA** | 164.312(a)(1) | Access control over protected health information |

---

## 5. Monitoring & Detection

### 5.1 Enable Audit Logs

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2, AU-3, AU-6 |

#### Description
Enable and export Slack audit logs for security monitoring, incident investigation, and compliance. Integrate with SIEM for automated threat detection.

#### Rationale
**Why This Matters:**
- Audit logs capture admin actions, authentication events, and data access
- Essential for incident investigation
- Required for most compliance frameworks

**Attack Prevented:** Undetected compromise — admin actions, authentication events, and data access invisible without audit logs

#### Prerequisites
- Slack Enterprise plan -- see [Audit logs in Slack](https://slack.com/help/articles/360000394286-Audit-logs-in-Slack)
- Org Owner access or the Audit Logs Admin system role
- SIEM or log management platform

#### ClickOps Implementation

**Step 1: Access Audit Logs**
1. Click your **organization name** in the sidebar → **Tools & settings** → **Organization settings** → **Security** → **Audit logs**
2. Click **Filter** to narrow entries by date range, acting user, what the event affects (user, workspace, or organization), or event type
3. Review the **Security Detections** tab for anomaly events

**Step 2: Export Logs**
1. Click **Export** in the top-right corner and select **Export CSV** or **Export JSON** for an on-demand export
2. For continuous delivery to a SIEM, use the Audit Logs API (Step 3) -- the console offers on-demand exports, not a scheduled feed

**Step 3: Integrate with SIEM**
1. Have your SIEM poll the Audit Logs API (`https://api.slack.com/audit/v1/logs`) with an app holding `auditlogs:read` on the Enterprise org -- see [Using the Audit Logs API](https://docs.slack.dev/admins/audit-logs-api)
2. Configure alerts for critical events

**Time to Complete:** ~1 hour

#### Code Implementation

{% include pack-code.html vendor="slack" section="5.1" %}

#### Key Events to Monitor

| Event | Description | Detection Use Case |
|-------|-------------|-------------------|
| `user_login_failed` | Failed authentication | Brute force attempts |
| `role_change_to_admin` | Admin role assigned | Privilege escalation |
| `app_installed` | New app installed | Malicious app detection |
| `file_downloaded` | File downloaded | Data exfiltration |
| `public_channel_created` / `private_channel_created` | New channel created | Shadow IT detection |
| `message_tombstoned` | Message deleted by DLP | Policy violations |

---

## 6. Third-Party Integration Security

### 6.1 Integration Risk Assessment Matrix

| Risk Factor | Low | Medium | High |
|-------------|-----|--------|------|
| **Data Access** | Read channel list only | Read messages in public channels | Read all messages + files |
| **OAuth Scopes** | Limited scopes | Broad read access | Write access, admin scopes |
| **Data Retention** | No data storage | Temporary storage | Permanent storage |
| **Vendor Security** | SOC 2 Type II + ISO | SOC 2 Type I | No certification |

### 6.2 Common Integrations and Recommended Controls

#### Obsidian Security
**Data Access:** Read (messages, channels, users, audit logs)
**Recommended Controls:**
- ✅ Use dedicated bot user
- ✅ Grant minimum required OAuth scopes
- ✅ Review access quarterly
- ✅ Monitor API usage via audit logs

#### Zoom
**Data Access:** Low (meeting links, calendar)
**Recommended Controls:**
- ✅ Limit to meeting creation only
- ✅ Disable automatic meeting recording sharing

#### Google Drive / Dropbox
**Data Access:** Medium (file sharing)
**Recommended Controls:**
- ✅ Control which files can be shared
- ✅ Apply DLP to file sharing
- ✅ Monitor for sensitive file sharing

---

## 7. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Slack Control | Guide Section |
|-----------|---------------|---------------|
| CC6.1 | SSO/SAML authentication | [1.1](#11-enable-saml-single-sign-on-sso) |
| CC6.1 | App approval controls | [3.1](#31-restrict-app-installation-and-approval) |
| CC6.2 | Admin role restrictions | [1.3](#13-restrict-workspace-admin-roles) |
| CC6.3 | Information barriers between groups | [1.5](#15-create-information-barriers-between-groups) |
| CC6.6 | Slack Connect controls | [3.2](#32-manage-slack-connect-external-collaboration) |
| CC6.7 | Slack AI feature and channel restrictions | [4.4](#44-govern-slack-ai-feature-access), [4.5](#45-restrict-slack-ai-access-to-sensitive-channels-canvases-and-lists) |
| CC7.2 | Audit logging | [5.1](#51-enable-audit-logs) |
| CC9.2 | AI agent and MCP vendor governance | [3.3](#33-govern-slack-mcp-server-and-ai-agent-access) |

### NIST 800-53 Rev 5 Mapping

| Control | Slack Control | Guide Section |
|---------|---------------|---------------|
| IA-2 | SAML SSO | [1.1](#11-enable-saml-single-sign-on-sso) |
| AC-2 | SCIM provisioning | [1.2](#12-configure-scim-user-provisioning) |
| AC-4 | Information flow enforcement | [1.5](#15-create-information-barriers-between-groups), [4.5](#45-restrict-slack-ai-access-to-sensitive-channels-canvases-and-lists) |
| AC-6(1) | Least privilege admin | [1.3](#13-restrict-workspace-admin-roles) |
| CM-7 | Least functionality | [3.3](#33-govern-slack-mcp-server-and-ai-agent-access), [4.4](#44-govern-slack-ai-feature-access) |
| SC-28 | DLP / EKM | [4.1](#41-enable-data-loss-prevention-dlp), [4.3](#43-enable-enterprise-key-management-ekm) |
| AU-2 | Audit logging | [5.1](#51-enable-audit-logs) |

### HIPAA Security Rule Mapping

| Requirement | Slack Control | Guide Section |
|-------------|---------------|---------------|
| 164.312(d) | SSO authentication | [1.1](#11-enable-saml-single-sign-on-sso) |
| 164.312(b) | Audit controls | [5.1](#51-enable-audit-logs) |
| 164.312(c)(1) | Integrity controls | [4.1](#41-enable-data-loss-prevention-dlp) |
| 164.312(e)(1) | Transmission security | [4.3](#43-enable-enterprise-key-management-ekm) |

---

## Appendix A: Edition/Tier Compatibility

As of **August 17, 2025**, Slack's plan lineup is **Free, Pro, Business+, and Enterprise+** (Enterprise+ is the plan formerly positioned as Enterprise Grid). The standalone Slack AI add-on was discontinued, and AI capabilities -- AI search, recaps, translations, and file summaries -- are now included in Business+ and above rather than sold separately. See [Updates to feature availability and pricing for Slack plans](https://slack.com/help/articles/39264531104275-Updates-to-feature-availability-and-pricing-for-Slack-plans).

| Control | Free | Pro | Business+ | Enterprise+ |
|---------|------|-----|-----------|-------------|
| 2FA (local) | ✅ | ✅ | ✅ | ✅ |
| SAML SSO | ❌ | ❌ | ✅ | ✅ |
| SCIM Provisioning | ❌ | ❌ | ✅ | ✅ |
| App Management | Basic | Basic | ✅ | ✅ |
| Data Loss Prevention | ❌ | ❌ | ❌ | ✅ |
| Enterprise Key Management | ❌ | ❌ | ❌ | ✅ |
| Custom Retention | ❌ | ✅ | ✅ | ✅ |
| Audit Logs API | ❌ | ❌ | ❌ | ✅ |
| Information Barriers | ❌ | ❌ | ❌ | ✅ |
| AI features (search, recaps, translations, file summaries) | ❌ | ❌ | ✅ | ✅ |
| AI feature access controls (Feature access → AI) | ❌ | ❌ | ✅ | ✅ |
| Restrict AI access to channels, canvases, lists | ❌ | ❌ | ❌ | ✅ |

---

## Appendix B: References

**Official Slack Documentation:**
- [Trust Center / Security](https://slack.com/trust/security)
- [Help Center](https://slack.com/help)
- [Security Tips to Protect Your Workspace](https://slack.com/help/articles/115004155306-Security-tips-to-protect-your-workspace)
- [Security Practices](https://slack.com/security-practices)
- [Manage Single Sign-On Settings](https://slack.com/help/articles/220403548-Manage-single-sign-on-settings)
- [Workspace administration (Help Center)](https://slack.com/help/categories/200122103-Workspace-administration)

**API & Developer Tools:**
- [Slack API Documentation](https://docs.slack.dev/apis/)
- [Legacy API Reference](https://api.slack.com/)
- [Audit Logs API](https://docs.slack.dev/admins/audit-logs-api)
- [Web API methods](https://docs.slack.dev/reference/methods)

**Compliance Frameworks:**
- SOC 2 Type II, SOC 3, ISO 27001, ISO 27017, ISO 27018, APEC PRP, APEC CBPR -- via [Trust Center / Compliance](https://slack.com/trust/compliance)
- HIPAA (Slack can be configured for e-PHI), FedRAMP Moderate (Slack, Enterprise and Enterprise+ plans configured per Slack's Secure Configuration Guide), and FedRAMP JAB High (GovSlack) -- via [Trust Center / Compliance](https://slack.com/trust/compliance)
- GDPR, CCPA/CPRA, FINRA compliant -- via [Compliance Resources](https://slack.com/trust/compliance)

**Security Incidents:**
- (2022-12) Stolen Slack employee tokens used to access externally hosted GitHub repositories. No customer data affected.
- (2022-07) A vulnerability transmitted hashed user passwords to other workspace members; approximately 0.5% of users required password resets.
- (2024-07) Credential-stuffing attack using leaked credentials granted unauthorized access to employee accounts and sensitive corporate data. Disclosed July 12, 2024.
- (2024-08) PromptArmor disclosed an indirect prompt injection against Slack AI: instructions planted in a public channel caused Slack AI to exfiltrate private-channel data through a crafted Markdown link. Slack characterized Slack AI's ingestion of public-channel content as intended behavior, making it a residual risk to be managed through AI feature and channel restrictions ([4.4](#44-govern-slack-ai-feature-access), [4.5](#45-restrict-slack-ai-access-to-sensitive-channels-canvases-and-lists)) rather than a patched vulnerability. [Details](https://www.promptarmor.com/resources/data-exfiltration-from-slack-ai-via-indirect-prompt-injection)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-09-25 | 0.3.0 | ai-drafted | validate-hth-guide run (doc drift + pack execution; no live Slack session, so 0 surfaces VERIFIED-LIVE and the maturity set is unchanged): console paths in 1.1-1.4, 2.1, 3.1-3.3, 4.1-4.3 and 5.1 corrected against Slack's current help articles (retired "Enterprise Grid Admin" breadcrumb; undocumented settings removed from 1.3, 1.4, 2.1, 4.3, 5.1); new read-only API packs for 1.3, 1.4, 1.5, 3.2, 3.3, 4.2 and a mutating one for 4.5; 1.2, 3.1 and 5.1 packs read their token from the environment, paginate and fail closed (3.1 moved api/ to sdk/); every cursor-paginated pack exits non-zero on a repeated cursor instead of looping, and the 3.3 pack no longer reports a response with no data fields as an empty MCP allowlist; 1.1 Terraform declares okta/okta; 4.1 DLP patterns cover Mastercard 2-series and no longer match commit SHAs; Automation lines for 1.4, 2.1, 4.2, 4.3, 4.4; SCIM and custom retention plan gates corrected; 3.1 rate-limit carve-out corrected; dead Appendix B links replaced; changelog re-sorted (2026-06-29 entry renumbered 0.1.1 to 0.1.2: the page's frontmatter first read 0.1.1 at that commit, but the changelog had already given 0.1.1 to the 2026-02-19 entry, so keeping versions unique and ascending makes it the next free number, 0.1.2; initial entry dated to its 2026-02-05 commit) | Claude Code (Opus 5.5) |
| 2026-08-08 | 0.2.1 | ai-drafted | Cheat-sheet cell repair: added missing Attack Prevented line(s) to §1.3, §3.2, §4.1, §4.2, §5.1 (no content-facts changed) | Claude Code (Fable 5) |
| 2026-08-03 | 0.2.0 | ai-drafted | Add Information Barriers (1.5), MCP/AI agent governance (3.3), Slack AI feature access (4.4), and AI channel restriction (4.5); correct DLP plan prerequisite and file-scanning scope; note non-Marketplace app rate limits; update plan matrix to post-Aug 2025 lineup | Claude Code (Sonnet 5) |
| 2026-06-29 | 0.1.2 | ai-drafted | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2026-02-19 | 0.1.1 | ai-drafted | Extract inline code to Code Packs (SDK, Terraform, API) | Claude Code (Opus 4.6) |
| 2026-02-05 | 0.1.0 | ai-drafted | Initial guide with SSO, DLP, retention, and app controls | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)

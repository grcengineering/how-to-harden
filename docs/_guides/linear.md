---
layout: guide
title: "Linear Hardening Guide"
vendor: "Linear"
slug: "linear"
tier: "3"
category: "DevOps"
description: "Issue tracking platform hardening for Linear including SAML SSO and SCIM, login-method restriction, workspace access, team permissions, and integration security"
version: "0.3.0"
maturity: ["ai-drafted"]
last_updated: "2026-09-25"
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
This guide covers Linear security including SAML SSO and SCIM provisioning, login-method restriction, workspace membership and invitations, roles and team permissions, integration and API-key security, audit logging, and data residency.

**Automation surfaces.** Linear's administrative automation surface is its GraphQL API at `https://api.linear.app/graphql`; the official TypeScript SDK (`@linear/sdk`) wraps the same schema. Linear publishes no CLI and no Terraform provider of its own. A community provider (`terraform-community-providers/linear`) exists, but its `linear_workspace_settings` resource resets every setting you leave out to the provider's default, so this guide does not use it. The API packs below are read-only audits. Settings that decide who can sign in are left to the console on purpose, because a wrong value locks people out.

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
Configure SAML SSO so Linear sign-in runs through your identity provider. Claim your email domains so SAML is required for them, and enable SCIM so the IdP creates and suspends Linear accounts.

#### Rationale
**Why This Matters:**
- Centralizing Linear authentication in your corporate IdP enforces MFA, conditional access, and session policies on every login
- Without SAML, members sign in with a Google account, an emailed login link or code, or a passkey, all outside your IdP's policies. Linear has no passwords, so the emailed link is the phishable path
- Once SAML is enabled, members on SAML-approved (DNS-claimed) domains must sign in through SAML by default
- SAML's just-in-time provisioning creates accounts but never removes them. SCIM suspends a Linear account when the IdP deactivates the user, which closes orphaned access to roadmaps and issues
- Linear workspaces hold product roadmaps, security issues, and internal planning, so a single compromised login can expose sensitive engineering intelligence

**Attack Prevented:** Credential theft, phishing, account takeover, orphaned-account access

#### Prerequisites
- Enterprise plan (SAML and SCIM are Enterprise features)
- Linear workspace admin or owner access
- A SAML 2.0 identity provider. Linear documents Okta, Microsoft Entra ID, Google Workspace, and OneLogin, plus a custom SAML 2.0 integration
- DNS access to publish a TXT record for each domain you claim

#### ClickOps Implementation

**Step 1: Open SAML & SCIM Settings**
1. Navigate to: **Settings** → **Administration** → **Security**
2. Under **Authentication methods**, click **Configure** next to **SAML & SCIM**

**Step 2: Exchange Metadata with Your IdP**
1. Create a SAML 2.0 application in your IdP and enter the details Linear shows you. In Okta, Linear's ACS URL (it ends in `/acs`) is the Single sign-on URL
2. Press **Continue**, then give Linear your IdP's metadata, either as a metadata **XML URL** or as the **raw XML**. Metadata flows from the IdP to Linear: Okta's Metadata URL, Entra ID's Federation Metadata XML, or Google Workspace's downloaded metadata
3. In Entra ID, set the NameID to Email Address format. Linear takes each user's email from the SAML NameID
4. To change the configuration later, use **...** → **Edit Configuration** on the same settings page

**Step 3: Claim Your Domains so SAML Is Required**
1. Add each corporate domain under the SAML-approved email domains setting, and publish the DNS TXT record Linear gives you to claim it
2. Once SAML is enabled, members on SAML-approved domains must sign in through SAML by default. Existing sessions are not logged out, but those users must use SAML at their next sign-in
3. Allow non-SAML logins only for specific other email domains, such as contractors without IdP accounts, and keep that list short
4. Use the option to prevent non-admins from creating new Linear workspaces with a claimed-domain email (Linear's docs call it **Disable new workspace creation**)
5. Before you rely on enforcement, complete a SAML sign-in yourself. Owners and admins may be able to sign in with other methods to prevent lockouts, depending on your authentication settings. That is a safety net, not a test

**Step 4: Enable SCIM Provisioning**
1. On the same **SAML & SCIM** page, turn on SCIM and click **View configuration** to get the SCIM base connector URL and bearer token. Treat the bearer token as a secret
2. Enter both values in your IdP's provisioning settings. Linear has tested Okta and OneLogin
3. SCIM provisions users as Members by default. To assign roles from the IdP, push `linear-owners` (Enterprise), `linear-admins`, and `linear-guests` groups
4. After SCIM is enabled, manage members and admins in the IdP. A user deactivated there is suspended in Linear

**Time to Complete:** ~1-2 hours

#### Code Implementation

Linear's public GraphQL API has no write interface for SAML or SCIM: `OrganizationUpdateInput` carries no SAML or SCIM field, so configuration is console-only. The pack below is the read side. It proves both are enabled.

{% include pack-code.html vendor="linear" section="1.1" %}

Source: [SAML](https://linear.app/docs/saml-and-access-control), [SCIM](https://linear.app/docs/scim)

---

### 1.2 Restrict Login Methods to SAML or Passkeys

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.5 |
| NIST 800-53 | IA-2(1) |

#### Description
Use Linear's **Restrict login methods** setting to require specific sign-in methods for every member: SAML where you have it, passkeys otherwise. Without it, Google, emailed login link, passkey, and SAML all stay open. Linear has no two-factor authentication setting of its own; the lever is which methods you allow.

#### Rationale
**Why This Matters:**
- Linear has no passwords and no built-in second factor. Members sign in with a Google account, an emailed login link or code, a passkey, or SAML, so a Linear login is only as strong as the weakest method you allow
- With no restriction, every method stays open to every member, and an attacker needs only the weakest one, for example a phished email login code
- Requiring SAML moves MFA, device posture, and session policy into your IdP. Requiring passkeys gives an origin-bound credential that a phishing proxy cannot relay
- Owners and admins can still sign in with any method, so they can't be locked out of this setting. That makes those few accounts the ones to protect most (see 2.3)
- Linear issues and projects can reveal unreleased features and security work that attackers actively seek

**Attack Prevented:** Phishing of emailed login links and codes, account takeover through a weaker sign-in method, adversary-in-the-middle relay of non-phishing-resistant logins

**Linear has no two-factor authentication setting.** Earlier versions of this control told you to turn on a workspace **Require two-factor authentication** toggle. Linear's login-methods documentation lists four sign-in methods (Google, email, passkey, SAML) and no second factor, and the enforcement lever is **Restrict login methods** ([Login methods](https://linear.app/docs/login-methods), checked 2026-09-24).

#### Prerequisites
- Business or Enterprise plan (login restrictions); Enterprise plan for SAML
- Linear workspace admin or owner access

#### ClickOps Implementation

**Step 1: Register Passkeys First**
1. Each member adds a passkey from **Settings** → **Account** → **Security & Access**. Several devices can be registered
2. Passkeys aren't supported in the Linear desktop app. Before you require them, confirm your members can sign in through a browser or the mobile app
3. Start with owners and admins, and with members who can see private teams

**Step 2: Restrict Login Methods**
1. Navigate to: **Settings** → **Administration** → **Security**
2. Use **Restrict login methods** to allow only SAML (once 1.1 is complete) or passkey
3. Before saving, confirm that at least one owner or admin has completed a sign-in with the method you are requiring

**Step 3: Enforce MFA in the IdP**
1. When SAML is the required method, require MFA in your IdP for the Linear application, and phishing-resistant methods (FIDO2/WebAuthn) for admins
2. Login-method restrictions do not apply to guests invited directly to the workspace. Provision guests through your IdP when they need the same bar

#### Code Implementation

The login-method list can be set through the API (`organizationUpdate` with `authSettings`). This guide deliberately ships only the read side, because a mistaken restriction locks members out.

{% include pack-code.html vendor="linear" section="1.2" %}

Source: [Login methods](https://linear.app/docs/login-methods), [Security & Access](https://linear.app/docs/security-and-access), [SAML](https://linear.app/docs/saml-and-access-control)

---

### 1.3 Configure Allowed Domains

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3 |
| NIST 800-53 | AC-2 |

#### Description
Decide who can join the workspace without an explicit invitation, and who may send invitations. Keep approved email domains to domains your organization owns, limit invitations to admins, and keep the reusable invite link off.

#### Rationale
**Why This Matters:**
- An approved email domain is an auto-join rule, not a block: anyone with a matching address can join the workspace without an invitation or approval, so every listed domain is a standing grant of access
- Linear states that the setting does not prevent users from creating new workspaces with that domain's email. Blocking separate workspaces is the job of the SAML domain claim in 1.1
- A domain you let lapse or transfer keeps auto-join open to whoever controls it next, which is why Linear tells admins to remove such domains
- On paid plans only admins can invite by default. Turning on **Allow users to send invites**, or sharing the persistent invite link, widens who can bring people in

**Attack Prevented:** Unauthorized workspace joining, access through lapsed or transferred domains, invite-link leakage

**This control was reframed in 2026-09.** Earlier versions described approved domains as a way to block public email providers and outsiders. Linear's documentation describes an auto-join convenience that "does not prevent users from creating new workspaces with that domain email", so the hardening is to keep the list minimal ([Invite members](https://linear.app/docs/invite-members), checked 2026-09-24).

#### ClickOps Implementation

**Step 1: Review Approved Email Domains**
1. Navigate to: **Settings** → **Administration** → **Security**
2. Keep the approved email domains to domains your organization owns and controls. Never list a public email provider's domain, because every address on it could join
3. Remove any domain you have cancelled or transferred to another organization
4. Re-review the list on a regular schedule

**Step 2: Restrict Invitations**
1. On the same page, leave **Allow users to send invites** off so only admins can invite members (paid plans; on the Free plan every member is an admin)
2. Leave the invite link disabled. If you must use one, share it internally only and click **Reset invite link** whenever it may have leaked. Invite links are unavailable in SAML- and SCIM-enabled workspaces

**Step 3: Don't Confuse the Two Domain Settings**
1. The approved email domains here only streamline joining
2. The DNS-claimed SAML-approved domains in 1.1 are what make SAML sign-in mandatory for a domain

#### Code Implementation

Linear's public GraphQL schema has mutations for domains but no query that lists a workspace's approved email domains, so reviewing that list (Step 1) is console-only. The pack audits who may send invitations.

{% include pack-code.html vendor="linear" section="1.3" %}

Source: [Invite members](https://linear.app/docs/invite-members), [SAML](https://linear.app/docs/saml-and-access-control)

---

## 2. Access Controls

### 2.1 Configure Team Permissions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Implement least privilege with Linear's roles and teams. Give each person the lowest workspace role that fits, restrict team creation to admins, and use team owners to delegate team administration.

#### Rationale
**Why This Matters:**
- Scoping members to only the teams they need limits how much of the workspace any single compromised account can reach
- Linear's roles (Workspace owner, Admin, Team owner, Member, Guest) separate what ordinary users can change from what administrators can, and Guests see only the teams they are added to
- On the Free plan every user is an Admin, so least privilege in Linear is only possible on a paid plan
- Function-based teams contain the blast radius of a phished or insider account to a narrow slice of issues
- Regular access reviews catch privilege creep before it becomes a standing risk

**Attack Prevented:** Privilege escalation, lateral movement, insider data access, over-permissioned accounts

#### Prerequisites
- Linear workspace admin access
- Business or Enterprise plan for the Team owner and Guest roles; Enterprise plan for the Workspace owner role

#### ClickOps Implementation

**Step 1: Structure Teams**
1. Create teams by function: navigate to **Settings**, scroll to **Your teams**, and click **+** (Join or create a team). Admins can also manage teams from **Settings** → **Administration** → **Teams**
2. Restrict team creation to admins: **Settings** → **Administration** → **Security** → **Restrict team creation**
3. Set each team's visibility (see 2.2)

**Step 2: Assign Minimum Necessary Roles**
1. Navigate to: **Settings** → **Administration** → **Members**
2. Review the workspace roles:
   - **Workspace owner** (Enterprise only): full control, including billing, security, audit logs, workspace exports, and OAuth application approvals
   - **Admin**: routine workspace administration; on Enterprise plans, admins have more limited permissions than owners
   - **Team owner** (Business and Enterprise): delegated control of an individual team
   - **Member**: collaborates across the teams they can access; no workspace administration
   - **Guest** (Business and Enterprise): access only to the teams they are explicitly added to
3. Change a role from the member's row: overflow menu (⋯) → **Change role...**
4. Use Guests for contractors and external collaborators instead of Members
5. With SCIM enabled, roles come from IdP groups (`linear-owners`, `linear-admins`, `linear-guests`); manage them there
6. Review membership regularly. Suspend leavers from the row's overflow menu (⋯) → **Suspend user...**; suspended users lose all access immediately

**Step 3: Delegate Team Administration**
1. Promote team owners from **Team settings** → **Members**
2. In **Team settings** → **Access and permissions**, restrict label, template, team-settings, and member management to team owners where appropriate

#### Code Implementation

{% include pack-code.html vendor="linear" section="2.1" %}

Source: [Members and roles](https://linear.app/docs/members-roles), [Teams](https://linear.app/docs/teams)

---

### 2.2 Configure Project Visibility

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6 |

#### Description
Control who can see sensitive work by making the teams that own it private. In Linear, issue and project visibility follows team membership: people who are not members of a private team cannot see its issues.

#### Rationale
**Why This Matters:**
- By default every workspace member can view and join any team that is not private, and search its issues, projects, and documents
- Private teams hide their issues from non-members, and projects created under a private team are visible only to its members
- Controlling cross-team access enforces need-to-know on the most sensitive work
- A compromised low-privilege account can only see what visibility settings expose to it
- Private-team data can still leave through the API, webhooks, and integrations: a personal API key of a private-team member can read that team's issues, and team owners and admins can set up webhooks for private teams

**Attack Prevented:** Unauthorized data access, information disclosure, insider snooping

#### Prerequisites
- Business or Enterprise plan (private teams); Enterprise plan for sharing individual issues out of a private team
- Workspace owner, admin, or team owner access to change an existing team's visibility

#### ClickOps Implementation

**Step 1: Make Sensitive Teams Private**
1. For a new team, turn on **Make team private** when you create it from workspace settings
2. For an existing team, open its team settings (right-click the team in the sidebar) → **Access and permissions** → **Change team visibility**
3. Converting a team to private removes non-members from active issue assignments and unsubscribes non-member subscribers
4. Admins can review every private team at **Settings** → **Administration** → **Teams**

**Step 2: Restrict Who Can Join Public Teams**
1. In **Team settings** → **Access and permissions**, restrict team access to members that team owners add or invite

**Step 3: Control Sub-Teams and Issue Sharing**
1. Under a private parent team, choose **Private** for any sub-team that must be hidden from the parent team's members. **Restricted**, the default, lets members of the parent team see and join it
2. On Enterprise, decide in **Team settings** → **Access and permissions** → **Issue sharing** whether members may share individual issues out of a private team

**Step 4: Review Exposure Paths**
1. Review the API keys (3.2), webhooks, and integrations (3.1) held by members of private teams
2. When exporting, remember that admins can include issues from any private team

#### Code Implementation

{% include pack-code.html vendor="linear" section="2.2" %}

Source: [Private teams](https://linear.app/docs/private-teams), [Members and roles](https://linear.app/docs/members-roles), [Teams](https://linear.app/docs/teams)

---

### 2.3 Limit Admin Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4 |
| NIST 800-53 | AC-6(1) |

#### Description
Keep the set of workspace owners and admins small and documented, and use Linear's workspace restrictions to decide which role may perform sensitive workspace-level actions.

#### Rationale
**Why This Matters:**
- Owners and admins control sign-in methods, SAML, approved domains, API and integration settings, and membership, and they can sign in with any login method even when others are restricted. Each one is a high-value target
- Keeping admins to a small, documented set shrinks the attack surface for workspace takeover
- Protecting admin accounts with passkeys or IdP-enforced MFA protects the controls every other user depends on
- Monitoring admin activity surfaces unauthorized configuration changes quickly
- On the Free plan every user is an Admin, so this control can only be met on a paid plan

**Attack Prevented:** Workspace takeover, privilege abuse, unauthorized configuration changes

#### Prerequisites
- A paid plan (on the Free plan every user is an Admin)
- Enterprise plan and the Workspace owner role for workspace restrictions

#### ClickOps Implementation

**Step 1: Inventory Admins and Owners**
1. Navigate to: **Settings** → **Administration** → **Members** and filter by role
2. Any member can list the admins from the command menu (Cmd/Ctrl K) → **View workspace admins**
3. Document why each person holds the role

**Step 2: Reduce and Protect**
1. Limit admins and owners to 2-3 people
2. Demote anyone else from the member's row: overflow menu (⋯) → **Change role...** With SCIM, change membership of the `linear-admins` and `linear-owners` groups in the IdP instead
3. Protect every owner and admin account with a passkey (1.2) or IdP-enforced MFA (1.1)
4. Monitor admin activity in the audit log (4.1)

**Step 3: Scope Sensitive Actions (Enterprise)**
1. As a workspace owner, navigate to: **Settings** → **Administration** → **Security** → **Workspace restrictions**
2. Configure which roles may perform workspace-level actions. Linear's API exposes these as minimum-role settings for inviting users, creating teams, creating personal API keys, managing API settings, installing integrations, and granting the admin role

#### Code Implementation

{% include pack-code.html vendor="linear" section="2.3" %}

Source: [Members and roles](https://linear.app/docs/members-roles), [Login methods](https://linear.app/docs/login-methods)

---

## 3. Integration Security

### 3.1 Configure Integration Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Control which third-party apps can be installed. Review the integrations, OAuth applications, and webhooks already connected, and verify the signature on every webhook your systems receive from Linear.

#### Rationale
**Why This Matters:**
- Each connected integration is granted access to workspace data and expands the supply-chain attack surface
- Removing unused integrations eliminates dormant OAuth grants that attackers can abuse if the vendor is compromised
- An app requests its OAuth scopes when it is authorized, and Linear documents no admin setting that narrows them afterward, so the effective control is deciding which apps get installed at all
- Integrations enabled for the workspace are reachable by guest users, which can expose data from teams the guest was never added to
- A webhook receiver that does not verify Linear's signature accepts forged events from anyone who learns its URL

**Attack Prevented:** Supply-chain compromise, OAuth token abuse, data exfiltration via third parties, forged webhook events

#### Prerequisites
- Any paid plan for third-party application approvals
- Admin permissions to view **Settings** → **Administration** → **API**; on Enterprise, the workspace owner manages app approvals

#### ClickOps Implementation

**Step 1: Require Approval for Third-Party Apps**
1. Navigate to: **Settings** → **Administration** → **Security**
2. Turn on third-party application approvals. On Enterprise a workspace owner does this; on other paid plans a workspace admin does
3. Members who try to install an app can then only request approval. Approved and denied apps appear in **Applications**

**Step 2: Review Integrations, OAuth Apps, and Webhooks**
1. Navigate to: **Settings** → **Integrations** and remove integrations the workspace no longer uses
2. Navigate to: **Settings** → **Administration** → **API** and review OAuth applications and webhooks. Delete any webhook without a current owner
3. For Linear-built integrations (GitHub, GitLab, Figma, Sentry, Intercom, Zapier, Airbyte), make sure guest users have no access to your accounts on those services

**Step 3: Verify Webhook Signatures**
1. Copy each webhook's signing secret from the webhook's detail page
2. Every receiver must verify the `Linear-Signature` header, a hex-encoded HMAC-SHA256 of the raw request body keyed with that secret, and reject any request whose signed `webhookTimestamp` is more than a minute old
3. Optionally, also accept only Linear's published outbound IP addresses (`https://linear.app/.well-known/appspecific/app.linear.ips.json`)

#### Code Implementation

The API pack audits the integration surface. The SDK pack is a webhook receiver that accepts only signed, fresh events, using Linear's official SDK helper.

{% include pack-code.html vendor="linear" section="3.1" %}

Source: [Third-Party App Approvals](https://linear.app/docs/third-party-application-approvals), [API and Webhooks](https://linear.app/docs/api-and-webhooks), [Webhooks](https://linear.app/developers/webhooks), [SDK webhooks](https://linear.app/developers/sdk-webhooks), [Members and roles](https://linear.app/docs/members-roles), [GitHub integration](https://linear.app/docs/github)

---

### 3.2 Configure API Tokens

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.11 |
| NIST 800-53 | SC-12 |

#### Description
Restrict who may create personal API keys. Then review and prune everything that holds standing credentials to a Linear account: personal API keys, active sessions, and authorized OAuth applications.

#### Rationale
**Why This Matters:**
- Personal API keys act as long-lived credentials that bypass interactive SSO and login-method restrictions
- Keys leaked in code, logs, or CI configs grant direct programmatic access to workspace data
- Admins decide whether Members may create API keys at all, and can see and revoke every existing key in the workspace
- Authorized OAuth applications hold delegated access that persists after the tool stops being used, so an unrevoked grant is a live path into the workspace if the third party is breached
- Active sessions are recorded with location and date, which makes an unrecognized session the earliest visible sign of account takeover
- Documenting key purposes makes it possible to spot and revoke credentials that no longer have an owner

**Attack Prevented:** Credential leakage, token theft, unauthorized API access, OAuth grant abuse, persistent access via stale tokens and sessions

#### ClickOps Implementation

**Step 1: Restrict and Review Workspace API Keys**
1. Navigate to: **Settings** → **Administration** → **API**
2. Under **Member API keys**, choose whether Members may create their own API keys. Admins can always create them
3. Review the workspace's existing API keys on the same page and revoke any without a documented owner and purpose

**Step 2: Review Personal API Keys**
1. Navigate to: **Settings** → **Account** → **Security & Access**
2. Review every personal API key and document its purpose and owner
3. Create automation keys with the narrowest permission that works (Read, Write, Admin, Create issues, Create comments), limited to specific teams where possible
4. Revoke keys with no documented owner or purpose

**Step 3: Revoke Stale Sessions**
1. On the same page, review **active sessions**. Each is listed with its location and date last seen, and clicking an entry shows its IP address and original sign-in date
2. Revoke any session from an unrecognized location, an old device, or a departed contractor. Inactive sessions expire automatically after 30 days
3. Treat an unexplained session as a suspected compromise: revoke it, then rotate the account's API keys

**Step 4: Review Authorized OAuth Applications**
1. Review the list of **authorized OAuth applications** on the same page
2. Revoke every application the member no longer actively uses
3. Re-review after any third-party breach disclosure affecting a connected vendor

When a user is suspended or converted to a guest, Linear revokes that user's API tokens.

#### Code Implementation

Linear's public GraphQL schema has no type that lists personal API keys, so reviewing existing keys (Steps 1–2) is console-only. The pack checks who may create keys and inventories the key owner's own sessions.

{% include pack-code.html vendor="linear" section="3.2" %}

Source: [API and Webhooks](https://linear.app/docs/api-and-webhooks), [Security & Access](https://linear.app/docs/security-and-access), [Invite members](https://linear.app/docs/invite-members)

---

## 4. Monitoring & Compliance

### 4.1 Configure Audit Logs

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2 |
| NIST 800-53 | AU-2 |

#### Description
Review Linear's workspace audit log and stream it to your SIEM. Linear keeps audit events for only 90 days, so anything you need beyond that window has to be exported while it still exists.

#### Rationale
**Why This Matters:**
- The audit log is the workspace's record of who did what. Each entry carries the actor's IP address and country, which is what makes an anomalous login or a session from an unexpected jurisdiction visible
- Linear retains audit log events for **90 days only**. An intrusion discovered on a typical breach-detection timeline can easily predate the oldest available evidence, and exporting to a SIEM is what preserves the trail
- Monitoring authentication, permission, and integration events surfaces account compromise and insider abuse early
- Retained audit records support SOC 2, GDPR, and HIPAA evidence requirements, which generally demand retention well beyond 90 days

**Attack Prevented:** Undetected intrusion, insider abuse, repudiation, delayed incident response, evidence loss through log expiry

#### Prerequisites
- Enterprise plan
- Workspace **Owner** role; the audit log is restricted to workspace owners

#### ClickOps Implementation

**Step 1: Access the Audit Log**
1. Navigate to: **Settings** → **Administration** → **Audit Log** (workspace owners only)
2. Review entries (actor, action, IP address, and country). You can filter by event type and hide session-creation events
3. Confirm the 90-day retention window against your own evidence requirements

**Step 2: Stream Logs to Your SIEM**
1. On the **Audit Log** page, enable **Stream logs** and configure the webhook endpoint
2. Point the webhook at your SIEM's HTTP collector so events are captured continuously rather than exported by hand
3. Verify the webhook's signature with its signing secret, as in 3.1, so forged events cannot be injected into your audit trail
4. Verify events are arriving, then set retention in the SIEM to match your compliance obligation

**Step 3: Query Programmatically**
1. The audit log is queryable through Linear's GraphQL API (`auditEntries`), filterable by type, actor, IP address, and date range; `auditEntryTypes` lists every event type
2. Use it for point-in-time investigation, and to reconcile SIEM coverage gaps before the 90-day window closes

**Key Events to Monitor:**
- Authentication events and sessions from unexpected countries
- Permission and role changes
- Integration and OAuth application changes
- Membership additions and removals

#### Code Implementation

{% include pack-code.html vendor="linear" section="4.1" %}

Source: [Audit log](https://linear.app/docs/audit-log)

---

### 4.2 Choose Data Residency at Workspace Creation

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.1 |
| NIST 800-53 | SA-9 |

#### Description
Linear lets you choose whether a workspace's data is hosted in the **US** or the **EU** region. The choice is made **at workspace creation** and is not self-serve to change afterward, so regulated teams must decide before the workspace exists.

#### Rationale
**Why This Matters:**
- Data residency is effectively fixed in Linear. Pick the wrong region and the self-serve remedy is creating a new workspace and migrating the data, which is expensive and disruptive once issues, projects, and integrations have accumulated
- Teams subject to GDPR, national data-localization rules, or customer contracts with residency clauses need the EU region selected up front to keep issue content, attachments, and comments inside the required jurisdiction
- Issue trackers accumulate personal data incidentally (customer names in bug reports, screenshots, support transcripts), so residency obligations apply even when the workspace was never intended to hold regulated data
- Documenting which region a workspace runs in gives auditors and vendor-risk reviewers a verifiable answer instead of an assumption

**Attack Prevented:** Regulatory exposure from cross-border data transfer, residency-clause breach, unplanned data migration

**Some data stays in the US whatever region you choose.** Workspace information, all user account information, and user-created API keys (used to authenticate users and route them to the right region), notification emails (held 7 days by Linear's email provider), usage and analytics data, and crash-related account information are always stored in the United States ([Security](https://linear.app/docs/security), checked 2026-09-24). Record these exceptions in your data-processing inventory.

#### ClickOps Implementation

**Step 1: Decide Region Before Creating the Workspace**
1. Confirm your residency obligation (GDPR, customer contract, internal policy) before anyone provisions the workspace
2. Select the **EU** region at creation if any obligation requires EU hosting; otherwise select **US**
3. Record the chosen region in your vendor inventory, together with the US-only data categories above

**Step 2: Verify Existing Workspaces**
1. Navigate to: **Settings** → **Administration** → **Workspace** to see each existing workspace's region
2. Where a workspace is in the wrong region, plan a migration to a new, correctly provisioned workspace rather than expecting a setting change
3. Document the outcome for audit evidence

**Automation:** ClickOps only. Linear exposes no write interface for this setting: the region is chosen when the workspace is created and "isn't self-serve to change later" ([Security](https://linear.app/docs/security), 2026-09-24).

#### Validation & Testing
Read the workspace's region at **Settings** → **Administration** → **Workspace** and check that it matches the region recorded in your data-processing inventory. Since the setting is fixed at creation, validation is a one-time attestation rather than a recurring config check.

Source: [Security](https://linear.app/docs/security)

---

## 5. Compliance Quick Reference

### SOC 2 Trust Services Criteria Mapping

| Control ID | Linear Control | Guide Section |
|-----------|----------------|---------------|
| CC6.1 | SSO and login-method restriction | [1.1](#11-configure-saml-single-sign-on) |
| CC6.2 | Team permissions | [2.1](#21-configure-team-permissions) |
| CC7.2 | Audit logs | [4.1](#41-configure-audit-logs) |

### NIST 800-53 Rev 5 Mapping

| Control | Linear Control | Guide Section |
|---------|----------------|---------------|
| IA-2 | SSO | [1.1](#11-configure-saml-single-sign-on) |
| IA-2(1) | Login-method restriction | [1.2](#12-restrict-login-methods-to-saml-or-passkeys) |
| AC-6 | Team permissions | [2.1](#21-configure-team-permissions) |
| AU-2 | Audit logs | [4.1](#41-configure-audit-logs) |

---

## Appendix A: References

**Official Linear Documentation:**
- [Linear Documentation](https://linear.app/docs)
- [Login methods](https://linear.app/docs/login-methods)
- [SAML](https://linear.app/docs/saml-and-access-control)
- [SCIM](https://linear.app/docs/scim)
- [Invite members](https://linear.app/docs/invite-members)
- [Members and roles](https://linear.app/docs/members-roles)
- [Teams](https://linear.app/docs/teams)
- [Private teams](https://linear.app/docs/private-teams)
- [API and Webhooks](https://linear.app/docs/api-and-webhooks)
- [Third-Party App Approvals](https://linear.app/docs/third-party-application-approvals)
- [Security](https://linear.app/docs/security)
- [Security & Access](https://linear.app/docs/security-and-access)
- [Audit log](https://linear.app/docs/audit-log)

**API & Developer Resources:**
- [Linear Developers](https://linear.app/developers)
- [GraphQL API: getting started](https://linear.app/developers/graphql)
- [Webhooks](https://linear.app/developers/webhooks)
- [TypeScript SDK](https://linear.app/developers/sdk)
- [SDK webhook helper](https://linear.app/developers/sdk-webhooks)
- [GraphQL schema (SDL)](https://raw.githubusercontent.com/linear/linear/master/packages/sdk/src/schema.graphql)

**Compliance Frameworks:**
- SOC 2 Type II, GDPR, HIPAA (Enterprise plan with BAA). See [Linear Security documentation](https://linear.app/docs/security)

**Security Incidents:**
- No major public security breaches identified as of this writing.

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-09-25 | 0.3.0 | ai-drafted | validate-hth-guide run (Phases 4–5, read-only tenant policy). 0 surfaces exercised live: the Linear console was behind a sign-in wall in the validation browser and no API key could be minted, so maturity is unchanged. Corrections from current Linear docs: rewrote 1.2 around **Restrict login methods** (Linear has no two-factor setting; renamed from "Enforce Two-Factor Authentication"); fixed console paths throughout (**Settings → Administration → …**); 1.1 now describes metadata exchange, domain claiming and SCIM; 1.3 reframed approved domains as auto-join rather than a block and added invitation controls; 2.1 lists all five roles and the Free-plan all-admin caveat; 2.2 gains real paths for private teams; 2.3 adds workspace restrictions; 3.1 adds third-party app approvals and webhook signature verification; 3.2 adds the workspace Member API keys setting; 4.2 lists the data that always stays in the US; replaced the stale developers.linear.app links. Added nine read-only GraphQL audit packs and one SDK webhook-verification pack, all run against a schema-validating mock and failing closed against the real API; 4.2 carries a ClickOps-only automation verdict | Claude Code (Opus 5.5) |
| 2026-08-08 | 0.2.0 | ai-drafted | Currency pass, scope-limited: only three Linear documentation pages (security, security-and-access, audit-log) were publicly reachable this pass, so findings outside them soften rather than assert. Rewrote 4.1 audit log (Enterprise, workspace owners only, 90-day retention, GraphQL queryable, webhook streaming to SIEM, actor IP/country); added 4.2 data residency (US/EU, fixed at workspace creation); added passkeys to 1.2 and OAuth-grant/session review to 3.2; annotated 1.2 and 1.3 as unverifiable against current public docs; removed the 404 SAML SSO link and the Trust Center/security marketing links in favor of linear.app/docs/security | Claude Code (Opus 4.8) |
| 2026-06-29 | 0.1.1 | ai-drafted | Add cheat-sheet Description and Rationale for all controls | Claude Code (Opus 4.8) |
| 2025-02-05 | 0.1.0 | ai-drafted | Initial guide with SSO, teams, and integrations | Claude Code (Opus 4.5) |

---

## Contributing

Found an issue or want to improve this guide?

- **Report outdated information:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `content-outdated`
- **Propose new controls:** [Open an issue](https://github.com/grcengineering/how-to-harden/issues) with tag `new-control`
- **Submit improvements:** See [Contributing Guide](/contributing/)

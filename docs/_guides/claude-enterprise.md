---
layout: guide
title: "Claude Enterprise Hardening Guide"
vendor: "Claude Enterprise"
slug: "claude-enterprise"
platform: "Anthropic"
platform_slug: "anthropic"
product: "Claude Enterprise (claude.ai)"
tier: "1"
category: "AI/ML Platform"
description: "Security hardening for Claude.ai Team and Enterprise plans — SSO and SCIM provisioning, roles and groups, audit log export, Compliance API, connector and Claude-in-Chrome governance, Cowork controls, and per-member spend limits."
version: "0.2.0"
maturity: ["ai-drafted"]
last_updated: "2026-08-15"
---

## Overview

Claude.ai Team and Enterprise plans are the chat-product surface of Anthropic: workspaces where employees converse with Claude, attach files, run Projects, and increasingly wire Claude into company systems through connectors, the Chrome extension, and Cowork. The admin surface that governs all of this lives in claude.ai's Organization settings, and most of it ships permissive-by-default on Team plans.

This is a **product guide within the [Anthropic platform](/guides/anthropic-claude/)**. Organization-wide controls (SSO details, org roles, admin API keys, integration governance) live in the Anthropic **Common Controls** hub; Claude Code and API/Console hardening live in their own guides.

### Intended Audience
- Security engineers governing enterprise AI assistants
- IT administrators running a Claude for Work deployment
- GRC professionals wiring Claude activity into audit and DLP programs

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers claude.ai Team/Enterprise administration: SSO and SCIM provisioning, role and group hygiene, audit log export, the Compliance API and least-privilege admin key scoping, connector governance (including verified-domain protection and per-action permissions), Claude in Chrome enablement policy, Cowork governance, and per-member spend limits. Claude Code client policy is covered in the [Claude Code guide](/guides/claude-code/); API keys and workspaces in the [Claude API & Console guide](/guides/anthropic-api/).

---

## Table of Contents

1. [Identity & Provisioning](#1-identity--provisioning)
2. [Audit & Compliance](#2-audit--compliance)
3. [Connectors & Extensions](#3-connectors--extensions)
4. [Spend Governance](#4-spend-governance)

---

## 1. Identity & Provisioning

### 1.1 Enforce SSO with Domain Verification

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 6.7, 12.5 |
| NIST 800-53 | IA-2, IA-8 |

#### Description
Verify your domains and enforce SAML 2.0/OIDC single sign-on for the claude.ai organization so every sign-in flows through your identity provider and its MFA/Conditional Access policies.

#### Rationale
**Why This Matters:**
- Without SSO enforcement, employees can hold password-based Claude accounts outside your identity lifecycle
- Domain verification is the anchor for the org's identity boundary (and a prerequisite for the connector verified-domain protection in [3.2](#32-block-cross-org-connection-of-your-verified-domains))
- IdP-enforced MFA and session policy apply to Claude only when sign-in is federated

**Attack Prevented:** Credential-based account takeover, orphaned accounts surviving offboarding

#### ClickOps Implementation

1. Navigate to: **claude.ai** → **Organization settings** → **Identity & Provisioning**
2. Verify your email domain(s) per the console instructions
3. Configure SAML 2.0 or OIDC against your IdP and test with a pilot user
4. Enforce SSO for all members once the pilot succeeds

**Time to Complete:** ~1 hour

#### Validation & Testing
1. A non-pilot member signing in is redirected to the IdP
2. Password sign-in for the org's verified domains is refused

**Expected result:** All org sign-ins federated. ([Set up single sign-on](https://support.claude.com/en/articles/13132885-setting-up-single-sign-on-sso) · [Enterprise administrator guide](https://claude.com/resources/tutorials/claude-enterprise-administrator-guide))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1 | Logical access security |
| **NIST 800-53** | IA-2 | Identification and authentication |

---

### 1.2 Use SCIM Provisioning, Not JIT

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.3, 6.2 |
| NIST 800-53 | AC-2 |

#### Description
Provision claude.ai members via SCIM directory sync rather than just-in-time (JIT) creation. SCIM automatically deprovisions members when they are removed from the IdP; JIT only creates accounts at sign-in and leaves stale members in the org list until they next attempt login.

#### Rationale
**Why This Matters:**
- JIT provisioning has no deprovisioning half — departed employees keep their seats, conversation history, and any connector grants until manually removed
- SCIM syncs group membership, which Enterprise custom roles and Cowork/Chrome capability gating depend on
- Automated lifecycle closes the classic offboarding gap for a tool that accumulates sensitive prompts and files

**Attack Prevented:** Departed-employee access persistence and orphaned seats holding sensitive conversation history

#### ClickOps Implementation

1. Navigate to: **Organization settings** → **Identity & Provisioning**
2. Choose **SCIM provisioning** and generate the SCIM token for your IdP
3. In the IdP, configure the SCIM integration (create, update, deactivate) and map groups
4. Confirm JIT-only mode is disabled once SCIM sync is live

**Time to Complete:** ~45 minutes

#### Validation & Testing
1. Remove a test user from the IdP — their claude.ai membership deactivates on the next sync
2. Group membership changes in the IdP reflect in claude.ai groups

**Expected result:** Membership mirrors the directory with automatic deprovisioning. ([Set up JIT or SCIM provisioning](https://support.claude.com/en/articles/13133195-set-up-jit-or-scim-provisioning))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.2 | User registration and deregistration |
| **NIST 800-53** | AC-2 | Account management |

---

### 1.3 Apply Least-Privilege Roles and Groups

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 5.4, 6.8 |
| NIST 800-53 | AC-6(1) |

#### Description
Keep the claude.ai role model tight: minimize primary owner/owner/admin counts, use Enterprise groups and custom roles to gate capabilities (Cowork, Claude in Chrome, model access) rather than granting broad admin, and review assignments on a cadence.

#### Rationale
**Why This Matters:**
- claude.ai roles are distinct from the Console org roles — auditing one does not cover the other. The documented Enterprise role vocabulary is five values: `user`, `managed` (permissions come solely from the custom roles attached to the member's groups — the least-privilege target state), `owner`, `membership_admin` (can manage members), and `primary_owner` (exactly one)
- Enterprise custom roles + groups are the mechanism that scopes risky capabilities (Chrome extension, Cowork cloud sessions) to the users who need them
- Excess owners multiply the accounts able to change identity, connector, and data settings org-wide

**Attack Prevented:** Privilege sprawl enabling org-wide settings tampering from any one compromised account

> **The role model is now auditable — and partly manageable — in code (verified 2026-08-15).** A beta Admin API surface is enabled for all Claude Enterprise organizations at `https://api.anthropic.com/v1/organizations/`: members (list, lookup-by-email, change-role, remove), invites (create, list, withdraw), groups including per-group membership (full CRUD for `direct` groups), and read-only custom roles. Group and custom-role requests need the beta header `anthropic-beta: ce-user-management-2026-07-13` (404 without it). The API can assign only `user` and `managed`; the administrative roles are assigned only in claude.ai settings and members holding them cannot be modified via API. SCIM-provisioned groups (`source_type: scim`) are API-read-only — change them in the IdP. ([User management](https://platform.claude.com/docs/en/manage-claude/user-management))

#### ClickOps Implementation

1. Navigate to: **Organization settings** → **Members**
2. Reduce owners/admins to the minimum named set; everyone else is a member — and prefer `managed` (custom-roles-only permissions) as the standard member state where the org uses groups seriously
3. (Enterprise) Define groups synced from the IdP and create custom roles gating capabilities per group
4. Add role review to your quarterly access-review cycle
5. **Guard two API-side privilege paths:** invite automation that passes `rbac_group_ids` grants the permissions of the groups' attached roles at accept-time and requires `write:rbac_groups` — treat keys holding that scope at the same tier as membership-admin credentials. And **deleting a group drops its members' attached-role permissions AND stops any group spend limit applying to them** — a group deletion can silently lift a spend cap (see 4.1)

**Time to Complete:** ~30 minutes

#### Validation & Testing
1. Owner/admin list matches the documented named set
2. A member without the gated role cannot enable Cowork/Chrome capabilities
3. Programmatic blanket-grant sweep: page `GET /v1/organizations/rbac_roles/{role_id}/permissions` for every custom role and flag any `organization` permission with action `capability_access_all` or `capability_access_all_ga` — these are blanket product-feature grants that defeat capability-gating

**Expected result:** Capability access follows group membership; admin count minimal; no custom role silently carries a blanket grant. ([Enterprise administrator guide](https://claude.com/resources/tutorials/claude-enterprise-administrator-guide))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.3 | Role-based access |
| **NIST 800-53** | AC-6(1) | Least privilege |

---

## 2. Audit & Compliance

### 2.1 Export and Retain Audit Logs

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2, 8.9 |
| NIST 800-53 | AU-2, AU-11 |

#### Description
Export the Enterprise audit log on a schedule and retain it in your own log store. The in-product export covers a 180-day lookback with a 24-hour download link, excludes chat titles/content, and exists on Enterprise only. Anthropic's own docs now position this export as "significantly narrower" than the Compliance API — "a capped lookback window, CSV download only, and no access to chat, file, or project content. Standardize on the Compliance API for ongoing programmatic use" — so treat this control as the floor and [2.2](#22-enable-the-compliance-api-with-least-privilege-keys) as the programmatic path.

#### Rationale
**Why This Matters:**
- 180 days is shorter than most investigation and compliance retention requirements — without scheduled export, older evidence is gone
- Admin actions (role changes, connector enablement, identity settings) are exactly what you need when investigating a misconfiguration or compromise
- Team plans lack the export entirely — a factor in plan selection for regulated environments

**Attack Prevented:** Not preventive — the investigation capability that makes admin-surface tampering discoverable

#### ClickOps Implementation

1. Navigate to: **Organization settings** → **Data and Privacy** → **Export logs**
2. Run the export and download within the 24-hour link window
3. Schedule a recurring calendar/automation task to export before the 180-day window rolls off
4. Land exports in your SIEM/log store with your standard retention

**Time to Complete:** ~30 minutes plus recurring task

#### Validation & Testing
1. Exported CSV parses and covers the expected window
2. Recurring export lands in the log store on schedule

**Expected result:** Continuous audit history beyond the 180-day product window. ([Access audit logs](https://support.claude.com/en/articles/9970975-access-audit-logs))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.2 | System monitoring |
| **NIST 800-53** | AU-11 | Audit record retention |

---

### 2.2 Enable the Compliance API with Least-Privilege Keys

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.2, 3.3 |
| NIST 800-53 | AU-6, AC-6 |

#### Description
Use the Compliance API (`/v1/compliance/activities` plus directory, effective-settings, content, and session endpoints) for programmatic audit and eDiscovery over claude.ai activity, and scope the keys that access it to the minimum selectable scopes. Scopes are fixed at key creation. Coverage now extends well beyond claude.ai chat: the session endpoints return transcripts of **Cowork and Claude Code sessions run on users' machines** (local sessions, captured while signed in with the Enterprise account) and cloud Cowork sessions from claude.ai web/mobile (remote sessions), plus directory data and effective settings across every linked organization.

> **Two key types reach this API — only one reaches all of it (verified 2026-08-15).** A **Compliance Access Key** (`sk-ant-api01-...`, created by the primary owner or an organization owner at **claude.ai → Organization settings → API**) reaches every Compliance API endpoint per its scopes. An **Admin API key** (`sk-ant-admin01-...`, created in the Claude Console) reaches the **Activity Feed only** — every other compliance endpoint returns `403`. Wire full-content tooling to a Compliance Access Key, not a Console admin key.

> **The enablement toggle governs recording itself.** The primary owner enables the Compliance API at claude.ai → Organization settings → API (cascades to linked orgs); eligible standalone Console orgs have a self-service toggle at **Console → Settings → Security**. While the toggle is off, **no activity events are recorded and local Cowork/Claude Code transcripts are not captured — un-recorded activity cannot be recovered later.** Treat the toggle as a protected setting: turning it off is an audit-destruction action, and Admin API keys carry `read:compliance_activities` only if the Compliance API was enabled when the key was created.

#### Rationale
**Why This Matters:**
- The Compliance API is the programmatic audit path for claude.ai — the vendor's own docs position the in-product CSV export as "significantly narrower" and say to standardize on this API for programmatic use
- The four Compliance Access Key scopes are `read:compliance_activities` (Activity Feed), `read:compliance_user_data` (chats, files, projects, Cowork/Claude Code session transcripts, users, group members), `delete:compliance_user_data` (delete chats/files/projects), and `read:compliance_org_data` (org metadata + effective settings). The broader `read:org_audit` scope — one read-only scope covering every user-management GET plus every Compliance read — is the cleanest choice for SIEM/security-audit integrations; an unscoped or over-scoped key is a standing exfiltration risk over your entire org's conversation and session content
- `delete:compliance_user_data` in particular should live on its own tightly-held key, if issued at all
- Compliance Access Keys **do not expire on their own**, and scopes are immutable — rotation is create-new-then-delete (deletion takes effect on the next request, no grace period)

**Attack Prevented:** Bulk conversation- and session-content exfiltration via an over-scoped compliance key, silent audit-recording disablement

#### ClickOps Implementation

1. Enable the Compliance API (primary owner, claude.ai → Organization settings → API), and record the toggle as a protected setting in your change-control docs
2. Create **Compliance Access Keys** at claude.ai → Organization settings → API with only the scopes each consumer needs (see the [key scope table](https://platform.claude.com/docs/en/manage-claude/admin-api-keys)); use `read:org_audit` for audit-only consumers
3. Wire your compliance/DLP tooling to `/v1/compliance/activities` for continuous activity-feed consumption — all `/v1/compliance/*` endpoints share a **600 requests-per-minute** limit per parent organization, so size polling cadence and backoff accordingly
4. Inventory issued keys, their scopes, and their holders; store them in a secrets manager, never in source control or SIEM forwarder configuration
5. **Put key deletion in the offboarding runbook:** keys are scoped to the organization, not the creator — removing, deprovisioning, or downgrading the creator leaves every key they created active with its original scopes. Delete their keys and issue replacements

**Time to Complete:** ~1 hour

#### Validation & Testing
1. A read-scoped key is refused on delete endpoints — the `403` body lists held vs required scopes
2. Activity feed events arrive in your tooling for a test conversation
3. Confirm a local Claude Code session run under an Enterprise-signed-in account appears in the session endpoints
4. On suspected key leak: delete the key, then audit the feed with `activity_types[]=compliance_api_accessed`, matching `actor.type` `api_actor` and `actor.api_key_id` to the compromised key

**Expected result:** Continuous programmatic audit with scope-minimal keys, recording provably on, and key lifecycle tied to offboarding. ([Compliance API](https://platform.claude.com/docs/en/manage-claude/compliance-api) · [Access setup](https://platform.claude.com/docs/en/manage-claude/compliance-api-access) · [Admin key scopes](https://platform.claude.com/docs/en/manage-claude/admin-api-keys))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.2 | System monitoring |
| **NIST 800-53** | AC-6 | Least privilege |

---

## 3. Connectors & Extensions

### 3.1 Govern Connectors with Per-Action Permissions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.5, 6.8 |
| NIST 800-53 | AC-3, CM-7 |

#### Description
Control which connectors (MCP integrations) the organization can use, and set per-connector, per-action-category permissions — Always allow / Needs approval / Blocked — so write-capable actions default to approval or blocked while reads stay available.

#### Rationale
**Why This Matters:**
- A connector runs with delegated access to the connected system; a prompt-injected Claude session can invoke its actions
- Per-action-category permissions are the mechanism to keep Claude read-only against systems of record while still useful
- Custom remote MCP connectors carry Anthropic's own explicit warning to connect only to trusted servers — treat connector addition like app-store approval

**Attack Prevented:** Prompt-injection-driven writes/exfiltration through connected business systems

#### ClickOps Implementation

1. Navigate to: **Organization settings** → **Connectors**
2. Enable only reviewed, business-justified connectors
3. For each connector: **Customize** → **Connectors** → set each action category to **Blocked** or **Needs approval**; reserve **Always allow** for read-only categories
4. Establish a review workflow for new connector requests (owner, data-access assessment)

**Time to Complete:** ~1 hour initial

#### Validation & Testing
1. A write-category action from a test conversation prompts for approval or is blocked
2. Non-allowlisted connectors cannot be added by members

**Expected result:** Connector surface enumerated, writes gated. ([Use connectors](https://support.claude.com/en/articles/11176164-use-connectors-to-extend-claude-s-capabilities))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.3 | Access authorization |
| **NIST 800-53** | CM-7 | Least functionality |

---

### 3.2 Block Cross-Org Connection of Your Verified Domains

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 3.3 |
| NIST 800-53 | AC-3, SC-7 |

#### Description
Enable the Enterprise protection that prevents services on your verified domains from being connected to Claude accounts outside your organization — closing the path where an employee's personal Claude account connects to corporate systems.

#### Rationale
**Why This Matters:**
- Without it, any user with credentials to a corporate service can wire that service into a PERSONAL Claude account, moving corporate data outside every org control in this guide
- The protection leverages the same domain verification done for SSO ([1.1](#11-enforce-sso-with-domain-verification))
- Pairs with network-level Tenant Restrictions (see the [platform hub](/guides/anthropic-claude/)) for defense in depth

**Attack Prevented:** Corporate-data exfiltration through personal Claude accounts connected to company services

#### ClickOps Implementation

1. Confirm domain verification is complete ([1.1](#11-enforce-sso-with-domain-verification))
2. Navigate to: **Organization settings** → **Connectors** and enable the verified-domain restriction
3. Communicate the policy so employees route legitimate needs through org accounts

**Time to Complete:** ~15 minutes

#### Validation & Testing
1. From a personal Claude account, attempt to connect a service on a verified domain — it should be refused

**Expected result:** Verified-domain services connect only to org accounts. ([Use connectors](https://support.claude.com/en/articles/11176164-use-connectors-to-extend-claude-s-capabilities))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.7 | Restrict transmission of information |
| **NIST 800-53** | SC-7 | Boundary protection |

---

### 3.3 Enable Claude in Chrome Deliberately, with a Site Allowlist

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.5, 9.4 |
| NIST 800-53 | AC-3, CM-7 |

#### Description
Treat the Claude in Chrome browser extension as a deliberate enablement decision: it is ON by default for Team plans (OFF for Enterprise). Gate it per role, constrain it with a site allowlist/blocklist, deploy via managed browser/MDM, and keep the 1Password integration off unless explicitly approved.

#### Rationale
**Why This Matters:**
- A browser-resident agent acts on whatever pages the user visits — the extension's blast radius is the user's entire authenticated web session
- The "skip all approvals" user permission mode removes background safety checks; org policy and user education must steer to per-site "always allow" at most
- Hard-blocked action classes (purchases, account creation, permanent deletion, financial transactions) are the floor, not the policy

**Attack Prevented:** Agentic browsing abuse of authenticated sessions (unintended actions, data exposure) on unvetted sites

#### ClickOps Implementation

1. Navigate to: **Organization settings** → **Claude in Chrome**
2. Team plans: confirm whether the default-ON posture is intended; disable or scope by role if not
3. Configure the **site allowlist/blocklist** to the vetted set
4. Deploy the extension via Google Workspace admin console or MDM rather than user-initiated installs
5. Leave the 1Password integration toggle OFF unless explicitly risk-accepted
6. Publish guidance on permission modes (approve manually; per-site always-allow only for vetted internal tools)

**Time to Complete:** ~45 minutes

#### Validation & Testing
1. A user outside the gated role cannot activate the extension
2. Navigation to a non-allowlisted site refuses agent actions

**Expected result:** Extension scoped to intended roles and sites. ([Claude in Chrome admin controls](https://support.claude.com/en/articles/13065128-claude-in-chrome-admin-controls) · [Permissions guide](https://support.claude.com/en/articles/12902446-claude-in-chrome-permissions-guide))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.3 | Access authorization |
| **NIST 800-53** | CM-7 | Least functionality |

---

### 3.4 Govern Cowork: Cloud Sessions, Connector Auto-Approval, and Egress

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 2.5, 12.3 |
| NIST 800-53 | AC-3, SC-7 |

#### Description
Before enabling Cowork, make three deliberate calls: whether cloud sessions run at all ("Run Cowork in the cloud" defaults ON for Team, OFF for Enterprise), whether users may set "Always allow" on connector tools (defaults OFF — keep it off for write-capable tools), and what the code-execution network egress allowlist permits, since Cowork inherits it.

#### Rationale
**Why This Matters:**
- Cowork sessions chain connector actions autonomously — an "Always allow" on a write-capable tool removes the human gate exactly where it matters most
- Cloud sessions execute outside your endpoint controls; the org egress allowlist (**Organization settings** → **Capabilities** → Code execution) is the boundary that remains
- Cowork session transcripts are readable via the Compliance API ([2.2](#22-enable-the-compliance-api-with-least-privilege-keys)) — wire them into monitoring before broad enablement

**Attack Prevented:** Autonomous-session abuse of connector write access and uncontrolled network egress from cloud execution

#### ClickOps Implementation

1. Navigate to: **Organization settings** → **Cowork**
2. Decide the org enablement and the **Run Cowork in the cloud** toggle per plan posture
3. Keep **Allow "Always allow" for connector tools** OFF (its default)
4. Review **Organization settings** → **Capabilities** → Code execution egress allowlist before enablement
5. (Enterprise) Gate Cowork and cloud capability by group/custom role; set per-group plugin install preferences

**Time to Complete:** ~45 minutes

#### Validation & Testing
1. A connector tool invocation inside Cowork prompts for approval (no standing always-allow)
2. Cloud-session egress to a non-allowlisted host fails
3. Cowork transcripts appear in the Compliance API feed

**Expected result:** Cowork enabled only with gated writes, scoped egress, and monitored transcripts. ([Cowork on Team/Enterprise](https://support.claude.com/en/articles/13455879-use-claude-cowork-on-team-and-enterprise-plans))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.3 | Access authorization |
| **NIST 800-53** | SC-7 | Boundary protection |

---

## 4. Spend Governance

### 4.1 Enforce Per-Member Spend Limits

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls | 8.11 |
| NIST 800-53 | AU-6, PM-3 |

#### Description
Use the Enterprise Spend Limits API to set per-user overrides over the group/seat-tier/org limit hierarchy, and operate the increase-request approval queue. This is distinct from Console workspace spend limits (covered in the [Claude API & Console guide](/guides/anthropic-api/)).

#### Rationale
**Why This Matters:**
- Runaway usage — compromised account, scripted abuse, or honest overuse — surfaces first as anomalous spend; hard limits convert it from an invoice surprise into a visible, gated event
- The approval queue creates an audit trail for capacity increases instead of silent admin bumps
- Per-user overrides let you give heavy legitimate users headroom without raising the org default

**Attack Prevented:** Cost-abuse blast radius from a compromised or misused member account

#### ClickOps Implementation

1. Set the org and seat-tier defaults in **Organization settings** (spend limits) — the API writes **only per-user overrides** (`POST /v1/organizations/spend_limits` accepts only `scope.type: "user"`); seat-tier, group, and org defaults are Console-of-claude.ai-settings territory
2. Automate per-user overrides and increase-request handling via the [Spend Limits API](https://platform.claude.com/docs/en/manage-claude/spend-limits-api) with a key scoped `read:spend_limits`/`write:spend_limits` ([2.2](#22-enable-the-compliance-api-with-least-privilege-keys))
3. Alert on limit-hit events and review the approval queue on a cadence. Queue mechanics worth encoding (verified 2026-08-15): requests originate only from a member clicking **Request more usage** in claude.ai and carry **no requested amount** — the admin supplies the new cap on the approve call; **setting a limit directly does NOT resolve a pending request** (use the approve endpoint or the audit trail gaps); a denial hides the member's request button for 30 days
4. Monthly spend resets at 00:00 UTC on the first of each month (`monthly` is the only period)

**Time to Complete:** ~1 hour

#### Validation & Testing
1. A test account hitting its limit is stopped and generates an increase request
2. Overrides read back correctly via the API
3. **Unlimited-member sweep:** page `GET /v1/organizations/spend_limits/effective` and flag every member whose effective `amount` is `null` — that member is **unlimited**, the exact failure state this control exists to prevent (`"0"` by contrast means included-usage only; amounts are minor-unit strings — `"50000"` = 500.00 USD; `source` tells you which hierarchy level supplied the cap: `user`/`seat_tier`/`rbac_group`/`organization`)

**Expected result:** Every member spend-bounded with an approval trail, and an automated sweep proving no member is unlimited. ([Spend Limits API](https://platform.claude.com/docs/en/manage-claude/spend-limits-api))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.2 | System monitoring |
| **NIST 800-53** | AU-6 | Audit review and analysis |

---

## Compliance Quick Reference

Per-control compliance mappings appear inside each control above. For organization-level SOC 2 / NIST / ISO mappings spanning the Anthropic platform, see the [Anthropic Common Controls hub](/guides/anthropic-claude/#compliance-quick-reference).

---

## Appendix A: References

- [Claude Enterprise administrator guide](https://claude.com/resources/tutorials/claude-enterprise-administrator-guide)
- [Set up single sign-on (SSO)](https://support.claude.com/en/articles/13132885-setting-up-single-sign-on-sso)
- [Set up JIT or SCIM provisioning](https://support.claude.com/en/articles/13133195-set-up-jit-or-scim-provisioning)
- [Access audit logs](https://support.claude.com/en/articles/9970975-access-audit-logs)
- [Compliance API](https://platform.claude.com/docs/en/manage-claude/compliance-api)
- [Admin/Enterprise key scopes](https://platform.claude.com/docs/en/manage-claude/admin-api-keys)
- [Spend Limits API](https://platform.claude.com/docs/en/manage-claude/spend-limits-api)
- [Use connectors](https://support.claude.com/en/articles/11176164-use-connectors-to-extend-claude-s-capabilities)
- [Claude in Chrome admin controls](https://support.claude.com/en/articles/13065128-claude-in-chrome-admin-controls)
- [Claude Cowork on Team and Enterprise plans](https://support.claude.com/en/articles/13455879-use-claude-cowork-on-team-and-enterprise-plans)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-08-15 | 0.2.0 | ai-drafted | Admin API currency pass. §2.2 corrected to the two-key-type model — a Compliance Access Key (`sk-ant-api01-`, created at claude.ai → Organization settings → API) reaches every Compliance endpoint per its scopes, while a Console Admin key reaches the Activity Feed only — with the exact four Compliance scopes plus `read:org_audit` for audit-only integrations, the recording-governance warning (toggle off = no events recorded, no local Cowork/Claude Code transcript capture, irrecoverable), session-transcript coverage (local and remote Cowork/Claude Code sessions), the shared 600 rpm limit, the never-expiring-key offboarding rule (keys survive their creator's removal), and leaked-key incident response via `activity_types[]=compliance_api_accessed`. §1.3 updated with the five-value Enterprise role vocabulary (`managed` as the least-privilege target state), the beta user-management API (`anthropic-beta: ce-user-management-2026-07-13`; API assigns only `user`/`managed`; SCIM groups API-read-only), the `rbac_group_ids` invite-write privilege path, the group-deletion spend-cap-lift warning, and a blanket-grant validation sweep (`capability_access_all`). §4.1 gains the spend-limits mechanics (API writes per-user overrides only, increase-request lifecycle with admin-supplied amounts and the 30-day denial cooldown, 00:00 UTC monthly reset) and an unlimited-member sweep (`amount: null` on an effective row = unlimited). §2.1 cites the vendor's own framing positioning the CSV export below the Compliance API. | Claude Code (Opus 5) |
| 2026-08-03 | 0.1.0 | ai-drafted | Authored as part of the Anthropic multi-product platform restructure: 10 controls across identity/provisioning, audit/compliance, connector/Chrome/Cowork governance, and spend limits — every setting verified against Anthropic's live admin documentation. | Claude Code (Sonnet 5) † |

> † Author **inferred**, not recorded. This row predates the Author column, so the value comes from the authoring session's commit window (every other guide authored in that window names the same tool and model, with no dissenting entry). Undaggered rows are attributed from a sibling guide that recorded its author explicitly in the same commit, or from the row's own text.


## Contributing

Found an issue or want to improve this guide? Open an issue or PR on [GitHub](https://github.com/grcengineering/how-to-harden). Keep all code in Code Packs (no inline code blocks).

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
description: "Harden Claude Enterprise Security Center reviews, effective settings, Cowork, Desktop, connectors, plugins, remote access and data governance."
version: "0.3.2"
maturity: ["ai-drafted"]
last_updated: "2026-11-12"
---

## Overview

Claude.ai Team and Enterprise plans are the chat-product surface of Anthropic: workspaces where employees converse with Claude, attach files, run Projects, and increasingly wire Claude into company systems through connectors, the Chrome extension, and Cowork. The admin surface that governs all of this lives in claude.ai's Organization settings, with plan-, feature- and rollout-dependent defaults. Enterprise, Desktop device policy and parent identity administration must be audited separately.

This is a **product guide within the [Anthropic platform](/guides/anthropic-claude/)**. Organization-wide controls (SSO details, org roles, admin API keys, integration governance) live in the Anthropic **Common Controls** hub; Claude Code and API/Console hardening live in their own guides.

For Claude Tag, apply the [dedicated Slack-agent guide](/guides/claude-tag/) in addition to common controls. Do not assume Enterprise chat retention, network admission controls or individual connector permissions automatically govern Tag channel work. Current Tag federation and personal-connector review are documented there.

### Research and validation boundary

This refresh used the [source-first candidate ledger](/research/anthropic-source-coverage-2026-11) and public vendor references, including the published Cowork/unified baseline. It did not access a live tenant, change settings or create credentials. Source verification and mocked/native-interface tests do not earn live-validation status. The exact applicable Security Center checklist must be reconciled with an Owner’s current report; the effective-settings schema is a separate evidence surface.

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
5. [Data Handling & Policy Context](#5-data-handling--policy-context)

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

#### Code Implementation

The effective-settings read in [2.4](#24-assess-effective-settings-against-an-explicit-baseline) can assess an explicit SSO baseline where that row is available; member enumeration alone does not prove SSO or IdP MFA. Identity-provider enforcement and recovery remain separate checks.

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

#### Code Implementation

The effective-settings read in [2.4](#24-assess-effective-settings-against-an-explicit-baseline) exposes documented provisioning mode where available. Reconcile directory sync and offboarding evidence in the IdP; an absent row is not proof SCIM is off.

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

> **Current API boundary (checked 2026-11-05):** Enterprise member, invite, group and custom-role reads are documented at `https://api.anthropic.com/v1/organizations/`. The current reference uses API version 2026-10-21 and no longer requires the older group/role beta header; member sign-out retains its separate beta header. Use `read:members` for members and custom-role reads, and `read:rbac_groups` for group reads. Assigning `managed` or groups on invites requires both `write:members` and `write:rbac_groups`. Administrative roles are assigned in the console; SCIM groups are API-read-only. Member lists paginate with `has_more/last_id`, while custom roles and permissions use `next_page`. ([User management](https://platform.claude.com/docs/en/manage-claude/user-management))

#### ClickOps Implementation

1. Navigate to: **Organization settings** → **Members**
2. Reduce owners/admins to the minimum named set; everyone else is a member — and prefer `managed` (custom-roles-only permissions) as the standard member state where the org uses groups seriously
3. (Enterprise) Define groups synced from the IdP and create custom roles gating capabilities per group
4. Add role review to your quarterly access-review cycle
5. **Guard two API-side privilege paths:** invite automation that passes `rbac_group_ids` grants the permissions of the groups' attached roles at accept-time and requires `write:rbac_groups` — treat keys holding that scope at the same tier as membership-admin credentials. And **deleting a group drops its members' attached-role permissions AND stops any group spend limit applying to them** — a group deletion can silently lift a spend cap (see 4.1)

**Time to Complete:** ~30 minutes

#### Code Implementation

{% include pack-code.html vendor="claude-enterprise" section="1.3" %}

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

### 1.4 Contain Stolen Sessions Without Assuming Work Stops

**Profile Level:** L2 (Walk)

#### Description
Use Enterprise Sign out everywhere during a lost-device or account incident, with IdP containment and a separate review of credentials and running work. The Admin API endpoint is beta and requires a key bound to the affected child organization.

#### Rationale
**Why This Matters:**
- The action reaches the person’s sessions and trusted devices across organizations and individual plans, while OAuth revocation is org-specific.
- A successful sign-out does not revoke API keys, unlink computers or stop cloud sessions and routines.

**Attack Prevented:** Continued use of a stolen interactive session and incomplete incident containment.

#### ClickOps Implementation

1. First revoke the attacker’s IdP access or disable the account through the supported identity lifecycle. Automatic provisioning can re-add a manually removed member if the IdP remains active.
2. An Owner opens **Organization settings → Members → member → Sign out everywhere**; use the member ID and verify the person before any API call. The primary owner must sign out their own sessions from account settings; no one can use this org action on them.
3. Separately inventory API/Admin/Compliance keys, linked Cowork computers, cloud Code sessions, scheduled/event-driven routines and OAuth tokens in other organizations. Stop or revoke each through its own authorized control.
4. Review `org_user_trusted_devices_revoked` in the Activity Feed. A partial result has `completed: false`; a 503 can leave some actions already completed. An in-progress login can finish for up to five minutes; review and repeat only as the incident procedure requires.

#### Code Implementation

{% include pack-code.html vendor="claude-enterprise" section="1.4" %}

#### Validation & Testing
1. Use the pack’s default target-read mode; no POST is sent unless HTH_APPLY=1 and the exact member ID is confirmed.
2. Verify both the account-session effect and completion event. Push registration cleanup is asynchronous; a 200 does not prove all cleanup or work termination.

**Expected result:** The documented boundary is exercised and any unsupported surface or exception is recorded.

#### Operational Impact
Cross-account logout is disruptive and users must re-enroll trusted devices. Tokens may take up to an hour to stop working; signing out is not offboarding or a cloud-task kill switch.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| CIS Controls | 4.1, 6.8 | Secure configuration and role-based access |
| NIST 800-53 | AC-6, CM-6, AU-6 | Least privilege, configuration and evidence |
| SOC 2 | CC6.1, CC7.2 | Access and monitoring |

**Sources:** [platform.claude.com](https://platform.claude.com/docs/en/manage-claude/user-management) (checked 2026-11-05).

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

#### Code Implementation

{% include pack-code.html vendor="claude-enterprise" section="2.1" %}

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

> **The enablement toggle governs recording itself.** The primary owner enables the Compliance API at claude.ai → Organization settings → API (cascades to linked orgs); eligible standalone Console orgs have a self-service toggle at **Console → Settings → Security**. While the toggle is off, **ordinary activity and local-session transcripts are not captured and cannot be backfilled**; enrolled Access Transparency events are an exception and can be recorded while the API is off. Treat the toggle as a protected setting: turning it off is an audit-destruction action, and Admin API keys carry `read:compliance_activities` only if the Compliance API was enabled when the key was created.

#### Rationale
**Why This Matters:**
- The Compliance API is the programmatic audit path for claude.ai — the vendor's own docs position the in-product CSV export as "significantly narrower" and say to standardize on this API for programmatic use
- The four Compliance Access Key scopes are `read:compliance_activities` (Activity Feed), `read:compliance_user_data` (chats, files, projects, Cowork/Claude Code session transcripts, users, group members), `delete:compliance_user_data` (delete chats/files/projects), and `read:compliance_org_data` (org metadata + effective settings). Use `read:compliance_activities` for an activity-only collector and `read:compliance_org_data` for effective settings. The broader `read:org_audit` reaches every Compliance read, including sensitive content; use it only where that full scope is justified
- `delete:compliance_user_data` in particular should live on its own tightly-held key, if issued at all
- Do not assume Compliance keys expire: inventory `expires_at` where provided (null means non-expiring), and scopes are immutable — rotation is create-new-then-delete (deletion takes effect on the next request, no grace period)

**Attack Prevented:** Bulk conversation- and session-content exfiltration via an over-scoped compliance key, silent audit-recording disablement

#### ClickOps Implementation

1. Enable the Compliance API (primary owner, claude.ai → Organization settings → API), and record the toggle as a protected setting in your change-control docs
2. Create **Compliance Access Keys** at claude.ai → Organization settings → API with only the scopes each consumer needs (see the [key scope table](https://platform.claude.com/docs/en/manage-claude/admin-api-keys)); use exact activity/settings scopes for collectors; issue `read:org_audit` only when all of its content access is required
3. Wire your compliance/DLP tooling to `/v1/compliance/activities` for continuous activity-feed consumption — all `/v1/compliance/*` endpoints share a **600 requests-per-minute** limit per parent organization, so size polling cadence and backoff accordingly
4. Inventory issued keys, their scopes, and their holders; store them in a secrets manager, never in source control or SIEM forwarder configuration
5. **Put key deletion in the offboarding runbook:** keys are scoped to the organization, not the creator — removing, deprovisioning, or downgrading the creator leaves every key they created active with its original scopes. Delete their keys and issue replacements

**Time to Complete:** ~1 hour

#### Code Implementation

{% include pack-code.html vendor="claude-enterprise" section="2.2" %}

The native singleton [Compliance Settings API](https://platform.claude.com/docs/en/api/http/organization/compliance_settings/retrieve) and official CLI/SDK read recording state, including inherited parent configuration. This is **separate** from the effective-settings list in 2.4 and native Security Center results. The response has no organization ID: independently confirm which organization the existing credential represents. The public reference documents a POST as well; enabling begins future capture, disabling stops it except Access Transparency, and Access Transparency provisioning can re-enable it. These packs only read. The exact minimum selectable Enterprise scope for this singleton was not specified in the inspected scope table; verify existing authorization and do not assume a content-read key or a 403 proves recording is off. No key is created or broadened to test it. Use the separately scoped activity exporter in 2.1 to verify delivery and known gaps.

#### Validation & Testing
1. A read-scoped key is refused on delete endpoints — the `403` body lists held vs required scopes
2. Activity feed events arrive in your tooling for a test conversation
3. Confirm a local Claude Code session run under an Enterprise-signed-in account appears in the session endpoints
4. Read the native recording singleton and verify `state.type` is `enabled`; reconcile parent inheritance and the actual credential organization. This does not establish historic capture or downstream delivery.
5. On suspected key leak: delete the key, then audit the feed with `activity_types[]=compliance_api_accessed`, matching `actor.type` `api_actor` and `actor.api_key_id` to the compromised key

**Expected result:** Continuous programmatic audit with scope-minimal keys, recording provably on, and key lifecycle tied to offboarding. ([Compliance API](https://platform.claude.com/docs/en/manage-claude/compliance-api) · [Access setup](https://platform.claude.com/docs/en/manage-claude/compliance-api-access) · [Admin key scopes](https://platform.claude.com/docs/en/manage-claude/admin-api-keys))

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.2 | System monitoring |
| **NIST 800-53** | AC-6 | Least privilege |

---

### 2.3 Review Security Center Results and Owner Attestations

**Profile Level:** L2 (Walk)

#### Description
Have an Enterprise Owner review **Security posture** regularly, remediate failed recommendations and retain evidence for manual attestations. Security Center is beta; its organization-specific results are not reproduced by the effective-settings API schema or by a hard-coded “16 checks” score.

#### Rationale
**Why This Matters:**
- Passed, Failed, Not attested and Shown for information represent different assurance states.
- Device/proxy/Code controls can require a person’s confirmation; an Owner attestation is not an automatic technical test.

**Attack Prevented:** Undetected configuration drift and false assurance from incomplete posture evidence.

#### ClickOps Implementation

1. An Owner or Primary Owner opens **account menu → Organization settings → Security posture**. Admins and ordinary users cannot open the page.
2. Review **Org**, **chats**, **Cowork** and **Claude Code**, including new/recently changed controls. For each, record the current value, recommendation where present, status, scope and change link. Do not convert informational results to failures or passes.
3. Follow each control’s real settings page; the dashboard is view-only. Reconcile custom-role/connector views with members actually set to **Custom**.
4. For device, proxy and other manual controls, attach implementation evidence and record the confirming Owner/date, exceptions and review deadline. Choose Accept risk or flag an issue deliberately rather than attesting an untested control.
5. Download the PDF report and retain it privately; it distinguishes automatic checks from Owner confirmations. Compare successive reports, then review the documented Compliance API data and activity feed without guessing undocumented posture event IDs.

#### Code Implementation

**Automation: Unverified for the individual native-check inventory.** The Help page says posture data is available through the Compliance API, but an exact individual-check/status endpoint schema was not verified in the public reference. Do not invent one or substitute the 64 boolean effective-setting names. Use 2.4 for an explicitly separate settings assessment and the Owner-exported PDF for applicable native recommendations.

#### Validation & Testing
1. Check a failed recommendation’s actual configuration and verify its result after page reload; preserve a manual attestation’s external evidence.
2. Compare the tenant report to this guide and the source ledger. The public Help page describes behavior but does not enumerate the complete checklist or a fixed global control count.

**Expected result:** The documented boundary is exercised and any unsupported surface or exception is recorded.

#### Operational Impact
Owner access and beta availability are prerequisites. The PDF and dashboard are guidance, not certification; no live tenant or report was available during this documentation refresh.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| CIS Controls | 4.1, 6.8 | Secure configuration and role-based access |
| NIST 800-53 | AC-6, CM-6, AU-6 | Least privilege, configuration and evidence |
| SOC 2 | CC6.1, CC7.2 | Access and monitoring |

**Sources:** [support.claude.com](https://support.claude.com/en/articles/18246629-review-your-organization-s-security-posture-with-the-security-center) · [trust.anthropic.com](https://trust.anthropic.com/resources?name=claude-cowork-security-best-practices&s=uukz8hyx7jmdmo80lys36s) · [platform.claude.com](https://platform.claude.com/docs/en/manage-claude/compliance-org-data) (checked 2026-11-05).

---

### 2.4 Assess Effective Settings Against an Explicit Baseline

**Profile Level:** L2 (Walk)

#### Description
Read the organization’s resolved settings and compare only named, typed requirements from an approved organizational baseline. This is an HTH assessment, not Anthropic’s native Security Center score or a claim to have reconstructed its complete applicable checklist.

#### Rationale
**Why This Matters:**
- Effective values incorporate plan availability, regulatory restrictions, defaults and feature dependencies.
- An omitted setting is not necessarily off; defaulting a missing or malformed value to false can silently pass a broken control.

**Attack Prevented:** False-negative configuration audits and misuse of over-scoped evidence collectors.

#### ClickOps Implementation

1. Primary Owner enables the Compliance API at **Organization settings → API**; issue a dedicated key with **read:compliance_org_data**, not content-read/delete scopes. A parent key reaches linked children; scope it to one organization where possible.
2. Inventory an approved child organization’s bare UUID and author a nonempty assessment baseline of documented name/type/value rows. Explicitly choose session, SSO/SCIM, IP, retention and capability values appropriate to that organization. Do not infer recommendations from enum names.
3. Run the read-only pack and review **matches_operator_baseline**, **differs_from_operator_baseline** and **unavailable/unknown**. Missing rows, nulls and unknown schema are never silently converted to a healthy boolean.
4. Keep the private resolved-state evidence with the manual/MDM and native posture report. Treat API-key metadata as hierarchy-wide evidence: deactivated entries remain for audit; creator removal does not itself revoke keys.

#### Code Implementation

{% include pack-code.html vendor="claude-enterprise" section="2.4" %}

#### Validation & Testing
1. Check the response organization UUID, setting types, duplicate names and completeness. A 404 can mean an invalid/out-of-tree target or a settings endpoint not enabled for the parent, so ask the account team rather than declaring no organization/settings.
2. Require nonzero exit for a differing baseline or incomplete assessment. Empty and unassessed settings do not imply compliance; device controls and manual attestations remain separate.

**Expected result:** The documented boundary is exercised and any unsupported surface or exception is recorded.

#### Operational Impact
No write API is used. Node.js 22+, curl and jq are prerequisites; evidence includes sensitive policy/key metadata and is saved to a new private directory. Narrow settings access does not include local-device readback.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| CIS Controls | 4.1, 6.8 | Secure configuration and role-based access |
| NIST 800-53 | AC-6, CM-6, AU-6 | Least privilege, configuration and evidence |
| SOC 2 | CC6.1, CC7.2 | Access and monitoring |

**Sources:** [platform.claude.com](https://platform.claude.com/docs/en/manage-claude/compliance-org-data) · [platform.claude.com](https://platform.claude.com/docs/en/api/compliance/organizations/settings/retrieve) (checked 2026-11-05).

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
3. For each connector: **Customize** → **Connectors** → the connector → **Tool permissions**; set each action category to **Blocked** or **Needs approval**; reserve **Always allow** for read-only categories
4. Establish a review workflow for new connector requests (owner, data-access assessment)

**Time to Complete:** ~1 hour initial

#### Code Implementation

Use the explicit effective-settings assessment in [2.4](#24-assess-effective-settings-against-an-explicit-baseline) for available organization switches. Per-connector tool grants, managed authentication and downstream permissions require their own console/API review; an organization-wide toggle does not prove every grant is safe.

#### Validation & Testing
1. A write-category action from a test conversation prompts for approval or is blocked
2. Non-allowlisted connectors cannot be added by members

**Expected result:** Connector surface enumerated, writes gated. ([Verified-domain restriction](https://support.claude.com/en/articles/15402193-restrict-verified-domain-connectors-to-your-enterprise))

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
2. Navigate to: **Organization settings** → **Organization and access** → **Connector domain restriction** and enable **Restrict verified-domain connectors to your enterprise** (managed at the parent level).
3. Communicate the policy so employees route legitimate needs through org accounts

**Time to Complete:** ~15 minutes

#### Code Implementation

Use [2.4](#24-assess-effective-settings-against-an-explicit-baseline) to read documented effective settings where available. A native write/Domain Guard verification handle was not verified in the inspected interfaces; use the evidenced console procedure and an approved test organization.

#### Validation & Testing
1. From a personal Claude account, attempt to connect a service on a verified domain — it should be refused

**Expected result:** New supported connector authentications using verified-domain identities are restricted. Existing connections remain active; services that do not disclose an account identity are allowed through, personal services can still be connected into the Enterprise, and no admin notification is generated. This is not a universal DLP boundary. ([Use connectors](https://support.claude.com/en/articles/11176164-use-connectors-to-extend-claude-s-capabilities))

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
Treat the Claude in Chrome browser extension as a deliberate enablement decision: it is ON by default for Team and Enterprise unless an owner disabled it; HIPAA-enabled organizations keep it off until an Owner enables it. Gate it per role, constrain it with a site allowlist/blocklist, deploy via managed browser/MDM, and keep the 1Password integration off unless explicitly approved.

#### Rationale
**Why This Matters:**
- A browser-resident agent acts on whatever pages the user visits — the extension's blast radius is the user's entire authenticated web session
- The "skip all approvals" user permission mode removes background safety checks; org policy and user education must steer to per-site "always allow" at most
- Hard-blocked action classes (purchases, account creation, permanent deletion, financial transactions) are the floor, not the policy

**Attack Prevented:** Agentic browsing abuse of authenticated sessions (unintended actions, data exposure) on unvetted sites

#### ClickOps Implementation

1. Navigate to: **Organization settings** → **Claude in Chrome**
2. **Changed default:** verify the actual toggle on both tiers. Enterprise is now on by default (except HIPAA); the older best-practices PDF describes an earlier off default. Disable or scope access deliberately.
3. Configure the **site allowlist/blocklist** to the vetted set; the same list governs Cowork’s built-in browser. A manually typed blocked page can load with Claude’s tools disabled, so this is an agent-action boundary, not a network filter.
4. Deploy the extension via Google Workspace admin console or MDM rather than user-initiated installs
5. Leave the 1Password integration toggle OFF unless explicitly risk-accepted
6. Publish guidance on permission modes (approve manually; per-site always-allow only for vetted internal tools)

**Time to Complete:** ~45 minutes

#### Code Implementation

Use [2.4](#24-assess-effective-settings-against-an-explicit-baseline) for available Chrome settings. Review actual extension policy and user/site permissions separately; native write enforcement for every site rule was not verified.

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

#### Description
Review Cowork and unified chat/Cowork as separate capabilities. Bound cloud execution, connector approval and sandbox network egress before a role receives agentic work, including unattended tasks.

#### Rationale
**Why This Matters:**
- Disabling the older Cowork/cloud toggle does not disable unified chat/Cowork.
- Cloud code executes beyond the corporate endpoint proxy; web search/fetch and connector tools have different enforcement paths.

**Attack Prevented:** Unreviewed autonomous execution, connector writes and exfiltration from cloud sessions.

#### ClickOps Implementation

1. Owners review **Organization settings → Cowork**: organization access, **Run Cowork in the cloud**, built-in browser, auto-approval and scheduled work. Cloud Cowork defaults on for Team and off for Enterprise; HIPAA-enabled local-mode configurations cannot enable cloud Cowork.
2. **Changed default, 2026-11-05:** open **Organization settings → Capabilities → Chat and Cowork unified** and explicitly choose **Keep disabled** or an approved rollout. Undecided eligible orgs turn on November 16, 2026 when Chat and Cloud code execution/file creation are on, including when those prerequisites become enabled later. A prior explicit choice is retained.
3. For a pilot, grant the unified capability to selected custom roles and move excluded people to Custom roles first. User/Admin/Owner/Primary Owner have it once the org switch is on; new roles start at All capabilities. Unified does not require the older Cowork switches and is unavailable with ZDR, HIPAA-ready configuration or CMEK.
4. Under **Capabilities → Code execution → Allow network egress**, retain no egress or a narrow package-manager/custom-domain list rather than All domains. Review browser site lists and web-search/fetch capability separately; MCP/connector tools are not governed by this sandbox allowlist.
5. Keep connector automatic Always allow disabled for high-risk populations and require approval/block for writes. Disable unused inline visualizations and sharing rather than treating them as required security features. Confirm each role’s effective connector policy.
6. Govern **Remote control**, **Require trusted devices** and **Scheduled tasks** separately (3.8). Apply Desktop folder/MCP policy for linked devices (3.6) and Compliance evidence before expansion.

#### Code Implementation

The settings assessment can read returned capability rows; it cannot set these switches or validate per-tool policy:

{% include pack-code.html vendor="claude-enterprise" section="2.4" %}

#### Validation & Testing
1. Check `chat_cowork_unified_enabled`, `code_execution_enabled`, `code_execution_network_egress_enabled` and `connector_tools_default_always_allow` where returned; the latter does not prove per-tool approval policy.
2. Exercise an approved/blocked connector write, allowed/blocked sandbox destination, web tool and linked-computer access separately. Verify transcripts and retention for the actual session type.

**Expected result:** The documented boundary is exercised and any unsupported surface or exception is recorded.

#### Operational Impact
Pilot two to four weeks per vendor guidance. Cloud VMs/snapshots expire 30 days after creation; conversation retention and local device data are distinct. An explicit disable affects access, not a claim that every existing unattended task has stopped.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| CIS Controls | 4.1, 6.8 | Secure configuration and role-based access |
| NIST 800-53 | AC-6, CM-6, AU-6 | Least privilege, configuration and evidence |
| SOC 2 | CC6.1, CC7.2 | Access and monitoring |

**Sources:** [support.claude.com](https://support.claude.com/en/articles/13455879-use-claude-cowork-on-team-and-enterprise-plans) · [support.claude.com](https://support.claude.com/en/articles/17444462-set-up-and-manage-the-new-unified-claude-experience-for-your-enterprise-organization) · [trust.anthropic.com](https://trust.anthropic.com/resources?name=claude-cowork-security-best-practices&s=uukz8hyx7jmdmo80lys36s) (checked 2026-11-05).

---

### 3.5 Require Reviewed Plugin and Skill Publishing

**Profile Level:** L2 (Walk)

#### Description
Control cloud library sources, security scanning and publishing independently. Automatic scanning supplements review of executable behavior; it does not establish that a plugin’s data access is appropriate.

#### Rationale
**Why This Matters:**
- An uploaded or edited skill/plugin can introduce instructions, executable tools and new connector access.
- Enterprise publishing defaults changed after the older best-practices PDF; scanning alone can permit unreviewed organization-wide distribution.

**Attack Prevented:** Supply-chain compromise through malicious skills, plugins and automatic library updates.

#### ClickOps Implementation

1. Open **Organization settings → Plugins & skills → Policy**. Set **Publishing → Requires review** (or Off for high-assurance populations) explicitly and review **User-created skills** and per-role publishing capabilities.
2. **Changed defaults:** scanning turned on October 2 for Enterprise orgs without a prior choice. From November 4, undecided Enterprise publishing can become **Open** when scanning is on. Verify both settings rather than trusting the PDF’s earlier opt-in/review posture.
3. Keep **Skill and plugin security scanning** on and review results in **Inventory** and **Requests**. Inventory installed sources, required/default/available offerings, group assignments and update ownership. Remove unused marketplaces.
4. Review exceptions: Owners/library managers’ own submissions bypass manual review; older org-wide shares can reappear without new review when publishing is re-enabled. Per-person/group shares are separate. Treat Code marketplace policies and host-executable plugins separately (Code 2.2).

**Automation:** Unverified — no write handle verified for this setting in the inspected public Admin/Compliance references. Configure it on the documented surface; the effective-settings read pack in [Enterprise 2.4](/guides/claude-enterprise/#24-assess-effective-settings-against-an-explicit-baseline) covers only rows actually returned, not device policy or manual attestations.

#### Validation & Testing
1. Use a harmless approved pilot upload/edit to check scan and publication behavior, including member role and reviewer exception.
2. Read `claude_ai_skill_plugins_scanning_enabled` where returned; it does not establish the Publishing mode or source trust.

**Expected result:** The documented boundary is exercised and any unsupported surface or exception is recorded.

#### Operational Impact
Requires review can delay distribution. Turning publishing Off does not delete already published items; inventory and remove them deliberately if needed.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| CIS Controls | 4.1, 6.8 | Secure configuration and role-based access |
| NIST 800-53 | AC-6, CM-6, AU-6 | Least privilege, configuration and evidence |
| SOC 2 | CC6.1, CC7.2 | Access and monitoring |

**Sources:** [support.claude.com](https://support.claude.com/en/articles/15927065-get-started-with-skill-and-plugin-scanning) · [support.claude.com](https://support.claude.com/en/articles/13119606-provision-and-manage-skills-for-your-organization) · [support.claude.com](https://support.claude.com/en/articles/13837433-manage-plugins-for-your-organization) (checked 2026-11-05).

---

### 3.6 Deploy a Separate Desktop Device Policy

**Profile Level:** L2 (Walk)

#### Description
Apply Claude Desktop policy to org login, attachable folders, local MCP and extension access. Desktop uses its own MDM payload; Code server-managed settings do not configure Cowork and must not be presented as a Desktop org-login control.

#### Rationale
**Why This Matters:**
- A cloud session can reach connected folders and locally configured MCP through a linked Desktop.
- Wrong preference domains or policies that only select an org leave a shadow-account path open.

**Attack Prevented:** Personal-account use and local-data exfiltration through unmanaged desktop capabilities.

#### ClickOps Implementation

1. For macOS deploy a configuration profile in **com.anthropic.claudefordesktop**. For Windows deploy **HKLM\SOFTWARE\Policies\Claude** through Group Policy/Intune; HKLM overrides HKCU. Use the documented device-policy keys, not the Code domain.
2. Set **forceLoginOrgUUID** to the approved org UUID (or documented UUID array), **allowedWorkspaceFolders** to narrow working directories, and disable **isLocalDevMcpEnabled** unless reviewed. Restrict or disable **isDesktopExtensionEnabled** and **isDesktopExtensionDirectoryEnabled**.
3. If using the in-product extension allowlist, keep both extension switches enabled so the approved registry can populate; device policy overrides that allowlist. A disable-all baseline and a curated allowlist are different deployment choices.
4. Use **secureVmFeaturesEnabled=false** only if disabling all Desktop Cowork is intended; it keeps chat and does not disable browser Cowork. Keep automatic updates on unless managed deployment supplies timely versions; configure the restart window deliberately.
5. On Enterprise, some Desktop controls also appear in Organization settings (beta). Confirm actual precedence and effective state on the installed version. Test with Code device policy present: folder restrictions affect the Code tab, shell deny rules can affect Cowork, and managed-only permissions can prevent folder writes.

#### Code Implementation

{% include pack-code.html vendor="claude-enterprise" section="3.6" %}

#### Validation & Testing
1. Generate the payload, review it and deploy only through normal change management; the pack only emits .mobileconfig/.reg text.
2. Read back MDM/HKLM and test approved/refused organizations, folders, local MCP and extensions on macOS and Windows. Reading a file alone does not prove cloud/MDM precedence.

**Expected result:** The documented boundary is exercised and any unsupported surface or exception is recorded.

#### Operational Impact
These controls affect the Desktop installation and linked access, not all web/mobile behavior. Linux/Desktop policy parity was not established from these macOS/Windows references; do not apply the payload there.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| CIS Controls | 4.1, 6.8 | Secure configuration and role-based access |
| NIST 800-53 | AC-6, CM-6, AU-6 | Least privilege, configuration and evidence |
| SOC 2 | CC6.1, CC7.2 | Access and monitoring |

**Sources:** [support.claude.com](https://support.claude.com/en/articles/12622667-enterprise-configuration-for-claude-desktop) · [trust.anthropic.com](https://trust.anthropic.com/resources?name=claude-cowork-security-best-practices&s=uukz8hyx7jmdmo80lys36s) (checked 2026-11-05).

---

### 3.7 Observe the Local Cowork VM with an Approved EDR Sensor

**Profile Level:** L3 (Run)

#### Description
Where local Cowork VM visibility is required, pilot the beta integration for an approved EDR vendor. Host EDR cannot see inside the isolated VM; this sensor covers the local VM only.

#### Rationale
**Why This Matters:**
- Local VM code execution creates a monitoring blind spot for the host sensor.
- The EDR vendor receives sensitive activity/content and its telemetry can leave outside the Cowork egress allowlist.

**Attack Prevented:** Unobserved malicious command execution inside the local VM.

#### ClickOps Implementation

1. Confirm Claude Desktop **4.4212.0+** on macOS or the Windows **MSIX** build on Windows 10/11 with hardware virtualization and Virtual Machine Platform. Follow an approved vendor’s current package and onboarding guidance; no generic sensor installer is supplied.
2. Use the vendor-signed package’s full local path in **coworkEDRIntegration** and the vendor’s documented lowercase ID in **coworkEDRIntegrationVendor** via Desktop MDM/HKLM policy. A path alone is not proof of sensor enrollment.
3. Confirm the supported-vendor list and signature on every VM start; review the vendor’s data handling, update supply chain and telemetry destination. Restart the VM and validate installation and console heartbeat after every Claude or sensor update.
4. Treat the integration as detection/visibility. It does not cover cloud sessions, replace tool approvals or establish prevention. Removing MDM settings stops future package runs but does not uninstall an already installed sensor; use the vendor’s documented cleanup.

#### Code Implementation

The optional EDR fields in the Desktop payload emitter use an already supplied signed package; emitting a payload neither downloads nor installs it:

{% include pack-code.html vendor="claude-enterprise" section="3.6" %}

#### Validation & Testing
1. Correlate an approved harmless local-VM test event with the EDR console, and verify the sensor is healthy after restart/update.
2. Record local versus cloud sessions and the deliberate telemetry egress exception; missing policy means no package is installed.

**Expected result:** The documented boundary is exercised and any unsupported surface or exception is recorded.

#### Operational Impact
Available on Team/Enterprise and Desktop with Bedrock, Vertex or Foundry. The package signature does not cover updates the sensor downloads later; signatures expire within two years and require vendor re-signing.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| CIS Controls | 4.1, 6.8 | Secure configuration and role-based access |
| NIST 800-53 | AC-6, CM-6, AU-6 | Least privilege, configuration and evidence |
| SOC 2 | CC6.1, CC7.2 | Access and monitoring |

**Sources:** [support.claude.com](https://support.claude.com/en/articles/17828685-run-your-endpoint-detection-and-response-edr-sensor-in-claude-cowork-on-claude-desktop) · [support.claude.com](https://support.claude.com/en/articles/12622667-enterprise-configuration-for-claude-desktop) (checked 2026-11-05).

---

### 3.8 Gate Linked Computers and Unattended Work

**Profile Level:** L2 (Walk)

#### Description
Decide whether cloud sessions may reach computers and whether schedules may run unattended. Where Remote Control is allowed, require trusted devices and constrain local folders/MCP independently.

#### Rationale
**Why This Matters:**
- A browser or phone can steer work on a linked computer without sharing the endpoint’s network boundary.
- Trusted-device enrollment is not retrospective protection for sessions already running before enablement.

**Attack Prevented:** Remote misuse of a signed-in account to access a member’s local files and tools.

#### ClickOps Implementation

1. An Owner opens **Organization settings → Capabilities → Remote sessions → Require trusted devices** and enables the beta requirement if Remote Control is approved. It is off by default and applies to Code Remote Control and Cowork computer access, not ordinary chat, terminal Code or API traffic.
2. Review Cowork **Remote control** and **Scheduled tasks** separately; disable cloud/linked access and unattended execution for populations that do not need them. Disable Code routines separately in Code settings.
3. End/restart existing remote sessions through the approved workflow because the trusted-device requirement applies only to newly started sessions. Review member devices at **Settings → Account → Trusted devices** and revoke lost devices.
4. Require device enrollment after fresh sign-in and presence confirmation when authentication is older than 18 hours; passkeys/security keys or re-sign-in are alternatives to a platform biometric. Keep the Desktop folder/MCP policy in 3.6.

**Automation:** Unverified — no write handle verified for this setting in the inspected public Admin/Compliance references. Configure it on the documented surface; the effective-settings read pack in [Enterprise 2.4](/guides/claude-enterprise/#24-assess-effective-settings-against-an-explicit-baseline) covers only rows actually returned, not device policy or manual attestations.

#### Validation & Testing
1. Test new remote sessions from enrolled and unenrolled devices with the same approved pilot account.
2. Verify schedules and linked-computer access independently after disable/sign-out; sign-out does not unlink computers or terminate all cloud work.

**Expected result:** The documented boundary is exercised and any unsupported surface or exception is recorded.

#### Operational Impact
Organization-wide requirement, no per-project/team scope. ZDR/HIPAA restrictions and unsupported platforms must be checked before enabling Remote Control.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| CIS Controls | 4.1, 6.8 | Secure configuration and role-based access |
| NIST 800-53 | AC-6, CM-6, AU-6 | Least privilege, configuration and evidence |
| SOC 2 | CC6.1, CC7.2 | Access and monitoring |

**Sources:** [code.claude.com](https://code.claude.com/docs/en/remote-control) · [support.claude.com](https://support.claude.com/en/articles/17444462-set-up-and-manage-the-new-unified-claude-experience-for-your-enterprise-organization) · [platform.claude.com](https://platform.claude.com/docs/en/manage-claude/user-management) (checked 2026-11-05).

---

### 3.9 Constrain Private MCP Tunnels and Managed Connector Auth

**Profile Level:** L2 (Walk)

#### Description
Treat an outbound MCP tunnel and enterprise-managed connector authentication as privileged integration paths. An outbound-only tunnel avoids an inbound port but can still grant cloud sessions access to sensitive private tools.

#### Rationale
**Why This Matters:**
- Tunnel routing and the tool authorization policy solve different problems.
- A managed identity source can expose a connector to an entire role without individual sign-in.

**Attack Prevented:** Excessive private-system access through tunneled MCP or broadly delegated connector credentials.

#### ClickOps Implementation

1. For enabled MCP tunnels, review **Organization settings → Connectors** and the current tunnel setup with the account team. Restrict the backing server’s methods/data and its service credential; apply the same per-tool/per-role approval policy as public connectors.
2. Review **Connectors → connector → Configuration → Managed authorization** and **Roles → role → Connectors → How members connect**. Scope managed auth to a pilot role; choose individual or per-connector identity where appropriate.
3. Verify the issuer/audience/claims and downstream service ACLs for Claude-issued auth. Do not infer that an outbound tunnel or role assignment limits what the backing credential can access.
4. Monitor tunnel and connector lifecycle, review stale grants, and remove unused connectivity through normal change management; do not expose a public server as a shortcut for an unavailable tunnel feature.

**Automation:** Unverified — no write handle verified for this setting in the inspected public Admin/Compliance references. Configure it on the documented surface; the effective-settings read pack in [Enterprise 2.4](/guides/claude-enterprise/#24-assess-effective-settings-against-an-explicit-baseline) covers only rows actually returned, not device policy or manual attestations.

#### Validation & Testing
1. Test allowed/blocked tools and a user outside the pilot role. Review the downstream audit record for the actual principal and dataset.
2. Confirm current beta/research-preview eligibility from setup docs; absence of tenant access is not evidence that a tunnel capability is unsupported.

**Expected result:** The documented boundary is exercised and any unsupported surface or exception is recorded.

#### Operational Impact
Blocking the connector or tunnel can break running automations. Cloud sandbox network allowlists do not constrain the private server’s own downstream access.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| CIS Controls | 4.1, 6.8 | Secure configuration and role-based access |
| NIST 800-53 | AC-6, CM-6, AU-6 | Least privilege, configuration and evidence |
| SOC 2 | CC6.1, CC7.2 | Access and monitoring |

**Sources:** [support.claude.com](https://support.claude.com/en/articles/14290952-mcp-tunnels) · [support.claude.com](https://support.claude.com/en/articles/15537633-auto-connect-your-organization-s-apps-to-claude) · [support.claude.com](https://support.claude.com/en/articles/13455879-use-claude-cowork-on-team-and-enterprise-plans) (checked 2026-11-05).

---

### 3.10 Review Specialized Apps and Slack Access Boundaries

**Profile Level:** L2 (Walk)

#### Description
Review specialized Claude products and integration surfaces as their own data/credential planes. Shared identity does not establish shared retention, egress, IP or per-tool policy.

#### Rationale
**Why This Matters:**
- Claude Tag inherits access through organization, Slack workspace and channel scopes; broad parent credentials widen every descendant.
- Claude Science has local data, custom connectors and remote compute that the usual chat policies only partly govern.

**Attack Prevented:** Cross-channel data exposure and unintended compute/data access through specialized apps.

#### ClickOps Implementation

1. For **Claude Tag/Claude in Slack**, review organization/workspace/channel credentials, repository access, memory, access bundles and effective channel settings in its admin surface before enabling. Use a narrow test channel; remove broad organization/workspace grants that should be channel-specific. Distinguish the Slack connector (Claude reads Slack) from a Slack-resident agent and from Code’s Slack-triggered cloud work.
2. For **Claude Science**, Owners open **Organization settings → Claude Science**. Review Featured/custom connectors and skills, previous local work import, managed network allowlist/package mirror, SSH, Modal, scientific model endpoints, memory and auto mode. Enterprise custom connectors/Modal/auto mode differ from Team defaults; disabling custom skills does not revoke ones already installed.
3. Require supported Science clients (organization settings apply from v0.1.41; auto-mode needs its documented later version). Test org/role restrictions and a disconnected client: some capabilities pause after 72 hours offline while cached network and Featured policies remain.
4. For **Microsoft 365 add-ins**, approve each app and its actual document/connector reach separately. Test with synthetic document content, not production secrets; prompts and in-app task panes are not data-loss prevention controls. Current [Compliance API guidance](https://support.claude.com/en/articles/15167101-get-started-with-claude-compliance-api-integrations) includes M365 add-in session content in **beta**, superseding older blanket claims of no capture. Verify recording is enabled and your collector actually retrieves a test session; do not infer retention coverage or M365-native visibility from this alone (checked 2026-11-12).
5. Record that Science session duration and IP allowlisting have partial coverage; local/SSH/Modal/custom-connector traffic is not uniformly covered. Local data is not erased by offboarding. Review M365 add-ins, Design/artifacts, hosted Security and Code Review before granting their separate capabilities or repository/provider permissions.

**Automation:** Unverified — no write handle verified for this setting in the inspected public Admin/Compliance references. Configure it on the documented surface; the effective-settings read pack in [Enterprise 2.4](/guides/claude-enterprise/#24-assess-effective-settings-against-an-explicit-baseline) covers only rows actually returned, not device policy or manual attestations.

#### Validation & Testing
1. Reconcile returned `claude_in_slack_enabled` and `claude_science_*` fields with actual role membership and the product’s effective controls; a boolean does not prove downstream least privilege.
2. Test cross-channel/role access and local/private-network boundaries with approved fixtures; track unsupported retention/hook coverage separately.

**Expected result:** The documented boundary is exercised and any unsupported surface or exception is recorded.

#### Operational Impact
This control establishes admission and boundary checks for specialized apps, not a claim that commercial chat controls govern all their runtimes. Government/FISMA deployment requirements are scoped separately in the hub’s published-baselines section.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| CIS Controls | 4.1, 6.8 | Secure configuration and role-based access |
| NIST 800-53 | AC-6, CM-6, AU-6 | Least privilege, configuration and evidence |
| SOC 2 | CC6.1, CC7.2 | Access and monitoring |

**Sources:** [support.claude.com](https://support.claude.com/en/articles/15594475-what-is-claude-tag) · [platform.claude.com](https://platform.claude.com/docs/en/manage-claude/claude-tag-api) · [claude.com](https://claude.com/docs/claude-science/admin-controls) · [platform.claude.com](https://platform.claude.com/docs/en/manage-claude/ip-allowlisting) · [platform.claude.com](https://platform.claude.com/docs/en/manage-claude/inference-hooks) (checked 2026-11-05).

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

#### Code Implementation

{% include pack-code.html vendor="claude-enterprise" section="4.1" %}

The read-only sweep preserves inherited sources and reports unlimited/unknown rows. It does not change caps or resolve requests.

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

## 5. Data Handling & Policy Context

### 5.1 Set Retention for Each Data and Session Type

**Profile Level:** L2 (Walk)

#### Description
Choose retention for chats, projects and artifacts explicitly, then map local sessions, cloud sessions and specialized apps separately. The organization’s retention window is not a universal deletion switch.

#### Rationale
**Why This Matters:**
- Projects are retained indefinitely by default and project retention overrides chat retention, including chats moved into a project.
- A local working directory or a standalone remote session can outlive the chat retention period.

**Attack Prevented:** Unnecessary persistence of sensitive conversations, generated artifacts and session data.

#### ClickOps Implementation

1. Owners open **Organization settings → Data and privacy** and set chat, project and artifact retention to approved values (minimum 30 days). Review all three categories; leaving projects indefinite bypasses a shorter chat policy for chats inside them.
2. Document that last activity, including opening some objects, resets the clock. Publicly published artifact links are not deleted by the ordinary artifact retention window. Inventory and remove those through their own workflow.
3. Map chat-linked unified cloud sessions (deleted with their chat), standalone cloud sessions, Code cloud/routines, Tag, Design, Managed Agents and local endpoint data to their product-specific retention/deletion rules. Compliance local transcripts and original device data are separate copies.
4. Export evidence/legal records before reducing a period: saving a shorter period schedules permanent deletion and cannot be reversed by relying on a background-process delay. Apply the organization’s endpoint/eDiscovery policy to local data.

**Automation:** Unverified — no write handle verified for this setting in the inspected public Admin/Compliance references. Configure it on the documented surface; the effective-settings read pack in [Enterprise 2.4](/guides/claude-enterprise/#24-assess-effective-settings-against-an-explicit-baseline) covers only rows actually returned, not device policy or manual attestations.

#### Validation & Testing
1. Read `data_retention_periods` where returned; a missing type means no administrator-configured period, not zero retention.
2. Verify representative standalone chat, project chat, artifact and session behavior against the current product docs; no live deletion is needed for this guide refresh.

**Expected result:** The documented boundary is exercised and any unsupported surface or exception is recorded.

#### Operational Impact
Permanent deletion is irreversible and can remove evidence. Trust/safety and legal-retention exceptions can still apply; the older PDF’s blanket exclusion for all cloud Cowork is superseded by current chat-linked-session guidance.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| CIS Controls | 4.1, 6.8 | Secure configuration and role-based access |
| NIST 800-53 | AC-6, CM-6, AU-6 | Least privilege, configuration and evidence |
| SOC 2 | CC6.1, CC7.2 | Access and monitoring |

**Sources:** [support.claude.com](https://support.claude.com/en/articles/10440198-configure-custom-data-retention-controls-for-enterprise-plans) · [platform.claude.com](https://platform.claude.com/docs/en/manage-claude/api-and-data-retention) · [support.claude.com](https://support.claude.com/en/articles/17444462-set-up-and-manage-the-new-unified-claude-experience-for-your-enterprise-organization) (checked 2026-11-05).

---

### 5.2 Evaluate Customer-Managed Keys Before Binding Them

**Profile Level:** L3 (Run)

#### Description
Use CMEK only when its confidentiality and control benefits justify feature restrictions and key availability risk. It is optional; the published baseline does not recommend enabling it indiscriminately.

#### Rationale
**Why This Matters:**
- Attaching a key cannot be undone or replaced, and applies only to data written after it takes effect.
- Disabling/deleting the key can make data unreadable; local endpoint data is outside the hosted key boundary.

**Attack Prevented:** Unauthorized hosted-data access where a customer-controlled key is a required boundary.

#### ClickOps Implementation

1. Eligible Enterprise Owners coordinate enablement with their account team, then follow the product-specific setup and coverage table under **Data and privacy → Encryption keys**. Choose AWS KMS, Google Cloud KMS or Azure Key Vault according to that reference.
2. Approve the documented irreversible binding, old-data handling and feature exclusions before setup. Unified chat/Cowork is unavailable with CMEK; do not use a key change as a feature-disable test.
3. Verify narrowly scoped key access, cloud-provider audit logging and a tested key-availability/recovery process. Do not delete a key or revoke Anthropic access as an audit check.

**Automation:** Unverified — no write handle verified for this setting in the inspected public Admin/Compliance references. Configure it on the documented surface; the effective-settings read pack in [Enterprise 2.4](/guides/claude-enterprise/#24-assess-effective-settings-against-an-explicit-baseline) covers only rows actually returned, not device policy or manual attestations.

#### Validation & Testing
1. Read organization `cmek_enabled` where returned and reconcile it with the eligible product/workspace coverage; the org flag does not prove every record or endpoint is encrypted under that key.
2. Confirm old/new data and local/hosted boundaries using setup evidence and provider key-use logs.

**Expected result:** The documented boundary is exercised and any unsupported surface or exception is recorded.

#### Operational Impact
A deleted key can make data unrecoverable. Rotating underlying KMS material differs from replacing the bound configuration; generic KMS infrastructure hardening is outside this guide.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| CIS Controls | 4.1, 6.8 | Secure configuration and role-based access |
| NIST 800-53 | AC-6, CM-6, AU-6 | Least privilege, configuration and evidence |
| SOC 2 | CC6.1, CC7.2 | Access and monitoring |

**Sources:** [platform.claude.com](https://platform.claude.com/docs/en/manage-claude/cmek) · [platform.claude.com](https://platform.claude.com/docs/en/manage-claude/cmek-coverage-claude-enterprise) · [support.claude.com](https://support.claude.com/en/articles/17444462-set-up-and-manage-the-new-unified-claude-experience-for-your-enterprise-organization) (checked 2026-11-05).

---

### 5.3 Review Sharing, Memory and Organization Instructions

**Profile Level:** L2 (Walk)

#### Description
Limit sharing and persistent context to the intended audience, and use organization instructions for organization-specific handling context. Instructions and memory are not enforcement boundaries.

#### Rationale
**Why This Matters:**
- Shared chats/artifacts, saved memory and support/feedback uploads are distinct data disclosure paths.
- Global instructions can express a policy without preventing a compromised tool or prompt injection from violating it.

**Attack Prevented:** Accidental disclosure through public/shared content and reuse of sensitive persistent context.

#### ClickOps Implementation

1. Owners review **Organization settings → Data and privacy** and sharing/capability settings for chats, projects, artifacts and cloud sessions. At **Organization settings → Artifacts**, review **External sharing**, the independent **Email invitations outside your organization** setting, and individually permitted artifacts in **Published artifacts**. Turning off External sharing stops public links except individual exceptions; it does not turn off external email invitations. Recheck older links and exceptions with a non-member test identity. See the [Artifacts admin guide](https://support.claude.com/en/articles/16994751-artifacts-admin-guide-for-team-and-enterprise-plans) (checked 2026-11-12). Externally shared artifacts are outside IP allowlisting.
2. Review **Capabilities → Memory**, role access and sensitive-context handling. Audit feedback/support-sharing, integration sharing and user-created skills separately where returned by the settings API. Record actual settings rather than assuming every missing row is disabled.
3. As HTH risk-review candidates, inventory returned Ask Your Org/Academy, location metadata, member usage visibility, redaction, work-across-apps, interactive content, artifact connectors and data/feedback-use switches. Approve the purpose, audience and data boundary for each enabled feature; the effective-settings enum provides neither an Anthropic recommendation nor a native pass/fail value. Review Console Workbench feedback collection separately.
4. Before publishing, inspect the full generated artifact/source and included data, not just the visible page: hidden elements or embedded values can disclose information. Inventory existing publications and data sources; require deliberate audience approval. An instruction to “ask before publishing” is not a technical restriction. Test current, legacy and live artifact behavior separately rather than applying one toggle's behavior to every generation.
5. At **Organization settings → Organization and access → Organization instructions**, set concise classification/handling context, protected-data restrictions and an escalation contact (up to 3,000 characters, up to an hour propagation). Keep technical enforcement in connector, device, sandbox and inference-hook controls.

**Automation:** Unverified — no write handle verified for this setting in the inspected public Admin/Compliance references. Configure it on the documented surface; the effective-settings read pack in [Enterprise 2.4](/guides/claude-enterprise/#24-assess-effective-settings-against-an-explicit-baseline) covers only rows actually returned, not device policy or manual attestations.

#### Validation & Testing
1. Read the returned sharing, memory, feedback and artifact capability rows and reconcile each with an actual policy and affected audience.
2. Test allowed and blocked sharing with harmless fixtures, and confirm current local/cloud memory behavior before processing sensitive content.

**Expected result:** The documented boundary is exercised and any unsupported surface or exception is recorded.

#### Operational Impact
Disabling a feature can disrupt existing workflows and does not by itself delete every older share or local memory. Treat organization context as advisory prompt input, with independent technical controls.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| CIS Controls | 4.1, 6.8 | Secure configuration and role-based access |
| NIST 800-53 | AC-6, CM-6, AU-6 | Least privilege, configuration and evidence |
| SOC 2 | CC6.1, CC7.2 | Access and monitoring |

**Sources:** [platform.claude.com](https://platform.claude.com/docs/en/manage-claude/compliance-org-data) · [support.claude.com](https://support.claude.com/en/articles/14546867-set-organization-instructions) · [platform.claude.com](https://platform.claude.com/docs/en/manage-claude/ip-allowlisting) (checked 2026-11-05).

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
| 2026-11-12 | 0.3.2 | ai-drafted | Reconciled Pluto Office/artifact findings with current beta Compliance capture and independent external-sharing controls/individual exceptions; added publication-source review. | Codex |
| 2026-11-11 | 0.3.1 | ai-drafted | Link dedicated Claude Tag guide and distinguish its identity, retention and network boundaries. | OpenAI Codex |
| 2026-11-05 | 0.3.0 | ai-drafted | Security Center workflow and explicit unknown native checklist; operator-baselined effective-settings assessment; guarded incident response, native API/CLI/SDK evidence, Desktop/EDR, unified rollout, plugin publishing, remote/private connectors and product-specific data handling. Reconciled dated PDF recommendations with current sources. | Codex |
| 2026-08-15 | 0.2.0 | ai-drafted | Admin API currency pass. §2.2 corrected to the two-key-type model — a Compliance Access Key (`sk-ant-api01-`, created at claude.ai → Organization settings → API) reaches every Compliance endpoint per its scopes, while a Console Admin key reaches the Activity Feed only — with the exact four Compliance scopes plus `read:org_audit` for audit-only integrations, the recording-governance warning (toggle off = no events recorded, no local Cowork/Claude Code transcript capture, irrecoverable), session-transcript coverage (local and remote Cowork/Claude Code sessions), the shared 600 rpm limit, the never-expiring-key offboarding rule (keys survive their creator's removal), and leaked-key incident response via `activity_types[]=compliance_api_accessed`. §1.3 updated with the five-value Enterprise role vocabulary (`managed` as the least-privilege target state), the beta user-management API (`anthropic-beta: ce-user-management-2026-07-13`; API assigns only `user`/`managed`; SCIM groups API-read-only), the `rbac_group_ids` invite-write privilege path, the group-deletion spend-cap-lift warning, and a blanket-grant validation sweep (`capability_access_all`). §4.1 gains the spend-limits mechanics (API writes per-user overrides only, increase-request lifecycle with admin-supplied amounts and the 30-day denial cooldown, 00:00 UTC monthly reset) and an unlimited-member sweep (`amount: null` on an effective row = unlimited). §2.1 cites the vendor's own framing positioning the CSV export below the Compliance API. | Claude Code (Opus 5) |
| 2026-08-03 | 0.1.0 | ai-drafted | Authored as part of the Anthropic multi-product platform restructure: 10 controls across identity/provisioning, audit/compliance, connector/Chrome/Cowork governance, and spend limits — every setting verified against Anthropic's live admin documentation. | Claude Code (Sonnet 5) † |

> † Author **inferred**, not recorded. This row predates the Author column, so the value comes from the authoring session's commit window (every other guide authored in that window names the same tool and model, with no dissenting entry). Undaggered rows are attributed from a sibling guide that recorded its author explicitly in the same commit, or from the row's own text.


## Contributing

Found an issue or want to improve this guide? Open an issue or PR on [GitHub](https://github.com/grcengineering/how-to-harden). Keep all code in Code Packs (no inline code blocks).

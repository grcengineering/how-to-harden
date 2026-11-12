---
layout: guide
title: "ChatGPT Dots Hardening Guide"
vendor: "ChatGPT Dots"
slug: "chatgpt-dots"
platform: "OpenAI"
platform_slug: "openai"
product: "ChatGPT Dots"
tier: "1"
category: "AI/ML Platform"
description: "Security hardening for ChatGPT dots, OpenAI's always-on personal agents (launched 2026-09-29): dots enablement and RBAC, owner-account protection, connected apps and Slack participation, shared cloud-computer capabilities, local computer access, custom rules and Agent Security orchestrator policy, memory and residency limits, Compliance API coverage, and the revoke, pause and reset sequence."
version: "0.3.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-12"
---

## Overview

This product guide covers personal dots within the [OpenAI platform common controls](/guides/chatgpt-enterprise/). Dots retain a cloud computer/context, use the owner’s authorized connections, and can delegate Work/Codex tasks. Use the [Work/Codex guide](/guides/chatgpt-work-codex/) for those executors. Workspace Agents, @ChatGPT in Slack/Teams and a personal dot’s messaging identity are distinct integrations.

**Intended audience:** workspace owners, security/device administrators and dot owners. **Profiles:** L1 (Crawl), L2 (Walk) and L3 (Run). **Scope:** current documented permissions, source identities, runtime policy, audit, data and individual lifecycle controls. Enterprise admin capabilities depend on workspace availability/eligibility; personal and Business owners must use the controls actually offered. No admin entitlement is inferred from a plan name. The current pages describe access as an admin preview; check current setup notices.

The main dot does not inherit Enterprise model defaults. Work/Codex delegates follow their applicable model and execution policy. Storage/inference residency, EKM and HIPAA are supported only under the documented eligibility and agreements; strict zero retention is not supported and dots are unavailable in FedRAMP workspaces.

This is AI-drafted from current public sources, reconciled against Pluto Security guidance on 2026-11-12, with no live tenant validation or maturity promotion. Existing control headings/anchors are preserved; 5.1 and known-gap headings explicitly mark superseded October claims. The [source-first inventory](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/openai-source-coverage.md) records the unresolved current Admin/policy API schema.

### Automation Surfaces at a Glance

| Surface | Current verified scope and disposition |
|---------|----------------------------------------|
| Terraform | OpenAI API provider manages API Platform objects; it is not evidence of ChatGPT dots policy. Current Global policy Terraform support is documented, but its public contract was not verified here. |
| API | Current first-party Compliance list/download script and CODEX_LOG support; daily Analytics usage endpoint and scope. Individual admin lifecycle and policy features are documented, but their current public write schemas remain unverified. |
| CLI | No current dots-specific admin contract verified. API Platform CLI is separate and covered in its guide. |
| SDK | No current dots administration SDK contract verified in the fetched indexes. API SDK types do not prove ChatGPT policy coverage. |
| Config | Native Global requirements for supported orchestration, conditional MCP hooks, and a US Codex residency requirement; each runtime has separate applicability. |
| SIEM | ChatGPT Compliance JSONL, DOTS attribution/agent metadata where available; exact current governance-event schemas unverified. Receiving-service records establish external outcomes. |

### Intended Audience

Workspace owners, security/device administrators, source-service owners and members who own a personal dot.

### How to Use This Guide

Apply L1 (Crawl) for an approved pilot, L2 (Walk) for sensitive integrations and L3 (Run) for residency/retention requirements. Verify the runtime and effective role grants before enabling access.

### Scope

Documented personal-dot access, cloud/local capabilities, integrations, approvals, audit, context and individual lifecycle. Workspace identity and independently delegated Work/Codex execution link to their dedicated guides.

## Table of Contents

1. [Access & Enablement](#1-access--enablement)
2. [Connected Apps & Channels](#2-connected-apps--channels)
3. [Cloud Computer, Browser & Local Access](#3-cloud-computer-browser--local-access)
4. [Autonomy & Approvals](#4-autonomy--approvals)
5. [Data, Memory & Residency](#5-data-memory--residency)
6. [Monitoring & Audit](#6-monitoring--audit)
7. [Lifecycle & Kill Switch](#7-lifecycle--kill-switch)
8. [Known Gaps and Member Guidance](#8-known-gaps-and-member-guidance)
9. [Compliance Quick Reference](#9-compliance-quick-reference)

---

## 1. Access & Enablement

### 1.1 Keep Use dots (Beta) off by default and grant it only through a pilot custom role

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-2, IA-2 |
| CIS Controls v8 | 4.1, 6.1 |

#### Description

Keep Use dots off in the workspace default and grant it through an approved custom role. The historical heading retains its Beta wording for existing links; the current administration page labels the permission Use dots and describes admin-preview access as off by default.

#### Rationale

**Why This Matters:**

- Effective grants are additive across defaults and assigned roles.
- Removing one group cannot revoke access granted by another role.

**Attack Prevented:** Unapproved autonomous-agent access and incomplete revocation.

#### ClickOps Implementation

1. Open **Admin Console > Permissions > Workspace default > Workspace capabilities** and turn **Use dots** off unless every member is approved.
2. Create a targeted custom role, grant Use dots, and assign the intended managed group. Review every direct and group role for the test member.
3. Review the three independent grants: messaging, local-computer access and custom rules. Enabling dots may offer shared cloud capabilities; approve each separately.

**Automation:** The current console/source-service controls are documented. The current ChatGPT Admin/policy API schema was not verified in this run; no API Platform operation or historical event schema is substituted for it.

#### Validation & Testing

Compare an approved member with an unapproved member and inspect all effective grants. Record current entitlement and UI labels; this run did not access a tenant.

**Sources:** [Primary reference](https://learn.chatgpt.com/docs/enterprise/dots-admin-guide) · [Supporting reference](https://learn.chatgpt.com/docs/enterprise/dots-security)

---

### 1.2 Require SSO or personal MFA on every account that owns a dot

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-2, IA-2 |
| CIS Controls v8 | 4.1, 6.1 |

#### Description

Protect the owner identity and every connected account. Only the owner can direct a personal dot; another person’s Slack mention does not authorize work. Source-service and browser sessions carry their own privileges.

#### Rationale

**Why This Matters:**

- A compromised owner can authorize ongoing work.
- A separate website session can permit changes beyond a read-only app connection.

**Attack Prevented:** Account takeover and actions through overprivileged signed-in sessions.

#### ClickOps Implementation

1. Apply the common guide’s workspace SSO, MFA and SCIM controls for eligible managed accounts; personal-plan owners must configure their own account protection.
2. Require approved identity/MFA in connected services and review existing cloud-browser sessions. Do not relax a device/VPN condition to make the cloud browser sign in.
3. Record the owner and dot identity from **Admin Console > Dots** and the identities used in Slack, plugins and websites.

**Automation:** The current console/source-service controls are documented. The current ChatGPT Admin/policy API schema was not verified in this run; no API Platform operation or historical event schema is substituted for it.

#### Validation & Testing

In an authorized test, verify owner-only instructions and inspect the connected service’s actor and outcome. Identity in a log is evidence of attribution, not proof of a complete action history.

**Sources:** [Primary reference](https://learn.chatgpt.com/docs/enterprise/dots-admin-guide) · [Supporting reference](https://learn.chatgpt.com/docs/enterprise/dots-security) · [Supporting reference](https://learn.chatgpt.com/docs/enterprise/identity-and-access)

---

## 2. Connected Apps & Channels

### 2.1 Restrict the app connections and actions dots inherit to read-only by default

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-6, CM-6 |
| CIS Controls v8 | 4.1, 6.1 |

#### Description

Limit workspace apps/actions and source-account permissions before enabling dots. A personal dot inherits its owner’s existing ChatGPT connections; connected-account authorization, workspace policy and per-action approval all constrain app calls.

#### Rationale

**Why This Matters:**

- A connection may already be available without a new consent flow.
- Read-only app settings do not block a signed-in browser or native computer from writing.

**Attack Prevented:** Excessive data access and an unintended external send.

#### ClickOps Implementation

1. In **Admin Console > Plugin controls**, enable only approved apps and actions. Set **New tools** (or **New actions**, where supported) to deny future additions; this does not disable actions already enabled. Scope access through supported roles.
2. Check the member’s actual source-account access and each action’s approval setting. Require approval for consequential sends or changes.
3. Test the same sensitive operation through plugins, the cloud browser, cloud computer and any delegated task. Revoke unnecessary source authorization.

**Automation:** The current console/source-service controls are documented. The current ChatGPT Admin/policy API schema was not verified in this run; no API Platform operation or historical event schema is substituted for it.

#### Validation & Testing

Use a disposable document and recipient. Confirm both a permitted read and a denied/unapproved write, then verify the receiving service rather than relying only on a proposed tool call.

**Sources:** [Primary reference](https://learn.chatgpt.com/docs/enterprise/dots-admin-guide) · [Supporting reference](https://learn.chatgpt.com/docs/enterprise/dots-security) · [Supporting reference](https://learn.chatgpt.com/docs/enterprise/apps-and-connectors)

---

### 2.2 Restrict Add dots to Slack and Microsoft Teams to a narrow role and keep Slack-side app approval on

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-6, CM-6 |
| CIS Controls v8 | 4.1, 6.1 |

#### Description

Treat a dot’s messaging identity and its owner’s Slack plugin connection as separate paths. The messaging permission does not install the ChatGPT Slack app or connect a member’s dot.

#### Rationale

**Why This Matters:**

- Disabling a Slack identity leaves an authorized Slack plugin usable.
- Messages posted by the dot can expose information to everyone in the target conversation.

**Attack Prevented:** Unapproved messaging integration and incomplete channel offboarding.

#### ClickOps Implementation

1. Limit **Add dots to Slack and Microsoft Teams** in **Admin Console > Permissions** to an approved custom role. Confirm current channel availability in the workspace.
2. Have the Slack owner/app manager enforce app approval and approve the ChatGPT app only for the intended workspace. The member completes dot setup from its profile.
3. Review the dot’s Slack/Teams connection status in **Admin Console > Dots** and inspect the separate member Slack plugin/account. On removal, revoke both paths and any browser session.

**Automation:** The current console/source-service controls are documented. The current ChatGPT Admin/policy API schema was not verified in this run; no API Platform operation or historical event schema is substituted for it.

#### Validation & Testing

Test owner instructions and a harmless message to an approved audience; inspect Slack actor/channel records. Other people’s mentions do not grant control of the personal dot.

**Sources:** [Primary reference](https://learn.chatgpt.com/docs/enterprise/dots-admin-guide) · [Supporting reference](https://learn.chatgpt.com/docs/enterprise/dots-security) · [Supporting reference](https://learn.chatgpt.com/docs/dots/channels)

---

### 2.3 Review the authority of delegated Codex Cloud environments

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-6, CM-6 |
| CIS Controls v8 | 6.8 |

#### Description

Treat delegation as a new execution boundary. A dot's permitted request must not silently acquire a shared environment's broad credentials, repositories or private-network identity.

#### Rationale

**Why This Matters:**

- Local sandbox restrictions do not automatically govern hosted execution.
- Environment-owned credentials and VPN/cloud identities can be shared even though personal connections remain tied to the person running the task.

**Attack Prevented:** Privilege expansion through an overprivileged delegated environment.

#### ClickOps Implementation

1. Separate **Use Codex in the cloud** from **Manage workspace environments** using the workspace permission controls. Give shared-environment editing to a smaller reviewed group.
2. In the environment configuration, keep **Privacy > Who can use > Only me** unless sharing is approved. Review prepared files, repository scope, environment-owned secrets, OIDC identities and VPN access before publishing a shared setup.
3. Turn off **Enable all public internet access** and add only required **Additional allowed domains** and package-manager destinations. Review VPN permissions independently: restricting public internet access does not disable VPN routes.
4. Save and publish/republish reviewed changes, replace running environments where required, and start a new test task. Limit source-service roles separately; an allowed domain is not an authorization policy.

**Automation:** Unverified — the fetched public environment guide documents configuration and permission controls, but this pass did not verify a current public administration write schema. No API Platform key/role endpoint is substituted for ChatGPT environment administration (checked 2026-11-12).

#### Validation & Testing

Run permitted and denied operations in a disposable task. Verify effective public and VPN reach, repository access, and the identity used at the receiving service. Confirm an ordinary task user cannot modify shared environment configuration. Do not include real secrets in the evidence.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST 800-53 | AC-6 least privilege; CM-6 configuration settings |

**Sources:** [Cloud environments](https://learn.chatgpt.com/docs/environments/cloud-environments) · [Dots execution boundaries](https://learn.chatgpt.com/docs/enterprise/dots-security)

---

## 3. Cloud Computer, Browser & Local Access

### 3.1 Re-baseline Cloud browser use and Cloud computer use before enabling dots

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-6, CM-6 |
| CIS Controls v8 | 4.1, 6.1 |

#### Description

Review shared cloud-browser and desktop capabilities for dots, Work Cloud and team automations. A restriction on local Codex does not establish the same restriction on a dot’s cloud computer.

#### Rationale

**Why This Matters:**

- A browser session can carry broad source-service rights.
- Shared capability changes affect more than one product.

**Attack Prevented:** Unintended cloud-browser or desktop access.

#### ClickOps Implementation

1. Open **Admin Console > Permissions > Workspace default > Workspace capabilities > Let agents use cloud computers**.
2. Keep **Use a browser** and **Allow computer use** off for populations that do not need them; inspect every custom-role grant.
3. If approved, inventory cloud-browser sign-ins and desktop app permissions separately. Sign out of unused source accounts: an active browser session is independent of password-manager storage, so turning off **Use password manager** does not terminate it. Review proposed site upload/download rules as a development item until available and verified.

**Automation:** The current console/source-service controls are documented. The current ChatGPT Admin/policy API schema was not verified in this run; no API Platform operation or historical event schema is substituted for it.

#### Validation & Testing

Verify both denied and allowed populations in each enabled environment. Cloud-browser per-site rules remain in development in the current dots security page; local rules do not substitute for them.

**Sources:** [Primary reference](https://learn.chatgpt.com/docs/enterprise/dots-admin-guide) · [Supporting reference](https://learn.chatgpt.com/docs/enterprise/dots-security)

---

### 3.2 Turn off Cloud network access for dots

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-6, CM-6 |
| CIS Controls v8 | 4.1, 6.1 |

#### Description

Disable cloud command/shell internet access when it is unnecessary. Allow network access governs that route; it does not by itself disable browsing, web search or connected apps.

#### Rationale

**Why This Matters:**

- Agents have several independent network paths.
- A local proxy allowlist cannot constrain every cloud action.

**Attack Prevented:** Exfiltration through unrestricted cloud command execution.

#### ClickOps Implementation

1. In **Let agents use cloud computers**, turn **Allow network access** off in the workspace default and remove excess custom-role grants.
2. Review **Use a browser**, plugins, web search and delegated Work/Codex environments independently.
3. Where networking is necessary, approve the runtime-specific destinations and verify them in the actual environment. Do not import local TOML as a universal cloud allowlist.

**Automation:** The current console/source-service controls are documented. The current ChatGPT Admin/policy API schema was not verified in this run; no API Platform operation or historical event schema is substituted for it.

#### Validation & Testing

Use harmless approved and denied destinations through each active route, and record residual access. Check the destination logs as well as available Compliance records.

**Sources:** [Primary reference](https://learn.chatgpt.com/docs/enterprise/dots-admin-guide) · [Supporting reference](https://learn.chatgpt.com/docs/enterprise/dots-security)

---

### 3.3 Keep Use password manager off for dots populations

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-6, CM-6 |
| CIS Controls v8 | 4.1, 6.1 |

#### Description

Keep Use password manager off unless there is an approved need. Private sign-in protects password entry from the model, but the resulting browser session can act with the signed-in account’s privileges.

#### Rationale

**Why This Matters:**

- The cloud browser stores its own cookies.
- Code can read tokens or cookies exposed to that code; private entry is not universal credential isolation.

**Attack Prevented:** Use of saved privileged accounts and persistent browser access.

#### ClickOps Implementation

1. Review **Use password manager** under workspace capabilities and every assigned role.
2. For an approved sign-in, verify the actual site and use the private form or **Open computer > Take over** to complete SSO/MFA. Preserve corporate device/network requirements.
3. Inventory saved sessions. End access by revoking source-service sessions where supported and clearing the site’s cloud-browser cookies.

**Automation:** The current console/source-service controls are documented. The current ChatGPT Admin/policy API schema was not verified in this run; no API Platform operation or historical event schema is substituted for it.

#### Validation & Testing

Confirm disabling password-manager use and revoking an established browser session are separate actions. Test with a low-privilege account; never place production credentials in a test fixture.

**Sources:** [Primary reference](https://learn.chatgpt.com/docs/enterprise/dots-admin-guide) · [Supporting reference](https://learn.chatgpt.com/docs/enterprise/dots-security)

---

### 3.4 Keep Allow local computer access off for dots

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-6, CM-6 |
| CIS Controls v8 | 4.1, 6.1 |

#### Description

Leave Allow local computer access off until the device and local execution policy have been reviewed. Admin opt-in and a member’s connection are both required; taking a computer offline leaves its connection configured.

#### Rationale

**Why This Matters:**

- A dot can delegate work from another messaging device.
- Device files, app permissions and retained local records form a separate boundary.

**Attack Prevented:** Remote use of an unapproved employee computer.

#### ClickOps Implementation

1. Keep **Allow local computer access** off in workspace/default roles for unapproved populations.
2. For approved users, apply the [Work/Codex local controls](/guides/chatgpt-work-codex/), including requirements, filesystem/sandbox/egress and OS permissions. A read-only sandbox still permits reads; use explicit denied-read requirements for credential paths. Review browser and native-app deny policies independently. Higher-priority MDM requirements take precedence on supported managed Macs.
3. Merge the read-only local baseline below into the applicable execution requirements, not into an unrelated cloud-computer setting. Native Windows shell subprocess reads do not enforce this denied-read sandbox rule; validate each deployed OS.
4. Review each connected computer and delegated thread. Disconnect through the supported member/device setup when offboarding, and remove independent credentials/sessions.
5. Use the [managed client update procedure](/guides/chatgpt-work-codex/#43-keep-desktop-and-companion-clients-on-a-managed-update-schedule) and restrict who can change the client launch environment. A local denied-read policy is not a guarantee that the client itself pins authenticated traffic to a trusted backend. Track vendor remediation for client-origin issues separately; do not invent an endpoint-override policy key.

#### Code Implementation

{% include pack-code.html vendor="chatgpt-dots" section="3.4" %}

The emitter does not deploy policy or change the workspace local-access grant. Verify the effective local runtime; it does not constrain the dot’s cloud computer.

#### Validation & Testing

Verify denial without both opt-ins. Inspect the runtime selected in Activity View and test the local executor’s effective policy rather than inferring it from the dot’s cloud settings.

**Sources:** [Primary reference](https://learn.chatgpt.com/docs/enterprise/dots-admin-guide) · [Supporting reference](https://learn.chatgpt.com/docs/enterprise/dots-security) · [Supporting reference](https://learn.chatgpt.com/docs/enterprise/cloud-local-access)

---

## 4. Autonomy & Approvals

### 4.1 Keep Use custom rules for dots off outside a narrow role

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-6, CM-6 |
| CIS Controls v8 | 4.1, 6.1 |

#### Description

Disable Use custom rules for dots outside an approved population. When disabled, members cannot add/edit rules and saved rules do not apply. This does not force every tool call to request a fresh approval.

#### Rationale

**Why This Matters:**

- Rules can authorize recurring actions within the owner’s scope.
- Required safety checks and source-system permissions remain independent.

**Attack Prevented:** Unreviewed persistent instructions and mistaken approval guarantees.

#### ClickOps Implementation

1. In **Admin Console > Permissions**, turn **Use custom rules for dots** off in the workspace default and review all role grants.
2. If enabled for a role, review intended send/recipient/schedule boundaries with those members.
3. Test the effect on saved rules, and separately configure plugin action approvals and mandatory enterprise requirements.

**Automation:** The current console/source-service controls are documented. The current ChatGPT Admin/policy API schema was not verified in this run; no API Platform operation or historical event schema is substituted for it.

#### Validation & Testing

Verify a saved custom rule stops applying after effective permission removal. Check a consequential action’s actual review behavior; “rules off” does not mean “every action always asks”.

**Sources:** [Primary reference](https://learn.chatgpt.com/docs/enterprise/dots-admin-guide) · [Supporting reference](https://learn.chatgpt.com/docs/enterprise/dots-security)

---

### 4.2 Enforce orchestrator approval and web-search limits in the Agent Security Global baseline

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-6, CM-6 |
| CIS Controls v8 | 4.1, 6.1 |

#### Description

Use supported Agent Security Global requirements for the cloud orchestrator when managed policy is enabled. Review local and Codex Cloud execution requirements separately; coverage across every browser/desktop/delegated action remains under review.

#### Rationale

**Why This Matters:**

- Requirements and user defaults have different enforcement semantics.
- A local executor’s policy cannot prove a cloud orchestrator restriction.

**Attack Prevented:** Overbroad autonomous approvals and misapplied runtime policy.

#### ClickOps Implementation

1. Open **Admin Console > Managed configuration**, select the appropriate Global policy and targets, and use the documented **Raw TOML > requirements.toml** editor. Confirm managed configuration is enabled for the population.
2. Merge the pack’s supported approval/search limits with existing requirements. Configure the permitted approval reviewer separately: an on-request policy alone does not promise a human reviewer. Browser actions have separate Auto-review controls. Review approval-policy behavior and supported versions.
3. Inspect local and Codex Cloud policies independently. Command prefix requirements can use **prompt** or **forbidden** in supported current clients; neither is a blanket policy for browser clicks or app/MCP actions. Do not copy an older claim that only forbidden is enforced. Preserve source-account permissions and review the main dot’s separate model-control boundary.

#### Code Implementation

{% include pack-code.html vendor="chatgpt-dots" section="4.2" %}

#### Validation & Testing

Compare effective policy and an approved/denied workflow in the actual runtime. Emitting valid TOML is an offline check; it does not verify that Global settings bind the tested dot.

**Sources:** [Primary reference](https://learn.chatgpt.com/docs/enterprise/agent-security) · [Supporting reference](https://learn.chatgpt.com/docs/enterprise/managed-configuration) · [Supporting reference](https://learn.chatgpt.com/docs/enterprise/dots-security)

---

### 4.3 Treat managed MCP hooks for dots as fail-open telemetry, not enforcement

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-6, CM-6 |
| CIS Controls v8 | 4.1, 6.1 |

#### Description

Use supported managed MCP hooks as conditional review and telemetry, with an explicit outage plan. PreToolUse errors/timeouts fail open. Command, local and plugin handlers do not run in the cloud orchestrator.

#### Rationale

**Why This Matters:**

- A configured hook can be skipped or unavailable.
- Hook visibility is not a complete record of all dot activity.

**Attack Prevented:** Overreliance on a fail-open decision service.

#### ClickOps Implementation

1. Configure only approved **mcp_tool** handlers in the Global requirements editor. Register the actual approved MCP server/tool and review its authentication/data processing.
2. Keep the vendor-documented input placeholders intact. Select a short justified timeout and test a real denial separately from a service failure.
3. Document fail-open behavior, supported event types and cloud limitations. Use source-service authorization for restrictions that must survive hook outages.

#### Code Implementation

{% include pack-code.html vendor="chatgpt-dots" section="4.3" %}

#### Validation & Testing

Test an allow, a deliberate deny and an unreachable service in a controlled tenant. Do not label a TOML parser or static handler inventory as enforcement verification.

**Sources:** [Primary reference](https://learn.chatgpt.com/docs/enterprise/agent-security) · [Supporting reference](https://learn.chatgpt.com/docs/hooks) · [Supporting reference](https://learn.chatgpt.com/docs/enterprise/dots-security)

---

### 4.4 Set member custom rules to hand off purchases and ask before external sends

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-6, CM-6 |
| CIS Controls v8 | 4.1, 6.1 |

#### Description

Where custom rules are approved, make owner authorization explicit: name the action, content, recipients, trigger and schedule. Permission to prepare a draft does not authorize sending it.

#### Rationale

**Why This Matters:**

- An authorized recurring task can send without a new prompt each time.
- A broader audience or changed task falls outside the original authorization.

**Attack Prevented:** Scope creep in unattended sends and purchases.

#### ClickOps Implementation

1. Review member instructions for purchases, external sends and sharing. Set clear confirmation boundaries in allowed custom rules.
2. Review every active task/trigger and intended audience in the dot’s Activity View.
3. Use source-account permissions and app approval settings alongside owner instructions. Auto-review can block or request clarification; owner approval cannot override required safety checks.

**Automation:** The current console/source-service controls are documented. The current ChatGPT Admin/policy API schema was not verified in this run; no API Platform operation or historical event schema is substituted for it.

#### Validation & Testing

Try a harmless draft and a changed-recipient send with disposable recipients. Record the resulting prompt/review and the receiving service’s final state; model behavior is not a deterministic access-control rule. For executable work, compare the actual command, arguments, target, working directory and reviewed file content with what will run; review again after a material change. Do not equate a friendly summary or successful output with immutable approval binding. This is an operator verification procedure, not a documented native hash-binding guarantee.

**Sources:** [Primary reference](https://learn.chatgpt.com/docs/enterprise/dots-admin-guide) · [Supporting reference](https://learn.chatgpt.com/docs/enterprise/dots-security)

---

## 5. Data, Memory & Residency

### 5.1 Keep dots out of workspaces and populations that require residency, EKM, or zero retention

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | SI-12, SC-12 |
| CIS Controls v8 | 4.1, 6.1 |

#### Description

The historical heading is retained for existing links; its former blanket residency/EKM exclusion is superseded. Current documentation supports specified storage regions, US/Europe inference, and eligible EKM/HIPAA workspaces. Strict zero data retention remains unsupported and FedRAMP workspaces remain unavailable.

#### Rationale

**Why This Matters:**

- Storage, inference and third-party processing have different boundaries.
- An eligible feature is not proof that a particular agreement/workflow covers every copy.

**Attack Prevented:** Use outside contractual residency, key-management or retention requirements.

#### ClickOps Implementation

1. Confirm workspace eligibility and contract: storage Australia, Canada, Europe (EEA/Switzerland), India, Japan, Singapore, South Korea, UK or US; UAE is excluded. Dots inference supports US/Europe, not UAE.
2. For EKM/HIPAA, confirm actual supported content, key configuration and BAA. Review cloud computers, plugins and delegated work separately.
3. The optional native residency pack is only the documented US Codex requirement. It disables incompatible Work/local-access and dots use; it is not a selector for the dot’s storage region.

#### Code Implementation

{% include pack-code.html vendor="chatgpt-dots" section="5.1" %}

#### Validation & Testing

Record actual workspace region/key/BAA eligibility and any workflow exclusions. Verify snapshot expiry configuration rather than assuming EKM implies immediate deletion.

**Sources:** [Primary reference](https://learn.chatgpt.com/docs/enterprise/dots-security) · [Supporting reference](https://learn.chatgpt.com/docs/enterprise/managed-configuration)

---

### 5.2 Limit what flows into a dot's persistent memory

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | SI-12, SC-12 |
| CIS Controls v8 | 4.1, 6.1 |

#### Description

Minimize source access before the dot reads it. Turning off ChatGPT Memory stops sharing but does not erase context already received by the dot. Dot conversations can also contribute to separately stored ChatGPT Memory.

#### Rationale

**Why This Matters:**

- Revoking a connection stops future requests but leaves earlier retained information.
- Dot context and saved ChatGPT memories have separate deletion paths.

**Attack Prevented:** Retention of sensitive data after access removal.

#### ClickOps Implementation

1. Limit proactive research and connected accounts to approved sources. Review ChatGPT Memory settings, saved memories and chat history independently.
2. To remove dot context, use the supported dot deletion/reset path; individual source-derived notes cannot be removed while keeping the dot.
3. Delete separately stored memories, chats, files and exports through their own owners. Preserve legal evidence/holds before deletion.

**Automation:** The current console/source-service controls are documented. The current ChatGPT Admin/policy API schema was not verified in this run; no API Platform operation or historical event schema is substituted for it.

#### Validation & Testing

Track a harmless marker through dot context, ChatGPT Memory and separately saved files. Dot context and dot-owned backups are deleted within 30 days of dot deletion; source/app copies follow their own policies.

**Sources:** [Primary reference](https://learn.chatgpt.com/docs/enterprise/dots-security) · [Supporting reference](https://learn.chatgpt.com/docs/dots/tasks-and-memory)

---

## 6. Monitoring & Audit

### 6.1 Ingest the Compliance Logs Platform records that cover dots, and prove coverage with a test task

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AU-2, AU-6, AU-12 |
| CIS Controls v8 | 8.2, 8.5 |

#### Description

Export the supported ChatGPT Compliance logs continuously and prove coverage with an identifiable task. Current dots-attributed records use client_id = DOTS with dot ID/name/type in the agent object where available; the earlier “no discriminator” claim is superseded.

#### Rationale

**Why This Matters:**

- Compliance records expire 30 days from creation.
- Tool-call suggestions and available results do not prove every external outcome.

**Attack Prevented:** Unattributed activity and loss of incident evidence.

#### ClickOps Implementation

1. In **Admin Console > Credentials > Admin keys**, use the available **CODEX_LOG** permission for dots records. Only workspace owners can grant broad compliance/Conversation messages access where supported.
2. Run the read-only exporter with a private output directory and explicit start time. It exports authorized CODEX_LOG files without inventing an unverified record-filter path.
3. Collect supported local OpenTelemetry separately where local execution is enabled, using the [Work/Codex telemetry control](/guides/chatgpt-work-codex/#33-collect-minimal-telemetry-and-verify-compliance-coverage). Keep prompt/response collection minimized. A local collector does not capture cloud orchestration.
4. Select actual DOTS-attributed records in your receiving pipeline; test APP_MCP_CALL/APP_MCP_RESULT and TOOL_CALL_SUGGESTED coverage. Correlate with source-service outcomes.

#### Code Implementation

{% include pack-code.html vendor="chatgpt-dots" section="6.1" %}

#### Validation & Testing

Exercise a harmless identified dot/task, confirm metadata and record freshness, and document missing tool results/approval detail. Offline pagination fixtures test the downloader, not tenant coverage.

**Sources:** [Primary reference](https://learn.chatgpt.com/docs/enterprise/dots-admin-guide) · [Supporting reference](https://learn.chatgpt.com/docs/enterprise/dots-security) · [Supporting reference](https://learn.chatgpt.com/docs/enterprise/compliance-api)

---

### 6.2 Alert on governance changes that widen what dots can reach

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AU-2, AU-6, AU-12 |
| CIS Controls v8 | 8.2, 8.5 |

#### Description

Monitor effective workspace roles, shared cloud capabilities, plugin actions, managed policy and individual-dot admin changes. ChatGPT administration and API Platform organization audit logs are separate control planes.

#### Rationale

**Why This Matters:**

- Several settings can widen a dot’s reach without changing Use dots.
- A similarly named API organization role event does not verify a ChatGPT workspace setting.

**Attack Prevented:** Undetected privilege expansion and misleading governance evidence.

#### ClickOps Implementation

1. Review **Admin Console > Dots** and available audit records for pause, resume, delete, manage and saved-tier changes.
2. Take approved configuration snapshots and inspect workspace default, direct/group roles, app actions and policy targets. Confirm the actual current record fields before creating detections.
3. Use **Analytics** and the daily workspace usage API for adoption; DOTS client_id and enterprise.analytics.usage.read identify the reporting surface. Usage is not a security-event feed.

**Automation:** The current console/source-service controls are documented. The current ChatGPT Admin/policy API schema was not verified in this run; no API Platform operation or historical event schema is substituted for it.

#### Validation & Testing

For an authorized harmless admin change, correlate the console state with the actual ChatGPT record and actor. The current public Admin API schema could not be loaded in this run; no new event-name/field Sigma claims are published.

**Sources:** [Primary reference](https://learn.chatgpt.com/docs/enterprise/dots-admin-guide) · [Supporting reference](https://learn.chatgpt.com/docs/enterprise/analytics-api) · [Supporting reference](https://learn.chatgpt.com/docs/enterprise/compliance-api)

---

## 7. Lifecycle & Kill Switch

### 7.1 Rehearse the dots kill sequence: stop the dot's work and revoke every grant

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-2, IR-4 |
| CIS Controls v8 | 4.1, 6.1 |

#### Description

Pause the individual dot from Admin Console and remove every effective access grant during containment. Admin pause prevents member resume. Already-running delegated Work/Codex tasks and independent schedules require separate cancellation.

#### Rationale

**Why This Matters:**

- Stopping the orchestrator is not a universal stop for delegated execution.
- Restoring a grant can restore the prior active state and restart billing.

**Attack Prevented:** Continued autonomous activity during incident response or offboarding.

#### ClickOps Implementation

1. Open **Admin Console > Dots**, identify the owner/dot identity and pause it. Preserve relevant links and available records.
2. Cancel Work/Codex tasks and independent schedules separately. Revoke plugin authorization, browser sessions, local connections and source credentials where needed.
3. Remove every **Use dots** grant through defaults/direct/group roles, including the IdP for SCIM-managed assignments. Confirm disabled inventory status; separately verify workspace membership removal.

**Automation:** The current console/source-service controls are documented. The current ChatGPT Admin/policy API schema was not verified in this run; no API Platform operation or historical event schema is substituted for it.

#### Validation & Testing

Rehearse in a controlled tenant. Current documentation says running work may complete on permission revocation. Compliance state has a reported 30-minute p95; scheduled state is checked 30 minutes after the next run, not an immediate-stop guarantee.

**Sources:** [Primary reference](https://learn.chatgpt.com/docs/enterprise/dots-admin-guide) · [Supporting reference](https://learn.chatgpt.com/docs/enterprise/dots-security)

---

### 7.2 Reset (delete) the dot at offboarding or after sensitive exposure

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-2, IR-4 |
| CIS Controls v8 | 4.1, 6.1 |

#### Description

Delete the dot when its retained context must be removed. Admin deletion is now documented and is distinct from reversible pause or access removal. Other product records and source-service effects survive independently.

#### Rationale

**Why This Matters:**

- Access removal preserves the dot’s data.
- Deleting the dot cannot undo a message, file change or separately retained copy.

**Attack Prevented:** Orphaned persistent context and incomplete offboarding.

#### ClickOps Implementation

1. Preserve required evidence and holds, pause the dot and handle ongoing delegated work first.
2. Use **Admin Console > Dots > dot details > Delete**, or the member’s supported Reset flow. Verify removal from inventory after completion.
3. Delete separate ChatGPT conversations, Codex/Work threads, Space/project/local/external files and ChatGPT memories through their own controls. Revoke remaining source sessions.

**Automation:** The current console/source-service controls are documented. The current ChatGPT Admin/policy API schema was not verified in this run; no API Platform operation or historical event schema is substituted for it.

#### Validation & Testing

Verify dot context/private research history and dot-owned backups follow the documented 30-day deletion window. Eligible residency/EKM snapshot expiry uses a five-day cycle/seven-day maximum; otherwise snapshots have no documented maximum age while active and no confirmed early purge.

**Sources:** [Primary reference](https://learn.chatgpt.com/docs/enterprise/dots-admin-guide) · [Supporting reference](https://learn.chatgpt.com/docs/enterprise/dots-security)

---

## 8. Known Gaps and Member Guidance

### 8.1 Documentation conflicts to resolve in a live tenant

The November administration and security pages resolve earlier disagreements about individual admin lifecycle, identity, audit attribution and regional/EKM eligibility. Workspace availability, supported policy versions and any remaining UI/reference mismatch must be checked in the actual tenant.

### 8.2 No admin kill switch, inventory or delete for an individual dot

**Superseded:** current Admin Console > Dots provides inventory, owner/status/identity, messaging status, pause/resume and delete. Admin pause prevents member resume. See 7.1–7.2; retain this historical heading only for existing links.

### 8.3 No write interface for any dots permission

**Current API contract unverified:** current Global policy API support is documented, so the former blanket absence claim is withdrawn. The public reference delivered a shell without a usable operation schema during this run. Console controls remain covered; no invented endpoint is provided.

### 8.4 Agent Security Global policy may not bind a cloud-only dot

Global policy applies to supported orchestration when enabled; local, Codex Cloud and the dot cloud computer have separate controls. Cloud-browser site upload/download rules remain in development. Do not extrapolate a local requirement to all cloud actions.

### 8.5 Audit attribution and plan coverage

Current records identify dots with client_id = DOTS and agent metadata where available. CODEX_LOG tool/app coverage remains partial; site-level destinations, some results and review detail remain in development. Pro/Business access does not establish Enterprise Compliance entitlement.

### 8.6 Business Premium and Pro: what the owner must do

Use the permissions available in the actual plan: account MFA, least-privilege source connections, app approvals, explicit recurring-task instructions, browser sign-out and owner pause/reset. Do not claim Enterprise role, EKM or Compliance features exist on a personal plan.

### 8.7 Member-level surfaces with no admin control

Members direct their own personal dots, configure allowed connections, and inspect Activity View. Workspace admins can now pause/delete the dot, but must handle independently stored data and delegated work separately.

### 8.8 Egress, retention, memory and offboarding unknowns

Source revocation stops new requests, not retained information. Dot context/private research and backups have a 30-day deletion window after deletion. Space pages, files, cached copies, ChatGPT memories and delegated threads follow separate policies; deletion of a Space file does not clear its dot-chat cache. No separate cache-removal procedure is confirmed.

### 8.9 Spend, specialist dots and Agent 365

Admin pause stops billing; resuming/restoring access can return the prior active state and billing. This guide covers documented personal-dot controls. Specialist/Agent 365 announcements do not establish an additional current admin contract; verify scope before deployment.

### 8.10 Benchmarks, incidents and dropped sources

Framework mappings below are control-family references, not a product-specific benchmark or evidence of an applied configuration. Source-admission and third-party research findings are recorded in the family inventory; unverified retrievals are not absence findings.

### 8.11 What live validation must settle

Tenant verification must confirm effective grants, current API schema/permissions, runtime policy, plugin/browser approval paths, lifecycle propagation, metadata and external outcomes. No tenant was accessed in this refresh; offline exporter/config tests cannot establish those results.

## 9. Compliance Quick Reference

| Framework | Relevant families |
|-----------|-------------------|
| NIST 800-53 Rev 5 | AC-2/AC-6 identity and privilege; AU-2/AU-6/AU-12 records; CM-6 requirements; IR-4 containment; SI-12 retention |
| CIS Controls v8 | 4 secure configuration; 6 access control; 8 audit logs |
| SOC 2 | CC6 access; CC7 monitoring/response; C1 confidentiality |

## Appendix A: Edition and Plan Availability

Confirm current availability in the [admin guide](https://learn.chatgpt.com/docs/enterprise/dots-admin-guide) and setup notices. Eligible Enterprise workspace controls do not imply personal/Business entitlement. Main-dot model policy, cloud-computer capabilities, local-access opt-in, BAA, EKM and residency require separate review.

## Appendix B: References

- [Dots administration](https://learn.chatgpt.com/docs/enterprise/dots-admin-guide)
- [Dots security and retention](https://learn.chatgpt.com/docs/enterprise/dots-security)
- [Agent Security](https://learn.chatgpt.com/docs/enterprise/agent-security)
- [Managed configuration](https://learn.chatgpt.com/docs/enterprise/managed-configuration)
- [Compliance API](https://learn.chatgpt.com/docs/enterprise/compliance-api)

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-11-12 | 0.3.0 | ai-drafted | Reconciled Pluto guidance: added delegated-environment least privilege, local denied-read pack, future-action denial, retained browser-session cleanup and split telemetry/reviewer validation. No live tenant validation. | Codex |
| 2026-11-05 | 0.2.0 | ai-drafted | Corrected individual admin lifecycle, DOTS attribution, eligibility and retention; separated runtime/integration containment; replaced unverified historical API/Sigma assumptions with current exporter and native TOML. Original control headings retained; no live validation. | Codex |
| 2026-10-09 | 0.1.1 | ai-drafted | Moved under the new OpenAI multi-product platform as a product guide (`platform: "OpenAI"`, `product: "ChatGPT Dots"`); the Overview now points to the ChatGPT Enterprise guide as the OpenAI Common Controls hub. No control changed. | Claude Code (Opus 5.5) |
| 2026-10-09 | 0.1.0 | ai-drafted | Initial guide for ChatGPT dots (launched 2026-09-29): 18 controls in 7 sections (access and enablement, connected apps and channels, cloud computer and local access, autonomy and approvals, data and memory, monitoring, lifecycle), a Known Gaps and Member Guidance reference section recording eighteen OpenAI documentation conflicts and the controls OpenAI does not offer, and Code Pack includes for 11 controls (api, siem/sigma, config, cli). Written from OpenAI documentation with no live tenant validation, then corrected after an adversarial review whose facts were re-checked on 2026-10-09 (help.openai.com, chatgpt.com/public/admin/api-reference and www.beyondtrust.com return 403 to automated fetchers, so those pages were read in a real browser) | Claude Code (Opus 5.5) |

---
layout: guide
title: "ChatGPT Work and Codex Hardening Guide"
vendor: "ChatGPT Work and Codex"
slug: "chatgpt-work-codex"
platform: "OpenAI"
platform_slug: "openai"
product: "ChatGPT Work and Codex"
tier: "1"
category: "AI/ML Platform"
description: "Managed identity, local and cloud execution, browser and computer permissions, integrations, data and security tooling for Work and Codex"
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-05"
---

## Overview

Use the [OpenAI common controls](/guides/chatgpt-enterprise/) for eligible ChatGPT workspace identity, roles, sharing, plugins and Compliance governance. This guide covers ChatGPT Work local/cloud, local Codex in the desktop app, CLI and IDE, Codex Cloud and Codex Security. The [API Platform guide](/guides/openai-api/) governs API-key-authenticated organization/project access. [Dots](/guides/chatgpt-dots/) has a separate personal-agent lifecycle.

These products share selected workspace policy and client capabilities. Each run must be assessed by identity, orchestrator and executor: device requirements govern supported local execution; Codex Cloud has supported execution policy; Work cloud containers and dots cloud computers retain separate capability controls. A local policy does not establish a cloud restriction. Global policy applies only to supported capabilities when enabled.

**Intended audience:** workspace owners, device and source-system administrators, security engineers and developers deploying managed clients. **Profiles:** L1 (Crawl) for the basic boundary; L2 (Walk) for sensitive environments. **Scope:** documented customer controls current on 2026-11-05; no tenant validation. API/model feature catalogs and provider-internal safeguards are outside configurable hardening scope. Linux desktop remains preview.

### Intended Audience

Workspace/device administrators, security engineers, developers and owners of the source systems reached by Work or Codex.

### How to Use This Guide

Apply L1 (Crawl) at each identity and execution boundary, then L2 (Walk) for sensitive workflows. Identify the orchestrator, executor, authentication route and installed version before selecting policy.

### Scope

Work local/cloud, Codex desktop/CLI/IDE/Cloud and Codex Security; supported device requirements, browser/computer/network, integrations, persisted state and telemetry. Provider-internal controls are outside customer configuration scope.

## Table of Contents

1. [Identity and machine accounts](#1-identity-and-machine-accounts)
2. [Managed execution and integrations](#2-managed-execution-and-integrations)
3. [Cloud environments, state and evidence](#3-cloud-environments-state-and-evidence)
4. [Security tooling and client lifecycle](#4-security-tooling-and-client-lifecycle)
5. [Automation and evidence limits](#5-automation-and-evidence-limits)

---

## 1. Identity and machine accounts

### 1.1 Bind approved identities and protect local credentials

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, SI-4 |

#### Description

Separate workspace product eligibility from device authentication. On managed devices restrict Codex login to the approved ChatGPT workspace and require OS keyring storage. API-key and Bedrock authentication use a separate organization and contract; a ChatGPT seat does not govern them.

#### Rationale

**Why This Matters:**

- A personal workspace or API credential can bypass the intended workspace policy boundary.
- The auto credential store can fall back to plaintext; a copied local auth file can expose shared CLI and IDE sessions.

**Attack Prevented:** Personal-account bypass and theft of persistent local credentials.

#### ClickOps Implementation

1. In **Admin Console > Permissions & roles**, review the combined **Codex and Work Local** permission or independent **Codex Local** and **Work Local** permissions shown for your workspace. Grant only the intended users and groups; review every additive role.
2. Use device management to deploy authentication requirements to **/etc/codex/requirements.toml** on Unix, **%ProgramData%\OpenAI\Codex\requirements.toml** on Windows, or macOS MDM **com.openai.codex > requirements_toml_base64**. These authentication keys are device-only; cloud policy ignores them.
3. Choose the approved workspace UUID and keyring mode. Keyring failure should block credential persistence; do not silently substitute auto. Review existing auth.json, access tokens, IDE/CLI shared sessions and local backups during migration.

#### Code Implementation

{% include pack-code.html vendor="chatgpt-work-codex" section="1.1" %}

#### Validation & Testing

On a disposable managed account, check /debug-config and attempt a disallowed workspace/login method. Confirm the native keyring is used and logout/revocation covers CLI and IDE; login status alone does not establish workspace policy.

**Sources:** [Configuration reference](https://learn.chatgpt.com/docs/enterprise/managed-configuration) · [Supporting documentation](https://learn.chatgpt.com/docs/auth) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/roles-and-workspace-permissions)

---

### 1.2 Scope workspace service accounts and token lifetimes

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, SI-4 |

#### Description

Use ChatGPT workspace service accounts for eligible pay-as-you-go automation. They are distinct from API project service accounts and do not inherit their creator’s plugins, roles or groups. Give token creation and configuration rights separately.

#### Rationale

**Why This Matters:**

- Unattended tokens can retain broad access after an employee leaves.
- Service-account plugin connections are independent identities whose source permissions require review.

**Attack Prevented:** Unbounded machine identity and orphaned automation tokens.

#### ClickOps Implementation

1. In **Admin Console > Service accounts**, select or create the intended account where available. Set the minimum role/groups and configure its plugins independently.
2. Share only the required service-account right: User can create tokens, Configure can configure plugins, and Manager can do both. Set the permitted token scope and lifetime in the workspace access-token controls.
3. For CLI 0.142.0+, supply an approved short-lived CODEX_ACCESS_TOKEN without saving a login where possible. Disable the service account to revoke all its tokens; SCIM-managed accounts with userType ServiceAccount must be changed at the IdP.

**Automation:** Current service-account read/write API routes are described in prose, but the current public Admin schema did not load during this review. UI implementation is verified; API pagination and writes remain unverified. Do not substitute API project service-account calls.

#### Validation & Testing

Test denied token/configuration operations for the opposite role and confirm disabled accounts lose access. Re-enabling requires new tokens; preserve inventory before irreversible deletion.

**Sources:** [Configuration reference](https://learn.chatgpt.com/docs/enterprise/service-accounts) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/access-tokens)

---

### 1.3 Control paired mobile, desktop and SSH access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, SI-4 |

#### Description

Inventory the devices that can control a connected computer, separately from the computer that executes work. Mobile Codex uses Cloud or a paired Mac/Windows host; SSH projects execute on the remote host.

#### Rationale

**Why This Matters:**

- A controller can reach the host’s existing files, plugins and credentials.
- Signing out disables Remote Control but preserves existing pairings, which can become usable after re-enabling it.

**Attack Prevented:** Unexpected reuse of trusted devices and exposure of a remote app-server transport.

#### ClickOps Implementation

1. On each approved host open **Settings > Connections > Control this Mac or PC**. Review remote access and pair only trusted devices through the QR flow using the same account and workspace. Review **Control other devices** separately.
2. Restrict Remote Control eligibility in workspace permissions where available. During offboarding review pairings and disable Remote Control; confirm which devices remain paired before restoring it.
3. For SSH projects, use trusted SSH keys and a least-privilege remote account. Review remote Codex authentication, requirements and filesystem access independently. Do not expose app-server transports on public/shared networks.

**Automation:** Current setup and remote-host behavior are documented; a public pairing-management API/CLI contract was not verified. SSH and device policy require their own supported administration tools. Do not use a local login status as evidence that every paired device was revoked.

#### Validation & Testing

Test an approved controller, a different workspace and disabled Remote Control. Verify the executor and its effective policy before approving a mobile action. Test logout and subsequent re-enable behavior with a disposable pairing.

**Sources:** [Mobile](https://learn.chatgpt.com/docs/mobile) · [Remote connections](https://learn.chatgpt.com/docs/remote-connections)

---

## 2. Managed execution and integrations

### 2.1 Enforce permission profiles, approvals and denied reads

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, SI-4 |

#### Description

Deliver enforced requirements instead of relying on project instructions or config defaults. Allow only reviewed permission profiles, require on-request approvals, and deny reads of sensitive paths. Read-only permissions still permit reading accessible secrets.

#### Rationale

**Why This Matters:**

- Repository config and skills are untrusted inputs and cannot define the organization’s security boundary.
- Full access removes sandbox restrictions; an allowed default alone does not restrict selectable profiles.

**Attack Prevented:** Sandbox escape by configuration drift, secret reads and unsafe escalation.

#### ClickOps Implementation

1. Open **Admin Console > Agent Security > policy > Global** and any applicable **Local** or **Codex Cloud** execution override. Use **Requirements > Edit as TOML** for advanced fields; preserve policy priority and assignments.
2. Use supported permission-profile allowlists on Codex 0.138.0+ and set an allowed managed default. Retain sandbox-mode constraints for legacy clients where needed. The retired approval_policy untrusted value is not a deployment setting.
3. Confirm effective cached policy and restart requirements. A supported local client uses a valid identity-matched cloud cache; without one, a failed load returns an error. A refresh does not establish immediate enforcement in an already-running task. Deploy deny_read requirements and specific command rules. Device MDM/legacy requirements outrank cloud policy, which outranks system requirements. Environment specificity wins only within a policy; a lower-priority policy cannot override a higher-priority one.

#### Code Implementation

{% include pack-code.html vendor="chatgpt-work-codex" section="2.1" %}

#### Validation & Testing

Inspect /debug-config on each runtime/version, then test reading a disposable denied file, workspace writes, full-access selection and an escalation. Native Windows direct-file rules do not alone establish subprocess enforcement; see 4.4 and test the selected sandbox.

**Sources:** [Configuration reference](https://learn.chatgpt.com/docs/enterprise/managed-configuration) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/agent-security) · [Supporting documentation](https://learn.chatgpt.com/docs/permissions)

---

### 2.2 Restrict browser access across every enabled browser route

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, SI-4 |

#### Description

Configure the embedded browser, external browser and full-CDP access separately. Browser origin rules use scheme, host and optional port; they are not URL-path filters. A native Computer Use action controlling a browser follows a different permission boundary.

#### Rationale

**Why This Matters:**

- An approved browser session carries the signed-in user’s source permissions.
- Disabling one browser feature does not disable other browsers or native app control.

**Attack Prevented:** Browser-session misuse, uploads to unapproved origins and overbroad persistent approvals.

#### ClickOps Implementation

1. In **Agent Security > policy > Global or Local > Requirements**, force off unneeded **browser_use**, **browser_use_external**, **browser_use_full_cdp_access** and **in_app_browser** features.
2. Where browser use is approved, configure **Browser use > Site rules**, default Block, and exact approved origins. Review upload, download, full CDP, history and persistent approval separately; prefer This turn approvals.
3. Review cloud browser permissions separately in **Admin Console > Permissions > Workspace capabilities > Let agents use cloud computers**. Local origin rules do not configure hosted Work/dots browsers.

#### Code Implementation

{% include pack-code.html vendor="chatgpt-work-codex" section="2.2" %}

#### Validation & Testing

Test a permitted origin and a denied origin, upload/download and a new turn. Check Computer Use and external browser routes separately; a passing embedded-browser test is not universal coverage.

**Sources:** [Configuration reference](https://learn.chatgpt.com/docs/enterprise/managed-configuration) · [Supporting documentation](https://learn.chatgpt.com/docs/browser)

---

### 2.3 Limit native Computer Use and locked-device access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, SI-4 |

#### Description

Default native application access to deny and allow only reviewed app identities. Distinguish macOS bundle IDs from Windows application identities. Keep unattended locked-device access disabled unless expressly reviewed.

#### Rationale

**Why This Matters:**

- Desktop control can interact with credentials and apps outside command sandbox permissions.
- Computer Use controlling a browser is not constrained by Browser Use origin rules.

**Attack Prevented:** Desktop-session takeover and bypass of browser-only restrictions.

#### ClickOps Implementation

1. In **Agent Security > supported local policy > Requirements > Computer use**, set default app access to deny and add the supported platform-specific app identities that the workflow needs.
2. Disable persistent approvals and locked computer use where unnecessary. Setting allow_locked_computer_use=false prevents enabling that mode; it does not turn off an already enabled state. Review affected devices individually.
3. Review macOS screen/input permissions, the temporary unlock/shield behavior, and every display. Windows Computer Use requires an unlocked visible session. Keep device and native app permissions scoped.

#### Code Implementation

{% include pack-code.html vendor="chatgpt-work-codex" section="2.3" %}

#### Validation & Testing

Use disposable apps/files to test denied applications and locked state after restarting the client. Verify each supported OS independently; do not infer cloud computer controls from local app identities.

**Sources:** [Configuration reference](https://learn.chatgpt.com/docs/enterprise/managed-configuration) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/chatgpt-work-local-security)

---

### 2.4 Constrain command egress and review every independent network path

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, SI-4 |

#### Description

Use managed command proxy rules with administrator-owned allow entries and exclusive managed domains where required. The command proxy does not govern hosted web search, app/MCP calls, browser use or all privileged executions.

#### Rationale

**Why This Matters:**

- Blocking code networking alone leaves other exfiltration paths available.
- A full approved sandbox escalation can bypass proxy restrictions; cloud VPN routes are independent of public internet controls.

**Attack Prevented:** Command-based exfiltration and false assurance from an incomplete network allowlist.

#### ClickOps Implementation

1. In **Agent Security > policy > applicable execution environment > Requirements > Manage networking**, enable managed networking and **Only allow domains set by admins** with explicit Allow entries.
2. Use the native experimental_network compatibility name until every client and policy validator supports network_proxy (Codex 0.166.0). Use one name per layer. Do not combine domains maps with legacy domain lists.
3. Review escalation rules, localhost/private-network behavior, cloud environment additional domains, network-secret destinations and VPNs. Work cloud containers/dots cloud computers do not inherit Local/Codex Cloud execution policy.

#### Code Implementation

{% include pack-code.html vendor="chatgpt-work-codex" section="2.4" %}

#### Validation & Testing

Test allowed and denied destinations from ordinary commands and each approved escalation path. Check browser/search/apps separately. Empty environment maps inherit entries; deny-only exclusive rules do not allow the rest of the internet.

**Sources:** [Configuration reference](https://learn.chatgpt.com/docs/enterprise/managed-configuration) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/agent-security) · [Supporting documentation](https://learn.chatgpt.com/docs/environments/cloud-environments)

---

### 2.5 Admit trusted MCP servers, plugins and marketplaces

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, SI-4 |

#### Description

Restrict MCP identities and local plugin sources using requirements. Review plugin skills, hooks and executable code as well as connected apps. A local marketplace rule does not configure bundled/remote installs or web and mobile plugins.

#### Rationale

**Why This Matters:**

- A plugin can execute local commands or redirect data through MCP.
- A server name or executable path alone does not pin its arguments, environment or remote ownership.

**Attack Prevented:** Malicious plugin/MCP installation and tool-chain substitution.

#### ClickOps Implementation

1. In **Agent Security > Global > Requirements**, allow only reviewed MCP server names and identities, or use an empty mcp_servers table to disable local MCP. Pin structured executable/argument identities when available; string command identity checks only the executable.
2. In the supported local policy, disable plugin features where unused and admit only reviewed marketplace Git/local/host sources. Even the curated openai/plugins source must be explicitly admitted when an allowlist is present.
3. Before trusting a repository, review its .codex/config.toml, nested config, hooks, rules, skills and executable MCP startup configuration; re-review changes pulled into an already trusted project. Mark unreviewed projects untrusted so project .codex layers are skipped. User/system hooks and configuration still load.
4. In **Admin Console > Plugins**, separately review workspace installation, app actions, publisher/upload/share permissions and source-side access. Maintain a review and revocation owner.

#### Code Implementation

{% include pack-code.html vendor="chatgpt-work-codex" section="2.5" %}

#### Validation & Testing

Attempt a disallowed server identity, changed arguments and an unapproved marketplace in a disposable client. Review codex plugin list --json without running a plugin; its inventory is not proof of approved effective permissions.

**Sources:** [Configuration reference](https://learn.chatgpt.com/docs/enterprise/managed-configuration) · [Config trust](https://learn.chatgpt.com/docs/config-file/config-basic) · [Plugin controls](https://learn.chatgpt.com/docs/enterprise/apps-and-connectors)

---

### 2.6 Treat managed hooks as conditional, fail-open telemetry

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, SI-4 |

#### Description

Use supported admin MCP hooks as additional telemetry and explicit deny checks. For Work with local access and dots, supported Global hooks run on the cloud orchestrator only when managed policy and the capability are enabled.

#### Rationale

**Why This Matters:**

- Cloud orchestration does not run local, plugin or command hooks even when tools execute locally.
- PreToolUse timeout, transport error or malformed output can fail open; hooks are not a complete audit stream.

**Attack Prevented:** Reliance on bypassable hook-only enforcement or missing runtime telemetry.

#### ClickOps Implementation

1. In **Agent Security > Global > Requirements**, configure only documented MCP hook events and authenticated callback endpoints. Keep callback credentials out of repositories.
2. For cloud-coordinated work use supported managed hooks; do not deploy local command/plugin hooks expecting cloud execution. Review mcp_tool coverage and unsupported hosted search, lifecycle and environment events.
3. Test a successful callback, explicit denial, timeout and malformed output. Retain independent enforceable app/network restrictions and Compliance exports.

**Automation:** Native managed hook TOML is documented; a reusable callback identity and event set depend on the deployment. The existing Dots 4.3 emitter illustrates that exact conditional surface. Current policy API/provider contract remains unverified.

#### Validation & Testing

Record which events arrive for each runtime and how each failure behaves. Do not pass a rollout whose required deny policy depends on an observed fail-open condition.

**Sources:** [Configuration reference](https://learn.chatgpt.com/docs/enterprise/agent-security) · [Supporting documentation](https://learn.chatgpt.com/docs/hooks)

---

### 2.7 Restrict Slack, Linear and GitHub task triggers

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, SI-4 |

#### Description

Review each integration’s actor, repository/environment selection, input audience and resulting writes. Current Slack delegates through @ChatGPT; legacy @Codex Slack guidance does not describe the current flow.

#### Rationale

**Why This Matters:**

- Issue text and channel threads are untrusted task input that can influence repository work.
- Automatic assignment and review triggers can execute without a new human prompt; channel replies have a broader audience than private approval cards.

**Attack Prevented:** Untrusted integration content starting work with the wrong identity, environment or output audience.

#### ClickOps Implementation

1. For Slack use **Admin Console** deployment controls described in common 5.4. Enable Cloud delegation only with reviewed, published workspace-shared environments. Where Codex Cloud RBAC applies, both the deployment service account and requester need access. Review environment-owned values and prepared files before sharing.
2. Name the repository/environment in the request, review the private approval and inspect the separate requester-owned task. A channel reply does not grant underlying task access; it does disclose its own content to channel members. Slack Connect channels are unsupported. Cancel the delegated task separately when available.
3. For Linear review **Codex settings > connectors > Codex for Linear**, Enterprise cloud-chat eligibility and the **Codex for Linear** workspace connector. Audit Linear **Settings > Your teams > team > Triage > Triage rules > Delegate > Codex**. Automatic triage runs as the issue creator; contextual environment selection can fall back to the most recently used environment. Review the repo map’s first/default repository.
4. For GitHub open **Codex settings > Code review**, choose the connected repository and review **Automatic review**, **Personal preferences**, review triggers and Security Review research-preview eligibility. GitHub push/admin rights govern repository setup. Treat AGENTS.md as guidance; @codex fix and non-review mentions can start a legacy cloud task with write capabilities. Preserve normal PR approvals and branch protections.
5. During containment disable the relevant trigger/install and source access, then stop already-running tasks and review resulting comments, commits and retained environment files. Disconnecting one integration is not evidence that its existing work or copied data was removed.

**Automation:** The fetched integration pages document configuration and triggers but do not provide one common administration API or verified webhook-signature/replay contract for these vendor-managed integrations. Use source-system app controls and the documented UI; native GitHub Action workflows are a separate reviewed execution route. No invented scope strings or automatic-revocation script is supplied.

#### Validation & Testing

In disposable integrations, verify the triggering identity, selected repository/environment, denied access and reply audience. Exercise automatic Linear triage and GitHub review/fix separately; confirm cancellation and source revocation do not leave an unchecked running task.

**Sources:** [Slack](https://learn.chatgpt.com/docs/third-party/slack) · [Linear](https://learn.chatgpt.com/docs/third-party/linear) · [GitHub](https://learn.chatgpt.com/docs/third-party/github)

---

## 3. Cloud environments, state and evidence

### 3.1 Publish minimal Codex Cloud environments and scope secrets

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, SI-4 |

#### Description

Treat the published environment filesystem, setup scripts, repository connector, environment visibility and secrets as separate access boundaries. Review current Cloud and still-supported Legacy workflows separately.

#### Rationale

**Why This Matters:**

- Publishing a prepared filesystem can expose credentials or artifacts to future tasks.
- Network-secret allowed destinations can expand a restricted internet allowlist.

**Attack Prevented:** Repository overreach, persistent secret exposure and cloud egress expansion.

#### ClickOps Implementation

1. In **Settings > Codex Cloud > Environments**, restrict who can use the environment and who can manage workspace environments. Review the source system’s repository installation and each user’s access.
2. Review setup scripts and the prepared filesystem before Publish. Remove credentials and sensitive artifacts. Prefer narrowly targeted network secrets: they use a proxy placeholder over HTTPS/443; ordinary environment variables and personal values have different behavior.
3. Choose restricted internet destinations and review package-manager presets, additional domains, network-secret targets and VPNs. Republish after changes; existing tasks retain their saved state and are not automatically remediated.

**Automation:** Environment setup/native configuration is documented, but a current public admin API/provider contract for every environment security setting was not verified. Apply in the documented console; do not confuse the API Platform project environment with Codex Cloud.

#### Validation & Testing

Start a new disposable task after publication and compare with an existing task. Test repository denial, allowed secret destination and denied destination; public-network off is not proof of VPN isolation.

**Sources:** [Configuration reference](https://learn.chatgpt.com/docs/environments/cloud-environments) · [Supporting documentation](https://learn.chatgpt.com/docs/environments/cloud-environment) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/agent-security)

---

### 3.2 Inventory local state, cloud snapshots and every retained copy

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, SI-4 |

#### Description

Apply retention and residency to each supported content category and runtime. Local execution can still transmit excerpts, screenshots and tool results to OpenAI. Local auth, history, session state, worktrees and security scan artifacts also require device access and backup controls.

#### Rationale

**Why This Matters:**

- Disconnecting a computer or source does not purge saved context, files or browser cookies.
- Conversation deletion, cloud snapshots, Library files, projects and exported evidence have different lifecycles.

**Attack Prevented:** Residual sensitive-data exposure and incorrect residency or erasure claims.

#### ClickOps Implementation

1. Review **Workspace settings** data controls and the eligible residency/EKM arrangement with the account team. Work and local computer access do not provide strict ZDR; Work does not support UAE inference residency.
2. Review **Admin Console > Permissions > Work Cloud / Allow local computer access** and each member’s computer connections. enforce_residency in any cloud policy disables local computer access for Work and dots; it does not itself configure residency or disable those products.
3. Document cleanup in each location: client CODEX_HOME and backups, worktrees/files, ChatGPT conversations, Space/Library/projects, cloud browser sessions and snapshots, connected storage and Compliance copies. Preserve legal evidence before irreversible removal.

**Automation:** Supported native storage/configuration paths and console controls are documented; no universal delete-every-copy operation is documented. Inventory and verify each runtime and downstream storage owner.

#### Validation & Testing

Use disposable data to confirm each copy’s access and deletion boundary. Record unsupported retention/region categories and resolve them before regulated use. Key rotation alone is not deletion or revocation.

**Sources:** [Configuration reference](https://learn.chatgpt.com/docs/enterprise/chatgpt-work-cloud-security) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/chatgpt-work-local-security) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/cloud-local-access) · [Supporting documentation](https://learn.chatgpt.com/docs/config-file/config-advanced)

---

### 3.3 Collect minimal telemetry and verify compliance coverage

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, SI-4 |

#### Description

Keep prompt, response and automatic review content out of local OTel unless explicitly required. Correlate supported local execution with ChatGPT Compliance records and receiving-service evidence; no one stream is a complete record of every action.

#### Rationale

**Why This Matters:**

- Telemetry can become a second sensitive-data store.
- Cloud orchestration is outside a local OTel collector and a requested tool call does not prove an external change.

**Attack Prevented:** Sensitive telemetry leakage and incomplete incident reconstruction.

#### ClickOps Implementation

1. For supported Codex 0.166.0+, deploy managed **Requirements > [otel]** settings to an approved collector and minimize tool-result content. Each log/trace/metrics exporter and its credentials needs independent review.
2. Check the bundled client build: macOS desktop 26.1027.30824 with CLI 0.166.0-alpha.5.1 cannot enforce OTel requirements. Do not claim the snippet is effective on that build.
3. In **Admin Console > Credentials > Admin keys**, grant only needed supported ChatGPT log permissions and export before the 30-day platform window expires. Work records include conversation_message and codex_log; API Platform organization audit logs are separate.

#### Code Implementation

{% include pack-code.html vendor="chatgpt-work-codex" section="3.3" %}

#### Validation & Testing

Send harmless identifiable test content and verify it is redacted at the collector. Trace an approved action across the actual Compliance export and destination log; record missing tool results, approval details and links.

**Sources:** [Configuration reference](https://learn.chatgpt.com/docs/enterprise/managed-configuration) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/compliance-api) · [Supporting documentation](https://learn.chatgpt.com/docs/enterprise/governance)

---

### 3.4 Authenticate and verify self-hosted configuration delivery

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, SI-4 |

#### Description

For CLI/desktop deployments that do not sign in with ChatGPT, an administrator-owned device requirements file can select an HTTPS configuration server. Keep this separate from workspace-managed policy and model-provider credentials.

#### Rationale

**Why This Matters:**

- An attacker-selected policy endpoint can replace requirements and defaults.
- A cached bundle can remain active until a subsequent configuration load; a changed server response is not immediate enforcement.

**Attack Prevented:** Policy-source substitution and unauthenticated distribution of required settings.

#### ClickOps Implementation

1. Select the configuration server only through administrator-controlled system requirements or macOS managed preferences. There is no documented workspace-console replacement for this device bootstrap.
2. Use HTTPS and, where the bundle requires authentication, configure the documented OAuth authorization-code/PKCE settings. Verify the access token on your server before returning the bundle; keep credentials outside policy files.
3. Serve defaults and requirements in their separate native bundle arrays. On the desktop, complete required configuration-server login with codex login on the same computer and reopen the app; startup pauses if required settings cannot load.

#### Code Implementation

{% include pack-code.html vendor="chatgpt-work-codex" section="3.4" %}

#### Validation & Testing

On a disposable device inspect /debug-config for the expected bundle IDs and requirements source. Test denied/expired server authentication, initial load failure and cached refresh. Start a new session and follow restart prompts before relying on a changed requirement.

**Sources:** [Self-hosted configuration](https://learn.chatgpt.com/docs/enterprise/configuration-server) · [Managed configuration](https://learn.chatgpt.com/docs/enterprise/managed-configuration)

---

## 4. Security tooling and client lifecycle

### 4.1 Constrain Codex Security scans and their configuration

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, SI-4 |

#### Description

Review Codex Security Cloud plugin, local plugin, CLI and SDK as distinct execution paths. Local scans use the process’s permissions and do not pause for interactive approval; scan configuration can start MCP processes and choose model destinations.

#### Rationale

**Why This Matters:**

- Scanning an untrusted checkout with untrusted configuration can execute code with scanner privileges.
- Cloud personal GitHub connections are separate from workspace connections and local sandbox policy.

**Attack Prevented:** Scanner configuration injection, unintended repository access and finding-data leakage.

#### ClickOps Implementation

1. For the Cloud plugin, review the scanner’s personal GitHub connection and approved repositories; workspace connections do not replace it. For local/CLI/SDK, run under a restricted identity and review the exact target.
2. Keep trusted scanner configuration outside the checkout and select it explicitly. Review provider/auth destination, validation commands, output directory and optional patch/create-pr operations. API-key authentication needs its own approved API organization.
3. Run codex-security info --json and scan --dry-run for the approved repository/configuration before a real scan. A dry run validates local configuration; it does not test model/AWS access or scan security.

#### Code Implementation

{% include pack-code.html vendor="chatgpt-work-codex" section="4.1" %}

#### Validation & Testing

Use only the pack’s dry-run mode on disposable fixtures. Confirm the trusted config path lies outside the repository and outputs stay private; separately authorize any real scan, validation, patches or PR creation.

**Sources:** [Configuration reference](https://learn.chatgpt.com/docs/security/cli/reference) · [Supporting documentation](https://learn.chatgpt.com/docs/security/setup) · [Supporting documentation](https://learn.chatgpt.com/docs/security/sdk)

---

### 4.2 Test external prompt guardrails and choose failure behavior

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, SI-4 |

#### Description

Where enabled, configure Prisma AIRS as an external guardrail for supported ChatGPT-authenticated prompt text. It does not inspect model responses, tools/results, files or images, and does not cover API-key-authenticated work.

#### Rationale

**Why This Matters:**

- Saving a connection does not activate it.
- The separate On AIRS failure setting defaults to allowing prompts and can bypass a required scan during an outage.

**Attack Prevented:** Unscanned prompt transmission and overclaimed DLP coverage.

#### ClickOps Implementation

1. In **Admin Console > Policy & security > External guardrails > Prisma AIRS**, configure the approved endpoint, security profile and key. Review the third party’s regional processing and retention before sending content.
2. Choose the enforcement action and **On AIRS failure** independently. Select Block prompts where policy requires inspection, and plan recovery for an outage.
3. Use **Test**, verify allowed/blocked cases, then **Enable**. Review all authentication routes; ChatGPT-authenticated desktop/CLI/IDE/cloud coverage does not extend to API-key authentication.

**Automation:** Verified console configuration. No current public API/CLI/provider contract for this guardrail was identified in the fetched indexes, so automation is unverified rather than asserted unavailable.

#### Validation & Testing

Test a harmless blocked pattern and a simulated unreachable endpoint. Confirm the expected error and restore service through the supported admin recovery view if needed; record excluded content types.

**Sources:** [Configuration reference](https://learn.chatgpt.com/docs/enterprise/prisma-airs)

---

### 4.3 Keep desktop and companion clients on a managed update schedule

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, SI-4 |

#### Description

Keep built-in desktop updates enabled unless an established deployment process promptly delivers approved versions and security fixes. Older releases receive no separate security patches or extended support.

#### Rationale

**Why This Matters:**

- A stale embedded runtime can ignore a newer security requirement.
- Disabling in-app updates transfers patch delivery to the organization and does not stop external MDM/store updates.

**Attack Prevented:** Exploitation of outdated clients and unenforced version-specific requirements.

#### ClickOps Implementation

1. Inventory app and bundled CLI versions, the standalone CLI, IDE extension and operating systems separately. Pilot updates that introduce required policy capabilities.
2. If a managed desktop rollout requires disabling its updater, open **Managed configuration > policy > Targets**, assign a pilot, then **Raw TOML > requirements.toml** and set features.in_app_updates=false. Do not place it in config defaults.
3. After a full app restart verify **Settings > General > In-app updates > Managed** and verify your deployment platform can install a new version. A fetch failure may leave the updater enabled. Remove every applicable false requirement to restore normal updates.

**Automation:** Native features.in_app_updates requirement is verified. Do not deploy a false snippet merely to obtain a pack; the recommended default is timely updates, with an organization-specific deployment exception.

#### Validation & Testing

Verify installed and embedded versions and policy behavior after a complete restart. The updater requirement is for supported macOS/Windows desktop builds, not Linux distribution packages, mobile, CLI or IDE updates.

**Sources:** [Configuration reference](https://learn.chatgpt.com/docs/enterprise/manage-app-updates) · [Supporting documentation](https://learn.chatgpt.com/docs/linux/linux-app)

---

### 4.4 Verify native Windows isolation and platform support

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 4.1, 6.1 |
| NIST 800-53 | AC-6, CM-6, SI-4 |

#### Description

Prefer MXC on compatible Windows devices and constrain legacy fallback deliberately. Review Linux preview and WSL as separate runtimes with their own installation and filesystem boundaries.

#### Rationale

**Why This Matters:**

- The weaker unelevated fallback has weaker network isolation and no denied-read support.
- MXC supports host loopback and deny-read globs match at process start; later-created matches may remain readable.

**Attack Prevented:** Fallback to weaker isolation and assumptions of uniform cross-platform enforcement.

#### ClickOps Implementation

1. In managed requirements set features.prefer_mxc=true where approved and windows.allowed_sandbox_implementations=[elevated] to restrict legacy fallback. That legacy allowlist does not block MXC; windows.allow_mxc=false is a separate control.
2. On the documented Windows 11 builds/capabilities and Codex 0.162.0+, use the vendor’s one-command MXC sandbox probe with --include-managed-config and a disposable workspace. Explicit MXC selection fails when unsupported; prefer_mxc permits fallback.
3. Review the effective proxy allow_local_binding requirement, loopback exposure, child-process shutdown and per-process deny-read glob timing. On Linux preview, verify supported signed distro packages and update through the distribution repository; native desktop policies need separate support checks.

#### Code Implementation

{% include pack-code.html vendor="chatgpt-work-codex" section="4.4" %}

#### Validation & Testing

Inspect /status and /debug-config and test the actual native/WSL/Linux runtime with disposable denied files and destinations. A successful startup probe is not a complete isolation test.

**Sources:** [Configuration reference](https://learn.chatgpt.com/docs/windows/windows-sandbox) · [Supporting documentation](https://learn.chatgpt.com/docs/windows/wsl) · [Supporting documentation](https://learn.chatgpt.com/docs/linux/linux-app)

---

## 5. Automation and evidence limits

Native snippets are emitted to stdout for review; they do not deploy policy or establish effective enforcement. Merge TOML tables carefully, choose the correct requirements/default editor, and verify every runtime/version. Current Global policy API/Terraform workflows are documented, but their current public contract was not verified during this run; Local and Codex Cloud policy use the documented UI. The OpenAI API provider and organization audit API do not verify ChatGPT policy.

The code packs cover 10 controls with native configuration or read-only CLI checks. No credentials were read, clients installed or live scans run. The [source-first inventory](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/openai-source-coverage.md) records defaults, version limits, independent surfaces and unresolved contracts. Tenant behavior, entitlement, policy caching/propagation, effective MDM, sandbox isolation, output redaction and supported Compliance records need controlled tenant verification.

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-11-05 | 0.1.0 | ai-drafted | Initial source-first coverage for Work, Codex runtimes, Codex Security, device requirements, cloud state and integration boundaries; native snippets and read-only checks. No live validation. | Codex |

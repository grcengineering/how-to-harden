---
layout: guide
title: "Grok Build Hardening Guide"
vendor: "Grok Build"
slug: "grok-build"
platform: "SpaceXSI"
platform_slug: "spacexai"
product: "Grok Build"
tier: "1"
category: "AI/ML Platform"
description: "Harden Grok Build identity, native system policy, permissions, sandboxing, MCP and extension authority, local data lifecycle, and the separate hosted Build-mode privacy boundary"
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-05"
---

## Overview

This is a product guide within the [SpaceXSI platform](/guides/cursor/). Grok Build has its own local `grok` CLI, authentication, TOML policy and state. **Cursor team settings and API keys do not configure Grok Build.** The platform hub's placement does not imply shared policy enforcement. Grok Bot's hosted computers and Slack integrations belong in the [Grok Bot guide](/guides/grok-bot/).

[Grok Build](https://docs.x.ai/build/overview) runs as a terminal UI, headless process or Agent Client Protocol (ACP) integration. Its tools execute with access to the local machine. Sections 1–5 cover that client. **Grok.com/mobile Build mode is a separate hosted app-building surface**, with different retention and publishing behavior; section 6 covers its verified privacy controls and unresolved administration gaps. The vendor's [Grok FAQ](https://docs.x.ai/grok/faq#where-did-grok-studio-go--i-cant-access-grok-studio) says Grok Studio is unsupported and directs users to Build.

**How this guide was produced:** Source discovery on 2026-11-05 preceded control selection. The [source ledger](/research/grok-build-source-coverage.md) records candidates, all six automation surfaces, documentation conflicts and exclusions. No tenant, product installation, inference, login, integration or managed-policy deployment was exercised. **VERIFIED-LIVE = 0**; the guide remains AI-drafted.

### Intended Audience

- Endpoint and platform administrators managing developer workstations or CI runners
- Security teams reviewing local agent tools and extension supply chains
- Data owners approving hosted app-building and publishing

### How to Use This Guide

Apply **L1 (Crawl)** to establish identity, approval, extension and lifecycle controls. Add **L2 (Walk)** for restricted execution and sensitive data. The stricter options can break builds, package downloads, delegation and video generation; test them on an authorized nonproduction endpoint before rollout.

**Pack behavior:** Config packs print candidate TOML by default and never install files. Their `verify` mode parses an explicitly supplied file using Bun's TOML parser, checking only the listed fields. Exit **0** means those candidate fields matched, **1** means a mismatch, and **2** means an unmet precondition. A matching file does not establish ownership, effective configuration, license entitlement or runtime enforcement. Merge fragments as one TOML document; concatenating fragments with repeated tables is invalid. The CLI packs require `HTH_RUN_GROK_READS=1`, collect private local inventory and print **NOT ASSESSED**, rather than a compliance verdict. They never authenticate, update, execute a prompt, connect with MCP doctor or delete state.

For every local policy control, the shared [5.1 CLI inventory](#51-record-posture-and-complete-containment-and-offboarding) supplies the documented effective-discovery read. This complements each file checker; no native CLI setter for individual policy pins was verified.

### Scope and Control Planes

| Plane | Authority and boundary |
|-------|------------------------|
| Local client policy | Native system/user TOML, local repository configuration and process environment; controlled through managed endpoint deployment |
| Sign-in | Browser OIDC, device code, external token provider or API key; team constraints are native Build policy |
| Execution | Local tool permissions, sandbox, rules, hooks, MCP, plugins and agent processes; credentials reachable by these processes remain relevant |
| Hosted Build mode | grok.com/mobile account data controls and persistent app-building sessions; CLI requirements do not configure it |
| Other SpaceXSI products | API/Business accounts and Grok Bot have separate administration; no inherited Cursor policy is assumed |

**Automation census:** Config and the first-party CLI are documented. Terraform resources/data sources, Build policy REST/GraphQL routes, an administrative SDK and a stable SIEM export schema remain **unverified**, rather than verified absent. Eight of nine controls have packs across two verified surfaces; hosted Build administration is an explicit gap.

## Table of Contents

1. [Identity and Managed Policy](#1-identity-and-managed-policy)
2. [Approvals and Isolation](#2-approvals-and-isolation)
3. [Extension and Repository Authority](#3-extension-and-repository-authority)
4. [Destinations and Data](#4-destinations-and-data)
5. [Audit, Containment and Lifecycle](#5-audit-containment-and-lifecycle)
6. [Hosted Build Mode](#6-hosted-build-mode)
7. [Compliance Quick Reference](#7-compliance-quick-reference)
8. [Appendices](#8-appendices)

## 1. Identity and Managed Policy

### 1.1 Pin Native System Policy and Approved Team Identity

**Profile Level:** L1 (Crawl)

| Framework | Alignment |
|-----------|-----------|
| CIS Controls v8 | Account Management; Access Control Management |
| NIST SP 800-53 | Identification and Authentication; Access Enforcement |

#### Description

Deploy root-owned `/etc/grok/requirements.toml` and pin approved team identity with `[grok_com_config] force_login_team_uuid` and `disable_api_key_auth`. The [enterprise reference](https://docs.x.ai/build/enterprise#restricting-login-methods) documents the native team check, including reuse and refresh of cached sessions. A bare first-party API key cannot represent team membership. BYOK destinations remain a separate authorization boundary.

#### Rationale

**Why This Matters:**

- A user preference can be edited by the person running the agent; an organization needs a protected policy source.
- A personal or wrong-team sign-in can put work outside the intended account and retention agreement.

**Attack Prevented:** Evading the approved first-party sign-in path with a personal team or leftover API key.

#### Prerequisites

A managed host, root-controlled deployment and the approved team's actual UUID. The vendor places enterprise pinning in its enterprise deployment documentation; confirm entitlement for the deployed version. Windows installation is documented, but an equivalent Windows system pin path was not verified here. Do not translate `/etc/grok` into an invented registry policy.

#### ClickOps Implementation

There is no verified Build web-console path for these local pins. Use the documented [MDM/configuration-management deployment path](https://docs.x.ai/build/enterprise#system-level-policy-for-mdm-and-managed-deployments): distribute reviewed native TOML to `/etc/grok/requirements.toml`, with ownership and parent-directory permissions that users cannot change. The file's priority exceeds system managed config, user managed config, user config and user requirements. Native requirements also take precedence over the limited Claude managed-settings compatibility layer.

For a corporate identity provider, review `[auth.oidc] issuer` and `client_id`, or the `[auth] auth_provider_command` executable. Protect that executable and token output as credentials; its background-refresh contract must return promptly without an interactive prompt. Do not assume a Cursor SSO setting governs this login.

#### Code Implementation

Set `HTH_ALLOWED_TEAM_UUID` to the approved UUID. Render the candidate; use `HTH_CANDIDATE_POLICY` with `verify` to assess the chosen file. The pack emits one allowed team, although the vendor also supports a list; an empty list rejects every login.

{% include pack-code.html vendor="grok-build" section="1.1" %}

#### Validation & Testing

Review `grok inspect` from the intended directory and process environment to confirm the loaded login policy. On an authorized test host, verify that approved login works, wrong-team login and cached credentials are rejected, and a first-party key cannot bypass the policy. Separately inspect BYOK endpoint IAM and model configuration. The pack does not perform any of those live actions.

#### Compliance Mappings

| Framework | Control intent |
|-----------|----------------|
| CIS Controls v8 | Managed accounts and authorized access |
| NIST SP 800-53 | IA-2; AC-3 |
| SOC 2 | CC6.1; CC6.2 |

## 2. Approvals and Isolation

### 2.1 Lock Bypass and Bound Interactive and Headless Approvals

**Profile Level:** L1 (Crawl)

| Framework | Alignment |
|-----------|-----------|
| CIS Controls v8 | Access Control Management |
| NIST SP 800-53 | Least Privilege |

#### Description

Use Ask mode and native root-owned `[ui] disable_bypass_permissions_mode = true`; disable remembered approvals and inheritance of main-checkout approvals into worktrees. Grok's [permissions](https://docs.x.ai/build/features/permissions) separate tool approval from sandbox enforcement. Headless `dontAsk` denies actions without an explicit allow; `acceptEdits` automatically permits edits and therefore has different authority.

#### Rationale

**Why This Matters:**

- Bypass mode permits tools without the normal approval checkpoint.
- Saved broad approvals can persist into a later task with a different trust level.

**Attack Prevented:** A malicious repository instruction obtaining unintended tool execution through bypass or previously remembered approval.

#### ClickOps Implementation

In an existing authorized TUI session, inspect the current permission mode and loaded rules before approving tools. For fleet enforcement use the [native system lock](https://docs.x.ai/build/enterprise#security-controls). **The lock is honored only from root-owned sources; placing it in user-writable `~/.grok/requirements.toml` does not enforce it.** Claude's `disableBypassPermissionsMode` setting does not disable Grok's always-approve mode.

Use narrow task-specific rules; deny takes precedence over ask and allow. Avoid catch-all approvals and blanket shell-tool allowances. For unattended work, use `--permission-mode dontAsk`, exact reviewed tool permissions, `--max-turns` and an active sandbox in a dedicated runner. Review ACP clients' requested tool modes with the same policy. The [headless reference](https://docs.x.ai/build/cli/headless-scripting) documents that these runs still create local sessions.

#### Code Implementation

The candidate pins Ask and turns off remembered approval options. The [October 21 release note](https://x.ai/changelog/build) documents `worktree_inherits_main_approvals = false`; require a version that supports it. Pinning an interactive default is not a substitute for verifying headless invocation arguments and existing saved state.

{% include pack-code.html vendor="grok-build" section="2.1" %}

#### Validation & Testing

On an authorized endpoint, try bypass flags and TUI mode changes and confirm rejection. Review effective permission rules and previously saved approvals. Use harmless fixtures to test an allowed read, an unallowed headless action, a deny rule and a new worktree. Verify the behavior across CLI, TUI and ACP; parsing TOML does not prove the client enforces the lock.

#### Compliance Mappings

| Framework | Control intent |
|-----------|----------------|
| CIS Controls v8 | Limit unnecessary access |
| NIST SP 800-53 | AC-6; CM-6 |
| SOC 2 | CC6.1 |

### 2.2 Enforce a Sandbox and Test Its Platform-Specific Limits

**Profile Level:** L2 (Walk)

| Framework | Alignment |
|-----------|-----------|
| CIS Controls v8 | Secure Configuration; Data Protection |
| NIST SP 800-53 | Boundary Protection |

#### Description

Pin a sandbox profile; the default is off. The [sandbox reference](https://docs.x.ai/build/features/sandbox) distinguishes strict/read-only isolation from workspace mode, which still reads broadly and allows child networking. Permissions decide whether a tool runs; the sandbox restricts an approved action. Neither is a complete boundary for every credential or network path.

#### Rationale

**Why This Matters:**

- Local tools can read files and inherit credentials outside the repository unless constrained.
- The documented protection varies by operating system and by child-process versus in-process networking.

**Attack Prevented:** An approved tool accessing unrelated host files or making unauthorized network requests within the sandbox's actual enforcement scope.

#### ClickOps Implementation

There is no verified native web GUI for the local sandbox. Use [managed native policy](https://docs.x.ai/build/enterprise#sandbox), then inspect the effective profile. For untrusted code, begin with built-in `strict`; keep `auto_allow_bash` false. A separate low-privilege runner is appropriate when the host holds valuable unrelated credentials.

**Documented limits:** Child-network blocking in strict/read-only is Linux-only and a no-op on macOS. Model API calls and in-process web tools are outside this network restriction. Built-in profiles leave `~/.grok` writable and do not permanently protect paths such as `~/.ssh`. Add kernel-enforced custom deny paths where needed; Linux read-deny requires bubblewrap. Use external endpoint/network policy for remaining paths.

#### Code Implementation

The `policy` output pins built-in strict. The optional `profile` output illustrates a custom deny profile in native `sandbox.toml`; it is **not activated** by the policy output. The [settings reference](https://docs.x.ai/build/settings/reference#sandboxtoml-custom-profiles) documents user and project profile files. Their definition integrity and precedence must be established before replacing a built-in pin with a custom name; pinning a name alone does not prove its contents are protected.

{% include pack-code.html vendor="grok-build" section="2.2" %}

#### Validation & Testing

On each target OS, test harmless reads/writes inside and outside the permitted tree and reads of a synthetic denied secret path. Test child and in-process egress separately. Confirm sandbox startup actually succeeds and Linux prerequisites exist. Inspect inherited environment and working directory; deny-file rules do not remove secrets already in process environment. The pack checks candidate fields only.

#### Compliance Mappings

| Framework | Control intent |
|-----------|----------------|
| CIS Controls v8 | Restrict sensitive data and secure configuration |
| NIST SP 800-53 | AC-6; SC-7; CM-6 |
| SOC 2 | CC6.6 |

## 3. Extension and Repository Authority

### 3.1 Review MCP Origins and Restrict Server Authority

**Profile Level:** L1 (Crawl)

| Framework | Alignment |
|-----------|-----------|
| CIS Controls v8 | Software Inventory; Access Control Management |
| NIST SP 800-53 | Least Privilege; External System Services |

#### Description

Inventory effective MCP definitions and permit only reviewed servers, launch commands and credential scopes. [MCP discovery](https://docs.x.ai/build/features/mcp-servers) includes user/project native config and compatibility sources. A project definition with the same name replaces the user definition, rather than merging it. A familiar name therefore does not establish the actual executable or remote endpoint.

#### Rationale

**Why This Matters:**

- Stdio servers execute local code; remote servers receive tool inputs and may act under a user's connected account.
- A repository or inherited compatibility config can substitute a trusted-looking server name.

**Attack Prevented:** Tool execution or data disclosure through an unreviewed MCP server, substituted endpoint or excessive connected-account grant.

#### ClickOps Implementation

In an authorized TUI use **`/mcps` → extensions modal** to review loaded servers and their state. Do not use OAuth sign-in or refresh as an inventory operation. Review `grok inspect` origins, native `.grok/config.toml` in parent directories, user settings and `.cursor/mcp.json`/Claude compatibility sources. Disable unused compatibility scanners and known unapproved native servers in protected requirements.

For retained servers, review pinned executable/package versions, endpoint ownership, arguments, headers and requested scopes. Prefer `bearer_token_env_var` or environment references over literal tokens in repository config; these references still expose the token to the executing server. OAuth state in `~/.grok/mcp_credentials.json` requires endpoint protection and separate provider-side revocation.

#### Code Implementation

Supply a real `HTH_MCP_SERVER_NAME` for the disabled-server candidate. It disables one known name; **it is not a universal MCP allowlist**. The CLI inventory performs documented `inspect --json` and `mcp list --json` reads, with no server connectivity test. Review its private files locally; no stable output schema was assumed.

{% include pack-code.html vendor="grok-build" section="3.1" %}

#### Validation & Testing

Re-run inventory from the exact repository and launch environment. Compare resolved command/URL, source and enabled state to the approved inventory. On an authorized test host, attempt a known-disabled server and confirm rejection; inspect other server names separately. Revoke retired OAuth grants at the provider and confirm continued access fails; removing a local definition does not establish revocation.

#### Compliance Mappings

| Framework | Control intent |
|-----------|----------------|
| CIS Controls v8 | Authorized software and limited external access |
| NIST SP 800-53 | CM-7; AC-6; SA-9 |
| SOC 2 | CC6.1; CC9.2 |

### 3.2 Review Rules, Skills, Plugins and Hooks Before Granting Trust

**Profile Level:** L1 (Crawl)

| Framework | Alignment |
|-----------|-----------|
| CIS Controls v8 | Software Inventory; Secure Configuration |
| NIST SP 800-53 | Configuration Change Control |

#### Description

Review discovered instructions and executable extensions as repository inputs with distinct authority. [Rules discovery](https://docs.x.ai/build/features/project-rules) walks from the repository root to the working directory and reads native and compatible instruction files. [Plugins](https://docs.x.ai/build/features/skills-plugins-marketplaces) can add skills, agents, hooks, MCP and language servers. Skill `allowed-tools` metadata does **not** grant or restrict tools.

#### Rationale

**Why This Matters:**

- Instructions can change agent behavior, while hooks and server commands can execute code with local authority.
- Compatibility scanners default on, expanding the inputs beyond `.grok` files.

**Attack Prevented:** A repository, plugin update or inherited configuration silently gaining instruction, executable-hook or tool-server authority.

#### ClickOps Implementation

Before granting trust, inspect **`/skills`**, **`/plugins`**, **`/hooks`** and **`/mcps`** in the extensions modal and compare them to `grok inspect`. Review `.grok`, `.agents`, explicit paths, enabled plugins and marketplace provenance, not only compatibility directories. Review native `AGENTS.md` and nested rules even when Cursor/Claude scanners are disabled. Reassess changes to extension code and paths on update.

The [hooks reference](https://docs.x.ai/build/features/hooks) stores project trust in `~/.grok/trusted_folders.toml`; `/hooks-trust` or `--trust` grants project hook/MCP/LSP trust. Do not pass `--trust` to an unreviewed checkout. The [October 19 release note](https://x.ai/changelog/build) says untrusted folders run only managed organization hooks, but headless treats user hooks as trusted. Review that user-level hook set in CI too.

**Hook limit:** `PreToolUse` is the blocking event. Explicit deny output or exit 2 blocks; timeouts, crashes and malformed output fail open. Audit hook health, use argv-list command hooks where supported, and retain native permissions/sandbox controls. Passive post-event logging cannot prevent an action that already occurred; model instructions and personas are not access controls.

#### Code Implementation

The candidate disables Cursor/Claude scanners for skills, rules, agents, MCP and hooks. It does not disable native `.grok`/`.agents` discovery or validate installed plugins; use the inventory in 3.1 and 5.1 and remove/disable unapproved native extensions through the documented CLI/TUI.

{% include pack-code.html vendor="grok-build" section="3.2" %}

#### Validation & Testing

Reconcile every discovered origin against the approved inventory. In a disposable test checkout, verify untrusted project executables do not start. Exercise explicit hook deny and hook failure separately; failure must not be mistaken for denial. Confirm headless user hooks and newly installed plugins are included in review. Do not inject real secrets into hook fixtures or post session bodies to an unapproved HTTP hook endpoint.

#### Compliance Mappings

| Framework | Control intent |
|-----------|----------------|
| CIS Controls v8 | Authorized software and configuration |
| NIST SP 800-53 | CM-3; CM-7; SI-4 |
| SOC 2 | CC8.1 |

## 4. Destinations and Data

### 4.1 Limit Model Destinations, Tools and Unattended Execution

**Profile Level:** L2 (Walk)

| Framework | Alignment |
|-----------|-----------|
| CIS Controls v8 | Data Protection; Network Infrastructure Management |
| NIST SP 800-53 | Information Flow Enforcement |

#### Description

Restrict approved model IDs and review their actual destination and credentials. Disable unnecessary WebFetch, `.envrc` loading, open-ended goals and delegation for sensitive work. The [settings reference](https://docs.x.ai/build/settings/reference) documents these native settings. A hidden model remains usable via `-m`; use `allowed_models`/`disabled_models` when access must be restricted, and protect approved model definitions as well as their names.

#### Rationale

**Why This Matters:**

- A custom model URL, web tool, MCP server or shell process can create a distinct data egress path.
- Inherited environment variables and background work can outlive the operator's immediate attention.

**Attack Prevented:** Routing repository data to an unapproved inference provider or continuing an unintended privileged task.

#### ClickOps Implementation

There is no verified central GUI path for this native runtime policy. Review **`/model`** and effective configuration, then deploy protected requirements. Inspect per-model `base_url`, `env_key`, inline keys and extra headers, plus model-list and proxy environment variables. Prefer secret-manager supplied environment credentials over literal config keys. A model-ID allowlist alone does not attest the URL behind that ID; pin approved definitions and enforce endpoint egress where needed.

Disable tools/delegation you do not need. [Subagents](https://docs.x.ai/build/features/subagents) are enabled by default, and custom agent/persona definitions need review. [Background Tasks](https://docs.x.ai/build/features/background-tasks) include commands, monitors and recurring `/loop` prompts; use **`Ctrl+G` → tasks pane** or **`/tasks`** to inspect and stop them. A worktree isolates a checkout, not account credentials or all execution authority.

#### Code Implementation

Supply `HTH_ALLOWED_MODEL_IDS_JSON` as a nonempty JSON array of exact approved IDs. The candidate disables unnecessary features, while reporting that endpoint identity and other egress remain unproven. If WebFetch is needed, separately configure its documented domain allowlist/proxy; those govern that tool, not model requests, server-side search, MCP or arbitrary shell networking.

{% include pack-code.html vendor="grok-build" section="4.1" %}

#### Validation & Testing

Inspect allowed model IDs **and** their effective URLs/credentials under the actual process environment. Test blocked model selection and each relevant network path using harmless fixtures. Review task/delegation state and launcher flags such as `--max-turns` and `--no-subagents`. Disabling future goals or subagents does not establish that existing tasks have stopped.

#### Compliance Mappings

| Framework | Control intent |
|-----------|----------------|
| CIS Controls v8 | Limit sensitive data destinations |
| NIST SP 800-53 | AC-4; SC-7; AC-6 |
| SOC 2 | CC6.6 |

### 4.2 Control Local Persistence, Telemetry and ZDR Output

**Profile Level:** L2 (Walk)

| Framework | Alignment |
|-----------|-----------|
| CIS Controls v8 | Data Protection |
| NIST SP 800-53 | Information Retention |

#### Description

Select CLI privacy settings, constrain memory and telemetry, and account for local records and user-supplied media storage. The [security FAQ](https://docs.x.ai/developers/faq/security#grok-build-cli) documents **`/privacy`** and **`/settings`** for disabling code-data retention even without ZDR. Team ZDR does not erase local session history or impose retention on another provider or storage bucket.

#### Rationale

**Why This Matters:**

- Logs, sessions, exported transcripts and memory can retain source material after a task finishes.
- A retention promise at inference does not establish the same behavior for every local artifact or connector.

**Attack Prevented:** Unintended reuse or disclosure of sensitive source data through telemetry, memory, transcripts or media-output storage.

#### ClickOps Implementation

In an authorized CLI session open **`/privacy`** or **`/settings`**, disable code-data retention/product-improvement consent as required and record the actual choices. If ZDR is required, verify the intended team's retention state; the [Build enterprise lifecycle](https://docs.x.ai/build/enterprise#privacy--data-lifecycle) documents team-scoped inference behavior, not a local erasure switch. The separate [Grok API retention control](/guides/grok-api/#21-choose-and-verify-team-zero-data-retention) documents the Console team-setting path and destructive preparation requirements. Confirm that the selected Build login/key belongs to that team before relying on it; do not transfer API/Business/consumer guarantees between accounts.

Keep cross-session memory off where unnecessary and minimize diagnostic logging. The [October 20 release note](https://x.ai/changelog/build) says any value of `DISABLE_TELEMETRY` or `DISABLE_ERROR_REPORTING`, including `0`/`false`, disables that channel; use an explicit managed launcher and test the chosen version. `GROK_CRASH_HANDLER` controls local crash reports, a separate artifact. Gitignore filtering reduces read/search exposure but is not a security boundary for shell tools.

#### Code Implementation

`policy` emits memory/tool settings; `environment` emits optional launcher assignments without evaluating them. Neither activates team ZDR or deletes existing data. For required video output under ZDR, the [native storage reference](https://docs.x.ai/build/settings/zdr-video-storage) requires an operator-owned S3-compatible bucket, scoped upload/playback credentials and bounded presigned URLs; restart the CLI after configuration. Review bucket IAM, lifecycle and URL exposure separately. Do not disable privacy to regain an unavailable tool without data-owner approval.

{% include pack-code.html vendor="grok-build" section="4.2" %}

#### Validation & Testing

Confirm actual privacy consent, team retention state and effective process environment. Inspect local session/log/export locations and the deployed memory setting; record a retention and deletion procedure. If media tools are allowed, test with synthetic data and verify the resulting bucket/object/URL lifecycle and restart behavior. The supplied file checker cannot prove backend retention or telemetry suppression.

#### Compliance Mappings

| Framework | Control intent |
|-----------|----------------|
| CIS Controls v8 | Data retention and protection |
| NIST SP 800-53 | SI-12; MP-6; SC-28 |
| SOC 2 | CC6.7 |

## 5. Audit, Containment and Lifecycle

### 5.1 Record Posture and Complete Containment and Offboarding

**Profile Level:** L1 (Crawl)

| Framework | Alignment |
|-----------|-----------|
| CIS Controls v8 | Audit Log Management; Account Management |
| NIST SP 800-53 | Audit Review; Incident Handling |

#### Description

Record the installed client and effective discovery state, then manage credentials, running tasks and retained artifacts separately. The [CLI reference](https://docs.x.ai/build/cli/reference) documents local inspection and lifecycle commands. Native logs and transcripts are useful evidence; a stable Build security-event export schema, central immutable audit trail and administrative event coverage were not verified.

#### Rationale

**Why This Matters:**

- Stopping a visible conversation does not establish that every task, credential or artifact is gone.
- An inventory result without provenance and a client version is difficult to reproduce after an incident.

**Attack Prevented:** Continued local or connected-account access after a user leaves, and loss of evidence needed to investigate an agent action.

#### ClickOps Implementation

Use **`Ctrl+\\` / `/dashboard` → agent row → `Ctrl+X` twice** to stop/close a session as documented in the [Agent Dashboard](https://docs.x.ai/build/features/dashboard); inspect **`Ctrl+G` / `/tasks`** for background commands, monitors and loops. Preserve necessary evidence before cleanup. Treat session bodies and debug logs as sensitive; minimize collection and restrict destinations.

For offboarding, revoke identity and provider credentials, run the documented local logout when appropriate, remove MCP grants at their providers and account for API keys in secret stores or runner environments. Use native session deletion and memory-clear commands only after retention review. [Sessions](https://docs.x.ai/build/features/sessions) retain prompts, responses, tool calls and file snapshots; compaction/closing is not erasure. [Worktrees](https://docs.x.ai/build/features/worktrees) persist after a session ends or is deleted and need separate review/removal. Track exported transcripts and backups too. Update clients through the approved distribution channel; disabling update checks for reproducible CI is not a patching program.

#### Code Implementation

The inventory collects version, inspect, plugin, session and worktree listings into a new private directory. It does not export conversation bodies or run update/login/logout/deletion. Review output privately: CLI inventory JSON is not interpreted as an enforcement schema, and local files are not a tamper-resistant audit service.

{% include pack-code.html vendor="grok-build" section="5.1" %}

#### Validation & Testing

Exercise an offboarding runbook on an authorized test account: prove tasks are stopped, revoked credentials fail, memory/session/worktree/export copies follow retention policy and managed policy still loads. Verify that the installed client supports selected controls. Do not treat local logout as provider token/key revocation or deleting a session as removal of its worktree.

#### Compliance Mappings

| Framework | Control intent |
|-----------|----------------|
| CIS Controls v8 | Audit evidence and account revocation |
| NIST SP 800-53 | AU-6; IR-4; AC-2; SI-2 |
| SOC 2 | CC7.2; CC7.4 |

## 6. Hosted Build Mode

### 6.1 Review Hosted Build Data Controls and Publishing Authority

**Profile Level:** L1 (Crawl)

| Framework | Alignment |
|-----------|-----------|
| CIS Controls v8 | Data Protection |
| NIST SP 800-53 | Information Flow Enforcement |

#### Description

Treat grok.com/mobile Build as a persistent app-development and publishing environment. The [security FAQ](https://docs.x.ai/developers/faq/security#grokcom-build-mode) states that Build chats/sessions are retained for functionality, Private Chats are unavailable, and the improvement toggle can include data from created apps. Native CLI policy, local sandboxing and CLI ZDR claims do not establish hosted Build isolation or retention.

#### Rationale

**Why This Matters:**

- A hosted build can contain application data beyond the initial conversation.
- Disabling model improvement is a different decision from disabling retention or restricting who can use a published app.

**Attack Prevented:** Submitting sensitive app data under an assumed Private Chat/CLI privacy boundary, or publishing without understanding the app's actual access model.

#### ClickOps Implementation

For consumer accounts, use the [documented data controls](https://x.ai/legal/faq#how-do-i-select-whether-my-content-is-used-for-model-training): on web open **Settings → Data → Improve the Model**; on mobile open **Settings → Data Controls → Improve the model** and deselect as required. Record the account/workspace and confirm the choice. This does not make hosted Build sessions private or ephemeral. Business/enterprise terms and workspace governance require their own review; do not assume a consumer toggle changes an enterprise agreement.

Before publishing or attaching sensitive information, obtain verified product-specific evidence for the app's audience, user authentication, secret storage, backend/network permissions, data retention and unpublish/delete behavior. Current fetched Build/Grok references and targeted native-domain searches did not establish those configuration paths. Keep deployments requiring these assurances pending that evidence; do not substitute CLI settings or invent hosted admin menus.

**Automation:** **Unverified** — no hosted Build publishing/secret/auth administration API, CLI, SDK, Terraform resource/data source or native policy schema was verified in the sources fetched on 2026-11-05. The local `grok` CLI packs do not administer hosted Build apps.

#### Validation & Testing

Confirm the actual data-control choice in the intended web/mobile account. With an authorized test app, independently verify audience access from an unintended account and inspect published code/data for secrets before release. Verify documented unpublish and deletion behavior with the vendor before relying on them. No hosted app or data-control setting was touched in this research pass.

#### Compliance Mappings

| Framework | Control intent |
|-----------|----------------|
| CIS Controls v8 | Approved sensitive-data use and access |
| NIST SP 800-53 | AC-4; AC-3; SI-12 |
| SOC 2 | CC6.1; CC6.7 |

## 7. Compliance Quick Reference

Mappings describe control intent, not a Grok Build benchmark or compliance certification.

| Theme | Controls | Representative NIST SP 800-53 controls |
|-------|----------|---------------------------------------|
| Managed identity and configuration | 1.1, 2.1 | IA-2, AC-3, CM-6 |
| Local execution and extension authority | 2.2, 3.1, 3.2, 4.1 | AC-6, SC-7, CM-3, CM-7 |
| Data handling and publishing | 4.2, 6.1 | SI-12, SC-28, AC-4 |
| Evidence, response and revocation | 5.1 | AU-6, IR-4, AC-2 |

## 8. Appendices

### Availability and Evidence Limits

| Area | Documented path | Limitation |
|------|-----------------|------------|
| Native enterprise policy | `/etc/grok/requirements.toml` | Entitlement/runtime untested; Windows system pin equivalent unverified |
| TUI/headless/ACP | Shared local client/config | Verify each launch environment and approval behavior |
| Sandbox | Native profiles and custom `sandbox.toml` | Off default; macOS child networking and in-process networking limits apply |
| MCP/extensions | Native config, CLI and TUI | Scanner disables do not disable all native discovery or revoke provider grants |
| CLI privacy | `/privacy`, `/settings`, team ZDR | Local records and other-provider/bucket retention remain separate |
| Hosted Build | Web/mobile data controls | Private Chats unavailable; publishing/secrets/auth administration unverified |
| Audit export | Local logs/session records | Native stable SIEM schema and immutable central export unverified |

### Current Documentation Conflicts

The enterprise network table still lists `code.grok.com` for remote sync and sharing, while the [October 9, 2026 release note](https://x.ai/changelog/build) explicitly removes `/share` and session sharing from the CLI. This guide follows the specific newer removal and supplies no sharing-control pack. Remaining remote synchronization behavior and any hosted sharing policy need current product verification; they are not treated as verified absence. Newer release notes also change hook trust and worktree approval inheritance; test the deployed version rather than relying on an older example.

### References

- [Grok Build enterprise deployment and policy](https://docs.x.ai/build/enterprise)
- [Settings overview and reference](https://docs.x.ai/build/settings)
- [CLI reference](https://docs.x.ai/build/cli/reference)
- [Build release notes](https://x.ai/changelog/build)
- [API security FAQ: distinct CLI and hosted Build privacy](https://docs.x.ai/developers/faq/security)
- [Source-first candidate and automation ledger](/research/grok-build-source-coverage.md)

### Changelog

| Date | Version | Change |
|------|---------|--------|
| 2026-11-05 | 0.1.0 | Initial source-first guide: native identity/policy, approvals, sandbox, MCP/extensions, runtime/data, lifecycle and separate hosted Build privacy/publishing gap; review-only config and CLI inventory packs; no live validation |

### Contributing

See [CONTRIBUTING.md](https://github.com/grcengineering/how-to-harden/blob/main/CONTRIBUTING.md). Contributions with authorized endpoint tests, Windows managed-policy evidence or documented hosted Build publishing/secret/auth controls are especially useful.

---
layout: guide
title: "Claude Code Hardening Guide"
vendor: "Claude Code"
slug: "claude-code"
platform: "Anthropic"
platform_slug: "anthropic"
product: "Claude Code"
tier: "1"
category: "AI/ML Platform"
description: "Harden Claude Code managed policies, permissions, plugins, isolation, remote execution, cloud-provider routing and CI credentials."
version: "1.2.1"
maturity: ["ai-drafted"]
last_updated: "2026-11-12"
---

## Overview

Claude Code is Anthropic's agentic coding tool, running in developer terminals, IDEs, and CI/CD pipelines with the ability to read code, execute commands, and modify files. That capability profile makes it a first-class security surface: a misconfigured deployment can exfiltrate source code, execute injected instructions from untrusted content, or grant third-party MCP servers standing access to internal systems.

This is a **product guide within the [Anthropic platform](/guides/anthropic-claude/)**. Organization-wide controls (SSO, roles, admin API keys, integration governance) live in the Anthropic **Common Controls** hub; API/Console platform controls (workspaces, API keys, spend limits) live in the [Claude API & Console guide](/guides/anthropic-api/).

### Research and validation boundary

This refresh used the [source-first candidate ledger](/research/anthropic-source-coverage-2026-11) and public vendor references, including the published Cowork/unified baseline. It did not access a live tenant, change settings or create credentials. Source verification and mocked/native-interface tests do not earn live-validation status. The exact applicable Security Center checklist must be reconciled with an Owner’s current report; the effective-settings schema is a separate evidence surface.

### Intended Audience
- Security engineers governing AI coding tools
- Platform/IT teams deploying Claude Code via MDM at fleet scale
- DevSecOps teams running Claude Code in CI/CD
- Incident responders covering agentic-tool compromise

### How to Use This Guide
- **L1 (Crawl):** Essential controls for all organizations
- **L2 (Walk):** Enhanced controls for security-sensitive environments
- **L3 (Run):** Strictest controls for regulated industries

### Scope
This guide covers Claude Code deployment policy (managed settings), permission and tool restriction, MCP server access control, hooks/plugins lockdown, bash sandbox and external sandbox isolation, prompt-injection and rules-file-attack defense, CI/CD pipeline hardening, developer metrics, Cowork collaborative-session governance, and incident response. Organization identity and API platform controls are covered by the sibling Anthropic guides.

---

## Table of Contents

1. [Policy & Deployment](#1-policy-deployment)
2. [Extensions & Supply Chain](#2-extensions-supply-chain)
3. [Execution Isolation](#3-execution-isolation)
4. [Threat Defense](#4-threat-defense)
5. [Monitoring, Collaboration & Incident Response](#5-monitoring-collaboration-incident-response)

---

## 1. Policy & Deployment

### 1.1 Deploy Managed Settings via MDM

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | CM-6, CM-7 |
| SOC 2 | CC6.1, CC8.1 |

#### Description
Deploy organization-wide Claude Code security policies using one of four managed settings delivery mechanisms. Managed settings cannot be overridden by user or project settings. The mechanisms are: (1) **Server-managed settings** via the Claude.ai admin console (Team v2.1.38+ / Enterprise v2.1.30+), requiring no MDM; (2) **MDM/OS-level policies** via macOS managed preferences (`com.anthropic.claudecode` domain in Jamf/Kandji) or the Windows registry (`HKLM\SOFTWARE\Policies\ClaudeCode` via GPO/Intune); (3) **File-based** `managed-settings.json` deployed to system paths, plus an optional `managed-settings.d/` drop-in directory whose `*.json` fragments merge onto the base file; (4) the **HKCU registry** (`HKCU\SOFTWARE\Policies\ClaudeCode`, Windows and WSL), a per-user fallback that Claude Code reads only when no other managed source delivers a policy key. Most managed keys use the highest-ranked source carrying a policy key by default; `managedSourcesBehavior: "merge"` can combine sources. Current versions have security-sensitive cross-source exceptions for lock keys, `env`, provider restrictions and sign-in keys. Review the [current precedence rules](https://code.claude.com/docs/en/server-managed-settings) instead of assuming the whole policy is first-wins.

#### Rationale
**Why This Matters:**
- Without managed settings, individual developers can use `--dangerously-skip-permissions` to bypass all safety checks
- User-defined hooks and MCP servers can introduce supply chain risks
- Managed settings enforce a security baseline that developers cannot weaken
- Server-managed settings are fetched at startup and polled hourly with offline caching

**Attack Prevented:** Permission bypass, unauthorized tool execution, malicious hook injection

#### Prerequisites
- MDM solution deployed to developer machines (Jamf, Intune, Kandji), OR Claude Team/Enterprise plan for server-managed settings
- Security team consensus on default permission mode and deny rules
- Inventory of approved MCP servers and tools

#### ClickOps Implementation

**Option A: Server-Managed Settings (No MDM Required)**
1. Navigate to: **claude.ai** → **Organization settings** → **Claude Code** → **Managed settings** ([claude.ai/admin-settings/claude-code](https://claude.ai/admin-settings/claude-code); Owner or Primary Owner)
2. Add JSON configuration with required security settings
3. Confirm current provider/authentication eligibility and the active source on each client. A first launch can briefly run before the remote fetch finishes or continue after a failed fetch; cached settings also have withheld values. Where remote policy is mandatory, evaluate managed `forceRemoteSettingsRefresh: true` with the current documented client/version and failure behavior before rollout. Keep an endpoint baseline for unsupported providers and recovery.
4. In v2.1.223+, administrative `env` sources merge per key, with telemetry/credential-routing exceptions; older versions differ. Credential/profile selectors such as `ANTHROPIC_PROFILE` are startup-only and must be delivered through endpoint policy, not a late server update. For first-party sign-in on clients older than v2.1.299, set org/login keys in both server and endpoint policy as documented.
5. Deliver `managed-mcp.json` through its separate system path, or use the documented policy allow/deny keys. Server-provided `managedMcpServers` requires v2.1.259+ and does not have the file’s exclusive-control behavior. Do not copy OS-only `policyHelper` or gateway sign-in keys into cloud policy.

**Option B: MDM Deployment**

**Step 1: Create managed-settings.json**
1. Create the JSON configuration file with your organization's security policy
2. Include at minimum: `permissions.disableBypassPermissionsMode` set to `"disable"`, `permissions.deny` rules, and `permissions.defaultMode`. The bypass key must sit inside the `permissions` object — Claude Code accepts a root-level copy in the file but never applies it

**Step 2: Deploy via MDM**

Deploy to the correct OS-specific path:

| OS | File Path | MDM/Policy Path |
|----|-----------|-----------------|
| macOS | `/Library/Application Support/ClaudeCode/managed-settings.json` | `com.anthropic.claudecode` preferences domain (Jamf/Kandji profile) |
| Linux / WSL | `/etc/claude-code/managed-settings.json` | N/A |
| Windows | `C:\Program Files\ClaudeCode\managed-settings.json` | `HKLM\SOFTWARE\Policies\ClaudeCode` → `Settings` (REG_SZ with JSON) |

For modular policies, create a `managed-settings.d/` directory alongside the base file. Use numeric prefixes to control merge order (e.g., `10-telemetry.json`, `20-security.json`). Files are sorted alphabetically, deep-merged onto the base — arrays are concatenated and de-duplicated, objects are deep-merged, and later files override earlier ones for scalar values.

**Step 3: Verify Deployment**
1. On a test machine, run `/status` inside Claude Code and read the **Setting sources** line: it must show `Enterprise managed settings` with the selected source in parentheses — `(file)`, `(drop-ins)`, or `(file + drop-ins)` for this option, `(plist)` or `(HKLM)` for MDM, `(remote)` for server-managed settings. A **Skipped sources** line names any managed source that was present but overridden by a higher-ranked one
2. Run `claude doctor` to list any entries Claude Code dropped as invalid — an invalid top-level key is dropped while the rest of the policy keeps enforcing
3. Attempt to use `--dangerously-skip-permissions` — should be blocked if `permissions.disableBypassPermissionsMode` is `"disable"`

**Time to Complete:** ~30 minutes (policy creation) + MDM deployment time

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="7.1" %}

#### Validation & Testing
1. Run the local-file validation script against staged policy. It checks base/drop-in content only and cannot establish effective cloud/MDM policy, endpoint version or all cross-source exception semantics
2. Verify `permissions.disableBypassPermissionsMode` is set to `"disable"`
3. Attempt `--dangerously-skip-permissions` — should be rejected
4. Verify deny rules block restricted operations

**Expected result:** All developer machines have managed settings deployed; bypass mode is disabled

#### Monitoring & Maintenance
**Ongoing monitoring:**
- MDM compliance dashboard confirms file is present on all enrolled devices
- Alert on devices missing managed-settings.json

**Maintenance schedule:**
- **Monthly:** Review and update deny rules as tooling changes
- **Quarterly:** Audit managed settings against security policy

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | Medium | Developers cannot bypass permission checks |
| **System Performance** | None | Settings loaded once at startup |
| **Maintenance Burden** | Low | MDM handles deployment; policy changes are centralized |
| **Rollback Difficulty** | Easy | Remove file from MDM profile |

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1, CC8.1 | Logical access security; change management |
| **NIST 800-53** | CM-6, CM-7 | Configuration settings; least functionality |
| **ISO 27001** | A.12.5.1 | Installation of software on operational systems |

---

### 1.2 Restrict Claude Code Permissions and Tools

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-3, CM-7 |
| SOC 2 | CC6.1, CC6.3 |

#### Description
Configure granular permission rules in managed settings to control which tools Claude Code can use, which files it can access, and which commands it can execute. Use deny rules (which always take precedence) to block sensitive operations like reading `.env` files, executing `curl` commands, or accessing secrets directories.

#### Rationale
**Why This Matters:**
- File edits and shell execution normally require permissions; read-only operations may be preapproved, and bypass/auto modes and installed extensions materially change the boundary
- Without restrictions, a compromised or confused AI agent could exfiltrate secrets, modify production configs, or execute malicious commands
- Deny rules take precedence over allow rules for matching tool requests; Bash text matching is not a security boundary around an executable. Alternate paths, wrappers or other tools may not match the same text
- `allowManagedPermissionRulesOnly: true` ensures users cannot add their own allow rules to weaken the policy

**Attack Prevented:** Secret exfiltration via AI agent, unauthorized file access, command injection

#### Prerequisites
- Managed settings deployment (Control 1.1)
- Inventory of sensitive file patterns and restricted commands

#### ClickOps Implementation

**Step 1: Define Permission Policy**
1. Identify sensitive file patterns: `.env`, `.env.*`, `secrets/`, credentials files
2. Identify restricted commands: `curl` (data exfiltration), `rm -rf` (destruction), credential access
3. Define approved operations: `npm run *`, `git status`, `git diff`, test runners

**Step 2: Configure via Admin Console or MDM**
1. Add permission rules to managed settings:
   - **deny:** `Read(./.env)`, `Read(./.env.*)`, `Read(./secrets/**)`, `Bash(curl *)`, `Bash(rm -rf *)`
   - **allow:** `Bash(npm run *)`, `Bash(git status)`, `Bash(git diff *)`
   - **ask:** `Bash(git push *)`, `Bash(git commit *)`
2. Set `allowManagedPermissionRulesOnly: true` to prevent user overrides
3. Set `permissions.disableBypassPermissionsMode: "disable"` — inside the `permissions` object, not at the root (see Control 1.1)

**Step 3: Configure Network Sandbox (L3)**
1. Enable `sandbox.enabled: true` for OS-level isolation
2. Set `sandbox.network.allowedDomains` to restrict outbound network access
3. Restrict socket access as needed

**Time to Complete:** ~20 minutes

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="7.2" %}

#### Validation & Testing
1. Attempt to read a `.env` file via Claude Code — should be denied
2. Attempt to run `curl` via Claude Code — should be denied
3. Run an approved command (e.g., `npm run test`) — should succeed
4. Verify user-added allow rules are ignored when `allowManagedPermissionRulesOnly` is true

**Expected result:** Sensitive files and commands are blocked; only approved operations succeed

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | Medium | Developers see denials for restricted operations |
| **System Performance** | None | Rule evaluation is instant |
| **Maintenance Burden** | Medium | Rules need updating as tooling evolves |
| **Rollback Difficulty** | Easy | Remove deny rules from managed settings |

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1, CC6.3 | Logical access security; role-based access |
| **NIST 800-53** | AC-3, CM-7 | Access enforcement; least functionality |
| **ISO 27001** | A.9.4.1 | Information access restriction |

---

### 1.3 Gate Remote Control, Cloud Sessions and Routines

**Profile Level:** L2 (Walk)

#### Description
Review the separate Code remote/cloud/routine capabilities before enabling work that persists beyond the terminal. Require trusted devices for approved Remote Control and constrain repositories, environments and credentials for cloud work.

#### Rationale
**Why This Matters:**
- Local Remote Control and Code on the web execute in different places and have different data/network boundaries.
- Member sign-out leaves cloud sessions/routines running, and trusted-device enforcement only covers newly started remote sessions.

**Attack Prevented:** Unauthorized remote steering and persistent cloud-task access after account containment.

#### ClickOps Implementation

1. Review **Organization settings → Claude Code** capabilities for remote control, web/cloud sessions, routines, review/security features and permission bypass. Use groups/custom roles for intended populations.
2. For approved Remote Control enable **Capabilities → Remote sessions → Require trusted devices** and restart existing remote sessions through normal change control. Review device enrollment and lost-device revocation separately.
3. For local Code deployments that must prohibit Remote Control, deploy documented managed `disableRemoteControl: true`; this is not a switch for every cloud product.
4. Review repositories, runtime environments, network policy, inherited secrets and schedule/event triggers for Code cloud work. Stop those sessions and routines explicitly during an incident rather than assuming sign-out did it.

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="7.12" %}

#### Validation & Testing
1. Read returned `claude_code_remote_control_enabled`, `claude_code_trusted_devices_required`, `claude_code_web_enabled` and `claude_code_routines_enabled` as separate evidence; missing rows remain unknown.
2. Verify denied remote access and allowed pilot use, cloud repository scope and routine termination in the actual supported product.

**Expected result:** The documented boundary is exercised and any unsupported surface or exception is recorded.

#### Operational Impact
Trusted Devices is beta and off by default; it affects remote steering, not ordinary terminal/API activity. ZDR/HIPAA availability is restricted.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| CIS Controls | 4.1, 6.8 | Secure configuration and role-based access |
| NIST 800-53 | AC-6, CM-6, AU-6 | Least privilege, configuration and evidence |
| SOC 2 | CC6.1, CC7.2 | Access and monitoring |

**Sources:** [code.claude.com](https://code.claude.com/docs/en/remote-control) · [platform.claude.com](https://platform.claude.com/docs/en/manage-claude/user-management) · [platform.claude.com](https://platform.claude.com/docs/en/manage-claude/compliance-org-data) (checked 2026-11-05).

---

### 1.4 Reconcile Federal Deployment Guidance with Current Provider Routing

**Profile Level:** L3 (Run)

#### Description
For FISMA workloads, use Anthropic’s public-sector Code best-practice guide as architecture/governance context and validate every variable and supported service against current configuration docs. A commercial Enterprise posture result does not authorize a federal deployment.

#### Rationale
**Why This Matters:**
- The January 2026 FISMA PDF includes variables that differ from current CLI references.
- Provider inference routing, endpoint permissions, logging and local tool execution remain separate responsibilities.

**Attack Prevented:** Unapproved inference routing, silent telemetry gaps and weak federal-workload access boundaries.

#### ClickOps Implementation

1. Read the [Claude Code public-sector guide](https://trust.anthropic.com/doc/trust?rid=698639ba9484b19b52b6f1d2&r=iz673w96495gyjer8h78n&download=true) and agency authorization boundary. Confirm an authorized Bedrock GovCloud or Google Assured Workloads service/region/model with the platform owner; no region string alone proves authorization.
2. Deploy Code through managed endpoints with narrow IAM/SSO/MFA, reviewed tool/MCP access, approved egress and version/integrity/drift checks. Use provider audit logging and protected customer OTel where permitted; distinguish essential inference from optional telemetry.
3. Use current documented `AWS_PROFILE` with `CLAUDE_CODE_USE_BEDROCK`, or `ANTHROPIC_VERTEX_PROJECT_ID`/`CLOUD_ML_REGION` with `CLAUDE_CODE_USE_VERTEX`. The old PDF’s `CLAUDE_CODE_AWS_PROFILE` and `CLAUDE_CODE_DISABLE_TELEMETRY` examples must not be copied as current configuration; current telemetry control is `DISABLE_TELEMETRY` or the documented nonessential-traffic switch.
4. Validate the actual provider, region/model and logs in an approved pilot. Keep commercial API, cloud-provider API and Claude for Government (`claude.fedstart.com`) as different offerings; use the hub’s Government source appendix for the latter.

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="7.13" %}

#### Validation & Testing
1. Inspect the managed environment without printing credentials; compare effective routing with provider-side request records and authentication policy.
2. Verify baseline integrity, drift alerts and incident evidence retention; offline payload parsing earns no FISMA or FedRAMP assurance.

**Expected result:** The documented boundary is exercised and any unsupported surface or exception is recorded.

#### Operational Impact
No cloud sign-in, authorization change, model call or credential creation is performed here. The payload examples are mutually exclusive choices and require a current approved model/region deployment.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| CIS Controls | 4.1, 6.8 | Secure configuration and role-based access |
| NIST 800-53 | AC-6, CM-6, AU-6 | Least privilege, configuration and evidence |
| SOC 2 | CC6.1, CC7.2 | Access and monitoring |

**Sources:** [code.claude.com](https://code.claude.com/docs/en/amazon-bedrock) · [code.claude.com](https://code.claude.com/docs/en/google-vertex-ai) · [code.claude.com](https://code.claude.com/docs/en/data-usage) · [trust.anthropic.com](https://trust.anthropic.com/doc/trust?rid=698639ba9484b19b52b6f1d2&r=iz673w96495gyjer8h78n&download=true) (checked 2026-11-05).

---

## 2. Extensions & Supply Chain

### 2.1 Control MCP Server Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | CM-7, SA-9 |
| SOC 2 | CC6.6, CC9.2 |

#### Description
Restrict which Model Context Protocol (MCP) servers Claude Code can connect to using a managed MCP configuration file or allowlist/denylist settings. MCP servers extend Claude Code's capabilities by providing additional tools — an uncontrolled MCP server can introduce arbitrary tool access.

#### Rationale
**Why This Matters:**
- MCP servers can provide Claude Code with tools to access databases, APIs, cloud services, and more
- A malicious or misconfigured MCP server can grant unintended access to sensitive systems
- The `managed-mcp.json` file provides exclusive control — when present, users cannot add their own MCP servers
- Deny rules in `deniedMcpServers` always take precedence over allow rules

**Attack Prevented:** Supply chain attack via malicious MCP server, unauthorized system access, data exfiltration through MCP tools

#### Prerequisites
- MDM deployment capability (for managed-mcp.json) or managed settings access
- Inventory of approved MCP servers and their security posture

#### ClickOps Implementation

**Step 1: Inventory MCP Servers**
1. Survey development teams for MCP servers in use
2. Assess each server's security posture (source, maintainer, permissions granted)
3. Create an approved list

**Step 2: Deploy Managed MCP Configuration**

Deploy `managed-mcp.json` to the OS-specific path:

| OS | Path |
|----|------|
| macOS | `/Library/Application Support/ClaudeCode/managed-mcp.json` |
| Linux / WSL | `/etc/claude-code/managed-mcp.json` |
| Windows | `C:\Program Files\ClaudeCode\managed-mcp.json` |

When this file exists, it takes **exclusive control** — users cannot add, modify, or use any MCP servers other than those defined in this file.

**Step 3: Alternative — Allowlist/Denylist via Managed Settings**
1. Add `allowedMcpServers` to managed settings with approved server names, commands, or URLs
2. Add `deniedMcpServers` for explicitly blocked servers (deny always wins)
3. URL wildcards are supported (e.g., `https://*.company.com/*`)
4. Set `allowManagedMcpServersOnly: true` in the same managed source. Without it, allowlists from every settings scope merge — including a user's own `~/.claude/settings.json` — so a user can broaden what your allowlist permits. Denylists merge from every scope regardless

**Time to Complete:** ~15 minutes

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="7.3" %}

#### Validation & Testing
1. Verify managed-mcp.json is deployed (if using exclusive control)
2. Attempt to add an unapproved MCP server — should be blocked
3. Verify approved MCP servers connect successfully
4. Test deny rule against a specific server name — should be blocked

**Expected result:** Only approved MCP servers can be used; all others are blocked when `managed-mcp.json` is deployed or `allowManagedMcpServersOnly` is `true` (an allowlist without it can be broadened by users)

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | Medium | Developers can only use pre-approved MCP servers |
| **System Performance** | None | MCP config is loaded once at startup |
| **Maintenance Burden** | Medium | Approved list needs updates as new servers are adopted |
| **Rollback Difficulty** | Easy | Remove managed-mcp.json or update allowlist |

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.6, CC9.2 | System boundaries; vendor risk management |
| **NIST 800-53** | CM-7, SA-9 | Least functionality; external system services |
| **ISO 27001** | A.15.1.2 | Addressing security within supplier agreements |

---

### 2.2 Lock Down Hooks and Plugins

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | CM-7, SI-7 |
| SOC 2 | CC6.1, CC8.1 |

#### Description
Restrict the Claude Code extensibility surface by enforcing managed-only hooks, controlling plugin marketplace access, and allowlisting HTTP hook destinations. Hooks execute at lifecycle events (PreToolUse, PostToolUse, SessionStart, etc.) and can run arbitrary commands — a malicious hook can exfiltrate data or modify tool behavior. Plugins extend Claude Code with skills, agents, commands, and hooks from external sources.

#### Rationale
**Why This Matters:**
- Hooks, plugin MCP/LSP servers and background executables can run host code. The [vendor's plugin security guidance](https://code.claude.com/docs/en/plugins/security) makes clear that tool permission and sandbox rules do not contain plugin-owned code. Review the source and updates, restrict installation sources and keep managed hook policy separate from HTTP destination policy. An allowlisted marketplace is a trust decision, not a code-safety guarantee.

**Attack Prevented:** Unreviewed executable plugin or hook code acquiring host credentials or changing tool behavior.

#### Prerequisites
- Managed settings deployment (Control 1.1)
- Inventory of approved internal plugin marketplaces
- List of authorized HTTP webhook endpoints

#### ClickOps Implementation

**Step 1: Lock Hooks to Managed-Only**
1. Navigate to: **claude.ai** → **Organization settings** → **Claude Code** → **Managed settings** ([claude.ai/admin-settings/claude-code](https://claude.ai/admin-settings/claude-code))
2. Add `"allowManagedHooksOnly": true`. Managed hooks, Agent SDK callbacks and hooks from plugins force-enabled by managed `enabledPlugins` remain allowed; do not describe this as blocking every plugin hook.
3. Define required hooks in managed settings. For the stricter pack, deploy `disableAllHooks: true` in managed settings to disable configured hooks, including managed hooks. Agent SDK callbacks and built-in mods are separate exceptions; disabling hooks can also disable custom status/file-suggestion commands.

**Step 2: Restrict Plugin Marketplaces**
1. Add `"strictKnownMarketplaces"` with your approved marketplace repos only
2. Set to empty array `[]` to block all marketplace plugin installations
3. Add `"blockedMarketplaces"` for explicitly banned sources — checked before download. Review plugin-owned hooks, MCP/LSP servers, background processes, JavaScript and bundled executables as host code: Claude tool permissions and the sandbox do not contain that code. Review updates and marketplace auto-update behavior, not only the initial install.
4. Optionally set `"pluginTrustMessage"` with org-specific guidance for developers

**Step 3: Allowlist HTTP Hook URLs**
1. Add `"allowedHttpHookUrls": ["https://hooks.example.com/*"]` with approved webhook endpoints
2. Set to empty array `[]` to block all HTTP hooks
3. Add `"httpHookAllowedEnvVars": ["HOOK_AUTH_TOKEN"]` to restrict which env vars hooks can access

**Step 4: Review Skills as Permission-Bearing Content**
1. Review skill descriptions, linked scripts, frontmatter and injected shell commands, not only the visible instructions. `allowed-tools` grants pre-approval; it is not a restrictive tool allowlist. `disable-model-invocation: true` controls automatic invocation, not an OS security boundary.
2. On Claude Code **v2.1.282+**, managed `allowManagedPermissionRulesOnly: true` suppresses `allowed-tools` from project/personal skills and the other documented untrusted sources. Check `/status` for ignored skill grants; managed deny/ask rules still matter. Test the actual source/version and do not assume the same frontmatter behavior in Cowork or the API.
3. Review all components of a plugin and its update source. A local MCP server is executable software with host privileges, not inherently safer than a remote integration. Do not copy a third-party bundle's empty MCP file or prompt instructions as proof of enforced central policy.

**Sources:** [Settings reference](https://code.claude.com/docs/en/settings-reference#allowmanagedhooksonly), [Skills permissions](https://code.claude.com/docs/en/skills#when-only-managed-permission-rules-apply) (checked 2026-11-12).

**Time to Complete:** ~15 minutes plus extension review.

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="7.6" %}

#### Validation & Testing
1. Create a hook in `.claude/settings.json` — verify it does not execute when `allowManagedHooksOnly` is true
2. Attempt to install a plugin from a non-approved marketplace — should be blocked
3. Verify `blockedMarketplaces` entries are rejected before download
4. Create an HTTP hook targeting a non-allowlisted URL — verify it is blocked
5. Verify `pluginTrustMessage` appears during plugin trust prompts. Run the CLI pack against a reviewed local plugin; warnings fail with `--strict`. A passing manifest scan is not a trust verdict for executable code or later downloads. MCP checks require v2.1.281+. See the [official manifest validator](https://code.claude.com/docs/en/plugins-reference#validate-the-manifest).

**Expected result:** The selected hook policy and its SDK/force-enabled-plugin exceptions are understood; marketplace restrictions and HTTP hook destinations are independently checked.

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | High | Developers cannot install arbitrary plugins or create hooks |
| **System Performance** | None | Settings evaluated once at startup |
| **Maintenance Burden** | Medium | Approved marketplace and webhook lists need updates |
| **Rollback Difficulty** | Easy | Remove restrictive settings from managed config |

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1, CC8.1 | Logical access security; change management |
| **NIST 800-53** | CM-7, SI-7 | Least functionality; software integrity |
| **ISO 27001** | A.12.5.1, A.12.6.1 | Software installation controls; technical vulnerability management |

---

## 3. Execution Isolation

### 3.1 Enforce Bash Sandbox Isolation

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | SC-39, CM-7 |
| SOC 2 | CC6.1, CC6.8 |

#### Description
Enable OS-level bash command sandboxing to isolate Claude Code's subprocess execution. The sandbox restricts filesystem access to the current working directory, routes network traffic through a validating proxy with domain allowlisting, and enforces restrictions at the kernel level using Seatbelt (macOS) or bubblewrap (Linux/WSL2). Set `failIfUnavailable: true` to prevent Claude Code from starting if sandboxing cannot be established.

#### Rationale
**Why This Matters:**
- Without sandboxing, Claude Code bash commands have full access to the developer's filesystem and network
- A prompt injection or confused agent could read credentials (`~/.aws/credentials`, `~/.ssh/`), exfiltrate data via `curl`, or modify system files
- OS isolation constrains covered processes, but excluded commands, supported-platform limitations, plugin host code and in-process tools remain separate boundaries
- `sandbox.network.allowManagedDomainsOnly: true` prevents developers from approving new network domains at runtime

**Attack Prevented:** Credential theft via filesystem access, data exfiltration via network, unauthorized file modification, supply chain attacks via package manager hijacking

#### Prerequisites
- Managed settings deployment (Control 1.1)
- macOS: Seatbelt available (built-in on all supported macOS versions)
- Linux/WSL2: bubblewrap (`bwrap`) and `socat` installed
- Inventory of required network domains for development workflows

#### ClickOps Implementation

**Step 1: Enable Sandbox**
1. Navigate to: **claude.ai** → **Organization settings** → **Claude Code** → **Managed settings** ([claude.ai/admin-settings/claude-code](https://claude.ai/admin-settings/claude-code))
2. Add `"sandbox": { "enabled": true, "failIfUnavailable": true }` to your managed settings JSON
3. Set `sandbox.allowUnsandboxedCommands` to `false` (inside the `sandbox` object) to close the `dangerouslyDisableSandbox` escape hatch

**Step 2: Configure Network Allowlist**
1. Identify required domains: `github.com`, package registries (`*.npmjs.org`, `pypi.org`), internal services
2. Add to `sandbox.network.allowedDomains` array
3. Set `sandbox.network.allowManagedDomainsOnly` to `true` to prevent user overrides — nested under `sandbox.network`; the settings root accepts unknown keys, so a root-level copy is silently ignored
4. Non-allowed domains are blocked automatically without prompting

**Step 3: Configure Filesystem Restrictions**
1. Add sensitive paths to `sandbox.filesystem.denyRead`: `~/.aws/credentials`, `~/.ssh/id_*`, `~/.gnupg/`
2. Add critical system paths to `sandbox.filesystem.denyWrite`: `/etc`, `/usr/local/bin`
3. Optionally set `sandbox.filesystem.allowManagedReadPathsOnly` to `true` for L3 environments

**Step 4: Install Linux Dependencies (if needed)**
1. On Ubuntu/Debian: `sudo apt install bubblewrap socat`
2. On Fedora/RHEL: `sudo dnf install bubblewrap socat`
3. Verify: Run `/sandbox` in Claude Code — should report "Sandbox active"

**Step 5: Account for Tools Outside the Sandbox**
1. **Warning**: The sandbox applies only to Bash, PowerShell, and Monitor commands and their child processes. In-process tools are outside its network proxy — the docs name `WebFetch` ("in-process tools such as WebFetch still follow their permission rules"), and `WebSearch`, which is not a shell command either, is likewise governed by permission rules rather than `sandbox.network.allowedDomains`
2. If outbound data exfiltration is a concern, add `"WebFetch"` and `"WebSearch"` to the `permissions.deny` list in managed settings

**Time to Complete:** ~20 minutes

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="7.5" %}

#### Validation & Testing
1. Run Claude Code with sandbox enabled — verify `/sandbox` shows active status
2. Attempt to read `~/.aws/credentials` via Claude Code — should be denied
3. Attempt to `curl` a non-allowlisted domain — should be blocked
4. Set `failIfUnavailable: true` and remove bubblewrap (Linux) — Claude Code should refuse to start
5. Verify `allowManagedDomainsOnly` prevents user domain approval prompts

**Expected result:** All bash commands execute in kernel-enforced sandbox; credential paths are unreadable; network limited to approved domains

#### Monitoring & Maintenance
**Ongoing monitoring:**
- Monitor for sandbox startup failures via OpenTelemetry metrics
- Track domain approval requests that hit the managed-only block

**Maintenance schedule:**
- **Monthly:** Review and update `allowedDomains` as development tooling evolves
- **Quarterly:** Audit `denyRead`/`denyWrite` paths against new credential storage patterns

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | Medium | Some commands may fail if domains not allowlisted |
| **System Performance** | Low | Proxy latency depends on the workload and deployment |
| **Maintenance Burden** | Medium | Domain allowlist needs updating as tooling changes |
| **Rollback Difficulty** | Easy | Set `sandbox.enabled: false` in managed settings |

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1, CC6.8 | Logical access security; system boundaries |
| **NIST 800-53** | SC-39, CM-7 | Process isolation; least functionality |
| **ISO 27001** | A.13.1.3 | Network segregation |

---

### 3.2 Deploy External Sandbox Tooling

**Profile Level:** L3 (Run)

#### Description
Use an independently reviewed execution boundary around Code when required. The vendor documents development containers as one deployment option; the container does not replace Code permissions, managed policy or controlled egress.

#### Rationale
**Why This Matters:**
- Bind-mounted project files remain writable on the host, and any secret visible in the container can be read by code inside it.
- Bypass-permission mode removes human review even in a container. A broadly trusted network host can still carry exfiltration.

**Attack Prevented:** Host credential exposure and excessive file/network access from agent-driven execution.

#### ClickOps Implementation

1. Follow the vendor's [development-container setup](https://code.claude.com/docs/en/devcontainer). In VS Code, review the repository configuration before **Command Palette → Dev Containers: Rebuild Container** or **Reopen in Container**. A build can execute repository code; use a trusted reviewed image/repository.
2. Inspect host mounts and credential injection. Do not mount host SSH/cloud credential directories. Use repository-scoped or short-lived credentials only for the needed integration.
3. Deliver the Code managed baseline independently of an editable repository Dockerfile. The vendor notes that a repository writer can remove Dockerfile-based policy; verify the selected source in Code rather than assuming a copied JSON file enforces it.
4. Add reviewed egress controls. The vendor's reference container is an example, not a maintained security base image; its firewall needs additional capabilities and those are not required by Code itself. Choose the organization's actual enforcement layer, including 3.1, and verify excluded tools separately.
5. Keep bypass mode disabled where human permission review is required. A container does not make an untrusted repository safe or establish a complete isolation guarantee.

#### Code Implementation

The pack now supplies the documented native starting configuration. It replaces a legacy script that unconditionally launched multiple wrappers and a rollback action; no install, restore or sandbox launch is performed by the new payload. Third-party wrapper flags are not represented as currently verified Anthropic interfaces.

{% include pack-code.html vendor="anthropic-claude" section="7.9" %}

#### Validation & Testing
1. Review the final image, mounts, credentials and network policy before an approved build; the feature tag pins its install script, not the Code CLI release.
2. In an approved pilot, test access to mounted files, denied host secrets and allowed/denied network destinations. Verify Code policy and local/provider logs.

**Expected result:** The deployment's actual host, filesystem, credential and network boundaries are documented and independently checked; parsing the sample is not a sandbox security proof.

#### Operational Impact
Containers change local persistence, networking and editor workflows. Preserve needed incident evidence before rebuild/cleanup. Generic container/host infrastructure hardening remains outside this guide; use the organization's existing baseline.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| NIST 800-53 | SC-39, SC-7, CM-6 | Isolation, network and application policy |
| SOC 2 | CC6.1, CC6.8 | Access and system boundaries |

---

## 4. Threat Defense

### 4.1 Defend Against Prompt Injection and Rules File Attacks

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | SI-10, SI-7 |
| SOC 2 | CC6.1, CC7.2 |

#### Description
Implement defenses against prompt injection attacks that target Claude Code through repository files. Attackers embed malicious instructions in CLAUDE.md, AGENTS.md, SKILL.md, and other rules files that Claude Code reads as context. These "rules file backdoor" attacks can instruct the AI to exfiltrate data, disable safety features, or execute malicious commands. Use the local scanner as a review aid alongside enforced permissions, credential isolation and managed plugin policy.

#### Rationale
**Why This Matters:**
- Instruction files, retrieved content, tool output and plugins can carry adversarial instructions. The [vendor security guidance](https://code.claude.com/docs/en/security) recommends reviewing untrusted content, using permissions and isolation, and keeping the client updated. Static pattern scanners surface review candidates but cannot prove prompt-injection absence; legitimate multilingual files can trigger character heuristics. The guide does not rely on an unrefreshed third-party incident catalog for this control.

**Attack Prevented:** Instructions in untrusted content steering tools toward disclosure or destructive changes.

#### Prerequisites
- Git pre-commit hook infrastructure or CI/CD pipeline
- Familiarity with Claude Code rules file locations (CLAUDE.md, AGENTS.md, `.claude/` directory)

#### ClickOps Implementation

**Step 1: Scan Rules Files Before Trusting Repositories**
1. Before opening any new repository with Claude Code, review `CLAUDE.md` and `.claude/` directory contents
2. Look for: encoded payloads (base64), invisible Unicode characters, instruction override patterns, network exfiltration commands
3. Check for hidden characters: `LC_ALL=C cat -v CLAUDE.md | grep -n 'M-'` lists every line containing a non-ASCII byte (zero-width U+200B/U+200C/U+200D, BOM U+FEFF, bidi controls such as U+202E); review each hit. Without `LC_ALL=C`, `cat -v` in a UTF-8 locale passes multibyte characters through unmarked and the check finds nothing

**Step 2: Require Reviewed Hooks**
1. Keep administrative hooks in managed settings and apply the hook/marketplace controls in [2.2](#22-lock-down-hooks-and-plugins).
2. Review hook source, destinations, credential access and update provenance before deployment. Do not install third-party plugins simply to satisfy this control.
3. Treat hook output as an additional signal; independently test actual permissions and filesystem/network isolation.

**Step 3: Deploy Rules File Scanning in CI**
1. Add the HTH rules file scanner script as a pre-commit hook or CI step
2. The scanner checks for: data exfiltration patterns, encoded payloads, invisible Unicode, instruction override attempts, safety bypass requests
3. Configure to run on every PR that modifies `CLAUDE.md`, `AGENTS.md`, or `.claude/` directory

**Step 4: Review Findings Before Admitting Content**
1. Record an owner, source revision and approval for repository instruction files, skills and plugins. Review changed linked files and executable plugin components.
2. Triage scanner findings manually; do not convert an empty scan into a security pass. Keep production credentials and sensitive host paths out of the test environment.

**Time to Complete:** ~30 minutes

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="7.7" %}

#### Validation & Testing
1. Run the local scanner on reviewed fixtures, including an injected-instruction example and a legitimate multilingual file. Review false positives and missed cases.
2. Verify the actual managed hooks, permissions and isolation with approved allowed/denied probes. A scanner exit zero is only a heuristic result.
3. Confirm newly changed instruction, skill, plugin and linked files require code review; block release until unresolved findings have an owner and disposition.

**Expected result:** Content and executable extensions receive evidenced review, with separate enforcement checks; no claim of complete injection detection.

#### Operational Impact
Heuristic scans add review work and can miss novel attacks. Keep fixtures current and review changes to imported files and plugin versions.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC6.1, CC7.2 | Logical access security; system monitoring |
| **NIST 800-53** | SI-10, SI-7 | Information input validation; software integrity |
| **ISO 27001** | A.12.2.1, A.14.2.8 | Controls against malware; system security testing |

---

### 4.2 Harden Claude Code in CI/CD Pipelines

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | SA-11, SA-15 |
| SOC 2 | CC7.1, CC8.1 |

#### Description
Scope Claude Code credentials, tool permissions and repository access when using GitHub Actions. Run only reviewed content in a protected environment. The pack provides an explicitly dispatched native action example; it never enables an automatic secret-bearing review of arbitrary pull requests. Apply your existing runner network policy separately.

#### Rationale
**Why This Matters:**
- A CI agent processes repository-controlled content while holding automation credentials. Use the [official GitHub Actions security and authentication guidance](https://code.claude.com/docs/en/github-actions), protect the runner's secrets and constrain granted tools. A network monitor in audit mode detects traffic but does not block it. A prompt or an allowlisted tool name does not make untrusted PR code safe to execute.

**Attack Prevented:** Credential disclosure or unauthorized writes by a CI agent processing repository content.

#### Prerequisites
- GitHub repository administration and an existing approved Claude API credential.
- A protected environment named **claude-code-reviewed**, configured with required reviewers and an environment-scoped API secret before using the sample.
- A reviewed commit and instruction/plugin inventory; no credential-bearing execution of untrusted fork code.

#### ClickOps Implementation

1. In **GitHub → repository Settings → Environments**, protect the review environment and restrict its branches/reviewers. Store the existing credential there. The YAML alone does not configure protection.
2. In **Actions**, explicitly dispatch the workflow with a reviewed immutable commit. Keep checkout credentials unpersisted and job permissions read-only for log-only analysis.
3. Review the pinned official action and updates. Supply an explicit least-privilege GitHub token or use the separately documented GitHub App authentication; the latter requires its documented OIDC permission. Do not run the app installer as a validation step.
4. Keep hooks disabled for this restricted example, grant only required tools and deny shell, write and external-fetch tools. Review skill/plugin code separately; tool rules do not contain plugin-owned host processes.
5. Apply the organization's existing runner credential and outbound network policy. Monitoring in audit mode records traffic; it is not a blocking firewall. Additional endpoint needs vary by provider, model, dependencies and optional features.
6. If adopting hosted **Code Review** or **Claude Security**, review their separate repository access, owner capabilities, data/retention and inference-hook exclusions; this workflow does not configure those products.

**Time to Complete:** ~30 minutes plus protected-environment review.

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="7.8" %}

#### Validation & Testing
1. Verify the environment really requires an authorized reviewer and cannot be bypassed by the workflow's trigger/branch configuration.
2. In an isolated pilot, select a reviewed fixture commit; confirm invalid revisions fail and that the action uses the pinned SHA, read-only token and expected tool settings.
3. Verify denied shell/write/network operations cannot execute, no comment or repository write occurs, and the max-turn/time limits bound the run. Test the actual runner network policy independently.
4. Confirm secrets are neither printed nor included in uploaded logs/artifacts; review instructions and dependencies again after changes.

**Expected result:** A deliberately approved run analyzes reviewed content with restricted authority. A successful workflow or syntax check is not proof of prompt-injection resistance.

#### Operational Impact
A protected environment adds review latency. Preserve useful incident logs under an approved retention policy; rotate a compromised credential and stop active jobs rather than removing a monitoring step as rollback.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.1, CC8.1 | Vulnerability management; change management |
| **NIST 800-53** | SA-11, SA-15 | Developer security testing; development process |
| **ISO 27001** | A.14.2.1, A.14.2.8 | Secure development policy; system security testing |

---

## 5. Monitoring, Collaboration & Incident Response

### 5.1 Monitor Claude Code Developer Metrics

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AU-6, SI-4 |
| SOC 2 | CC7.2 |

#### Description
Use the Claude Code Analytics API (`/v1/organizations/usage_report/claude_code`) to monitor per-user developer activity including sessions, commits, pull requests, lines of code, tool acceptance rates, and cost by model. This endpoint provides daily granularity with per-user breakdowns.

#### Rationale
**Why This Matters:**
- Per-user metrics enable detection of anomalous Claude Code usage patterns
- Tool acceptance rates below 70% may indicate permission configuration issues or developer friction
- Cost attribution by user and model enables budget management — this API is Anthropic's sanctioned path for per-user Claude Code cost, superseding per-key Usage API breakdowns
- Tracking commits and PRs created by Claude Code quantifies AI-assisted development impact
- Dimension fields sharpen detection: `terminal_type` (e.g. `vscode`, `iTerm.app`, `tmux` — flag unexpected environments), `customer_type` (`api` vs `subscription`), and `actor` (`user_actor` with `email_address`, or `api_actor` with `api_key_name` — correlate against your key inventory)

**Attack Prevented:** Unauthorized bulk code generation, cost abuse, shadow AI usage detection

> **Monitoring blind spot (verified 2026-08-15):** this API only tracks Claude Code usage **on the Claude API**. Sessions routed through Claude in Amazon Bedrock, Microsoft Foundry, Google Cloud (Vertex AI), or Claude Platform on AWS are invisible to it. If those deployments are permitted, close the gap with the OpenTelemetry integration or provider-side logging — otherwise "shadow AI usage detection" is only true for one of your routing paths.

#### Prerequisites
- Admin API key on a **Claude Console organization** — the API is free for all organizations with Admin API access, covering both `customer_type` `api` (pay-as-you-go) and `subscription` (Pro/Team) customers; a Team/Enterprise plan is **not** the gate. Claude Enterprise (claude.ai) organizations' Claude Code activity is reported by the **Claude Enterprise Analytics API** (Analytics key) instead, and Claude Platform on AWS is not covered
- Monitoring infrastructure for alert thresholds; data lands with up to 1-hour delay, single-day queries via `starting_at` (YYYY-MM-DD, UTC), `limit` max 1000

#### ClickOps Implementation

**Step 1: Review Usage in Console**
1. Navigate to: **platform.claude.com/claude-code** (the Claude Code usage page, separate from the general **Usage** page). It requires the **UsageView** permission, granted to the Developer, Billing, Admin, Owner, and Primary Owner roles
2. Team and Enterprise (claude.ai) organizations use **claude.ai/analytics/claude-code** instead (Admins and Owners)
3. Review per-user activity patterns

**Step 2: Configure Alerts**
1. Set up daily automated checks using the API script below
2. Configure alerts for:
   - Users with unusually high session counts
   - Tool acceptance rates below 70%
   - Cost exceeding per-user thresholds
3. Integrate with observability platform (Datadog, Grafana, etc.)

**Step 3: Configure OpenTelemetry (Optional)**
1. Set environment variables in managed settings for OTel export
2. Available metrics: sessions, LOC, PRs, commits, cost, tokens, code edit decisions, active time
3. Available events: user prompts, tool results, API requests, API errors, tool decisions

**Time to Complete:** ~15 minutes (API setup) + integration time

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="7.4" %}

#### Validation & Testing
1. Run analytics script — verify data returns for active Claude Code users
2. Verify per-user session counts, commit counts, and LOC metrics
3. Verify tool acceptance rates are calculated correctly
4. Confirm cost breakdown by model matches Console dashboard

**Expected result:** Per-user Claude Code metrics are monitored daily with alerts for anomalies

#### Monitoring & Maintenance
**Ongoing monitoring:**
- Daily automated analytics report via cron or CI
- Weekly review of tool acceptance rate trends
- Monthly cost review by user and model

**Maintenance schedule:**
- **Weekly:** Review automated analytics reports
- **Monthly:** Adjust alert thresholds based on team growth
- **Quarterly:** Full access review correlating Claude Code users with org membership

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.2 | System monitoring |
| **NIST 800-53** | AU-6, SI-4 | Audit record review; system monitoring |
| **ISO 27001** | A.12.4.1 | Event logging |

---

### 5.2 Govern Claude Cowork and Collaborative Sessions

**Profile Level:** L2 (Walk)

#### Description
Keep Code collaboration controls separate from Desktop/Cowork administration. Code channels, login pinning, auto mode and transcript retention do not collectively configure the Cowork organization or its native Desktop payload.

#### Rationale
**Why This Matters:**
- The earlier shared settings example mixed Code policy with Cowork controls and could imply personal Desktop accounts were prevented.
- Local device files and server-managed Code policy have different effects on Cowork; multiple installed policies can conflict.

**Attack Prevented:** Shadow-account access and false assurance from applying a policy to the wrong client.

#### ClickOps Implementation

1. Configure Code channels (`channelsEnabled`, `allowedChannelPlugins`), Code organization login (`forceLoginMethod`, `forceLoginOrgUUID`) and `disableAutoMode` only in the supported Code managed plane. Disable unneeded remote sessions/routines separately.
2. Follow [Enterprise 3.4](/guides/claude-enterprise/#34-govern-cowork-cloud-sessions-connector-auto-approval-and-egress) for Cowork/unified enablement, connector approvals, egress and the November 16 rollout. Neither Code channels nor Code auto mode is the Cowork approval toggle.
3. Follow [Enterprise 3.6](/guides/claude-enterprise/#36-deploy-a-separate-desktop-device-policy) for Desktop org pinning, workspace folders, local MCP and extensions. Code console-delivered settings do not reach Cowork; local Code file policy can, so test both payloads together.
4. Use supported transcript cleanup settings and preserve incident evidence first. Device transcripts, Compliance captures and original files have different lifetimes. Do not claim a seven-day Code cleanup deletes cloud conversations or all local artifacts.

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="7.10" %}

#### Validation & Testing
1. Read `/status` and `claude doctor` for Code; inspect Desktop device policy independently and test approved/refused accounts.
2. Verify Cowork, Chrome, built-in browser and scheduled-task restrictions in their own product/admin plane, including permitted local/cloud sessions.

**Expected result:** The documented boundary is exercised and any unsupported surface or exception is recorded.

#### Operational Impact
The shared 7.10 pack now labels its settings as Code policy only. Do not deploy it as the Desktop configuration; reducing retention can remove local forensic evidence.

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|------------|---------------------|
| CIS Controls | 4.1, 6.8 | Secure configuration and role-based access |
| NIST 800-53 | AC-6, CM-6, AU-6 | Least privilege, configuration and evidence |
| SOC 2 | CC6.1, CC7.2 | Access and monitoring |

**Sources:** [code.claude.com](https://code.claude.com/docs/en/managed-settings) · [code.claude.com](https://code.claude.com/docs/en/settings-reference) · [support.claude.com](https://support.claude.com/en/articles/12622667-enterprise-configuration-for-claude-desktop) · [trust.anthropic.com](https://trust.anthropic.com/resources?name=claude-cowork-security-best-practices&s=uukz8hyx7jmdmo80lys36s) (checked 2026-11-05).

---

### 5.3 Establish Incident Response for Claude Code and Cowork

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | IR-4, IR-5, IR-8 |
| SOC 2 | CC7.3, CC7.4 |

#### Description
Establish incident response procedures specific to Claude Code and Cowork security events. Traditional IR playbooks do not cover AI agent-specific scenarios such as prompt injection leading to data exfiltration, MCP server compromise, unattended scheduled task abuse, or Chrome session hijacking. Define detection, containment, evidence collection, and recovery procedures for these novel attack surfaces.

#### Rationale
**Why This Matters:**
- AI agent incidents involve unique attack chains not covered by standard IR playbooks (e.g., prompt injection → MCP tool poisoning → credential exfiltration)
- Cowork's organization availability toggle (**Organization settings** → **Cowork** → **Enable for your organization**) is the fastest containment action; it is organization-wide, although Enterprise plans can scope Cowork access with groups and custom roles
- Forensic evidence for Cowork is stored locally on user machines in the `.claude` folder — it must be collected before session cleanup runs
- OpenTelemetry logs in your SIEM and, on Enterprise plans, the Compliance API (which captures Cowork sessions) are the centralized evidence sources; local-session history still has to be collected from the user's machine
- Without documented IR procedures, response to AI agent incidents will be ad-hoc and slow

**Attack Prevented:** Prolonged, uncontained AI agent incidents (prompt injection exfiltration, MCP server compromise, hijacked automation) due to ad-hoc response

**Attack Scenarios Requiring IR:**
- Prompt injection in a document triggers data exfiltration via MCP server or `curl` to attacker endpoint
- Malicious MCP server installed by user exfiltrates credentials via tool calls
- Chrome automation hijacked to access sensitive internal systems
- Scheduled task compromised to run unauthorized operations for hours unattended
- Supply chain attack via malicious plugin or skill installation
- Personal account bypass via account switching (without tenant restrictions)

#### Prerequisites
- Existing organizational IR framework
- OpenTelemetry integration with SIEM (Control 5.1/5.2)
- Familiarity with Claude Desktop local storage locations

#### ClickOps Implementation

**Step 1: Document the Emergency Kill-Switch**
1. The fastest containment action: an Owner or Primary Owner opens **Organization settings** → **Cowork** and turns off **Enable for your organization** ([Use Claude Cowork on Team and Enterprise plans](https://support.claude.com/en/articles/13455879-use-claude-cowork-on-team-and-enterprise-plans))
2. This disables Cowork for ALL users in the organization; **Run Cowork in the cloud** is a separate toggle on the same page, and Claude in Chrome is disabled separately under **Organization settings** → **Claude in Chrome**
3. Limitation: the toggle is organization-wide — only Enterprise plans can narrow Cowork access to specific teams, through groups and custom roles
4. For Claude Code, retain the managed security baseline. Terminate/restrict the affected sessions, client capability, connector or identity through the documented control; deleting managed policy removes protections and is not a containment action.
5. Assign specific team members authority to execute the kill-switch without additional approval

**Step 2: Define Forensic Collection Procedures**
1. Primary evidence source: session history in the `.claude` folder on the user's local machine
2. Collect BEFORE `cleanupPeriodDays` triggers automatic deletion — after each session starts, Claude Code sweeps away transcripts older than that many days (minimum 1)
3. Session transcripts are stored as `.jsonl` files with timestamped entries
4. Correlate local evidence with OTel logs in your SIEM using `session_id` and `prompt.id` UUID fields
5. For Enterprise: the Compliance API captures Cowork sessions (via Claude, Claude Desktop, and Claude Mobile) as well as Chat and Code activity, and admins can retrieve local-session content through it — enable the public Compliance API through the Primary Owner and use the scoped access described in the Enterprise guide; do not infer access from an NDA or Trust Center link

**Step 3: Build AI Agent IR Scenarios**
1. Add these scenarios to your IR playbook:
   - **Prompt injection → exfiltration**: Malicious document or web page injects instructions causing data upload to attacker endpoint. Detection: unexpected outbound network calls in OTel `tool_result` events. Containment: kill-switch + network block.
   - **MCP server compromise**: User-installed or compromised MCP server exfiltrates data via tool calls. Detection: unexpected MCP tool invocations in OTel. Containment: remove MCP server from `managed-mcp.json`, push update.
   - **Chrome session hijack**: Cowork's Chrome automation directed to access unauthorized internal systems. Detection: unexpected URLs in OTel browser events. Containment: disable Chrome in Cowork.
   - **Scheduled task abuse**: Prompt injection creates a persistent loop accessing data or sending messages. Detection: long-running sessions, off-hours activity in OTel. Containment: user stops task + kill-switch if needed.
   - **Plugin/skill supply chain**: Malicious plugin installed from marketplace executes unauthorized code. Detection: unexpected plugin installation events. Containment: block marketplace, remove plugin, push managed settings update.

**Step 4: Conduct Quarterly Tabletop Exercises**
1. Run tabletop exercises simulating AI agent-specific attacks
2. Recommended scenario: prompt injection in a shared document → data exfiltration via MCP server → detection via OTel → containment via kill-switch → forensic collection from user machine
3. Include security team, IT ops, and representative Claude Code/Cowork users
4. Update IR playbook based on lessons learned

**Step 5: Establish Reporting Channels**
1. Internal: security team escalation path for suspicious Claude behavior (users should know to immediately stop any suspicious task)
2. External: report security vulnerabilities to Anthropic via their [HackerOne program](https://hackerone.com/anthropic)
3. In-app: users can report suspicious behavior with `/feedback`
4. Anthropic publishes its security contact in [security.txt](https://www.anthropic.com/.well-known/security.txt) — a HackerOne submission form, under the [Responsible Disclosure Policy](https://www.anthropic.com/responsible-disclosure-policy); it lists no security email address

**Time to Complete:** ~1 hour (playbook creation) + quarterly tabletop exercises

#### Code Implementation

{% include pack-code.html vendor="anthropic-claude" section="7.11" %}

#### Validation & Testing
1. Verify kill-switch authority is documented and assigned to specific team members
2. Verify forensic collection procedure can successfully extract `.claude` session files from a test machine
3. Verify OTel logs in SIEM can be correlated with local session data using `session_id`
4. Run a tabletop exercise for at least one AI agent IR scenario
5. Verify all team members know how to execute the kill-switch

**Expected result:** IR playbook includes AI agent scenarios; kill-switch authority assigned; forensic collection tested; quarterly tabletop cadence established

#### Operational Impact

| Aspect | Impact Level | Details |
|--------|-------------|----------|
| **User Experience** | None | IR procedures are transparent to users during normal operations |
| **System Performance** | None | No runtime impact |
| **Maintenance Burden** | Medium | Quarterly tabletop exercises and playbook updates |
| **Rollback Difficulty** | N/A | Procedural control, not a technical setting |

#### Compliance Mappings

| Framework | Control ID | Control Description |
|-----------|-----------|---------------------|
| **SOC 2** | CC7.3, CC7.4 | Incident detection and response; incident recovery |
| **NIST 800-53** | IR-4, IR-5, IR-8 | Incident handling; incident monitoring; incident response plan |
| **ISO 27001** | A.16.1.1, A.16.1.5 | Information security incident management; response to incidents |

---


## Compliance Quick Reference

Per-control compliance mappings appear inside each control above. For organization-level SOC 2 / NIST / ISO mappings spanning the Anthropic platform, see the [Anthropic Common Controls hub](/guides/anthropic-claude/#compliance-quick-reference).

---

## Appendix A: References

See the [Anthropic platform hub references](/guides/anthropic-claude/#appendix-b-references) for the shared reference list; key Claude Code sources:

- [Claude Code Security](https://code.claude.com/docs/en/security)
- [Claude Code Managed Settings](https://code.claude.com/docs/en/managed-settings) — delivery mechanisms, source precedence, and `/status` verification
- [Claude Code Settings Reference](https://code.claude.com/docs/en/settings-reference) — every settings key and its scope
- [Claude Code Managed MCP](https://code.claude.com/docs/en/managed-mcp)
- [Claude Code Sandboxing](https://code.claude.com/docs/en/sandboxing)
- [Claude Code IAM & Enterprise Auth](https://code.claude.com/docs/en/iam)
- [Use Claude Cowork on Team and Enterprise plans](https://support.claude.com/en/articles/13455879-use-claude-cowork-on-team-and-enterprise-plans) — Cowork admin controls, monitoring, and data storage
- [Enforce network-level access control with Tenant Restrictions](https://support.claude.com/en/articles/13198485-enforce-network-level-access-control-with-tenant-restrictions)

---

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-11-12 | 1.2.1 | ai-drafted | Reconciled Pluto extension/bundle research; corrected managed-hook exceptions and strict hook pack, added skill pre-approval/version checks without treating prompts as enforcement. | Codex |
| 2026-11-05 | 1.2.0 | ai-drafted | Separated Code from Desktop/Cowork policy; corrected permission/sandbox/plugin boundaries and containment; added remote/cloud/routine controls and federal provider-routing guidance with current variables. | Codex |
| 2026-10-04 | 1.1.1 | ai-drafted | validate-hth-guide run against a live Claude Console organization, read-only: 0 of 22 surfaces exercised live, so `ai-validated` was not added. The §5.1 Console page at platform.claude.com/claude-code loaded only its headings and placeholder rows (no metric or per-user data; the org had no Claude Code activity), and the §5.1 script, run with an Admin API key, returned 0 records for each day tried. The claude.ai Team/Enterprise admin pages need a Team or Enterprise org. Corrections: the claude.ai managed-settings path in §1.1, §2.2, §3.1 and §5.2 is now **Organization settings** → **Claude Code** → **Managed settings** (was "Admin Settings"); the Team/Enterprise analytics URL in §5.1 is claude.ai/analytics/claude-code. | Claude Code (Opus 5.5) |
| 2026-09-25 | 1.1.0 | ai-drafted | [SECURITY] Fixes from a validate-hth-guide run (22 surfaces; 0 exercised live — the Console was behind a sign-in wall and the claude.ai admin surfaces need a Team or Enterprise org — so `ai-validated` was not added). §4.2's workflow pinned two action commits that do not exist and passed inputs `claude-code-action@v1` ignores: repinned, with model, tool and turn limits moved into `claude_args`. The §4.1 rules-file scanner never matched invisible Unicode: fixed, bidi controls added. Validators for §1.1, §1.2 and §2.1 now merge `managed-settings.d/` drop-ins, read `disableBypassPermissionsMode` only under `permissions`, and exit non-zero on failure; the §5.1 script no longer aborts on macOS, follows pagination, fails on a day with zero records instead of reporting healthy acceptance rates, and keeps the admin key out of process arguments; the §5.3 collector preserves timestamps and writes SHA256SUMS. Guide: settings keys shown under their parent objects, `/status` and `claude doctor` verification, HKCU fallback and first-wins source precedence, `allowManagedMcpServersOnly`, `cleanupPeriodDays` minimum 1 (0 fails validation), Cowork admin paths, instructions and Compliance API coverage re-sourced from support.claude.com, tenant-restriction availability and header rules, HackerOne and security.txt contacts. | Claude Code (Opus 5.5) |
| 2026-08-15 | 1.0.2 | ai-drafted | §5.1 corrections from the Admin API currency pass: prerequisites fixed — the gate is an Admin API key on a Claude Console organization (free for every org with Admin API access, both `api` pay-as-you-go and `subscription` Pro/Team customer types), not a Team/Enterprise plan; Claude Enterprise (claude.ai) users' Claude Code activity reports through the separate Claude Enterprise Analytics API. Documented the cloud-provider monitoring blind spot (sessions via Bedrock, Foundry, Vertex AI, or Claude Platform on AWS are invisible to this API — close with OpenTelemetry or provider-side logging), added the detection dimensions (`terminal_type`, `customer_type`, `user_actor`/`api_actor`), and the operational facts (up to 1-hour data delay, single-day `starting_at` queries, `limit` max 1000). Console hosts canonicalized to platform.claude.com. | Claude Code (Opus 5) |
| 2026-08-08 | 1.0.1 | ai-drafted | Cheat-sheet cell repair: added missing Attack Prevented line(s) to §5.3 (no content-facts changed) | Claude Code (Fable 5) |
| 2026-08-03 | 1.0.0 | ai-drafted | Split out of the monolithic Anthropic Claude guide as part of the multi-product platform restructure; carries the 11 Claude Code controls (formerly section 7) renumbered into five thematic sections. | Claude Code (Sonnet 5) |

## Contributing

Found an issue or want to improve this guide? Open an issue or PR on [GitHub](https://github.com/grcengineering/how-to-harden). Keep all code in Code Packs (no inline code blocks).

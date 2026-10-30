---
layout: guide
title: "Devin CLI Hardening Guide"
vendor: "Devin CLI"
slug: "devin-cli"
platform: "Cognition"
platform_slug: "cognition"
product: "Devin CLI"
tier: "2"
category: "AI/ML Platform"
description: "Harden Devin CLI with enterprise identity policy, organization permissions, sandboxing, workspace trust, MCP governance, import controls, credential protection, and plugin review."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-10-30"
---

## Overview

This is a product guide within the [Cognition platform](/guides/devin/). It covers the local Devin CLI agent, including its use as the Devin Local engine in [Devin Desktop](/guides/devin-desktop/). Cloud organization identity, membership, and repository authorization belong in the hub; local permissions and device policies do not replace those controls.

Devin CLI can run commands, read credentials available to the operating-system user, load executable extensions, and access remote services. Separate three boundaries: administrator-managed policy, user/project configuration, and operating-system isolation. A rule written in a repository is not an immutable organization policy. [Cognition's controls reference](https://docs.devin.ai/cli/enterprise/controls) also documents differences between this agent and legacy Cascade.

### Intended Audience

- Endpoint administrators deploying AI development tools
- Enterprise administrators managing Cognition access
- Security engineers reviewing developer workstations and extensions

### How to Use This Guide

- **L1 (Crawl):** Preserve trust prompts and protect credentials.
- **L2 (Walk):** Enforce enterprise permissions and govern extensions.
- **L3 (Run):** Evaluate stronger isolation with documented platform limitations.

### Scope

Eight controls cover local execution and associated enterprise administration. The CLI can also drive cloud sessions; those sessions require the [Devin hub's controls](/guides/devin/). This guide does not claim that a local configuration secures cloud execution, that network filtering is production-stable, or that hooks are a fail-closed security boundary.

**Validation status:** no tenants declared — Tier 0+1 only. Pack syntax, static fixtures, and mocked command dispatch are tested; no live login, permission denial, sandbox escape test, or admin-console change has been performed. All guidance remains `ai-drafted`.

## Table of Contents

1. [Identity & Policy](#1-identity--policy)
2. [Execution Boundaries](#2-execution-boundaries)
3. [External Tools & Imported Configuration](#3-external-tools--imported-configuration)
4. [Sensitive Data](#4-sensitive-data)
5. [Extension Review](#5-extension-review)
6. [Compliance Quick Reference](#6-compliance-quick-reference)

## 1. Identity & Policy

### 1.1 Pin Device Identity

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-3, CM-6 |

#### Description

Deploy administrator-owned `system.json` before onboarding. Set the confirmed `enterprise_host` and `account_id`; optionally route CLI/updater traffic through an approved proxy. These are device policy fields, not user-config substitutes. [System configuration](https://docs.devin.ai/cli/enterprise/system-config).

#### Rationale

**Why This Matters:**
- A managed workstation should not silently authenticate to a personal or unintended tenant.
- A misspelled or malformed policy can leave a device unmanaged.

**Attack Prevented:** Accidental use of unmanaged identities and unapproved outbound API routes; not theft of an already-issued token.

#### Prerequisites

Enterprise access, confirmed account identifier, endpoint management, and a pilot device with independent administrator access.

#### ClickOps Implementation

1. In your endpoint-management system, deploy strict JSON to the documented path: macOS `/Library/Application Support/Devin/system.json`; Linux `/etc/devin/system.json`; Windows `C:\ProgramData\Devin\system.json`.
2. Set root/Administrator ownership and deny regular-user modification of the file and its directory. Confirm Windows ACLs separately.
3. If adding `proxy`, use `mode: "manual"`, an approved `url`, and reviewed `no_proxy` exceptions. Remove conflicting user-config proxy sections before rollout.
4. Pilot authentication before expanding deployment. Previously stored credentials are **not** revalidated by this policy: schedule a deliberate logout/login with the user, not a silent bulk logout.

#### Code Implementation

The config pack prints strict JSON with `emit`; `validate FILE` checks its schema, while `audit FILE` additionally checks Unix ownership and modes. It never deploys a policy. Supply confirmed `DEVIN_ENTERPRISE_HOST` and `DEVIN_ACCOUNT_ID`; optional `DEVIN_PROXY_URL` must not contain credentials. The CLI pack only reports version and authentication status.

{% include pack-code.html vendor="devin-cli" section="1.1" %}

#### Validation & Testing

After an authorized fresh login, verify the configured host and account with `devin auth status`. An out-of-policy login should fail. Inspect startup warnings and deployment integrity: unreadable/malformed JSON is treated as absent, invalid fields can lose enforcement, and unknown keys are ignored. A static schema pass is not runtime proof.

**Operational impact and rollback:** incorrect account/proxy values can interrupt access. Pilot first; restore the reviewed prior policy through endpoint management if needed. Do not weaken file permissions as a workaround.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | AC-3; CM-6 | Access enforcement; configuration settings |

### 1.2 Enforce Organization Permissions

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-3, AC-6 |

#### Description

Place compulsory deny/ask rules in enterprise Terminal Permissions, not merely in repository or user configuration. Grant only individually reviewed exceptions. [Team settings](https://docs.devin.ai/cli/enterprise/team-settings) and [permission precedence](https://docs.devin.ai/cli/reference/permissions).

#### Rationale

**Why This Matters:**
- Local approvals can accumulate into unnecessarily broad execution authority.
- Organization rules remain applicable when users change permission mode.

**Attack Prevented:** Lower-precedence configuration bypass and unnecessary automatic execution after prompt injection; command-name denylists alone are not a complete shell security boundary.

#### Prerequisites

Enterprise administrator access; an inventory of credential paths and essential development tasks.

#### ClickOps Implementation

1. Open **Settings → Enterprise → Devin Desktop** in the Devin dashboard and locate the **Devin CLI-specific settings**. Legacy Windsurf Enterprise uses its **CLI Settings** page instead.
2. Select **Terminal Permissions → Configure**.
3. Paste the pack's three-key object (`deny`, `ask`, `allow`) after adapting secret paths. Do not add a `permissions` wrapper in this editor.
4. Keep broad interpreters and shells out of automatic approvals. Review explicit exceptions with the security owner.

#### Code Implementation

The native JSON fragment is a console payload, not an API request. For a local config file it requires a `permissions` wrapper, but local placement does **not** create enterprise enforcement. No team-permissions setter is documented in the reviewed CLI/config references; this pack does not invent one.

{% include pack-code.html vendor="devin-cli" section="1.2" %}

#### Validation & Testing

Use benign dummy files to test denies and asks from a normal user. Confirm a project-local allow cannot defeat an organization deny or ask. At one configuration level, a more-specific command/MCP allow can exempt a broader ask; a matching deny still wins. Review saved approvals after policy changes.

**Operational impact and rollback:** additional prompts are intentional. Remove only the specific reviewed blocking rule; do not switch the user into Bypass as a fix.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | AC-3; AC-6 | Access enforcement; least privilege |

## 2. Execution Boundaries

### 2.1 Require Sandbox Isolation

**Profile Level:** L3 (Run)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-6, CM-6 |

#### Description

Pilot OS sandboxing on supported endpoints before requiring it. The command reference marks `--sandbox` **Research Preview**. Its filesystem boundary supplements permission prompts; it does not turn the entire CLI process into a sandbox. [Sandbox documentation](https://docs.devin.ai/cli/sandbox) and [commands reference](https://docs.devin.ai/cli/reference/commands).

#### Rationale

**Why This Matters:**
- Arbitrary shell programs can access more than the agent's built-in file tools.
- Explicit sandbox exceptions can silently undermine an otherwise restrictive deployment.

**Attack Prevented:** Some out-of-scope shell reads/writes; not every agent or extension action.

#### Prerequisites

macOS or Linux; Linux requires `bwrap` and `socat`. Native Windows does not support this sandbox. Test development workflows and separate endpoint/network containment before enforcement.

#### ClickOps Implementation

1. In **Settings → Enterprise → Devin Desktop → Devin CLI-specific settings → Sandbox Enforcement**, review **Excluded allow**, **Excluded ask**, and **Excluded deny**. Avoid automatic exclusions and keep necessary exceptions narrow.
2. After a supported-device pilot, change enforcement from **Optional** to **Required**. Do not apply to a population containing unsupported Windows clients.
3. Review filesystem deny rules and every granted write scope. The workspace is writable; additional write approvals enlarge the sandbox boundary.
4. Treat domain filtering as experimental: Cognition calls it unstable. Do not depend on it as the sole egress control for sensitive work.

#### Code Implementation

The wrapper defaults to a dependency preflight. Only `--launch` starts a no-initial-prompt interactive session, explicitly preserving workspace trust. It never falls back to an unsandboxed launch. The presence of dependencies does not prove OS isolation.

{% include pack-code.html vendor="devin-cli" section="2.1" %}

#### Validation & Testing

In a disposable workspace, test harmless reads/writes against dummy denied/out-of-scope paths. Check that missing sandbox prerequisites prevent startup. Shell commands/fetches normally auto-approve in sandbox Autonomous mode; direct edit/write tools still prompt because they run outside that boundary. Re-test after new write approvals or exception changes.

**Operational impact and rollback:** Required can stop unsupported clients, and policy changes affect active sessions at the next prompt. Return only the affected pilot to Optional if necessary; do not remove the wrapper's `--sandbox` flag to conceal a failed isolation check.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | AC-6; CM-6 | Least privilege; configuration settings |

### 2.2 Preserve Workspace Trust

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-3, CM-6 |

#### Description

Preserve workspace trust checks and use Normal permissions for ordinary non-sandboxed interactive sessions. Do not “fix” an untrusted CI workspace by bypassing its trust check. [Commands and flags](https://docs.devin.ai/cli/reference/commands).

#### Rationale

**Why This Matters:**
- A checkout can contain executable hooks and misleading agent instructions.
- Unattended execution removes the opportunity to inspect a risky first action.

**Attack Prevented:** Unreviewed repository activation and accidental permission-bypass launches; trust acceptance itself does not certify repository safety.

#### ClickOps Implementation

1. Review a repository and its agent configuration before opening it in the CLI. Inspect hooks and extension sources without starting an agent session.
2. Keep the workspace trust prompt enabled. For a non-sandboxed session, select **Normal** rather than **Bypass**.
3. Before adopting a CI wrapper, inspect its arguments and environment. Reject `--respect-workspace-trust false` and unrestricted permission modes unless a separately approved containment design requires them.

#### Code Implementation

The wrapper is a dry run unless explicitly passed `--launch`. It starts Normal mode with trust checks enabled and accepts no arbitrary extra arguments. Use control 2.1 instead where OS sandboxing is required; this wrapper is not a sandbox.

{% include pack-code.html vendor="devin-cli" section="2.2" %}

#### Validation & Testing

In a disposable, previously untrusted checkout, verify that the CLI requests trust. Non-interactive `--print` should fail rather than silently trust it. Confirm ordinary shell execution still asks in Normal mode. Do not submit an operational task merely to test the launcher.

**Operational impact and rollback:** the first trusted opening needs human review. Repair repository provenance or the intended trust state instead of disabling the check globally.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | AC-3; CM-6 | Access enforcement; configuration settings |

## 3. External Tools & Imported Configuration

### 3.1 Govern MCP Servers

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-3, AC-6 |

#### Description

Restrict CLI MCP connections to reviewed servers through the enterprise toggle/registry policy. Separately inventory and disable unnecessary local server definitions. Empty explicit allowlists are **not** deny-all. [Team settings](https://docs.devin.ai/cli/enterprise/team-settings) and [MCP configuration](https://docs.devin.ai/cli/extensibility/mcp/configuration).

#### Rationale

**Why This Matters:**
- MCP servers can execute code locally or send information to another service.
- Approval of a registry is broader than approval of one server.

**Attack Prevented:** Unreviewed external-tool use and standing access to unnecessarily broad integrations.

#### Prerequisites

Enterprise administrator for managed enforcement; server owners, allowed operations, authentication scopes, and a source/package review.

#### ClickOps Implementation

1. In the CLI-specific **Team Settings → MCP Servers**, disable MCP when it is not needed.
2. If enabled, choose a curated **MCP Registry**, add the approved registry URL, and enable **MCP registry enforcement**. Multiple registries combine as a union; adding one expands the permitted set.
3. If using explicit **Allowlisted MCP Servers**, populate only approved entries. An empty list permits all servers.
4. Review each project's and user's configured servers. Never commit literal credentials in shared MCP configuration.

#### Code Implementation

The CLI pack lists configuration by default. `disable NAME SCOPE` previews a local change; the additional `--apply` flag is required to make it. This is not organization enforcement and does not revoke OAuth credentials. Current releases use dedicated `mcp_config.json` files; versions before v3000.3 used `mcpServers` inside main configs, with migration on startup.

{% include pack-code.html vendor="devin-cli" section="3.1" %}

#### Validation & Testing

Verify an approved harmless server works and an unapproved one is rejected. Confirm the target server is disabled in the intended `local`, `project`, or `user` scope. Inspect imported and plugin-provided servers too; editing one file does not establish the complete effective inventory.

**Operational impact and rollback:** tools may disappear. Re-enable only the approved named definition; do not clear the enterprise allowlist to restore access.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | AC-3; AC-6 | Access enforcement; least privilege |

### 3.2 Restrict Configuration Imports

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | CM-6 |

#### Description

Disable unreviewed configuration-import providers, then enable only the sources needed for the project. Imports are enabled by default and may contribute rules, skills, hooks, MCP servers, or cloud plugins. [Configuration import](https://docs.devin.ai/cli/reference/configuration/read-config-from).

#### Rationale

**Why This Matters:**
- Another coding tool's configuration is a separate trust decision.
- A clean `.devin` directory does not imply an extension-free session.

**Attack Prevented:** Unexpected instruction and integration loading from legacy or unrelated tool configuration.

#### ClickOps Implementation

1. In a local editor, merge the pack into the **user** config at `~/.config/devin/config.json`, or `%APPDATA%\devin\config.json` on Windows.
2. Keep unwanted `read_config_from` providers false. The `cloud` switch is user-only; do not place it in project configuration. It excludes personal cloud plugins and cloud MCP imports, not organization/enterprise-required plugins or their governance.
3. Review native `.devin` configuration separately, then enable only reviewed imports. Disabling imported `AGENTS.md` rules can remove useful project safeguards; assess that tradeoff before applying the all-disabled baseline.
4. Review `.devin/config.local.json` and project overrides because user defaults are not immutable policy.

#### Code Implementation

The native fragment is a reviewed-merge template, not an installer. The accompanying CLI pack inventories effective rules and skills without dumping their content.

{% include pack-code.html vendor="devin-cli" section="3.2" %}

#### Validation & Testing

Use harmless test rules to establish that each disabled provider is no longer loaded. Review `/hooks` in an already-trusted session as well as MCP inventory. Native extensions remain possible, and some nested rules are loaded lazily; a startup list alone is not comprehensive proof.

**Operational impact and rollback:** custom workflows may disappear. Restore only a reviewed provider rather than deleting the whole import policy.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | CM-6 | Configuration settings |

## 4. Sensitive Data

### 4.1 Protect Sensitive Files

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | AC-3, AC-6 |

#### Description

Keep credentials outside agent-readable workspaces, set user-level `respect_gitignore: true`, and apply explicit read/write restrictions to sensitive paths. Devin authentication stores a persistent token in `credentials.toml`; the documented default token does not expire. [Authentication storage](https://docs.devin.ai/cli/enterprise/devin-auth) and [configuration reference](https://docs.devin.ai/cli/reference/configuration/config-file).

#### Rationale

**Why This Matters:**
- Git exclusion alone normally prevents commits, not access by an AI tool.
- A stolen CLI credential can outlive the current terminal session.

**Attack Prevented:** Accidental secret ingestion, commits, and exposure through permitted file tools; not every shell/extension access path.

#### ClickOps Implementation

1. In your local editor, merge the user-config fragment, preserving existing permission rules. Do not overwrite the whole file.
2. Resolve the actual credential location: macOS/Linux use `$XDG_DATA_HOME/devin/credentials.toml` when set, otherwise `~/.local/share/devin/credentials.toml`; Windows uses `%APPDATA%\devin\credentials.toml`.
3. Restrict OS access to the developer account and administrator. Add that actual path to enterprise permission denies; the pack's example covers only the default Unix path.
4. Use synthetic credentials in tests. Never copy real token contents into a ticket, prompt, test fixture, or shared MCP file.

#### Code Implementation

The native user fragment enables ignored-path protection and explicit deny examples. It is not valid as a complete project configuration. Local rules can be superseded by higher-precedence sources; use control 1.2 for mandatory organization restrictions and 2.1 for sandboxed shell containment.

{% include pack-code.html vendor="devin-cli" section="4.1" %}

#### Validation & Testing

Test with dummy ignored files and a dummy credential path. Verify the effective agent denies those reads, including from nested paths. Review both direct file-tool and sandboxed-shell behavior. `include_gitignored_files: false` only hides completion candidates; it is not equivalent to `respect_gitignore`.

**Operational impact and rollback:** ignored build inputs may become inaccessible. Move necessary nonsecret inputs to a reviewed location rather than allowing the entire credentials directory. Logout removes local stored credentials; do not assume it invalidates all copies of a stolen token—coordinate revocation with the administrator/vendor.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | AC-3; AC-6 | Access enforcement; least privilege |

## 5. Extension Review

### 5.1 Review Plugins and Hooks

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST 800-53 | CM-6, AC-6 |

#### Description

Approve plugin sources and dependencies, pin reviewed releases where supported, and inspect lifecycle hooks before trusting a workspace. Use enterprise managed manifests for mandatory plugin policy. [Plugin governance](https://docs.devin.ai/cli/extensibility/plugins/overview) and [hooks](https://docs.devin.ai/cli/extensibility/hooks/overview).

#### Rationale

**Why This Matters:**
- Plugins can bring instructions, hooks, MCP integrations, and further dependencies.
- A failed security hook is not necessarily a blocked operation.

**Attack Prevented:** Unreviewed extension supply chains and accidental reliance on fail-open guardrails.

#### Prerequisites

An approved inventory; administrator access for managed manifests; a disposable pilot with no production credentials.

#### ClickOps Implementation

1. Review each source and dependency before installation. Avoid bypassing the plugin trust prompt or automatically updating unreviewed floating revisions.
2. Open **Customize → Plugins**, select the **Enterprise** or **Organization** scope, then **Plugin settings (gear) → Edit manifest**. Preserve mandatory approved dependencies before applying a restrictive manifest. [Web plugin administration](https://docs.devin.ai/product-guides/plugins).
3. Use the pack as a deny-all starting template, adding approved sources at the **same scope** to `optionalPlugins` or `requiredPlugins`. Prefer exact `sha` pins rather than floating `ref` entries when release review is required.
4. Before launching an unfamiliar checkout, inspect `.devin/hooks.v1.json` and hooks in native/imported config. In an already-trusted session, `/hooks` shows loaded sources.

#### Code Implementation

The CLI inventory never installs, updates, or removes a plugin. The native managed-manifest template is not a `system.json` policy and is not automatically applied. A local manifest cannot stand in for enterprise control.

{% include pack-code.html vendor="devin-cli" section="5.1" %}

#### Validation & Testing

On the pilot, verify that an unapproved plugin is blocked and a pinned approved dependency resolves as intended. Test hook failures deliberately with harmless fixtures: command-hook exit `2` blocks; other nonzero exits, timeouts, or unreadable output do not. Plugin hooks are documented as best effort, and failure to fetch a managed manifest leaves that level unenforced for that session. Use independent endpoint/permission controls for mandatory boundaries.

**Operational impact and rollback:** restrictive manifests can hide useful skills. Restore the prior reviewed manifest or add the exact approved dependency; never treat a fetch failure as a successful policy evaluation.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|-----------|------------|--------------|
| NIST 800-53 Rev. 5 | CM-6; AC-6 | Configuration settings; least privilege |

## 6. Compliance Quick Reference

These are implementation relationships, not a product-specific benchmark or a certification claim. No Devin CLI-specific CIS Benchmark, DISA STIG, CISA SCuBA, NSA, or ACSC baseline was identified in the documentation/search sweep on 2026-10-29. The control values here are HTH recommendations tied to documented vendor capabilities.

| NIST 800-53 Rev. 5 control | Guide controls |
|--------------------------|----------------|
| AC-3 — Access Enforcement | 1.1, 1.2, 2.2, 3.1, 4.1 |
| AC-6 — Least Privilege | 1.2, 2.1, 3.1, 4.1, 5.1 |
| CM-6 — Configuration Settings | 1.1, 2.1, 2.2, 3.2, 5.1 |

## Appendix A: Compatibility & Control Boundaries

| Surface | Applicability and limitation |
|---------|-----------------------------|
| Enterprise authentication | Official enterprise-auth guide requires Devin Enterprise and the **Use Devin CLI** role permission. Configure that role through the Cognition hub. |
| Team enforcement | Devin Enterprise or supported legacy Windsurf Enterprise settings; only settings explicitly listed for CLI apply. |
| macOS/Linux local configuration | User config under `~/.config/devin`; machine-wide `system.json` paths differ by OS. |
| Windows local configuration | User config under `%APPDATA%\devin`; sandbox Required currently prevents native Windows sessions. |
| Sandbox network filtering | Documented as unstable; no egress-isolation assurance is claimed by these packs. |
| MCP file layout | Dedicated `mcp_config.json` since v3000.3; older layouts migrate at startup. |
| Project config | General reference lists permissions/imports/hooks; plugin documentation additionally defines governance keys. Do not assume all user-level fields work in project scope. |
| Cloud handoff, sharing, models | Apply cloud access/sharing controls from the hub; review CLI-specific model allowlists separately. Disabling web search does not disable reading specific URLs. |

## Appendix B: Automation Surface Census

All eight controls have a native-config or first-party CLI pack. Two implementation types are used. The included scripts are standalone, default read-only/dry-run, and require explicit flags for local changes or session launches. JSON templates are inert until manually merged or pasted.

| Surface | Documented scope and disposition |
|---------|----------------------------------|
| Terraform | Cognition's cloud provider does not substitute for endpoint policy; no local CLI setting resource/data source is claimed here. Cloud resources are handled by the hub. |
| REST / GraphQL | Reviewed local CLI/team-setting docs describe no REST/GraphQL setter for these local policies. No guessed endpoint is shipped. |
| First-party CLI | `devin auth status`, inventory commands, explicit MCP disabling, and documented launch flags. Read-only inventory is not enforcement. |
| SDK | No official local-policy SDK is documented in the reviewed reference; none is used. |
| Config | `system.json`, scoped `config.json` fragments, Terminal Permissions JSON, and managed plugin manifests. Their different schemas must not be interchanged. |
| SIEM | No CLI event schema sufficient for a supported detection pack was established. Enterprise analytics and cloud audit logs are not proof of every local tool call. |

## Appendix C: References

All vendor references were fetched on 2026-10-29. Documentation verification is not live product validation.

- [System Configuration](https://docs.devin.ai/cli/enterprise/system-config)
- [Devin Auth](https://docs.devin.ai/cli/enterprise/devin-auth)
- [Team Settings](https://docs.devin.ai/cli/enterprise/team-settings)
- [Permissions](https://docs.devin.ai/cli/reference/permissions)
- [Configuration File](https://docs.devin.ai/cli/reference/configuration/config-file)
- [Configuration Precedence](https://docs.devin.ai/cli/reference/configuration/global-vs-local)
- [Configuration Import](https://docs.devin.ai/cli/reference/configuration/read-config-from)
- [Commands & Flags](https://docs.devin.ai/cli/reference/commands)
- [Sandbox](https://docs.devin.ai/cli/sandbox)
- [MCP Configuration](https://docs.devin.ai/cli/extensibility/mcp/configuration)
- [Plugins](https://docs.devin.ai/cli/extensibility/plugins/overview)
- [Hooks](https://docs.devin.ai/cli/extensibility/hooks/overview)
- [Local-agent Control Differences](https://docs.devin.ai/cli/enterprise/controls)
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-10-30 | 0.1.0 | ai-drafted | Initial eight-control local CLI guide; eleven config/CLI packs; offline fixtures and mocked dispatch only. | Codex |

## Contributing

Report corrections through [GitHub issues](https://github.com/grcengineering/how-to-harden/issues) or see the [contributing guide](/contributing/). Particularly useful evidence includes versioned endpoint-policy tests and enterprise-console verification without credentials or customer data.

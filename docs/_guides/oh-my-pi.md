---
layout: guide
title: "OhMyPi Hardening Guide"
vendor: "OhMyPi"
slug: "oh-my-pi"
tier: "3"
category: "AI/ML Platform"
description: "Harden OhMyPi configuration authority, execution boundaries, credentials, integrations, tool access and private verification."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-15"
---

## Overview

The can1357 OhMyPi fork, omp CLI, typed YAML configuration, approval modes, discovery, MCP, secret handling and session grants. These agents can expose source code, credentials and authenticated services to model-directed actions and third-party resources. Prioritize the authority available to the entire process, then restrict loading and individual tools.

### Intended Audience

Security engineers, platform teams, IT administrators and responders governing developer or automation agents.

### How to Use This Guide

- **L1 (Crawl):** Establish identity, conservative configuration, scoped credentials and private verification.
- **L2 (Walk):** Add whole-process isolation and externally enforced network restrictions for untrusted input.
- **L3 (Run):** Require independent evidence and change review for regulated deployments; this guide does not assert certification.

### Scope

The can1357 OhMyPi fork, omp CLI, typed YAML configuration, approval modes, discovery, MCP, secret handling and session grants. Pi.dev-specific flags/settings, unverified organization policy APIs and generic infrastructure implementation are outside scope. General OS hardening remains with your existing baseline. Isolation references here describe the agent-specific trust boundary, not a new host deployment recipe.

### Research and validation boundary

Source and release checks were performed on 2026-11-15; the candidate is restricted to **18.20.2**. See the [source-first candidate and surface ledger](/research/agent-source-coverage-2026-11) for exact upstream commits, discovery gaps and evidence limits. This is documentation research plus offline hostile-input/native-schema/mock-CLI testing. **No live agent/tenant was hardened, no device settings changed, and no live-validation status earned.**

The [Code Pack](https://github.com/grcengineering/how-to-harden/tree/main/packs/oh-my-pi) generates candidates and non-executing launch plans, compares explicit files and provides opt-in native reads. It does not install policy, provide a sandbox or compute complete effective state. All default operations are local/read-only or stdout-only. Native diagnostic execution is separate and explicit. Do not evaluate launch JSON as shell code.

## Table of Contents

1. [Identity and Configuration Authority](#1-identity-and-configuration-authority)
2. [Execution and Network Boundaries](#2-execution-and-network-boundaries)
3. [Credentials and Integrations](#3-credentials-and-integrations)
4. [Tool and Data Restrictions](#4-tool-and-data-restrictions)
5. [Monitoring and Verification](#5-monitoring-and-verification)
6. [Compliance Quick Reference](#6-compliance-quick-reference)
7. [Appendices](#7-appendices)

## 1. Identity and Configuration Authority

### 1.1 Identify OhMyPi and pin its own release

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | SI-2, CM-8 |

#### Description

OhMyPi is `can1357/oh-my-pi`, distributed as `@oh-my-pi/pi-coding-agent` with the `omp` CLI. It is a Pi fork with its own settings, approval and discovery contracts. This candidate targets 18.20.2; Pi.dev settings or security-version floors must not be transplanted.

**Source:** [Official configuration/security reference](https://github.com/can1357/oh-my-pi/blob/v18.20.2/README.md), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Look-alike packages and stale examples can introduce a different trust model.
- Release-sensitive controls can be silently ignored on unsupported builds.

**Attack Prevented:** Supply-chain substitution and reliance on unavailable safeguards.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Open **can1357/oh-my-pi → Releases → v18.20.2** and reconcile the executable, package and bundled runtime with your inventory.
2. Review the release’s approval/settings changes and source/package provenance before rollout. A package version does not attest every bundled dependency.
3. Use your existing approved deployment route; no install or update script is required to inspect these packs.

#### Code Implementation

The first-party CLI version read previews by default; an explicit opt-in is required to invoke the selected binary.

{% include pack-code.html vendor="oh-my-pi" section="1.1" %}

#### Validation & Testing

Preview the fixed `--version` read and opt in only on the reviewed executable. Reject an unrecognized output or a different version until sources and tests are reconciled.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Updates may change settings schemas, discovery and persistent state. Preserve approved compatible state and artifact versions for recovery.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | SI-2, CM-8 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

### 1.2 Use a protected final overlay and inspect precedence

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | CM-6, AC-3 |

#### Description

Start with the reviewed `config.yml` baseline and pass a protected `--config` overlay after any other overlays. Project settings override global settings, overlays override project settings, and environment/runtime overrides can still outrank overlays. This is launch governance, not native user-immutable organization policy.

**Source:** [Official configuration/security reference](https://github.com/can1357/oh-my-pi/blob/v18.20.2/docs/settings.md), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Agent-writable configuration can undo a carefully reviewed baseline.
- Higher-precedence sources and fail-open parsing can change effective policy.

**Attack Prevented:** Configuration tampering and privilege expansion through lower-trust inputs.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Review **Settings → Precedence / One-shot overlays** and the active agent directory, normally `~/.omp/agent`.
2. Store the approved overlay outside the agent-writable project/state and keep launch arguments/environment controlled. A missing or invalid overlay is a hard error, while other live config layers can retain last-good values after invalid reloads.
3. Common supported fields appear in `/settings`; use the source-backed file/CLI route for the complete schema. Check the effective source instead of assuming a saved global value won.

#### Code Implementation

Candidate output only; review and deploy through your approved change process. The 4.1/4.2 outputs are fragments, while 1.2 is the complete restrictive baseline.

{% include pack-code.html vendor="oh-my-pi" section="1.2" %}

#### Validation & Testing

Compare the overlay offline, then privately inspect `omp config get <key> --json` and its effective layer. Test a conflicting harmless project field and an unauthorized runtime override in a disposable launch environment.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

A strict final overlay can interrupt existing workflows. Redeploy an approved prior overlay and restart as needed; do not edit global arrays assuming they remain additive.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | CM-6, AC-3 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

## 2. Execution and Network Boundaries

### 2.1 Limit the entire process and its discovery roots

**Profile Level:** L2 (Walk)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-6, SC-39 |

#### Description

Approval modes regulate tool dispatch; approved commands and loaded extensions still use the process’s OS authority. Use an external whole-process boundary for untrusted work and limit host files, sockets, credentials and network services. A state-directory selector or project cwd does not provide isolation.

**Source:** [Official configuration/security reference](https://github.com/can1357/oh-my-pi/blob/v18.20.2/docs/config-usage.md), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Prompt injection can steer any capability the process can reach.
- Tool-level safeguards do not contain every extension or subprocess path.

**Attack Prevented:** Host credential theft and cross-workspace effects from untrusted content.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Review **Configuration Discovery → Config roots** for `.omp`, `.claude`, `.codex` and `.gemini`, including user, profile and project sources.
2. Prepare an approved isolated process environment with a dedicated home/state and no privileged host sockets. Keep the final overlay outside writable mounts.
3. Inspect the launch plan: it selects `read`, disables extension/skill/LSP discovery and supplies a fixed approval mode. It does not execute, install the boundary or remove arbitrary user/project resources by itself.

#### Code Implementation

This produces a plan only. It does not create or attest the external isolation boundary.

{% include pack-code.html vendor="oh-my-pi" section="2.1" %}

#### Validation & Testing

Test a harmless host path and unapproved destination from permitted execution and extension paths in a disposable environment. Verify OS denials. Keep native user MCP state and foreign discovery absent or separately reviewed.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Isolation and disabled discovery can break project tools. Approve the minimum task resources and test the same boundaries after every exception.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | AC-6, SC-39 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

### 2.2 Keep network and browser automation within approved scope

**Profile Level:** L2 (Walk)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | SC-7, AC-6 |

#### Description

An approved bash, eval, browser or computer call may reach external/internal services with process privileges. Enforce egress externally and keep unnecessary local relays/services disabled. Loopback services and shared browser profiles still expose authority to same-user processes.

**Source:** [Official configuration/security reference](https://github.com/can1357/oh-my-pi/blob/v18.20.2/docs/approval-mode.md), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Agent listeners and outbound services expose real execution authority.
- A proxy or loopback default alone does not prove all traffic is constrained.

**Attack Prevented:** Unauthorized remote actions and exfiltration through overlooked network paths.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Review the approved process network policy and the exact browser/computer capabilities needed for the task.
2. Keep `tools.approval.browser`, `computer` and `computer.control` denied in the review profile. `computer.control` is a separate foreground-control grant, not implied by the general computer policy.
3. Inspect local listener and relay exposure privately; use a dedicated browser profile only if a separately approved task requires it. Do not treat TLS/proxy preferences as network containment.

#### Code Implementation

**Verification pack:** a bounded local check, not an enforcement operation or effective-policy attestation. See the pack README for exact inputs, output and omissions.

{% include pack-code.html vendor="oh-my-pi" section="2.2" %}

#### Validation & Testing

Run harmless blocked-destination and tool-unavailability checks in the isolated test context. The calling-process environment audit checks selected unsafe TLS variables only; it does not scan listeners or attest network enforcement.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Disabling browser/computer actions removes convenience. Re-enable exact capabilities only in an approved profile with limited browser/account state.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | SC-7, AC-6 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

## 3. Credentials and Integrations

### 3.1 Separate model routing, discovery and credential access

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-6, IA-5 |

#### Description

`enabledProviders` opts foreign configuration sources into discovery; it is not a model-provider allowlist. `disabledProviders` gates model providers and discovery sources in a shared namespace, using distinct IDs. Defaults, model filters and empty discovery arrays cannot enforce exclusive inference routing.

**Source:** [Official configuration/security reference](https://github.com/can1357/oh-my-pi/blob/v18.20.2/docs/settings.md), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Ambient credentials enlarge the impact of one hostile tool or resource.
- Model selection and a successful login do not prove approved account scope.

**Attack Prevented:** Credential misuse and unauthorized provider or internal-service access.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Read **Settings → Provider and source disabling** and inventory actual model provider IDs separately from discovery source IDs such as `claude`.
2. Review exact approved endpoints/accounts and use external credential/egress restrictions. A project array replaces the global `disabledProviders` array; include the full intended list in the authoritative overlay if using it.
3. Keep unrelated auth stores and environment credentials out of the process. Check selectors such as `CLAUDE_CONFIG_DIR`, which can opt a foreign user root into discovery outside the empty-list default.

#### Code Implementation

**Verification pack:** a bounded local check, not an enforcement operation or effective-policy attestation. See the pack README for exact inputs, output and omissions.

{% include pack-code.html vendor="oh-my-pi" section="3.1" %}

#### Validation & Testing

Use dummy credentials to verify unapproved model routes are unavailable and foreign roots remain unconsumed. The environment pack checks selected ambient credential signals only; it does not inspect the auth database/broker or prove a provider allowlist.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Disabling a provider/source can remove models and imported resources. Review exact IDs and restart/re-discover as documented; never assume the two namespaces are identical.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | AC-6, IA-5 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

### 3.2 Control MCP and executable resources at every root

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | CM-7, SR-3 |

#### Description

Disable project MCP config and skill discovery for a restricted review profile, and review native user MCP servers, extensions, hooks and foreign configuration sources separately. `mcp.enableProjectConfig: false` does not disable user servers. MCP tool approval uses the exact final registered tool name; wildcard map keys are not asserted here.

**Source:** [Official configuration/security reference](https://github.com/can1357/oh-my-pi/blob/v18.20.2/docs/mcp-config.md), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Resources can introduce executable code, instructions and persistent access.
- Workspace inspection alone misses user, profile and system discovery roots.

**Attack Prevented:** Supply-chain execution and unauthorized third-party tool access.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Inspect **MCP config** and **Configuration Discovery → Config roots** using the approved manifest.
2. Retain the candidate’s `mcp.enableProjectConfig: false`, `skills.enabled: false` and empty foreign-source opt-in list. The plan additionally disables extensions/skills/LSP and selects only the native read tool.
3. Check global/profile state and project roots, including `.mcp.json`, `mcp.json` and WATCHDOG files. The inventory reads only known top-level metadata and never executes package or hook code.

#### Code Implementation

**Verification pack:** a bounded local check, not an enforcement operation or effective-policy attestation. See the pack README for exact inputs, output and omissions.

{% include pack-code.html vendor="oh-my-pi" section="3.2" %}

#### Validation & Testing

Use a harmless project MCP entry and extension to verify they do not load in the restricted profile; independently verify native user servers and any discovery overrides. MCP tools declare write tier regardless of their annotations, so do not trust a “read-only” label as enforcement.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Resource lockdown can disable assistant workflows. Add a reviewed resource only to a separate approved profile and retest its credentials and tool policies.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | CM-7, SR-3 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

## 4. Tool and Data Restrictions

### 4.1 Replace default YOLO and deny alternate execution paths

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-3, CM-7 |

#### Description

Set `tools.approvalMode: always-ask-cached` and explicit per-tool denies for bash, eval, task, browser, computer and foreground control in the restrictive review profile. The default mode is YOLO. `--auto-approve`/`--yolo` can force YOLO even alongside an approval-mode flag, though explicit denies remain enforced.

**Source:** [Official configuration/security reference](https://github.com/can1357/oh-my-pi/blob/v18.20.2/docs/approval-mode.md), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Alternate execution paths can bypass a narrowly configured tool rule.
- Headless behavior and explicit overrides differ from interactive defaults.

**Attack Prevented:** Unapproved mutation, execution and delegation by an injected instruction.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Review **Tool approval mode → Modes / User overrides** and preserve the generated per-tool deny map.
2. If separately authorizing execution, require explicit `prompt` or `deny` policies for both bash and eval. Bash patterns do not constrain shells launched by eval; restrictedFolders checks a no-target shell’s cwd, not file paths in command text.
3. Deny `task` unless delegation is approved. Headless subagents run in YOLO; parent task approval and explicit per-tool policies are the relevant gates, and headless prompts cannot be answered.

#### Code Implementation

Candidate output only; review and deploy through your approved change process. The 4.1/4.2 outputs are fragments, while 1.2 is the complete restrictive baseline.

{% include pack-code.html vendor="oh-my-pi" section="4.1" %}

#### Validation & Testing

Use harmless fixture calls to check each denied capability and a headless child. Test direct eval as well as bash. Reject unauthorized runtime YOLO flags at the protected launch entrypoint.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Explicit denials remove execution and delegation. Introduce narrowly reviewed prompts only in an isolated task profile; do not rely on remembered grants as an organization control.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | AC-3, CM-7 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

### 4.2 Enable secret obfuscation and govern telemetry/state

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-4, AU-9 |

#### Description

Enable `secrets.enabled` and disable `telemetry.otlpExportEnabled` unless approved export is required. Secret obfuscation is opt-in and covers configured/built-in token patterns before provider requests; it does not guarantee removal from local files, transcripts, terminals, extensions or all outbound paths.

**Source:** [Official configuration/security reference](https://github.com/can1357/oh-my-pi/blob/v18.20.2/packages/coding-agent/src/secrets/settings.ts), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Source, tokens and session evidence can escape through several paths.
- Convenience features and heuristic filtering leave residual exposure.

**Attack Prevented:** Sensitive-data disclosure and reuse of retained authority or context.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Review **Settings → Secret obfuscation** and [**Privacy → OTLP Telemetry Export**](https://github.com/can1357/oh-my-pi/blob/v18.20.2/packages/coding-agent/src/telemetry-settings.ts); use the generated source-backed keys.
2. Keep secrets out of committed overlays and inspect any configured OTEL exporter endpoints privately. Telemetry export changes apply on next launch.
3. Protect auth/session/approval-cache state and exports in the dedicated agent directory. In **Ask and remember**, avoid persistent grants for untrusted work and use the documented `/forget-approvals` workflow when deliberately clearing them.

#### Code Implementation

Candidate output only; review and deploy through your approved change process. The 4.1/4.2 outputs are fragments, while 1.2 is the complete restrictive baseline.

{% include pack-code.html vendor="oh-my-pi" section="4.2" %}

#### Validation & Testing

Audit candidate values, then test synthetic token markers through actual permitted provider paths in a disposable environment. Verify restart removes unwanted exporter initialization; a candidate audit cannot prove historical exports or stored transcripts were erased.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Redaction can alter prompts and disabling telemetry reduces observability. Retain sanitized security evidence through an approved separate channel and review any required exporter exception.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | AC-4, AU-9 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

## 5. Monitoring and Verification

### 5.1 Compare candidates and inspect effective typed settings

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | CM-6, CA-7 |

#### Description

Compare the complete candidate with the reviewed baseline, including ordered arrays, nested maps and value types. Reconcile live effective values and their layers after restart/reload; saving a global key may leave a project, overlay, environment or runtime override in control.

**Source:** [Official configuration/security reference](https://github.com/can1357/oh-my-pi/blob/v18.20.2/docs/settings.md), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Syntactically valid configuration can still be ignored or overridden.
- A file-only check cannot attest a running process or its external boundary.

**Attack Prevented:** Silent policy drift and false confidence from incomplete verification.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Run the candidate audit against strict JSON or restricted YAML. No arbitrary YAML tags, aliases, duplicate keys or unreviewed extra fields are accepted.
2. Review effective `tools.approvalMode`, the explicit per-tool policies, `mcp.enableProjectConfig`, secret handling and telemetry state using the native typed configuration interface.
3. Inspect reload warnings and any retained last-good layer. Runtime settings can outrank the final overlay; protect launch and SDK entrypoints externally.

#### Code Implementation

**Verification pack:** a bounded local check, not an enforcement operation or effective-policy attestation. See the pack README for exact inputs, output and omissions.

{% include pack-code.html vendor="oh-my-pi" section="5.1" %}

#### Validation & Testing

Offline tests widen approval maps, alter booleans and inject malformed/ambiguous YAML. Separate native fixture checks should verify actual precedence and headless refusal before deployment; none was executed against a live OhMyPi app here.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Strict comparison intentionally rejects custom fields until reviewed. Update source evidence and regression fixtures with a deliberate baseline change instead of ignoring the result.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | CM-6, CA-7 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

### 5.2 Review private diagnostics and expire remembered authority

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AU-6, AU-9 |

#### Description

Monitor effective approval policies, loaded resources, auth/telemetry changes and remembered grants. Native diagnostic completion is not an effective-policy pass. Persistent grants can survive across sessions in `approval-cache.db`, so session changes alone may not remove authority.

**Source:** [Official configuration/security reference](https://github.com/can1357/oh-my-pi/blob/v18.20.2/docs/approval-mode.md), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Diagnostics and session evidence may themselves contain secrets.
- Recovery must account for retained processes, grants and external effects.

**Attack Prevented:** Persistent unauthorized access and secondary disclosure during response.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Preview the fixed native `config get` reads and opt into execution only in the approved isolated context. The wrapper suppresses raw native output.
2. Review `/settings` and **Tool approval mode → Ask and remember** privately for current grant lifetime and loaded resources.
3. Rehearse stopping the affected process, clearing approvals through the documented operator command and reviewing child processes/upstream grants before restart. No deletion or revocation is automated by this pack.

#### Code Implementation

Native reads preview by default. `--execute` is available only for the fixed diagnostic commands, never remediation; completion is not reported as a policy pass.

{% include pack-code.html vendor="oh-my-pi" section="5.2" %}

#### Validation & Testing

Use harmless fixtures to compare before/after grants and denied tools. Confirm explicit denies remain active in headless execution and record release, overlay hash and test date without publishing transcripts or account data.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Expiring remembered authority adds prompts and may stop jobs. Restore only a reviewed task profile; do not restore a broad grant database to resolve an approval failure.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | AU-6, AU-9 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

## 6. Compliance Quick Reference

These are suggested control relationships against the [NIST SP 800-53 Rev. 5 catalog](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final), not a product benchmark or certification. Bounded searches did not identify a product-specific CIS/SCuBA baseline; DISA coverage remains unverified. No invented benchmark IDs or edition guarantees are used.

| Objective | Guide controls | Evidence to retain privately |
|---|---|---|
| Asset identity and configuration | 1.1, 1.2, 5.1 | Exact build, approved artifact hash, actual source/precedence and drift result |
| Least privilege and information flow | 2.1–4.2 | Task mounts/credentials, external network/OS denies, effective resources and harmless negative tests |
| Monitoring and response | 5.2 | Sanitized diagnostic outcomes, grant/session review and recovery test |

## 7. Appendices

### Deployment and capability matrix

| Surface | Applicability and limits |
|---|---|
| Reviewed product release | 18.20.2; other versions require explicit source reconciliation |
| Local configuration and CLI | Candidate generation/comparison and fixed opt-in native reads; no automatic deployment |
| Whole-process boundary | Supplied by your approved external environment; the launch plan is not a sandbox |
| Tenant identity/SSO | Apply upstream provider/account controls separately; no unverified tenant API is fabricated |
| API/SDK/Terraform/SIEM | See the surface census; available operational APIs are not assumed to expose policy administration |
| Validation maturity | `ai-drafted`; source, schema and fixture checks are not live or human review |

### Integration Risk Assessment Matrix

| Integration | Principal exposure | Admission requirement |
|---|---|---|
| Model provider | Source and inference credentials | Approved endpoint/account, retention terms and restricted credential/egress scope |
| MCP server | Tool authority, remote data and subprocess credentials | Reviewed command/endpoint, exact tool scope and independent process boundary |
| Extension/plugin/skill | Startup code or instructions with process authority | Reviewed source/version, discovery roots, credentials and persistence |
| Browser/remote API | Authenticated actions or remote execution | Task-specific account, restricted ingress and explicit capability admission |

### References

- [First-party reference](https://github.com/can1357/oh-my-pi/blob/v18.20.2/README.md)
- [First-party reference](https://github.com/can1357/oh-my-pi/blob/v18.20.2/docs/settings.md)
- [First-party reference](https://github.com/can1357/oh-my-pi/blob/v18.20.2/docs/config-usage.md)
- [First-party reference](https://github.com/can1357/oh-my-pi/blob/v18.20.2/docs/approval-mode.md)
- [First-party reference](https://github.com/can1357/oh-my-pi/blob/v18.20.2/docs/mcp-config.md)
- [First-party reference](https://github.com/can1357/oh-my-pi/blob/v18.20.2/packages/coding-agent/src/secrets/settings.ts)
- [Source coverage, automation census and release pins](/research/agent-source-coverage-2026-11)
- [Code Pack usage and evidence limits](https://github.com/grcengineering/how-to-harden/tree/main/packs/oh-my-pi)

## Changelog

| Date | Version | Maturity | Changes | Author |
|---|---|---|---|---|
| 2026-11-15 | 0.1.0 | ai-drafted | Initial source-backed guide and version-gated candidate, audit, inventory and native-read packs; offline fixtures only. | Codex (GPT-6) |

## Contributing

Report corrections with the exact release, first-party source and a sanitized reproduction. Follow [CONTRIBUTING.md](https://github.com/grcengineering/how-to-harden/blob/main/CONTRIBUTING.md). Keep credentials and private agent/tenant evidence out of public issues and pull requests.

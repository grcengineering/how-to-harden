---
layout: guide
title: "Hermes Agent Hardening Guide"
vendor: "Hermes Agent"
slug: "hermes"
tier: "3"
category: "AI/ML Platform"
description: "Harden Hermes Agent configuration authority, execution boundaries, credentials, integrations, tool access and private verification."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-15"
---

## Overview

Nous Research Hermes Agent CLI/gateway, managed scope, dangerous-command approvals, MCP/plugins/skills, API/dashboard exposure and local state. These agents can expose source code, credentials and authenticated services to model-directed actions and third-party resources. Prioritize the authority available to the entire process, then restrict loading and individual tools.

### Intended Audience

Security engineers, platform teams, IT administrators and responders governing developer or automation agents.

### How to Use This Guide

- **L1 (Crawl):** Establish identity, conservative configuration, scoped credentials and private verification.
- **L2 (Walk):** Add whole-process isolation and externally enforced network restrictions for untrusted input.
- **L3 (Run):** Require independent evidence and change review for regulated deployments; this guide does not assert certification.

### Scope

Nous Research Hermes Agent CLI/gateway, managed scope, dangerous-command approvals, MCP/plugins/skills, API/dashboard exposure and local state. The Hermes model family, hosted-business contractual controls and generic infrastructure hardening are outside scope. General OS hardening remains with your existing baseline. Isolation references here describe the agent-specific trust boundary, not a new host deployment recipe.

### Research and validation boundary

Source and release checks were performed on 2026-11-15; the candidate is restricted to **0.23.1**. See the [source-first candidate and surface ledger](/research/agent-source-coverage-2026-11) for exact upstream commits, discovery gaps and evidence limits. This is documentation research plus offline hostile-input/native-schema/mock-CLI testing. **No live agent/tenant was hardened, no device settings changed, and no live-validation status earned.**

The [Code Pack](https://github.com/grcengineering/how-to-harden/tree/main/packs/hermes) generates candidates and non-executing launch plans, compares explicit files and provides opt-in native reads. It does not install policy, provide a sandbox or compute complete effective state. All default operations are local/read-only or stdout-only. Native diagnostic execution is separate and explicit. Do not evaluate launch JSON as shell code.

## Table of Contents

1. [Identity and Configuration Authority](#1-identity-and-configuration-authority)
2. [Execution and Network Boundaries](#2-execution-and-network-boundaries)
3. [Credentials and Integrations](#3-credentials-and-integrations)
4. [Tool and Data Restrictions](#4-tool-and-data-restrictions)
5. [Monitoring and Verification](#5-monitoring-and-verification)
6. [Compliance Quick Reference](#6-compliance-quick-reference)
7. [Appendices](#7-appendices)

## 1. Identity and Configuration Authority

### 1.1 Identify Nous Research Hermes Agent and pin its release

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | SI-2, CM-8 |

#### Description

This guide covers Nous Research `hermes-agent`, not the Hermes model family or an unrelated package named Hermes. The candidate is tied to v0.23.1 and its release documentation; verify the deployed gateway/agent as well as the CLI.

**Source:** [Official configuration/security reference](https://hermes-agent.nousresearch.com/docs/user-guide/cli), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Look-alike packages and stale examples can introduce a different trust model.
- Release-sensitive controls can be silently ignored on unsupported builds.

**Attack Prevented:** Supply-chain substitution and reliance on unavailable safeguards.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Open **NousResearch/hermes-agent → Releases → v0.23.1** and reconcile the source/package identity with your inventory.
2. Check the exact executable and the gateway’s deployed revision; preserve a known-good configuration and image digest.
3. Treat updates to plugins, skills, MCP servers and container images as separate supply-chain changes. Do not run an upstream installer merely to verify a version.

#### Code Implementation

The first-party CLI version read previews by default; an explicit opt-in is required to invoke the selected binary.

{% include pack-code.html vendor="hermes" section="1.1" %}

#### Validation & Testing

The version pack previews and optionally invokes only `--version` on an explicit binary. An unrecognized version fails. Confirm the running process separately; a local CLI version does not attest a remote gateway.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Version upgrades can alter config and approval behavior. Restore only an approved compatible build and config after reviewing state compatibility.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | SI-2, CM-8 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

### 1.2 Pin critical leaves through a protected managed scope

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | CM-6, AC-3 |

#### Description

Use administrator-owned `/etc/hermes/config.yaml` for security-critical leaves, with an administrator-fixed `HERMES_MANAGED_DIR` launch environment. Managed values override user config and the shell only for the keys they pin. A malformed managed file is logged and ignored, so effective-policy verification is mandatory.

**Source:** [Official configuration/security reference](https://hermes-agent.nousresearch.com/docs/user-guide/managed-scope), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Agent-writable configuration can undo a carefully reviewed baseline.
- Higher-precedence sources and fail-open parsing can change effective policy.

**Attack Prevented:** Configuration tampering and privilege expansion through lower-trust inputs.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Open **Managed Scope → Where it lives** and review the resolved managed directory in your deployment artifact.
2. Use your existing deployment mechanism to protect the directory and files from the agent identity. The documented modes are directory 0755 and files 0644; these packs do not change permissions.
3. Keep secrets out of the world-readable managed `.env`. Pin the bootstrap directory in the supervisor/container, not in a user-editable shell or `.env`. No graphical fleet-policy workflow was verified for these file settings.

#### Code Implementation

Candidate output only; review and deploy through your approved change process. The 4.1/4.2 outputs are fragments, while 1.2 is the complete restrictive baseline.

{% include pack-code.html vendor="hermes" section="1.2" %}

#### Validation & Testing

Compare the candidate, then inspect `hermes doctor` and `hermes config` privately for the resolved source/pinned keys. Test a harmless conflicting user setting. Verify malformed policy causes an alert and admission refusal in your launcher; Hermes itself continues without that policy.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Managed leaves constrain existing workflows but do not freeze unspecified keys or arbitrary subprocess behavior. Restore an approved managed artifact and restart to recover.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | CM-6, AC-3 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

## 2. Execution and Network Boundaries

### 2.1 Isolate the whole agent rather than only terminal tools

**Profile Level:** L2 (Walk)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-6, SC-39 |

#### Description

Hermes is a single-tenant personal agent. Its SECURITY.md treats OS isolation as the containment boundary. A Docker terminal backend confines shell/file tools, while the Python agent, execute_code host subprocesses, MCP, plugins, hooks and skill loading can remain outside that backend.

**Source:** [Official configuration/security reference](https://github.com/NousResearch/hermes-agent/blob/v0.23.1/SECURITY.md), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Prompt injection can steer any capability the process can reach.
- Tool-level safeguards do not contain every extension or subprocess path.

**Attack Prevented:** Host credential theft and cross-workspace effects from untrusted content.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Read **Security Policy → Whole-process wrapping** before accepting web/email/shared-channel input.
2. Place the complete Hermes process tree, including the selected gateway/backend, in an approved container/VM/sandbox; expose only task mounts and approved network services. Do not mount a developer home, Docker socket or production credential store.
3. Review the launch preview. Isolating only a client does not isolate a shared gateway executing elsewhere. The candidate’s `terminal.backend: docker` is only an additional shell/file boundary; it does not create whole-agent isolation, and backend images need their own approved version/digest.

#### Code Implementation

This produces a plan only. It does not create or attest the external isolation boundary.

{% include pack-code.html vendor="hermes" section="2.1" %}

#### Validation & Testing

Use disposable harmless files to test host and network reachability through terminal, code execution and a permitted MCP/plugin path independently. Verify the external boundary rather than inferring it from terminal backend selection.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Whole-process isolation may require redesigning credentials and state mounts. Recreate the approved environment instead of broadening host access to make a failing tool work.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | AC-6, SC-39 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

### 2.2 Deny open gateway and unauthenticated API access

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-3, SC-7 |

#### Description

Keep gateway access restricted to exact platform users or approved DM pairing. Never enable global allow-all on a work deployment. The API server exposes agent tools including terminal execution and requires `API_SERVER_KEY` even on loopback; narrow browser origins and use strong public-dashboard authentication.

**Source:** [Official configuration/security reference](https://hermes-agent.nousresearch.com/docs/user-guide/features/api-server), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Agent listeners and outbound services expose real execution authority.
- A proxy or loopback default alone does not prove all traffic is constrained.

**Attack Prevented:** Unauthorized remote actions and exfiltration through overlooked network paths.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Review **Security → User authorization (gateway)**: retain platform `*_ALLOWED_USERS`/pairing and `GATEWAY_ALLOW_ALL_USERS=false`; also check bridged `gateway.allow_all_users` values and secondary-profile environments.
2. If the API is required, keep `API_SERVER_HOST=127.0.0.1`, inject a strong `API_SERVER_KEY` and explicitly restrict `API_SERVER_CORS_ORIGINS`. Do not enable the API just to test this guide.
3. For a public dashboard follow [**Web Dashboard → Authentication**](https://hermes-agent.nousresearch.com/docs/user-guide/features/web-dashboard) with OAuth/OIDC. Username/password is for trusted networks; the agent API key and dashboard login are different boundaries.

#### Code Implementation

**Verification pack:** a bounded local check, not an enforcement operation or effective-policy attestation. See the pack README for exact inputs, output and omissions.

{% include pack-code.html vendor="hermes" section="2.2" %}

#### Validation & Testing

The environment audit flags open gateway, missing enabled-API key, non-loopback bind and wildcard CORS in its own environment only. In an authorized test context, deny an unknown user and unauthenticated API request, and inspect the real listeners/profile environments.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Narrowing access can disconnect bots and clients. Keep a separate operator access path and redeploy an approved roster; never recover by turning on allow-all.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | AC-3, SC-7 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

## 3. Credentials and Integrations

### 3.1 Minimize forwarded credentials and skill-declared access

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-6, IA-5 |

#### Description

Keep `terminal.env_passthrough`, `terminal.docker_forward_env` and `terminal.credential_files` empty unless a task explicitly requires them. Skill declarations can add required environment variables and credential files to sandbox access, so empty explicit arrays alone do not prove credentials are withheld.

**Source:** [Official configuration/security reference](https://hermes-agent.nousresearch.com/docs/user-guide/security), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Ambient credentials enlarge the impact of one hostile tool or resource.
- Model selection and a successful login do not prove approved account scope.

**Attack Prevented:** Credential misuse and unauthorized provider or internal-service access.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Inspect **Security → Skill environment passthrough / Credential files** and review every enabled skill’s `required_environment_variables` and `required_credential_files`.
2. Keep the candidate’s forwarding arrays empty; supply task-scoped, short-lived credentials only through an approved injection path. Do not place sensitive keys in managed `.env`.
3. Review MCP environment overrides, host subprocess reach, SSH-agent/socket access and external secret integrations. The calling-process audit is only a bounded signal, not a complete credential inventory.

#### Code Implementation

**Verification pack:** a bounded local check, not an enforcement operation or effective-policy attestation. See the pack README for exact inputs, output and omissions.

{% include pack-code.html vendor="hermes" section="3.1" %}

#### Validation & Testing

Use dummy markers to verify a denied credential is unavailable through shell, execute_code and MCP independently. Never print real environments, auth files or secret values as evidence.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Credential minimization can disable integrations. Grant the smallest task-specific access and repeat the isolated negative test after skill or plugin changes.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | AC-6, IA-5 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

### 3.2 Review executable plugins, MCP and persistent automation

**Profile Level:** L2 (Walk)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | CM-7, SR-3 |

#### Description

Treat user plugins, hook handlers, skills, MCP commands and scheduled jobs as persistent executable capabilities. Terminal-backend isolation does not contain their host code paths. Inventory and approve their source, version, credentials and triggers before enabling them.

**Source:** [Official configuration/security reference](https://hermes-agent.nousresearch.com/docs/user-guide/features/plugins), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Resources can introduce executable code, instructions and persistent access.
- Workspace inspection alone misses user, profile and system discovery roots.

**Attack Prevented:** Supply-chain execution and unauthorized third-party tool access.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Review the user Hermes home, plugin directory, profile skills, MCP definitions and scheduled jobs in your approved editor. Current gateway architecture discovers user plugins once, not per-project plugins.
2. Keep unapproved plugins disabled and inspect startup hooks and skill dependencies. A workspace-only inventory does not enumerate the actual user home or gateway state.
3. For MCP use the official reference’s trust/credential controls; retain approval for untrusted write-capable tools. Do not represent a tool label or trust setting as process containment.

#### Code Implementation

**Verification pack:** a bounded local check, not an enforcement operation or effective-policy attestation. See the pack README for exact inputs, output and omissions.

{% include pack-code.html vendor="hermes" section="3.2" %}

#### Validation & Testing

Compare the approved manifest with the effective tool/plugin/job inventory after restart. Test only harmless local fixtures; never connect to an unapproved remote MCP server to collect evidence.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Disabling a persistent integration can interrupt jobs. Suspend through the supported operator workflow and preserve a reviewed manifest; removing a workspace file does not revoke its upstream grants.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | CM-7, SR-3 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

## 4. Tool and Data Restrictions

### 4.1 Keep flagged-command approvals manual and headless paths denied

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-3, CM-7 |

#### Description

Set `approvals.mode: manual`, headless cron/single-query/unattended policies to deny, and narrow `approvals.approvers` to the requester/platform administrators with an empty list. Manual mode governs detected dangerous commands, not every tool call. Container backends can skip dangerous-command checks; the OS boundary remains essential.

**Source:** [Official configuration/security reference](https://hermes-agent.nousresearch.com/docs/user-guide/security), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Alternate execution paths can bypass a narrowly configured tool rule.
- Headless behavior and explicit overrides differ from interactive defaults.

**Attack Prevented:** Unapproved mutation, execution and delegation by an injected instruction.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. In the protected candidate, review `approvals` and preserve `mcp_reload_confirm` and `destructive_slash_confirm` as true.
2. Keep `command_allowlist` empty. Allowlist rules can override unattended denial; removing a remembered rule requires restart to clear in-memory decisions.
3. Reject unapproved `--yolo`, `/yolo`, `HERMES_YOLO_MODE` and `approvals.mode: off`. Review resumed sessions because session YOLO state can persist.

#### Code Implementation

Candidate output only; review and deploy through your approved change process. The 4.1/4.2 outputs are fragments, while 1.2 is the complete restrictive baseline.

{% include pack-code.html vendor="hermes" section="4.1" %}

#### Validation & Testing

With harmless fixtures, test a flagged local command, a headless deny and approval by an unapproved chat participant. Do not extrapolate those results to all commands or to a Docker terminal. Restart after approval-memory changes and repeat.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Headless tasks that need dangerous operations will fail and need redesign or a scoped operator action. Do not restore availability by enabling blanket approval.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | AC-3, CM-7 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

### 4.2 Redact output and protect session and checkpoint data

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-4, AU-9 |

#### Description

Retain `security.redact_secrets: true` and enable checkpoints for recoverable work. Redaction is a heuristic for output, not a DLP or credential boundary. Checkpoints, conversations, memory and skills are local data that can themselves contain sensitive source and tool output.

**Source:** [Official configuration/security reference](https://hermes-agent.nousresearch.com/docs/guides/secure-hermes-on-a-work-machine), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Source, tokens and session evidence can escape through several paths.
- Convenience features and heuristic filtering leave residual exposure.

**Attack Prevented:** Sensitive-data disclosure and reuse of retained authority or context.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Pin output redaction in the managed candidate and review the private Hermes state/checkpoint storage available to the process.
2. Use synthetic token-shaped fixtures to evaluate the redaction paths you actually use. Keep production keys outside prompts, files and shared evidence.
3. Enable checkpoints only in the approved state location; preview `/rollback diff` before any deliberate recovery. `HERMES_WRITE_SAFE_ROOT` constrains write_file/patch only and may block Hermes state writes unless the required state root is included.

#### Code Implementation

Candidate output only; review and deploy through your approved change process. The 4.1/4.2 outputs are fragments, while 1.2 is the complete restrictive baseline.

{% include pack-code.html vendor="hermes" section="4.2" %}

#### Validation & Testing

The candidate audit checks redaction/checkpoint values, not stored-data content, retention or successful restoration. In an authorized disposable environment, test a synthetic redaction and recovery; preserve the untouched original fixture for comparison.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Checkpoints consume storage and may retain deleted secrets. Apply a private retention policy and use reviewed recovery rather than automatic replay of old config.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | AC-4, AU-9 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

## 5. Monitoring and Verification

### 5.1 Check candidate drift and prove managed enforcement

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | CM-6, CA-7 |

#### Description

Treat missing or ignored managed policy as an admission failure in your deployment wrapper. The offline audit checks an explicit candidate file against the reviewed baseline; it does not emulate managed/user/environment merging or inspect a running gateway.

**Source:** [Official configuration/security reference](https://hermes-agent.nousresearch.com/docs/user-guide/managed-scope), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Syntactically valid configuration can still be ignored or overridden.
- A file-only check cannot attest a running process or its external boundary.

**Attack Prevented:** Silent policy drift and false confidence from incomplete verification.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Run the candidate audit before deployment and investigate every extra, missing or incorrectly typed key.
2. After restart, privately review `hermes doctor` and the managed header/pinned keys in `hermes config`.
3. Reconcile actual bootstrap paths, enabled resources and environment bridges with the approved deployment. Alert on parse warnings and unexpected changes rather than accepting startup as proof.

#### Code Implementation

**Verification pack:** a bounded local check, not an enforcement operation or effective-policy attestation. See the pack README for exact inputs, output and omissions.

{% include pack-code.html vendor="hermes" section="5.1" %}

#### Validation & Testing

Offline fixtures include malformed YAML, duplicate keys, aliases, unsafe types, nonempty command allowlists and widened approvers. Then test effective conflicting user settings in the isolated deployment; no such live proof was performed for this guide.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Strict comparison rejects customizations until reviewed. Preserve the approved baseline and update source evidence/tests with each accepted exception.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | CM-6, CA-7 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

### 5.2 Preserve private diagnostics and rehearse containment

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AU-6, AU-9 |

#### Description

Record version, managed sources, gateway authorization decisions and resource changes without publishing tokens or transcripts. The fixed native doctor command is an operator diagnostic; its zero exit code is not a security verdict.

**Source:** [Official configuration/security reference](https://hermes-agent.nousresearch.com/docs/user-guide/cli), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Diagnostics and session evidence may themselves contain secrets.
- Recovery must account for retained processes, grants and external effects.

**Attack Prevented:** Persistent unauthorized access and secondary disclosure during response.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Preview the native diagnostic pack and execute only in the approved test context; its output is intentionally suppressed.
2. Review raw doctor/config diagnostics privately and retain only sanitized rule outcomes, source/release identifiers and test dates.
3. For suspected compromise, use your operator response procedure to stop affected agent/gateway processes and persistent jobs, inspect whole-process access and revoke upstream grants as appropriate. No response action is automated here.

#### Code Implementation

Native reads preview by default. `--execute` is available only for the fixed diagnostic commands, never remediation; completion is not reported as a policy pass.

{% include pack-code.html vendor="hermes" section="5.2" %}

#### Validation & Testing

Rehearse with harmless fixtures and a synthetic unapproved user. Verify access is refused after containment and that retained jobs/sessions do not resume outside the approved boundary.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Stopping the gateway interrupts every dependent channel/profile. Coordinate recovery from the approved manifest and verify authorization again before reopening access.

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
| Reviewed product release | 0.23.1; other versions require explicit source reconciliation |
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

- [First-party reference](https://hermes-agent.nousresearch.com/docs/user-guide/cli)
- [First-party reference](https://hermes-agent.nousresearch.com/docs/user-guide/managed-scope)
- [First-party reference](https://github.com/NousResearch/hermes-agent/blob/v0.23.1/SECURITY.md)
- [First-party reference](https://hermes-agent.nousresearch.com/docs/user-guide/features/api-server)
- [First-party reference](https://hermes-agent.nousresearch.com/docs/user-guide/security)
- [First-party reference](https://hermes-agent.nousresearch.com/docs/user-guide/features/plugins)
- [First-party reference](https://hermes-agent.nousresearch.com/docs/guides/secure-hermes-on-a-work-machine)
- [Source coverage, automation census and release pins](/research/agent-source-coverage-2026-11)
- [Code Pack usage and evidence limits](https://github.com/grcengineering/how-to-harden/tree/main/packs/hermes)

## Changelog

| Date | Version | Maturity | Changes | Author |
|---|---|---|---|---|
| 2026-11-15 | 0.1.0 | ai-drafted | Initial source-backed guide and version-gated candidate, audit, inventory and native-read packs; offline fixtures only. | Codex (GPT-6) |

## Contributing

Report corrections with the exact release, first-party source and a sanitized reproduction. Follow [CONTRIBUTING.md](https://github.com/grcengineering/how-to-harden/blob/main/CONTRIBUTING.md). Keep credentials and private agent/tenant evidence out of public issues and pull requests.

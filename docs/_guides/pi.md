---
layout: guide
title: "Pi.dev Hardening Guide"
vendor: "Pi.dev"
slug: "pi"
tier: "3"
category: "AI/ML Platform"
description: "Harden Pi.dev configuration authority, execution boundaries, credentials, integrations, tool access and private verification."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-15"
---

## Overview

Earendil Pi coding agent CLI, project trust, resources/MCP, credentials, review-only tool selection and session handling. These agents can expose source code, credentials and authenticated services to model-directed actions and third-party resources. Prioritize the authority available to the entire process, then restrict loading and individual tools.

### Intended Audience

Security engineers, platform teams, IT administrators and responders governing developer or automation agents.

### How to Use This Guide

- **L1 (Crawl):** Establish identity, conservative configuration, scoped credentials and private verification.
- **L2 (Walk):** Add whole-process isolation and externally enforced network restrictions for untrusted input.
- **L3 (Run):** Require independent evidence and change review for regulated deployments; this guide does not assert certification.

### Scope

Earendil Pi coding agent CLI, project trust, resources/MCP, credentials, review-only tool selection and session handling. Unrelated Pi products, a fictional managed tenant API, generic container deployment and undocumented per-tool approval settings are outside scope. General OS hardening remains with your existing baseline. Isolation references here describe the agent-specific trust boundary, not a new host deployment recipe.

### Research and validation boundary

Source and release checks were performed on 2026-11-15; the candidate is restricted to **1.5.2**. See the [source-first candidate and surface ledger](/research/agent-source-coverage-2026-11) for exact upstream commits, discovery gaps and evidence limits. This is documentation research plus offline hostile-input/native-schema/mock-CLI testing. **No live agent/tenant was hardened, no device settings changed, and no live-validation status earned.**

The [Code Pack](https://github.com/grcengineering/how-to-harden/tree/main/packs/pi) generates candidates and non-executing launch plans, compares explicit files and provides opt-in native reads. It does not install policy, provide a sandbox or compute complete effective state. All default operations are local/read-only or stdout-only. Native diagnostic execution is separate and explicit. Do not evaluate launch JSON as shell code.

## Table of Contents

1. [Identity and Configuration Authority](#1-identity-and-configuration-authority)
2. [Execution and Network Boundaries](#2-execution-and-network-boundaries)
3. [Credentials and Integrations](#3-credentials-and-integrations)
4. [Tool and Data Restrictions](#4-tool-and-data-restrictions)
5. [Monitoring and Verification](#5-monitoring-and-verification)
6. [Compliance Quick Reference](#6-compliance-quick-reference)
7. [Appendices](#7-appendices)

## 1. Identity and Configuration Authority

### 1.1 Verify the current Earendil Pi coding agent

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | SI-2, CM-8 |

#### Description

Pi.dev is Mario Zechner’s Pi coding agent, now published by Earendil as `@earendil-works/pi-coding-agent` from `earendil-works/pi`. This pack targets 1.5.2. GHSA-mqxh-6gq7-558m affected versions below 0.79.0 and was fixed in 0.79.0; that historical floor is not this pack’s supported-version range.

**Source:** [Official configuration/security reference](https://github.com/earendil-works/pi/security/advisories/GHSA-mqxh-6gq7-558m), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Look-alike packages and stale examples can introduce a different trust model.
- Release-sensitive controls can be silently ignored on unsupported builds.

**Attack Prevented:** Supply-chain substitution and reliance on unavailable safeguards.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Open **earendil-works/pi → Releases → v1.5.2** and reconcile the package/executable identity with your inventory.
2. Read the first-party advisory and ensure the running version includes its project-extension startup fix. Do not substitute an unrelated package named pi.
3. Pin the approved artifact and dependencies through your existing software deployment process. No installation is needed to run the offline pack tests.

#### Code Implementation

The first-party CLI version read previews by default; an explicit opt-in is required to invoke the selected binary.

{% include pack-code.html vendor="pi" section="1.1" %}

#### Validation & Testing

Preview the native version read, then opt in on the exact reviewed binary. Reject older, prerelease and unreviewed newer versions and reconcile the actual runtime, not just package metadata.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Updates can change resource discovery and saved state. Keep the approved old build/state backup and review compatibility before rollback.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | SI-2, CM-8 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

### 1.2 Set conservative defaults in the controlled agent directory

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | CM-6, AC-6 |

#### Description

Place the candidate in the dedicated agent directory’s `settings.json`, selected by `PI_CODING_AGENT_DIR`. Set `defaultProjectTrust: never` there; project settings cannot supply that default. Resource lists and local discovery require additional controls, so empty configured arrays do not disable all resources.

**Source:** [Official configuration/security reference](https://docs.pi.dev/latest/configuration), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Agent-writable configuration can undo a carefully reviewed baseline.
- Higher-precedence sources and fail-open parsing can change effective policy.

**Attack Prevented:** Configuration tampering and privilege expansion through lower-trust inputs.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Review **Configure Pi → Files** and select a dedicated private agent directory rather than reusing a developer’s home state.
2. In an approved editor, review the generated settings and the directory’s `auth.json`, models, extensions, skills and package declarations. Common preferences are available in `/settings`; no fleet-managed, user-immutable policy GUI was verified.
3. Protect the launch command/state from the agent identity using the external execution environment. The native settings file alone is not an organization enforcement plane.

#### Code Implementation

Candidate output only; review and deploy through your approved change process. The 4.1/4.2 outputs are fragments, while 1.2 is the complete restrictive baseline.

{% include pack-code.html vendor="pi" section="1.2" %}

#### Validation & Testing

Compare the explicit candidate and review actual resource loading in an isolated fresh invocation. Confirm project trust is declined and the expected agent directory is used. Do not call a candidate match an effective settings result.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

A separate state directory requires deliberate authentication and resource setup. Recover from an approved state snapshot without importing the entire developer home.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | CM-6, AC-6 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

## 2. Execution and Network Boundaries

### 2.1 Wrap the whole Pi process for untrusted work

**Profile Level:** L2 (Walk)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-6, SC-39 |

#### Description

Pi has no built-in per-tool approval boundary or general sandbox. Extensions, package installers and other child processes inherit its account privileges. Use whole-process container/VM/sandbox isolation for hostile repositories. Gondolin routes tools into isolation while Pi and other extensions remain on the host and may retain host environment credentials.

**Source:** [Official configuration/security reference](https://docs.pi.dev/latest/containerization), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Prompt injection can steer any capability the process can reach.
- Tool-level safeguards do not contain every extension or subprocess path.

**Attack Prevented:** Host credential theft and cross-workspace effects from untrusted content.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Read **Run Pi safely → Choose how to run Pi** and **Isolate Pi → Choose an isolation method**.
2. Use an approved whole-process environment with only task files, state and narrowly scoped credentials. Do not copy a complete home or expose privileged sockets.
3. Inspect the fixed launch-plan JSON. It selects conservative resource flags but does not execute or configure Docker/OpenShell, filesystem mounts, user identity or egress.

#### Code Implementation

This produces a plan only. It does not create or attest the external isolation boundary.

{% include pack-code.html vendor="pi" section="2.1" %}

#### Validation & Testing

In an authorized disposable environment, prove a harmless host file and unapproved destination are inaccessible from Pi, extension code and child processes. Tool-only isolation does not prove the other paths are contained.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Isolation may require a new provider credential strategy. Adjust only required mounts/services and keep recovery outside the agent-accessible environment.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | AC-6, SC-39 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

### 2.2 Constrain network routes outside Pi

**Profile Level:** L2 (Walk)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | SC-7, SC-8 |

#### Description

Allow only required inference and approved integration destinations through the external environment. Pi’s `httpProxy` setting applies to Pi-managed HTTP clients, not every arbitrary shell, extension or child process. A proxy preference is therefore insufficient as an egress boundary.

**Source:** [Official configuration/security reference](https://docs.pi.dev/latest/settings), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Agent listeners and outbound services expose real execution authority.
- A proxy or loopback default alone does not prove all traffic is constrained.

**Attack Prevented:** Unauthorized remote actions and exfiltration through overlooked network paths.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Review **Settings → Network and retries** and configure an approved proxy only in agent-directory settings if needed.
2. Enforce network policy outside the agent process for all direct, DNS, metadata and private-service routes relevant to your environment. Preserve TLS verification.
3. Inspect background catalog/update, MCP and package traffic separately from inference. Use the calling-process environment audit as one bounded input, not a network enforcement result.

#### Code Implementation

**Verification pack:** a bounded local check, not an enforcement operation or effective-policy attestation. See the pack README for exact inputs, output and omissions.

{% include pack-code.html vendor="pi" section="2.2" %}

#### Validation & Testing

Test an approved inference route and a harmless denied destination from the isolated process. Inspect actual network enforcement records. No packet capture or native model request was run while authoring this guide.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Restrictive egress can break updates and models. Add only reviewed destinations; do not disable TLS to make a failing connection work.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | SC-7, SC-8 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

## 3. Credentials and Integrations

### 3.1 Keep credentials scoped and audit readiness without disclosure

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | IA-5, AC-6 |

#### Description

Pi resolves credentials from provider configuration, environment and saved authentication state. Supply only the approved task/provider identity and keep host SSH agents, cloud credentials and unrelated auth stores out of the process. Model defaults and cycling filters are not a credential or network security boundary.

**Source:** [Official configuration/security reference](https://docs.pi.dev/latest/cli), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Ambient credentials enlarge the impact of one hostile tool or resource.
- Model selection and a successful login do not prove approved account scope.

**Attack Prevented:** Credential misuse and unauthorized provider or internal-service access.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Inspect the dedicated agent directory and **CLI → Credential commands** using dummy fixtures first.
2. Use `auth check --json --no-refresh` for bounded readiness diagnostics; never add `--credentials`, `print-api-key` or `print-bearer-token` to audit scripts.
3. Review extensions and model configuration for executable credential sources and endpoints. The credential-environment pack reports selected ambient access without printing values.

#### Code Implementation

**Verification pack:** a bounded local check, not an enforcement operation or effective-policy attestation. See the pack README for exact inputs, output and omissions.

{% include pack-code.html vendor="pi" section="3.1" %}

#### Validation & Testing

Verify unapproved credentials are absent with dummy markers. Native readiness can fail because no credential was supplied; that is not permission to import a full auth store. The diagnostic wrapper reports completion only and suppresses raw results.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

A narrowly scoped identity may lack package/build access. Supply only what the approved task requires and review upstream account access separately.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | IA-5, AC-6 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

### 3.2 Disable implicit resources and built-in MCP for review

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | CM-7, SR-3 |

#### Description

Use fixed flags to disable discovered extensions, skills, prompt templates, context files, themes and built-in MCP for untrusted review. Explicit `-e`/`--extension` and `--skill` inputs can override discovery disabling, so an approved launcher must not forward arbitrary agent arguments.

**Source:** [Official configuration/security reference](https://docs.pi.dev/latest/packages), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Resources can introduce executable code, instructions and persistent access.
- Workspace inspection alone misses user, profile and system discovery roots.

**Attack Prevented:** Supply-chain execution and unauthorized third-party tool access.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Review **CLI → Resource options** and **Pi Packages → Select package resources** before enabling any package.
2. Retain `--no-extensions`, `--no-skills`, `--no-prompt-templates`, `--no-context-files`, `--no-themes` and `--no-mcp` in the reviewed launch plan.
3. Inventory `.pi`, `.agents` and known context files, including ancestors and user roots not covered by the top-level pack. An extension implementing its own MCP is not controlled by `--no-mcp`.

#### Code Implementation

**Verification pack:** a bounded local check, not an enforcement operation or effective-policy attestation. See the pack README for exact inputs, output and omissions.

{% include pack-code.html vendor="pi" section="3.2" %}

#### Validation & Testing

Use harmless project/user resource fixtures to verify none loads in the restricted invocation. Test that unapproved explicit extension/skill flags cannot enter your launcher. The supplied plan accepts only its own fixed interface and never launches an agent.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Resource-dependent workflows will stop. Enable only separately reviewed packages in a different approved execution profile and repeat discovery/credential tests.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | CM-7, SR-3 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

## 4. Tool and Data Restrictions

### 4.1 Use an explicit read-tool selection and remove MCP reach

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-3, CM-7 |

#### Description

For review tasks select only `read,grep,find,ls` and disable built-in MCP. Pi’s `--tools` list does not itself remove MCP reach unless MCP-specific selection/exclusion is used. These tools still read files with Pi’s OS permissions; read-only selection is not path containment.

**Source:** [Official configuration/security reference](https://docs.pi.dev/latest/cli), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Alternate execution paths can bypass a narrowly configured tool rule.
- Headless behavior and explicit overrides differ from interactive defaults.

**Attack Prevented:** Unapproved mutation, execution and delegation by an injected instruction.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Review **CLI → Tools / MCP tools** and the candidate’s plain-name `defaultTools` list.
2. Use the fixed launcher flags as well as conservative defaults. Do not use a list of only `+name`/`-name` changes as if it were an allowlist.
3. Keep shell, write, edit, powershell, codemode and extension tools unavailable for this review profile. Use a separate isolated coding profile if execution is authorized.

#### Code Implementation

Candidate output only; review and deploy through your approved change process. The 4.1/4.2 outputs are fragments, while 1.2 is the complete restrictive baseline.

{% include pack-code.html vendor="pi" section="4.1" %}

#### Validation & Testing

In an isolated fixture session inspect the actual tool list and attempt harmless shell/write/MCP calls; require them to be unavailable. Verify file access remains limited by the OS mounts, not by the tool names.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Read-only review cannot build or edit. Expand the profile only for approved tasks with independent execution and credential boundaries.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | AC-3, CM-7 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

### 4.2 Decline project trust and make session paths explicit

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-4, AU-9 |

#### Description

Use `--no-approve` to decline trust-gated project resources, `--no-context-files` to suppress context discovery, `--no-session` for ephemeral review, and an absolute `--session-dir` to override the initial project sessionDir lookup. Declining trust alone still allows AGENTS/CLAUDE context and occurs after that lookup.

**Source:** [Official configuration/security reference](https://docs.pi.dev/latest/security), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Source, tokens and session evidence can escape through several paths.
- Convenience features and heuristic filtering leave residual exposure.

**Attack Prevented:** Sensitive-data disclosure and reuse of retained authority or context.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Read **Run Pi safely → Understand project trust** and review any saved parent-directory trust decisions.
2. Retain the fixed command flags and a private absolute session directory. Project trust is a resource-loading decision, not approval for tool actions.
3. Treat any deliberately retained session JSONL, export or `/share` output as sensitive evidence. Do not share source-bearing transcripts or infer that ephemeral mode erases provider, extension or external logs.

#### Code Implementation

Candidate output only; review and deploy through your approved change process. The 4.1/4.2 outputs are fragments, while 1.2 is the complete restrictive baseline.

{% include pack-code.html vendor="pi" section="4.2" %}

#### Validation & Testing

Use a harmless project with a misleading `sessionDir`, a context marker and a project extension. Confirm the restricted session uses the explicit state path, does not persist a normal session and does not load the marker or extension. Candidate-file checking alone does not perform this test.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Ephemeral sessions lose normal resume history. Choose persistence deliberately for approved work and protect its location and retention.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | AC-4, AU-9 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

## 5. Monitoring and Verification

### 5.1 Detect configuration and startup-resource drift

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | CM-6, CA-7 |

#### Description

Compare the reviewed candidate and reconcile actual runtime resources after changes to Pi, packages, user settings or project trust. Project settings override many user preferences and resource lists combine, so a file audit cannot compute complete effective state.

**Source:** [Official configuration/security reference](https://docs.pi.dev/latest/settings), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Syntactically valid configuration can still be ignored or overridden.
- A file-only check cannot attest a running process or its external boundary.

**Attack Prevented:** Silent policy drift and false confidence from incomplete verification.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Run the candidate comparison against strict JSON; duplicate or unexpected fields and altered types fail.
2. Review the actual agent directory, saved trust decisions, loaded resource list and command line privately in the isolated environment.
3. After accepting an exception, update its source evidence, candidate and regression tests together. Keep the launch entrypoint protected from arbitrary flag injection.

#### Code Implementation

**Verification pack:** a bounded local check, not an enforcement operation or effective-policy attestation. See the pack README for exact inputs, output and omissions.

{% include pack-code.html vendor="pi" section="5.1" %}

#### Validation & Testing

Offline tests check native schema shape and hostile fixtures, including widening tools, trust, packages and resource flags. Use separate harmless runtime negative tests before deployment; no live Pi invocation was performed here.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Any unreviewed customization fails the strict comparison. Review it rather than weakening the audit or treating empty arrays as discovery suppression.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | CM-6, CA-7 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

### 5.2 Collect safe diagnostics and rehearse recovery

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AU-6, AU-9 |

#### Description

Keep version, auth-readiness and resource evidence private and bounded. A completed diagnostic is not proof of least privilege or containment. Restore code through reviewed version-control changes; contain the process and upstream identity independently if compromise is suspected.

**Source:** [Official configuration/security reference](https://docs.pi.dev/latest/security), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Diagnostics and session evidence may themselves contain secrets.
- Recovery must account for retained processes, grants and external effects.

**Attack Prevented:** Persistent unauthorized access and secondary disclosure during response.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Preview the fixed native diagnostics, supplying the exact approved provider ID. Only `auth check --json --no-refresh` is available when you deliberately opt in.
2. Review actual authentication/resource state privately, preserving sanitized rule outcomes and versions rather than tokens or session contents.
3. Rehearse stopping the isolated process, inspecting any child processes and restoring a disposable worktree. Review shared artifacts and upstream credentials separately; these packs do not delete sessions or revoke grants.

#### Code Implementation

Native reads preview by default. `--execute` is available only for the fixed diagnostic commands, never remediation; completion is not reported as a policy pass.

{% include pack-code.html vendor="pi" section="5.2" %}

#### Validation & Testing

Use fake credentials and a disposable workspace. Verify diagnostic failures produce nonzero status without raw output, and repeat the isolation and tool-denial tests after recovery.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Stopping Pi can leave child processes and external actions already in progress. Verify those outcomes before restarting from approved state.

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
| Reviewed product release | 1.5.2; other versions require explicit source reconciliation |
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

- [First-party reference](https://github.com/earendil-works/pi/security/advisories/GHSA-mqxh-6gq7-558m)
- [First-party reference](https://docs.pi.dev/latest/configuration)
- [First-party reference](https://docs.pi.dev/latest/containerization)
- [First-party reference](https://docs.pi.dev/latest/settings)
- [First-party reference](https://docs.pi.dev/latest/cli)
- [First-party reference](https://docs.pi.dev/latest/packages)
- [First-party reference](https://docs.pi.dev/latest/security)
- [Source coverage, automation census and release pins](/research/agent-source-coverage-2026-11)
- [Code Pack usage and evidence limits](https://github.com/grcengineering/how-to-harden/tree/main/packs/pi)

## Changelog

| Date | Version | Maturity | Changes | Author |
|---|---|---|---|---|
| 2026-11-15 | 0.1.0 | ai-drafted | Initial source-backed guide and version-gated candidate, audit, inventory and native-read packs; offline fixtures only. | Codex (GPT-6) |

## Contributing

Report corrections with the exact release, first-party source and a sanitized reproduction. Follow [CONTRIBUTING.md](https://github.com/grcengineering/how-to-harden/blob/main/CONTRIBUTING.md). Keep credentials and private agent/tenant evidence out of public issues and pull requests.

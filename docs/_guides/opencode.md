---
layout: guide
title: "OpenCode Hardening Guide"
vendor: "OpenCode"
slug: "opencode"
tier: "3"
category: "AI/ML Platform"
description: "Harden OpenCode configuration authority, execution boundaries, credentials, integrations, tool access and private verification."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-15"
---

## Overview

Anomaly OpenCode V2 CLI, local server, desktop/web clients and managed policy; Console account-scoped policies are discussed where they intersect local enforcement. These agents can expose source code, credentials and authenticated services to model-directed actions and third-party resources. Prioritize the authority available to the entire process, then restrict loading and individual tools.

### Intended Audience

Security engineers, platform teams, IT administrators and responders governing developer or automation agents.

### How to Use This Guide

- **L1 (Crawl):** Establish identity, conservative configuration, scoped credentials and private verification.
- **L2 (Walk):** Add whole-process isolation and externally enforced network restrictions for untrusted input.
- **L3 (Run):** Require independent evidence and change review for regulated deployments; this guide does not assert certification.

### Scope

Anomaly OpenCode V2 CLI, local server, desktop/web clients and managed policy; Console account-scoped policies are discussed where they intersect local enforcement. V1 examples, generic host/container construction and unverified tenant administration APIs are outside scope. General OS hardening remains with your existing baseline. Isolation references here describe the agent-specific trust boundary, not a new host deployment recipe.

### Research and validation boundary

Source and release checks were performed on 2026-11-15; the candidate is restricted to **2.3.0**. See the [source-first candidate and surface ledger](/research/agent-source-coverage-2026-11) for exact upstream commits, discovery gaps and evidence limits. This is documentation research plus offline hostile-input/native-schema/mock-CLI testing. **No live agent/tenant was hardened, no device settings changed, and no live-validation status earned.**

The [Code Pack](https://github.com/grcengineering/how-to-harden/tree/main/packs/opencode) generates candidates and non-executing launch plans, compares explicit files and provides opt-in native reads. It does not install policy, provide a sandbox or compute complete effective state. All default operations are local/read-only or stdout-only. Native diagnostic execution is separate and explicit. Do not evaluate launch JSON as shell code.

## Table of Contents

1. [Identity and Configuration Authority](#1-identity-and-configuration-authority)
2. [Execution and Network Boundaries](#2-execution-and-network-boundaries)
3. [Credentials and Integrations](#3-credentials-and-integrations)
4. [Tool and Data Restrictions](#4-tool-and-data-restrictions)
5. [Monitoring and Verification](#5-monitoring-and-verification)
6. [Compliance Quick Reference](#6-compliance-quick-reference)
7. [Appendices](#7-appendices)

## 1. Identity and Configuration Authority

### 1.1 Verify OpenCode V2 and its policy feature floor

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | SI-2, CM-8 |

#### Description

Use Anomaly OpenCode V2, distributed as `@opencode/cli`; the older `opencode-ai` package and V1 examples have different contracts. This pack targets 2.3.0. Integration/MCP/skill/plugin policies require at least 2.2.3, and `websearch.use` requires 2.2.6. Those feature floors are not a compatibility guarantee for the whole baseline.

**Source:** [Official configuration/security reference](https://opencode.ai/docs/migrate-v1/), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Look-alike packages and stale examples can introduce a different trust model.
- Release-sensitive controls can be silently ignored on unsupported builds.

**Attack Prevented:** Supply-chain substitution and reliance on unavailable safeguards.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Open the official release page and select **v2.3.0**; reconcile the package identity and platform artifact with your software inventory.
2. Check the deployed CLI and background server versions independently. Do not install an unreviewed script or trust a cached “latest release” result.
3. Follow **Migrate from V1 → Permissions and tools**: native V2 uses `permissions` arrays with `shell` and `subagent`. Retain the approved old configuration for recovery.

#### Code Implementation

The first-party CLI version read previews by default; an explicit opt-in is required to invoke the selected binary.

{% include pack-code.html vendor="opencode" section="1.1" %}

#### Validation & Testing

Preview the version pack, then opt into its fixed `--version` read only in an approved test environment. Reject prereleases, older releases and unreviewed newer versions. Check server diagnostics as well; a CLI version alone cannot prove the server version.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Migration can break plugins and API clients. Keep a known-good V1 configuration separately; never point V1 at a native V2-only candidate.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | SI-2, CM-8 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

### 1.2 Put enforceable restrictions in managed policies

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | CM-6, AC-3 |

#### Description

Deploy security policies through the system configuration directory or macOS `ai.opencode.managed` preferences. Managed policies outrank Console, user and project policies. Ordinary settings do not prevent users or projects from adding new resources; use explicit policy actions for those restrictions.

**Source:** [Official configuration/security reference](https://opencode.ai/docs/config/), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Agent-writable configuration can undo a carefully reviewed baseline.
- Higher-precedence sources and fail-open parsing can change effective policy.

**Attack Prevented:** Configuration tampering and privilege expansion through lower-trust inputs.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. In your approved configuration editor, open the managed artifact: Linux `/etc/opencode/opencode.json(c)`, macOS `/Library/Application Support/opencode/opencode.json(c)`, or Windows `%ProgramData%\opencode\opencode.json(c)`.
2. On macOS, reconcile `/Library/Managed Preferences/ai.opencode.managed.plist` and its user-specific equivalent; a user-specific managed profile replaces the machine profile.
3. Protect the deployment artifact from the agent identity, then review and deploy the candidate through your existing MDM/configuration process. No native graphical enforcement procedure was verified for these file policies.

#### Code Implementation

Candidate output only; review and deploy through your approved change process. The 4.1/4.2 outputs are fragments, while 1.2 is the complete restrictive baseline.

{% include pack-code.html vendor="opencode" section="1.2" %}

#### Validation & Testing

Compare the candidate offline, then inspect effective configuration sources and server warnings after deployment. In a disposable project, attempt to re-enable one denied resource with a project policy; require the managed denial to survive.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

The candidate denies shell, writes, subagents and all provider integrations by default. Approved work will stop until narrowly reviewed exceptions are deployed; rollback is an approved policy redeployment.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | CM-6, AC-3 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

## 2. Execution and Network Boundaries

### 2.1 Constrain the entire execution environment

**Profile Level:** L2 (Walk)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-6, SC-39 |

#### Description

Treat shell execution, plugins, local MCP servers and provider packages as code with the agent account’s authority. A working directory, permission prompt or policy rule is not a general filesystem/process sandbox. Use a dedicated isolated environment for untrusted repositories and expose only task data and credentials.

**Source:** [Official configuration/security reference](https://opencode.ai/docs/plugins/), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Prompt injection can steer any capability the process can reach.
- Tool-level safeguards do not contain every extension or subprocess path.

**Attack Prevented:** Host credential theft and cross-workspace effects from untrusted content.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Review **Plugins → Discover/Control** and all applicable user/project/system plugin roots before starting the agent.
2. Prepare an approved whole-process sandbox or dedicated execution account; keep host SSH agents, production credentials and administrative sockets outside it.
3. Review the preview-only launch plan. `--standalone` selects a private server rather than the shared background service; it does not provide OS isolation.

#### Code Implementation

This produces a plan only. It does not create or attest the external isolation boundary.

{% include pack-code.html vendor="opencode" section="2.1" %}

#### Validation & Testing

In a disposable fixture environment, test access to a harmless file outside the permitted mounts and an unapproved network destination. Record the actual OS denial. Do not infer containment from a policy prompt or successful plan generation.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Isolation can break builds and provider authentication. Add only required mounts/services; recreating the approved environment is safer than copying a developer home into it.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | AC-6, SC-39 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

### 2.2 Keep the agent server private and verify TLS paths

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | SC-7, SC-8 |

#### Description

Keep the V2 service on loopback unless remote access is explicitly required. Pairing links authenticate clients and should be handled as credentials. Standard proxy variables configure client traffic; they do not force shells, plugins or every child process through a network boundary.

**Source:** [Official configuration/security reference](https://opencode.ai/docs/cli/web/), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Agent listeners and outbound services expose real execution authority.
- A proxy or loopback default alone does not prove all traffic is constrained.

**Attack Prevented:** Unauthorized remote actions and exfiltration through overlooked network paths.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Review **CLI → Web → Access/Remote access**: the shared service listens on localhost by default; do not approve `pair --remote` without a separate exposure decision.
2. Inspect the actual service listener and allowed browser origins. Pairing links expire after five minutes, but authenticated sessions last 30 days; changing the server password invalidates those sessions.
3. Configure approved proxy/CA paths for both CLI and managed service environments. Preserve loopback exclusions and certificate verification; avoid sharing `service get env` output because it can contain proxy credentials.

#### Code Implementation

**Verification pack:** a bounded local check, not an enforcement operation or effective-policy attestation. See the pack README for exact inputs, output and omissions.

{% include pack-code.html vendor="opencode" section="2.2" %}

#### Validation & Testing

The environment pack checks only selected unsafe variables in its own process. Separately inspect service status/listeners, TLS success and externally enforced egress. Test an unauthenticated request in an authorized disposable environment; do not publish passwords or pairing URLs.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Changing service settings stops the background server and needs a deliberate restart. Retain the prior private configuration and coordinate session invalidation.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | SC-7, SC-8 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

## 3. Credentials and Integrations

### 3.1 Allow only approved providers and account scopes

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-6, IA-5 |

#### Description

Use `provider.use` to restrict provider IDs and `integration.connect`/`integration.use` to restrict connection and account scope. Provider selection alone does not distinguish an approved Console workspace from a personal account. The generated default denies all inference routes until an exact exception is reviewed.

**Source:** [Official configuration/security reference](https://opencode.ai/docs/policies/), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Ambient credentials enlarge the impact of one hostile tool or resource.
- Model selection and a successful login do not prove approved account scope.

**Attack Prevented:** Credential misuse and unauthorized provider or internal-service access.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. In the managed JSON artifact, put broad denies before exact allow exceptions; the last matching statement in an authority layer wins.
2. For a direct approved provider, use the same exact `--approved-provider` value when generating and auditing the candidate. Bare integration IDs permit configured/environment credentials; connected `#account` identities remain denied.
3. For Console, review the actual connected organization ID and an account-scoped `opencode#org_…` rule from the official policies documentation. Do not copy a sample organization ID or mistake `integration.use` for an MCP deny.

#### Code Implementation

**Verification pack:** a bounded local check, not an enforcement operation or effective-policy attestation. See the pack README for exact inputs, output and omissions.

{% include pack-code.html vendor="opencode" section="3.1" %}

#### Validation & Testing

Use dummy credentials in a test environment: an approved route should be available and a personal/unapproved route should be absent. The credential-environment pack detects only selected ambient access; it does not verify provider identity, contracts, retention or model routing.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Overly broad denies can make inference unavailable. Add reviewed, exact exceptions through the authoritative policy, preserving the broad default deny.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | AC-6, IA-5 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

### 3.2 Govern MCP servers, skills and plugin code separately

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | CM-7, SR-3 |

#### Description

Deny `mcp.use`, `skill.use` and `plugin.use` separately, then permit reviewed exact resources only when needed. Since 2.2.3, a bare `integration.use: *` deny no longer blocks these three resource classes. A plugin can execute code outside tool permission checks; controlling its load is essential.

**Source:** [Official configuration/security reference](https://opencode.ai/docs/mcp-servers/), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Resources can introduce executable code, instructions and persistent access.
- Workspace inspection alone misses user, profile and system discovery roots.

**Attack Prevented:** Supply-chain execution and unauthorized third-party tool access.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Review **Config → Locations**, **Plugins → Discover** and **MCP servers** for system, global, direct project and `.opencode` discovery.
2. Keep the three separate resource-class denies in the managed candidate. Review local paths, pinned package versions, startup hooks and MCP credentials before adding exceptions.
3. Use the top-level resource inventory to identify review leads; also inspect ancestors and user/managed roots manually. The pack does not parse or execute discovered files.

#### Code Implementation

**Verification pack:** a bounded local check, not an enforcement operation or effective-policy attestation. See the pack README for exact inputs, output and omissions.

{% include pack-code.html vendor="opencode" section="3.2" %}

#### Validation & Testing

In a disposable project, configure a harmless denied plugin, skill and MCP server and verify they are not loaded or connected. Reconcile effective resource inventory after restart. A clean top-level scan does not prove global discovery is empty.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Default-deny breaks resource-dependent workflows. Add an exact reviewed resource and repeat negative tests; deleting a project entry alone does not remove a global copy.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | CM-7, SR-3 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

## 4. Tool and Data Restrictions

### 4.1 Use hard denies for dangerous tool capabilities

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-3, CM-7 |

#### Description

Separate per-agent permissions from administrator policies. The restrictive candidate asks for otherwise unmatched actions and policy-denies shell, edit, subagent, external-directory access and web fetch. A `tool.use` allow only lifts an earlier deny; the agent’s permission rule still decides whether access is granted.

**Source:** [Official configuration/security reference](https://opencode.ai/docs/permissions/), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Alternate execution paths can bypass a narrowly configured tool rule.
- Headless behavior and explicit overrides differ from interactive defaults.

**Attack Prevented:** Unapproved mutation, execution and delegation by an injected instruction.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. In the managed candidate, inspect ordered `tool.use` statements and the V2 `permissions` array.
2. Keep arbitrary shell and mutation unavailable for review-only tasks. If a coding task needs them, redesign the approved policy and external boundary rather than silently adding a wildcard allow.
3. Review agent-specific permissions and saved approvals; policy denials should override both. A shell program, once allowed, retains its own filesystem and network authority.

#### Code Implementation

Candidate output only; review and deploy through your approved change process. The 4.1/4.2 outputs are fragments, while 1.2 is the complete restrictive baseline.

{% include pack-code.html vendor="opencode" section="4.1" %}

#### Validation & Testing

Try harmless fixture writes, a shell command, a subagent and an external path. Require policy denial rather than an approval prompt. Confirm that `grep` checks the search expression, not a secret-file exclusion list.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Read-only review loses build and editing capabilities. Expand permissions only for the task’s approved environment and rerun denial tests after policy changes.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | AC-3, CM-7 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

### 4.2 Minimize source, secret and web-search exposure

**Profile Level:** L2 (Walk)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-4, SC-7 |

#### Description

Keep credential material outside agent-visible files and disable unapproved web-search providers with [`websearch.use`](https://opencode.ai/docs/policies/#web-search). The candidate adds read denies for common environment/SSH/AWS file patterns, but these are defense in depth; they do not stop an approved shell or arbitrary plugin from reading mounted secrets.

**Source:** [Official configuration/security reference](https://opencode.ai/docs/network/), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Source, tokens and session evidence can escape through several paths.
- Convenience features and heuristic filtering leave residual exposure.

**Attack Prevented:** Sensitive-data disclosure and reuse of retained authority or context.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Review the managed read-deny patterns against real normalized internal/external paths; avoid putting private keys or `.env` fixtures in the task mount.
2. Retain the explicit `websearch.use` deny; clients older than 2.2.6 ignore it. Review provider data-handling terms before allowing source to leave the environment.
3. Review session storage and backup/export handling using the deployment’s data policy. No retention, DLP or universal redaction toggle is asserted by this pack.

#### Code Implementation

Candidate output only; review and deploy through your approved change process. The 4.1/4.2 outputs are fragments, while 1.2 is the complete restrictive baseline.

{% include pack-code.html vendor="opencode" section="4.2" %}

#### Validation & Testing

Use synthetic secret-shaped fixture files only. Check denied reads and unavailable search providers, then inspect all permitted routes in the isolated test. The data-policy fragment is the ordered policy list, not a transcript-retention setting.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

File patterns can deny legitimate files and still miss alternate paths. Keep isolation authoritative and tune only against harmless fixtures.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | AC-4, SC-7 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

## 5. Monitoring and Verification

### 5.1 Reject invalid policy and configuration drift

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | CM-6, CA-7 |

#### Description

Compare candidate files and verify effective settings after every change. OpenCode drops invalid policy statements with a warning while continuing with the remaining statements. Successful startup or a valid JSON file therefore does not prove that a deny is active.

**Source:** [Official configuration/security reference](https://opencode.ai/docs/policies/), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Syntactically valid configuration can still be ignored or overridden.
- A file-only check cannot attest a running process or its external boundary.

**Attack Prevented:** Silent policy drift and false confidence from incomplete verification.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Run the strict candidate comparison before deployment. General JSONC must be converted using a reviewed parser; this audit deliberately accepts strict JSON only.
2. In the isolated deployment, inspect **debug config** sources and startup warnings without exporting secret-bearing values.
3. Resolve every invalid/ignored statement, then repeat the affected negative test. Protect policy artifacts from writes by the agent account.

#### Code Implementation

**Verification pack:** a bounded local check, not an enforcement operation or effective-policy attestation. See the pack README for exact inputs, output and omissions.

{% include pack-code.html vendor="opencode" section="5.1" %}

#### Validation & Testing

Offline fixtures cover malformed data, duplicate keys, order changes, extra wildcard allows and unsupported versions. Native schema shape is checked against the retained official snapshot; runtime policy diagnostics and actual denial remain separate operator checks.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

A strict candidate comparison flags any unreviewed customization. Review that change deliberately and update the baseline/tests together; do not suppress the finding.

#### Compliance Mappings

| Framework | Control ID | Relationship |
|---|---|---|
| NIST SP 800-53 Rev. 5 | CM-6, CA-7 | Supports the configuration, least-privilege or evidence objective described above; implementation and assurance require independent review. |

---

### 5.2 Record private evidence and contain exposed sessions

**Profile Level:** L1 (Crawl)

| Framework | Controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AU-6, AU-9 |

#### Description

Monitor version, effective policy sources, resource changes and listener exposure. Keep raw diagnostics private. A native command returning zero only means that command completed; it does not prove all policies or containment boundaries.

**Source:** [Official configuration/security reference](https://opencode.ai/docs/cli/commands/), checked 2026-11-15. Recommendations and test procedures below are HTH’s interpretation of that interface and its limits.

#### Rationale

**Why This Matters:**

- Diagnostics and session evidence may themselves contain secrets.
- Recovery must account for retained processes, grants and external effects.

**Attack Prevented:** Persistent unauthorized access and secondary disclosure during response.

#### Prerequisites

An approved deployment owner, the reviewed product version and a disposable isolated test context. Use synthetic data; do not copy production secrets into fixtures.

#### ClickOps Implementation

1. Preview the native diagnostics pack, then opt into the fixed `service status` read only in the approved test context.
2. Review service logs for dropped policy statements and unexpected resource loads; preserve only redacted findings and version/source identifiers in shared evidence.
3. If exposure is suspected, use the approved response procedure to stop the affected service, invalidate client sessions and review upstream credentials. Reconcile active remote access separately from saved consent.

#### Code Implementation

Native reads preview by default. `--execute` is available only for the fixed diagnostic commands, never remediation; completion is not reported as a policy pass.

{% include pack-code.html vendor="opencode" section="5.2" %}

#### Validation & Testing

Correlate a harmless test denial with private server evidence, and verify a fresh unauthenticated client cannot act. Retain test date, binary/server versions and policy source. No live result or automatic remediation is claimed here.

#### Monitoring & Maintenance

Review after product, package, policy or launch changes and at least monthly. Keep the reviewed artifact hash, version, test scope and sanitized result; investigate drift before approving more authority.

#### Operational Impact

Stopping or resetting a service interrupts all its clients. Preserve access to the approved recovery artifact and coordinate restart and credential response.

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
| Reviewed product release | 2.3.0; other versions require explicit source reconciliation |
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

- [First-party reference](https://opencode.ai/docs/migrate-v1/)
- [First-party reference](https://opencode.ai/docs/config/)
- [First-party reference](https://opencode.ai/docs/plugins/)
- [First-party reference](https://opencode.ai/docs/cli/web/)
- [First-party reference](https://opencode.ai/docs/policies/)
- [First-party reference](https://opencode.ai/docs/mcp-servers/)
- [First-party reference](https://opencode.ai/docs/permissions/)
- [First-party reference](https://opencode.ai/docs/network/)
- [First-party reference](https://opencode.ai/docs/cli/commands/)
- [Source coverage, automation census and release pins](/research/agent-source-coverage-2026-11)
- [Code Pack usage and evidence limits](https://github.com/grcengineering/how-to-harden/tree/main/packs/opencode)

## Changelog

| Date | Version | Maturity | Changes | Author |
|---|---|---|---|---|
| 2026-11-15 | 0.1.0 | ai-drafted | Initial source-backed guide and version-gated candidate, audit, inventory and native-read packs; offline fixtures only. | Codex (GPT-6) |

## Contributing

Report corrections with the exact release, first-party source and a sanitized reproduction. Follow [CONTRIBUTING.md](https://github.com/grcengineering/how-to-harden/blob/main/CONTRIBUTING.md). Keep credentials and private agent/tenant evidence out of public issues and pull requests.

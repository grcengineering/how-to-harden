---
layout: guide
title: "Cursor Cloud Agents Hardening Guide"
vendor: "Cursor Cloud Agents"
slug: "cursor-cloud-agents"
platform: "SpaceXSI"
platform_slug: "spacexai"
product: "Cursor Cloud Agents"
tier: "1"
category: "DevOps"
description: "Cursor cloud and self-hosted agent security for repositories, secrets, OIDC, automation triggers, reviews and retention"
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-05"
---

## Overview

Cloud Agents execute unattended terminal work in hosted VMs or your self-hosted workers. Automations, Bugbot, Security Agents, Approval Agents, Rollouts and Agent SDK deployments add entrypoints and privileges to that execution plane. Their settings need explicit review beyond the local editor sandbox.

See the [family Common Controls index](/guides/cursor/#products-in-this-platform) for product boundaries. A shared owner does not establish shared policy inheritance. SpaceXSI is the current first-party name; the historical platform URL remains stable. [Source-first reconciliation](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/spacexai-source-coverage.md) records the discovery scope, evidence and gaps.

### Intended Audience

Administrators, security engineers and application owners responsible for this product's identities, data and integrations.

### How to Use This Guide

Apply L1 (Crawl) controls first, then L2 (Walk) for sensitive workloads and L3 (Run) where strict deployment requirements justify them. **No tenants declared — Tier 0+1 only; VERIFIED-LIVE = 0.** All content remains AI-drafted. No credentials, settings or live integrations were created or changed during research.

### Scope

Covers Cloud Agent repository authorization, saved Builds/Apps, secrets/network, private connectivity, self-hosted Team Pools/My Machines, OIDC, automation/review/deploy integrations and lifecycle. Inherit Cursor organization identity/privacy/model governance only where documented. Grok Bot computers and console.x.ai teams have separate policy.

## Table of Contents

1. [Repository and Runtime Authority](#1-repository-and-runtime-authority)
2. [Secrets and Network](#2-secrets-and-network)
3. [Federated Identity](#3-federated-identity)
4. [Automation and Integration Authority](#4-automation-and-integration-authority)
5. [Storage and Response](#5-storage-and-response)

---

## 1. Repository and Runtime Authority

### 1.1 Restrict Source-Control Installation and Protected Git Scopes

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.1, 6.8 |
| NIST SP 800-53 | AC-3, AC-6 |

#### Description
Grant the Cursor Git provider app access only to approved repositories and link the triggering user’s account. Use Protected Git Scopes where available to bind Git organizations to your Cursor organization.

#### Rationale
**Why This Matters:**
- The app installation and triggering user permissions jointly determine repository reach.

**Attack Prevented:** Unapproved code cloning and agent launch from another organization.

#### ClickOps Implementation
1. Review the Cursor app’s repository selection in the Git provider and the user’s connected Git account.
2. Configure **Dashboard → Integrations → Protected Git Scopes** from the documented Cursor organization setting; verify which Git providers and deployment editions support it.

[First-party configuration reference](https://cursor.com/docs/cloud-agent/security) (fetched 2026-11-05).

**Automation:** Source-provider app/repository installation is managed in that provider. Current Cursor documentation places Protected Git Scopes in **Dashboard → Integrations** and requires both Cursor team-admin and Git-provider-admin authority; no verified configuration API/provider/CLI was found for that claim. A repository blocklist covers editor/CLI, not Cloud Agents, Automations or Bugbot.

#### Validation & Testing
Attempt an authorized synthetic launch on an excluded repository and a wrong Cursor organization; confirm denial before supplying secrets. Documentation and offline checks do not prove tenant enforcement.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 | AC-3 (access enforcement), AC-6 (least privilege); thematic mapping, not product certification |

---

### 1.2 Choose and Govern the Self-Hosted Execution Boundary

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.1, 6.8 |
| NIST SP 800-53 | AC-3, AC-6 |

#### Description
Self-hosting moves tool execution to your worker, while Cursor still runs inference/planning and receives needed tool content. Do not treat it as an offline or data-never-leaves deployment.

#### Rationale
**Why This Matters:**
- Local credentials, desktop access and network reach can be broader than a dedicated hosted VM.

**Attack Prevented:** Lateral movement through a privileged developer or shared worker.

#### ClickOps Implementation
1. Inspect **Cloud Agents dashboard → Allow Self-Hosted Machines / Require Self-Hosted Machines**. Choose approved Team Pools or My Machines deliberately.
2. Run workers under dedicated OS identities with reviewed workspace roots, local MCP servers and desktop permissions. Limit live workspace/desktop sharing; keep host firewall and proxy policy enforced independently.

[First-party configuration reference](https://cursor.com/docs/cloud-agent/self-hosted) (fetched 2026-11-05).

**Automation:** Native worker CLI and Cloud REST worker/pool APIs exist for worker registration, claims and lifecycle. They do not establish a write API for **Allow/Require Self-Hosted Machines**. Worker credential creation and execution are intentionally not run; validate host OS/firewall and runtime identity separately.

#### Validation & Testing
Confirm the actual runtime and egress for representative entrypoints, including automation/API runs. Check what files, output, screenshots and artifacts leave the worker. Documentation and offline checks do not prove tenant enforcement.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 | AC-3 (access enforcement), AC-6 (least privilege); thematic mapping, not product certification |

---

## 2. Secrets and Network

### 2.1 Use Build and Runtime Secrets for Their Intended Exposure

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.1, 6.8 |
| NIST SP 800-53 | AC-3, AC-6 |

#### Description
Use Build Secrets only at build time, Runtime Secrets for redacted runtime values, and ordinary Environment Variables for nonsensitive configuration. Review the environment snapshot and install script as privileged code.

#### Rationale
**Why This Matters:**
- Runtime redaction hides values from selected outputs but does not remove them from the process environment or interactive terminal.

**Attack Prevented:** Credential leakage through builds, tools or persisted images.

#### ClickOps Implementation
1. In the **Cloud Agents dashboard**, edit the saved environment’s secrets and select the appropriate secret type.
2. For Docker builds, mount Build Secrets through the documented secret mount rather than baking them into layers. Review install scripts, app builds and dependencies before making an environment available.

[First-party configuration reference](https://cursor.com/docs/cloud-agent/security-network) (fetched 2026-11-05).

**Automation:** Cloud REST documents list/set/delete for environment, team and personal secrets; use the exact credential/scope contract for the intended plane. Build/runtime secret types and exposure must be checked in the saved environment. This pass supplies no secret-creation pack and never reads secret values; metadata inventory is not proof of effective runtime redaction.

#### Validation & Testing
Use synthetic canaries to inspect logs, commits, artifacts and snapshots. Confirm runtime processes cannot access build-only credentials and rotate any value previously baked into an image. Documentation and offline checks do not prove tenant enforcement.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 | AC-3 (access enforcement), AC-6 (least privilege); thematic mapping, not product certification |

---

### 2.2 Lock Hosted Egress and Review Environment Overrides

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.1, 6.8 |
| NIST SP 800-53 | AC-3, AC-6 |

#### Description
Use a restrictive Cloud Agent network mode and lock it on Enterprise. Review saved environment and user overrides; a team default alone can be superseded. Self-hosted runs use the worker’s network controls.

#### Rationale
**Why This Matters:**
- Cloud commands run automatically and can exfiltrate through broad network access.

**Attack Prevented:** Code and secret export through prompt-injected terminal work.

#### ClickOps Implementation
1. Open **Cloud Agents dashboard → Security** and set **Allowlist only** or the reviewed default-plus-allowlist mode. Enterprise admins enable **Lock Network Access Policy**.
2. Review every saved environment’s inheritance/mode. Allow exact artifact bucket hosts only when needed; inspect private connectivity/tunnel authentication and provider app reach separately.

[First-party configuration reference](https://cursor.com/docs/cloud-agent/security-network) (fetched 2026-11-05).

**Automation:** User/environment/team egress and the Enterprise lock have documented dashboard controls. A setting-specific write contract was not established from the general environment API; do not invent a field. Self-hosted egress belongs to the worker network. Preserve the exact artifact bucket host rather than allowing all regional S3 buckets.

#### Validation & Testing
Test a synthetic blocked destination from both a hosted run and a self-hosted worker. Verify mandatory service exceptions and that no wildcard bucket entry opens unrelated storage. Documentation and offline checks do not prove tenant enforcement.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 | AC-3 (access enforcement), AC-6 (least privilege); thematic mapping, not product certification |

---

## 3. Federated Identity

### 3.1 Constrain OIDC Issuer, Audience, Subject and Runtime

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.1, 6.8 |
| NIST SP 800-53 | AC-3, AC-6 |

#### Description
Prefer short-lived OIDC credentials over stored cloud keys. Verifiers must validate signature, issuer, audience, time and authorized stable subjects; runtime differences need explicit treatment.

#### Rationale
**Why This Matters:**
- The mint API accepts caller-selected audiences, so merely accepting a Cursor signature permits overly broad trust.

**Attack Prevented:** A different agent or worker assuming a privileged cloud role.

#### ClickOps Implementation
1. Configure the cloud IAM/resource-server verifier using **https://api.cursor.com** discovery/JWKS. Pin the required audience and stable owner/team/environment subject.
2. On self-hosted workers, enable the identity socket only if required and isolate the OS user; any same-user process can mint. Review the verifier’s ability to enforce **agent_runtime**; AWS trust only matches aud/sub.

[First-party configuration reference](https://cursor.com/docs/cloud-agent/identity) (fetched 2026-11-05).

**Automation:** Unverified — OIDC and cloud trust policies are documented, but the correct IAM role, claim values and cloud/provider configuration are deployment-specific; no broad trust-policy generator is supplied.

#### Validation & Testing
Reject wrong-audience, wrong-team, expired and self-hosted tokens where the policy disallows them. Decoding a JWT without signature verification is not a validation result. Documentation and offline checks do not prove tenant enforcement.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 | AC-3 (access enforcement), AC-6 (least privilege); thematic mapping, not product certification |

---

## 4. Automation and Integration Authority

### 4.1 Scope Automation Owners, Sharing and Event Triggers

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.1, 6.8 |
| NIST SP 800-53 | AC-3, AC-6 |

#### Description
Review each automation’s Creator or service-account identity, repositories, shared editors and event filters. A trigger is an external action entrypoint, not just a notification.

#### Rationale
**Why This Matters:**
- Slack reactions/messages, source-control events, schedules and webhooks can repeatedly launch privileged code without a new interactive request.

**Attack Prevented:** Untrusted event content causing autonomous repository changes.

#### ClickOps Implementation
1. Open **Automations**, inspect the automation’s **Share** settings and billing/identity choice, repository selection and all triggers.
2. Limit Slack channels/filter expressions, Git event/ref scope and webhook access. Store webhook API keys as secrets and rotate when exposed. Review attached MCP integrations and prompt/Agent SDK changes as code.

[First-party configuration reference](https://cursor.com/docs/cloud-agent/automations) (fetched 2026-11-05).

#### Code Implementation

The official pinned provider exposes a workflow resource **and by-ID data source**. The example defaults to no creation and an explicit disabled workflow; it does not install Slack or trigger work. Scope **user** is private/creator, **team_visible/team_editable_user** use creator credentials, and **team/team_editable** use the team service account. State can contain prompts and trigger details; protect it.

{% include pack-code.html vendor="cursor-cloud-agents" section="4.1" %}

#### Validation & Testing
Use synthetic event payloads in a separately approved test environment; verify wrong-channel/ref requests do not run and service-account permissions match policy. Documentation and offline checks do not prove tenant enforcement.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 | AC-3 (access enforcement), AC-6 (least privilege); thematic mapping, not product certification |

---

### 4.2 Keep Review and Approval Agents Inside Repository Protections

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.1, 6.8 |
| NIST SP 800-53 | AC-3, AC-6 |

#### Description
Treat Bugbot and Security Reviewer output as machine evidence. Scope vulnerability scans and approval routing to approved repositories and criteria, with repository protections still enforcing required independent review.

#### Rationale
**Why This Matters:**
- An approval agent can satisfy a workflow condition while missing contextual security risk.

**Attack Prevented:** Unsafe merge through automated approval or incomplete review coverage.

#### ClickOps Implementation
1. In **Automations**, inspect **Security Agents** and **PR Routing & Approval** configuration. Review repository selection, exclusion rules, criteria and check dependencies.
2. Ensure Git-provider or Origin rulesets require the intended human/check approvals. Review Vulnerability Scanner’s at-rest scope separately from PR Security Reviewer and Bugbot.

[First-party configuration reference](https://cursor.com/docs/approval-agents) (fetched 2026-11-05).

**Automation:** Native agent execution/automation interfaces and repository-provider protections exist, but a setting-specific Security/Approval Agent policy write was not established. The workflow provider can perform **approve_pr** and other write actions: review that authority explicitly rather than treating machine review as independent human approval.

#### Validation & Testing
Submit a synthetic risky change and confirm routing/check behavior; verify a machine approval cannot bypass required human or protected-branch policy. Documentation and offline checks do not prove tenant enforcement.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 | AC-3 (access enforcement), AC-6 (least privilege); thematic mapping, not product certification |

---

### 4.3 Scope Rollouts Telemetry and Production Fix Authority

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.1, 6.8 |
| NIST SP 800-53 | AC-3, AC-6 |

#### Description
Give Rollouts only the telemetry and deployment-event authority needed to assess approved services. A fix launches a Cloud Agent; its resulting code needs the same review controls.

#### Rationale
**Why This Matters:**
- Production logs/traces can contain credentials or personal data, and telemetry MCP tools extend agent authority.

**Attack Prevented:** Sensitive production-data export and unreviewed remediation.

#### ClickOps Implementation
1. Open **Automations → Team → Rollouts** and review the setup’s repositories, deployment reporting and telemetry connections.
2. Limit connected telemetry accounts and tools; keep secrets out of events. Review who can revise rollout plans and start **Fix issue** runs.

[First-party configuration reference](https://cursor.com/docs/rollouts) (fetched 2026-11-05).

**Automation:** Rollouts uses native telemetry/automation and **Fix issue** starts a Cloud Agent. No verified policy write or automatic rollback interface was established. Review the associated workflow in 4.1 and source/telemetry permissions independently.

#### Validation & Testing
Verify staging/service boundaries with synthetic telemetry. Current docs say Rollouts does not autonomously merge, revert or roll back; do not grant broader power based on older launch wording. Documentation and offline checks do not prove tenant enforcement.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 | AC-3 (access enforcement), AC-6 (least privilege); thematic mapping, not product certification |

---

## 5. Storage and Response

### 5.1 Set Conversation Retention and Review Customer-Managed Keys

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.1, 6.8 |
| NIST SP 800-53 | AC-3, AC-6 |

#### Description
Cloud conversations are indefinite by default; inactive snapshots expire on a rolling thirty-day window. Enterprise early-access retention and CMEK address different stored-data requirements.

#### Rationale
**Why This Matters:**
- Deleting a visible conversation does not immediately delete every VM snapshot or configured secret.

**Attack Prevented:** Retained source and conversation exposure beyond approved policy.

#### ClickOps Implementation
1. Review **Cloud Agents dashboard → Team Settings** for the documented retention policy availability (Indefinite or 90 days, select Enterprise early access).
2. For Enterprise CMEK, confirm the support-configured scope and rotation/access responsibilities. Review secrets/tokens separately from run retention.

[First-party configuration reference](https://cursor.com/docs/enterprise/privacy-and-data-governance) (fetched 2026-11-05).

**Automation:** The documented Delete Agent REST operation removes conversation/artifacts; snapshots keep their rolling retention. Enterprise conversation retention and CMEK setup are separately configured; no verified management write was established for those settings. Do not infer snapshot deletion or key revocation from agent deletion.

#### Validation & Testing
Record the effective plan/policy and key scope. Test synthetic deletion only when authorized; document snapshot expiry rather than claiming on-demand deletion. Documentation and offline checks do not prove tenant enforcement.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 | AC-3 (access enforcement), AC-6 (least privilege); thematic mapping, not product certification |

---

### 5.2 Inventory and Stop Runs Before Removing Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| CIS Controls v8 | 6.1, 6.8 |
| NIST SP 800-53 | AC-3, AC-6 |

#### Description
Maintain a complete agent inventory and incident procedure for running work, trigger sources, API/service credentials, stored artifacts and self-hosted workers. Stopping work and deleting its transcript are separate operations.

#### Rationale
**Why This Matters:**
- A retained trigger or worker credential can restart work after a visible agent is stopped.

**Attack Prevented:** Persistent autonomous execution after incident containment.

#### ClickOps Implementation
1. Use the **Cloud Agents dashboard** to review active runs and their owners, runtime and initiating integration.
2. Disable offending automation/integration, stop the run, revoke affected Git/API/service credentials, and isolate compromised workers. Use the Delete Agent API only under an approved data-deletion workflow.

[First-party configuration reference](https://cursor.com/docs/cloud-agent/api/endpoints) (fetched 2026-11-05).

#### Code Implementation

{% include pack-code.html vendor="cursor-cloud-agents" section="5.2" %}

#### Validation & Testing
Use the read-only inventory pack; verify paging and owner context. Confirm transcript deletion excludes snapshots, and audit each containment plane rather than treating a successful stop as full revocation. Documentation and offline checks do not prove tenant enforcement.

#### Compliance Mappings

| Framework | Mapping |
|-----------|---------|
| NIST SP 800-53 | AC-3 (access enforcement), AC-6 (least privilege); thematic mapping, not product certification |

---

## Automation and Evidence Limits

Cloud REST APIs expose agents/environments/workers/pools; native Agent CLI operates workers and runtimes, while SDKs create execution workflows. Team security policy is not inferred from runtime APIs. The first-party cursor/cursor v0.8.0 workflow resource and data source cover Automations. A user-scoped read-only agent inventory pack is provided (Bash entrypoint plus adjacent Bun/TypeScript helper); GUI egress/retention/CMEK and cloud IAM conditions remain explicit where no verified write contract was found. Official SDK/CLI operations that create workers, credentials or executions were not run.

The [family research ledger](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/spacexai-source-coverage.md) distinguishes documented interfaces, bounded searches and unverified gaps across Terraform resources/data sources, REST/GraphQL, CLI, SDK, native config/MDM and SIEM. Packs are available only where a fetched contract supports them. Read-only inventories and offline configuration preparation are not enforcement. No live tenant, consent flow, destructive operation or integration trigger was exercised.

## Compliance Quick Reference

| Theme | NIST SP 800-53 | CIS Controls v8 |
|-------|----------------|-----------------|
| Identity and privilege | AC-2, AC-3, AC-6, IA-2 | 5, 6 |
| Data and network boundary | SC-7, SC-8, SI-12 | 3, 13 |
| Monitoring and response | AU-2, AU-6, IR-4 | 8, 17 |

Mappings are thematic. No product-specific CIS, DISA or SCuBA recommendation/version was established by the bounded catalog search. The CIS AI benchmark body was not retrieved, so no numeric benchmark mappings are asserted.

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2026-11-05 | Initial source-first product coverage; documented control-plane and automation limits |

## Contributing

See [CONTRIBUTING.md](https://github.com/grcengineering/how-to-harden/blob/main/CONTRIBUTING.md). Submit current first-party configuration evidence and edition details with corrections.

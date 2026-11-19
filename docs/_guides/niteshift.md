---
layout: guide
title: "Niteshift Hardening Guide"
vendor: "Niteshift"
slug: "niteshift"
tier: "2"
category: "AI/ML Platform"
description: "Harden Niteshift cloud coding environments, GitHub access, previews, agent extensions, secrets, and automations."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-18"
---

## Overview

[Niteshift](https://niteshift.dev/) is a cloud coding-agent platform operated by [Bifrost Technologies Inc.](https://niteshift.dev/privacy-policy). A task's own cloud environment is not evidence of default-deny outbound networking, limits on delegated credentials, or a policy boundary for agent instructions. Enforce authorization at the system that owns the data or action.

**Validation status:** No live tenant or credentials were used. Code Packs are configuration examples and offline checks, except the read-only status wrapper that requires an existing task. No automation was enabled.

### Intended Audience

Platform, GitHub, identity and security administrators responsible for a coding-agent pilot.

### How to Use This Guide

- **L1 (Crawl):** Restrict repositories, branch writes, execution and secrets before onboarding.
- **L2 (Walk):** Review preview identities, tool integrations, triggers and operational evidence.

### Scope

Niteshift Config v2, its GitHub integration, task extensions, preview exposure and automations. Classic environments have separate configuration paths. For GitHub rulesets and identity security use the [GitHub Hardening Guide](/guides/github/). For cloud identities, prefer short-lived federation and enforce environment-specific trust and least-privilege permissions at the relying party. For private connectivity, limit allowed destinations at the network provider; use nonproduction integrations and synthetic data. Do not infer isolation for production data merely because a database branch is per-task.

## Table of Contents

1. [Repository Access](#1-repository-access)
2. [Environment Boundaries](#2-environment-boundaries)
3. [Agent Integrations and Automation](#3-agent-integrations-and-automation)
4. [Compliance Quick Reference](#4-compliance-quick-reference)

## 1. Repository Access

### 1.1 Scope GitHub App Repository Access

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6 |

#### Description

Install the Niteshift GitHub App for selected repositories only. Review related and plugin-marketplace repositories as separate access grants.

#### Rationale

**Why This Matters:**

- Broad installation grants widen source-code exposure.
- Repository selection can be reduced without granting additional agent authority.

**Attack Prevented:** Reduces the risk of unauthorized access or changes through this surface; not a guarantee of prevention.

#### ClickOps Implementation

1. In GitHub organization settings, locate the installed Niteshift GitHub App and configure the repository selection. Remove unrelated or sensitive repositories after reviewing dependencies.
2. Review the [documented product behavior](https://docs.niteshift.dev/interfaces/github) before applying the change.

**Automation:** No Niteshift admin write pack for this control. The linked source documents the procedure but does not establish a supported admin REST, GraphQL, SDK or Terraform operation for it.

#### Validation & Testing

Reconcile the chosen repositories against the Niteshift dashboard; confirm a nonselected test repository is unavailable.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6 |

### 1.2 Protect Merge and Trigger Boundaries

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | CM-5 |

#### Description

Apply GitHub rulesets requiring independent review and CI. Do not add the app as a bypass actor. Separate agent changes from merge authority.

#### Rationale

**Why This Matters:**

- PR-author-only commands do not constrain issue triggers to the issue author.
- Autofix can push changes back to the existing PR branch.

**Attack Prevented:** Reduces the risk of unauthorized access or changes through this surface; not a guarantee of prevention.

#### ClickOps Implementation

1. In GitHub, open **Settings → Rules → Rulesets** for the protected branch. Require reviews and checks and verify the app is not a bypass actor. Review Niteshift PR preferences and prefer draft PRs where appropriate.
2. Review the [documented product behavior](https://docs.niteshift.dev/interfaces/github) before applying the change.

**Automation:** No Niteshift admin write pack for this control. The linked source documents the procedure but does not establish a supported admin REST, GraphQL, SDK or Terraform operation for it.

#### Validation & Testing

Use a harmless change in a pilot repo to confirm agent branch writes cannot bypass merge requirements.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | CM-5 |

## 2. Environment Boundaries

### 2.1 Review Environment Lifecycle Code

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | CM-3 |

#### Description

Review setup, resume, settings and services as executable configuration. Use a synthetic environment for validation and require human ownership of these files in GitHub.

#### Rationale

**Why This Matters:**

- Setup and resume can execute with scoped credentials.
- An instructions file is a prompt, not a permission boundary.

**Attack Prevented:** Reduces the risk of unauthorized access or changes through this surface; not a guarantee of prevention.

#### ClickOps Implementation

1. Open **Settings → Environments → [environment]**, select the reviewed branch and use **Test in a sandbox** with nonproduction dependencies. For classic setups, review the classic script separately before migration.
2. Review the [documented product behavior](https://docs.niteshift.dev/environment-configuration/overview) before applying the change.

**Automation:** No Niteshift admin write pack for this control. The linked source documents the procedure but does not establish a supported admin REST, GraphQL, SDK or Terraform operation for it.

#### Validation & Testing

Record the approved commit, boot outcome and resume outcome. Revert a failed rollout through the reviewed source-control path.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | CM-3 |

### 2.2 Keep Internal Services Unpublished

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | CM-7 |

#### Description

Omit service port declarations for internal-only processes and omit tunnels when not required. A declared port publishes an authenticated preview; tunnels bypass Niteshift authentication.

#### Rationale

**Why This Matters:**

- An internal process can become reachable through a published port.
- Preview organization authentication is distinct from the application session.

**Attack Prevented:** Reduces the risk of unauthorized access or changes through this surface; not a guarantee of prevention.

#### ClickOps Implementation

1. In **Settings → Environments → [environment]**, inspect the branch configuration and use **Edit with agent** if needed; independently review the manifest change before merging.
2. Review the [documented product behavior](https://docs.niteshift.dev/environment-configuration/services) before applying the change.

#### Code Implementation

{% include pack-code.html vendor="niteshift" section="2.2" %}

#### Validation & Testing

Review manifest diffs and review the example manifest against the selected branch. In a pilot task run the status command to check supervised services; separately check that no external URL is advertised for the internal service.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | CM-7 |

### 2.3 Minimize Stored Secret Scope

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-5 |

#### Description

Keep raw secrets out of commands, literal values and repository config. Use distinct nonproduction credentials; grant setup or agent scope only as needed.

#### Rationale

**Why This Matters:**

- Setup secret scope and agent secret scope are distinct.
- Task isolation does not restrict external services by itself.

**Attack Prevented:** Reduces the risk of unauthorized access or changes through this surface; not a guarantee of prevention.

#### ClickOps Implementation

1. Use **Settings → Environments → [environment]** to review setup-script and agent scopes. Use named service secret references where required and restart affected services after a rotation.
2. Review the [documented product behavior](https://docs.niteshift.dev/environment-configuration/overview) before applying the change.

**Automation:** No Niteshift admin write pack for this control. The linked source documents the procedure but does not establish a supported admin REST, GraphQL, SDK or Terraform operation for it.

#### Validation & Testing

Use disposable credential names and benign operations to verify intended access. Confirm the old credential no longer works at its issuer.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-5 |

### 2.4 Constrain Browser Session Access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6 |

#### Description

Use a seeded low-privilege nonproduction account. Treat recorded browser state and preview artifacts as sensitive and keep development-only authentication routes out of production.

#### Rationale

**Why This Matters:**

- The agent and preview share a browser authentication session per task.
- Screenshot or video evidence can expose data available to that identity.

**Attack Prevented:** Reduces the risk of unauthorized access or changes through this surface; not a guarantee of prevention.

#### ClickOps Implementation

1. Inspect the login service in the environment settings. For recorded sessions use **Settings → Environments → [environment] → Recorded sessions** only when necessary; revoke an exposed session at the application or identity provider.
2. Review the [documented product behavior](https://docs.niteshift.dev/environment-configuration/browser-authentication) before applying the change.

**Automation:** No Niteshift admin write pack for this control. The linked source documents the procedure but does not establish a supported admin REST, GraphQL, SDK or Terraform operation for it.

#### Validation & Testing

In a synthetic environment confirm a viewer without organization access cannot see the authenticated preview; verify the seeded identity has no privileged functions.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6 |

## 3. Agent Integrations and Automation

### 3.1 Constrain Extensions and Tool Credentials

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | CM-7 |

#### Description

Install only approved plugins and narrowly scoped MCP tools. Vet dependencies and hooks before adding a marketplace; configure privileges at the backing service, not solely in prompts.

#### Rationale

**Why This Matters:**

- Enabled Codex plugin hooks are trusted at task startup.
- Marketplace access and downstream service permissions are independent grants.

**Attack Prevented:** Reduces the risk of unauthorized access or changes through this surface; not a guarantee of prevention.

#### ClickOps Implementation

1. Open **Settings → Environments → [environment] → Plugins**, inspect each agent tab and remove unapproved marketplaces and plugins. Verify separate MCP integrations and credentials against the environment inventory.
2. Review the [documented product behavior](https://docs.niteshift.dev/customizing-agents/plugins) before applying the change.

**Automation:** No Niteshift admin write pack for this control. The linked source documents the procedure but does not establish a supported admin REST, GraphQL, SDK or Terraform operation for it.

#### Validation & Testing

Start a synthetic task and compare its loaded tools and plugins with the approved inventory; check that its service identity cannot do writes that were not approved.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | CM-7 |

### 3.2 Start Repository Automations Paused

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6 |

#### Description

Use a dedicated least-privilege service account and a paused repository automation until reviewed. Prefer HMAC when an approved webhook source supports it. Treat event text as data, not instructions.

#### Rationale

**Why This Matters:**

- Repository definitions synchronize from the default branch.
- The vendor accepts bearer authentication as well as HMAC; sender preference alone does not disable bearer.

**Attack Prevented:** Reduces the risk of unauthorized access or changes through this surface; not a guarantee of prevention.

#### ClickOps Implementation

1. Use the automation UI to pause superseded UI triggers. For repository-backed triggers, review the paused file under the environment configuration directory; merge only after reviewing branch, service-account permissions and task prompt.
2. Review the [documented product behavior](https://docs.niteshift.dev/automations.md) before applying the change.

#### Code Implementation

{% include pack-code.html vendor="niteshift" section="3.2" %}

#### Validation & Testing

Confirm the pilot automation is paused and does not launch tasks. Compare the exact intended identity and trigger count before enabling it; pause or revert if duplicated.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6 |

### 3.3 Limit Autonomous Changes and Evidence Exposure

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-6 |

#### Description

Use human review for CI- or comment-driven edits. Keep logs, screenshots and model inputs free of production data, and maintain a source-linked activity review.

#### Rationale

**Why This Matters:**

- Automated retries can propagate unintended changes.
- Task artifacts and code-review channels have different audiences.

**Attack Prevented:** Reduces the risk of unauthorized access or changes through this surface; not a guarantee of prevention.

#### ClickOps Implementation

1. Review the task and linked GitHub PR, check runs and comments. Cancel or pause unwanted work using the applicable task or automation controls and revoke credentials at their issuer if exposed.
2. Review the [documented product behavior](https://docs.niteshift.dev/autofix) before applying the change.

**Automation:** No Niteshift admin write pack for this control. The linked source documents the procedure but does not establish a supported admin REST, GraphQL, SDK or Terraform operation for it.

#### Validation & Testing

Trace a pilot task to its source, actor, commit and checks without storing tokens or raw browser state. Test rollback in the pilot environment.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-6 |

## 4. Compliance Quick Reference

| Area | Controls |
|------|----------|
| Repository and workload least privilege | 1.1, 1.2, 2.3, 3.2 |
| Configuration review and reduced exposure | 2.1, 2.2, 2.4, 3.1 |
| Operational evidence | 3.3 |

## Appendices

### Interface and Evidence Boundaries

| Surface | Finding |
|---------|---------|
| Config | Documented service manifest and repository automation front matter; operator checks do not enforce tenant policy by themselves. |
| CLI | First-party in-task `ns services status` and `ns automations export` documented. Status is read-only runtime evidence; export is migration, not a universal admin inventory. |
| API | Documented incoming task webhook is an execution trigger, not an admin API; public admin REST and GraphQL surfaces are unverified. |
| Terraform and SDK | Public provider resources, data sources and official admin SDKs not verified. |
| SIEM | Native audit export fields and supported destinations not verified. Use authorized GitHub and task evidence rather than inventing an audit schema. |
| Deployment prerequisites | Confirm plan and roles, federation trust claims and provider controls, audit/retention, offboarding, and egress behavior with the vendor before regulated use. Do not assume enforcement from docs silence. |

### References

- [Niteshift product documentation index](https://docs.niteshift.dev/llms.txt)
- [Environment configuration](https://docs.niteshift.dev/environment-configuration/overview)
- [Services and tunnels](https://docs.niteshift.dev/environment-configuration/services)
- [GitHub integration](https://docs.niteshift.dev/interfaces/github)
- [Repository automations](https://docs.niteshift.dev/automations.md)
- [Privacy policy](https://niteshift.dev/privacy-policy)

## Changelog

| Date | Version | Maturity | Changes | Author |
|------|---------|----------|---------|--------|
| 2026-11-18 | 0.1.0 | ai-drafted | Initial guide and Code Packs. | Codex |

## Contributing

See the [contribution guidelines](https://github.com/grcengineering/how-to-harden/blob/main/CONTRIBUTING.md).

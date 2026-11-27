---
layout: guide
title: "Qodo Hardening Guide"
vendor: "Qodo"
slug: "qodo"
tier: "3"
category: "AI/ML Platform"
description: "Qodo adds code review and governance to pull requests"
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

**Product Editions Covered:** Qodo 2.x Git review, Qodo portal and supported Git integrations

## Overview

Qodo adds code review and governance to pull requests. Protect access to the portal, treat repository inputs as lower-trust than administrative policy, and preserve human review of changes.

### Intended Audience

Platform administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Baseline controls for the documented deployment.
- **L2 (Walk):** Add verified controls where the workload needs stronger isolation.
- **L3 (Run):** Add controls warranted by higher-risk workflows and contractual requirements.

### Scope

Coverage is Qodo 2.x Git code review. Legacy Qodo Merge v1 and open-source PR-Agent may have different controls and precedence. Qodo retired its VS Code, JetBrains and Visual Studio Professional IDE plugins on November 1, 2026; Git PR review is unaffected.

---

## Table of Contents

1. [Identity](#1-identity)
2. [Review Governance](#2-review-governance)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

---

## 1. Identity

### 1.1 Enforce organizational single sign-on

**Profile Level:** L1 (Crawl)

#### Description

Connect an approved organization identity provider on eligible plans; apply access assignment and MFA there.

#### Rationale

- Qodo documents that successful setup enforces SSO and other authentication methods cannot be used in parallel.

#### Prerequisites

Qodo admin, entitled plan, IdP admin and tested recovery procedure.

#### ClickOps Implementation

1. Open the profile menu → **Account Management → Settings → Authentication → Configure**.
2. Choose the approved IdP and configure its connection in the WorkOS Admin Portal. Verify configured URLs and identity assignments.

Source: [Vendor configuration reference](https://docs.qodo.ai/account-management/single-sign-on-sso).

#### Code Implementation

No documented public Qodo SSO configuration API was verified.

#### Validation & Testing

Test assigned-user sign-in and verify an unassigned pilot does not gain access. Check another sign-in method is not available after enforcement.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Setup can affect all users because enforcement defaults on. Reserve an approved recovery window.

#### Rollback Procedure

Use documented IdP troubleshooting and vendor-supported recovery; do not assume parallel login remains available.

---

## 2. Review Governance

### 2.1 Require approval for imported review rules

**Profile Level:** L1 (Crawl)

#### Description

Do not automatically activate review rules from non-admin users, repository files, or the Rule Miner unless approved under a bounded exception.

#### Rationale

- An imported review rule does not establish organizational intent. Portal defaults also differ by onboarding cohort.

#### Prerequisites

Qodo admin; protected rules repositories and approved rule owners.

#### ClickOps Implementation

1. In **Configurations → Context → Review standards**, disable auto-approval of user suggestions, repository rules and Rule Miner suggestions wherever available.
2. Disable **REVIEW.md instructions** by default for untrusted repositories. Inspect already-active rules and file-based overrides.

Source: [Vendor configuration reference](https://docs.qodo.ai/configuration/context).

#### Code Implementation

Use the portal and verify effective precedence; no public mutation API is claimed.

#### Validation & Testing

Verify an unapproved benign rule remains pending and a default-branch or wiki override has not displaced the portal selection.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Some previously automatic guidance now requires review. Assign a rule owner and triage cadence.

#### Rollback Procedure

Restore only an approved scoped behavior and preserve review of previously queued rules.

---
### 2.2 Keep automated fixes out of protected source branches

**Profile Level:** L2 (Walk)

#### Description

Disable Remediation agent and Auto fix by default. If approved for a narrow pilot, retain Open a fix PR and existing human gates.

#### Rationale

- Qodo documents that disabling Open a fix PR can send changes directly to the source branch when remediation is enabled.

#### Prerequisites

Qodo admin, Git-host owner and independently enforced human review and checks.

#### ClickOps Implementation

1. Open **Configurations → Remediation** and turn off **Remediation agent** by default. Verify **Auto fix** is off where shown.
2. For an approved pilot only, ensure **Open a fix PR** remains enabled and protected branches still require human review and deterministic checks.

Source: [Vendor configuration reference](https://docs.qodo.ai/configuration/remediation).

#### Code Implementation

Verify from the console. No API or TOML mutation is claimed for these preview settings.

#### Validation & Testing

Check effective configuration at workspace, Git-org and repo levels. No autonomous writes should appear outside the approved path in a synthetic pilot.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Manual fixes require more maintainer time. This does not disable code review.

#### Rollback Procedure

Restore previous settings only for approved repositories without weakening branch protections.

---
### 2.3 Keep AI summaries separate from author descriptions

**Profile Level:** L2 (Walk)

#### Description

Publish Qodo summaries as comments instead of modifying the user’s original pull request description.

#### Rationale

- Reviewers need to distinguish the author’s change intent from generated descriptions and preserve the original evidence.

#### Prerequisites

Qodo 2.x, protected .pr_agent.toml and wiki configuration.

#### ClickOps Implementation

1. In **Configurations → Workflow → PR summary**, set **Comment location** to **Standalone comment**.
2. Verify the repository wiki, default-branch configuration and organization settings do not override it. For repository-as-code, merge the fragment into the existing table.

Source: [Vendor configuration reference](https://docs.qodo.ai/configuration/configuration-and-command-reference).

#### Code Implementation

The shell pack prints the native TOML fragment that sets Qodo 2.x publish_mode. Merge without duplicating the table or overwriting other settings.

{% include pack-code.html vendor="qodo" section="2.3" %}

#### Validation & Testing

Open a new private pilot PR after merging. Confirm the original description is unchanged and the summary appears in a separate comment.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Changes discussion layout only; notify users and preserve checks.

#### Rollback Procedure

Restore the prior publish mode in the controlling source.

---

## 3. Compliance Quick Reference

These mappings indicate how settings can contribute to a control objective; they do not establish conformity or operation over a period.

| HTH control | NIST SP 800-53 Rev. 5 | Evidence to retain |
| --- | --- | --- |
| 1.1 | IA-2 | Assigned and unassigned identity pilot |
| 2.1 | CM-3, CM-5 | Approval status and effective sources |
| 2.2 | CM-3, CM-5 | Remediation settings and human Git gates |
| 2.3 | AU-10 | Unchanged description and separate summary |

## Appendix A: Automation and Evidence

The TOML fragment controls summary presentation, not source-branch remediation or access rights. The Qodo Agentic Toolbox CLI is not a verified organization administration CLI. No live verification was performed.

## Appendix B: References

- [Portal hierarchy and file precedence](https://docs.qodo.ai/configuration/portal-configuration)
- [Default branch and wiki configuration](https://docs.qodo.ai/configuration/configuration-file)
- [Git provider support](https://docs.qodo.ai/install-qodo/git-provider-feature-support)

- [Workflow and PR summary settings](https://docs.qodo.ai/configuration/workflow)
- [Qodo IDE plugin retirement](https://docs.qodo.ai/qodo-ide-plugin-deprecation)

## Changelog

| Date | Version | Maturity | Changes | Author |
| --- | --- | --- | --- | --- |
| 2026-11-27 | 0.1.0 | ai-drafted | Initial platform controls and documented verification packs | How to Harden Community |

## Contributing

Report inaccurate or outdated guidance through the [issue tracker](https://github.com/grcengineering/how-to-harden/issues).

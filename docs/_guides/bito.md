---
layout: guide
title: "Bito Hardening Guide"
vendor: "Bito"
slug: "bito"
tier: "3"
category: "AI/ML Platform"
description: "Bito’s AI Code Review Agent reads pull requests and repository context and posts reviews"
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

**Product Editions Covered:** Bito-hosted GitHub AI Code Review Agent and documented self-hosted review configuration

## Overview

Bito’s AI Code Review Agent reads pull requests and repository context and posts reviews. Its hosting mode, Git installation permissions, and treatment of repository instructions are separate security decisions.

### Intended Audience

Platform administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Baseline controls for the documented deployment.
- **L2 (Walk):** Add verified controls where the workload needs stronger isolation.
- **L3 (Run):** Add controls warranted by higher-risk workflows and contractual requirements.

### Scope

Covers GitHub App repository selection, centrally approved agent behavior and optional scanner feedback. The IDE extension, AI Architect and its MCP integration are separate surfaces.

---

## Table of Contents

1. [Integration Access](#1-integration-access)
2. [Review Trust Boundary](#2-review-trust-boundary)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

---

## 1. Integration Access

### 1.1 Limit GitHub App repository access

**Profile Level:** L1 (Crawl)

#### Description

Use selected repositories for the Bito GitHub App installation and activate Bito reviews only where approved.

#### Rationale

- Disabling review in Bito does not remove the app’s repository access granted at GitHub.

#### Prerequisites

GitHub organization owner, Bito workspace admin and an approved repository list.

#### ClickOps Implementation

1. Configure the Bito GitHub App installation in GitHub for **Only select repositories**.
2. In Bito, open **Code Review → Repositories** and enable **Code Review Status** only for approved repositories. Compare both scopes to the same inventory.

Source: [Vendor configuration reference](https://docs.bito.ai/ai-code-reviews-in-git/install-run-using-bito-cloud/guide-for-github).

#### Code Implementation

No Bito-native organization installation-policy API was verified. Verify both the GitHub app installation and the Bito console.

#### Validation & Testing

Verify that an approved test repository appears in Bito and an excluded repository is not accessible to the installation. Check permission changes on app upgrades.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Removing a repository can stop reviews and related checks; coordinate branch protection changes without dropping independent required checks.

#### Rollback Procedure

Re-add only the explicitly reapproved repository in both planes.

---

## 2. Review Trust Boundary

### 2.1 Disallow repository-controlled review policy by default

**Profile Level:** L1 (Crawl)

#### Description

Keep production review settings centrally managed. Disable repository config overrides and automatic ingestion of agent instruction files unless a narrow, documented exception is approved.

#### Rationale

- Bito documents reading the configuration file from the source branch of the pull request. Repository-controlled settings and instructions are not equivalent to admin-approved policy.

#### Prerequisites

Workspace admin plus an independent Git-host review and CI policy.

#### ClickOps Implementation

1. Open **Code Review → Repositories → Settings** for the Agent.
2. In **Review details**, turn off **Allow config file settings** and **Auto-apply agent rules**. Review **Adaptive learning**, **Auto reply**, and applied guidelines separately.
3. In a documented exception using repo config, retain the admin default and explicitly disable repo-level guidelines in the approved baseline.

Source: [Vendor configuration reference](https://docs.bito.ai/ai-code-reviews-in-git/install-run-using-bito-cloud/create-or-customize-an-agent-instance).

#### Code Implementation

This opt-in exception fragment is for the exact repo setting, not the admin toggle. Merge into a reviewed YAML file only if the exception is approved.

{% include pack-code.html vendor="bito" section="2.1" %}

#### Validation & Testing

Save and reopen the Agent settings. Use a harmless fixture PR to verify expected policy. For exceptions, treat the repo file as a requested local default only, not proof of centralized enforcement.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Existing repo-specific review behavior may stop. Move approved instructions to the admin-managed profile.

#### Rollback Procedure

Restore the recorded prior values on the approved pilot agent only.

---
### 2.2 Enable independent and supplemental secret checks

**Profile Level:** L1 (Crawl)

#### Description

Enable Bito Secret Scanner feedback where approved, and keep an independent non-AI secret scan as a required check.

#### Rationale

- A supplemental review signal may miss findings or repeat sensitive context in comments. Independent checks and private remediation remain necessary.

#### Prerequisites

Agent admin for SaaS, or access to the approved self-hosted configuration. A private synthetic review repository.

#### ClickOps Implementation

1. On Bito-hosted, open **Code Review → Repositories → Settings → Tools** and enable **Secret Scanner**.
2. On self-hosted, merge the documented key into the existing properties file and roll out through the operator’s normal change process. Retain independent protection.

Source: [Vendor configuration reference](https://docs.bito.ai/ai-code-reviews-in-git/install-run-as-a-self-hosted-service/agent-configuration-bito-cra.properties-file).

#### Code Implementation

The shell pack prints one native properties setting for self-hosted Bito. Add only that key to the existing bito-cra.properties; do not overwrite it.

{% include pack-code.html vendor="bito" section="2.2" %}

#### Validation & Testing

Use a vendor-safe synthetic fixture and verify the resulting finding without posting a real credential. Inspect default file exclusions and independently cover configuration files.

#### Monitoring & Maintenance

Review after configuration, entitlement or deployment changes. Record scope, time, expected result and evidence in the change ticket. Preserve access restrictions on evidence.

#### Operational Impact

Additional review noise is possible. Treat any displayed credential as sensitive and handle it under the local incident process.

#### Rollback Procedure

Restore only the prior Bito setting if necessary; do not remove the independent check.

---

## 3. Compliance Quick Reference

These mappings indicate how settings can contribute to a control objective; they do not establish conformity or operation over a period.

| HTH control | NIST SP 800-53 Rev. 5 | Evidence to retain |
| --- | --- | --- |
| 1.1 | AC-6 | Allowlisted GitHub App repositories and active Bito review list |
| 2.1 | CM-5, CM-6 | Effective admin controls and reviewed exceptions |
| 2.2 | SI-4 | Redacted fixture outcome and independent scan |

## Appendix A: Automation and Evidence

Bito-hosted agent settings and GitHub App grants require console or Git-host verification. Local fragments express review configuration, not permission enforcement. Self-hosted processing can still send context to Bito and an upstream model provider; approve the actual data flow. Do not include tokens in configuration tracked by Git. No live deployment verification was performed.

## Appendix B: References

- [Bito privacy and security](https://docs.bito.ai/privacy-and-security)
- [Bito configuration modes](https://docs.bito.ai/ai-code-reviews-in-git/agent-settings)
- [Repository overrides](https://docs.bito.ai/ai-code-reviews-in-git/agent-settings/repo-level-settings)

## Changelog

| Date | Version | Maturity | Changes | Author |
| --- | --- | --- | --- | --- |
| 2026-11-27 | 0.1.0 | ai-drafted | Initial platform controls and documented verification packs | How to Harden Community |

## Contributing

Report inaccurate or outdated guidance through the [issue tracker](https://github.com/grcengineering/how-to-harden/issues).

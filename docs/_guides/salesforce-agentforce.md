---
layout: guide
title: "Salesforce Agentforce Hardening Guide"
vendor: "Salesforce Agentforce"
slug: "salesforce-agentforce"
platform: "Salesforce"
platform_slug: "salesforce"
product: "Agentforce"
tier: "2"
category: "AI/ML Platform"
description: "Harden Salesforce Agentforce execution identities, exposed actions and release evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

This is a product guide in the [Salesforce platform](/guides/salesforce/). Apply the CRM baseline first and verify agent controls separately.

## Overview

Agentforce runs within Salesforce orgs but adds agent identities, channel bindings, action definitions and an agent-specific release process. Apply the Salesforce CRM baseline as a prerequisite, not as proof that any agent is appropriately scoped.

### Intended Audience

- Tenant administrators and owners of the affected integrations
- Security engineers and assurance reviewers collecting configuration evidence

### How to Use This Guide

L1 (Crawl) covers foundational configuration and evidence. Review current controls and owners first, then pilot changes using nonproduction accounts and synthetic records.

### Scope

This starter guide covers the three control areas below. Edition, release, tenant and authorization conditions can affect exact availability. Documentation-derived console paths have not been tested in a live customer tenant. Read-only packs collect narrow evidence; they do not score tenant compliance or apply remediation.

## Table of Contents

1. [Security Configuration](#1-security-configuration)
2. [Compliance Quick Reference](#2-compliance-quick-reference)

## 1. Security Configuration

### 1.1 Scope the execution identity

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AC-6

#### Description

Limit agent and signed-in identities to the records, fields and actions required by the selected channel.

#### Rationale

- A service agent running as a dedicated user can see or modify data granted to that user. A customer context variable identifies a subject but does not itself restrict record access.

#### ClickOps Implementation

In **Agentforce Builder → Agent Access**, review the agent's user record and assigned permissions. For service channels using the agent user, start with the generated minimal user, tailor the agent-specific permission set, and review sharing, role hierarchy, and field permissions. For channels running as the logged-in user, review that user's grants instead.

Source: [Salesforce Agentforce documentation](https://help.salesforce.com/s/articleView?id=ai.agent_user.htm&language=en_US&type=5) (checked 2026-11-27).

**Automation:** This guide does not automate edits to permissions or substitute a metadata inventory for effective access testing.

#### Validation & Testing

In a sandbox, exercise normal tasks with synthetic records, then verify an unrelated record and field remain outside the approved identity's reach. Confirm which identity executed each test.

---

### 1.2 Constrain actions and trusted data

**Profile Level:** L1 (Crawl)

**NIST 800-53:** CM-7

#### Description

Expose only reviewed business actions and the minimum relevant grounding sources.

#### Rationale

- Every enabled action is an additional route from a conversation to data retrieval or mutation. Descriptive prompts are not an authorization boundary.

#### ClickOps Implementation

In the agent builder, review the configured business topics or subagents and actions. Retain only approved flows, Apex and integrations and restrict access to sensitive records and fields at the data layer. For protected tasks, implement verified identity and action eligibility conditions before connecting the channel.

Source: [Salesforce Agentforce documentation](https://help.salesforce.com/s/articleView?id=005315874&language=en_US&type=1) (checked 2026-11-27).

**Automation:** Agentforce DX supports authoring and publication, but this guide does not automate live policy edits.

#### Validation & Testing

In a development org, confirm expected actions handle synthetic eligible requests and do not act on out-of-scope or unverified requests. Inspect recorded action traces for unintended writes.

---

### 1.3 Inventory release tests before activation

**Profile Level:** L1 (Crawl)

**NIST 800-53:** SA-11

#### Description

Require named, reviewed agent tests before deployment, and keep the result separately from the inventory.

#### Rationale

- An unrestricted or untested action can ship when the agent behavior changes even though baseline Salesforce controls did not change.

#### ClickOps Implementation

In **Agentforce Studio** (next-generation testing) or **Testing Center** (legacy), confirm the approved agent tests exist for the intended org and version. Review covered channels, record-access boundaries and any write action; use synthetic records and a development org before activating the agent.

Source: [Salesforce Agentforce documentation](https://developer.salesforce.com/docs/ai/agentforce/guide/agent-dx-test-run.html) (checked 2026-11-27).

**Automation:** First-party Salesforce CLI lists test definitions without starting a run.

#### Code Implementation

{% include pack-code.html vendor="salesforce-agentforce" section="1.3" %}

#### Validation & Testing

Compare the available test API names to your release checklist, run approved tests in the development org and retain results. A listed definition does not prove a successful or meaningful test.

## 2. Compliance Quick Reference

These mappings support control objectives; they are not claims of certification or compliance.

| HTH control | Objective | NIST SP 800-53 Rev. 5 |
|-------------|-----------|-----------------------|
| 1.1 | Scope the execution identity | AC-6 |
| 1.2 | Constrain actions and trusted data | CM-7 |
| 1.3 | Inventory release tests before activation | SA-11 |

### References

- [Coverage and validation boundaries](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/sspm-data-platform-source-coverage.md)
- [Salesforce CLI agent commands](https://developer.salesforce.com/docs/platform/salesforce-cli-reference/guide/cli_reference_agent.html)
- [List Agentforce test definitions](https://developer.salesforce.com/docs/platform/salesforce-cli-reference/guide/cli_reference_agent_test_list.html)
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)

## Changelog

| Version | Date | Maturity | Changes |
|---------|------|----------|---------|
| 0.1.0 | 2026-11-27 | ai-drafted | Initial controls and evidence pack; no live tenant verification. |

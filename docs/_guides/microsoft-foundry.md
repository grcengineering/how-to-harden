---
layout: guide
title: "Microsoft Foundry Hardening Guide"
vendor: "Microsoft Foundry"
slug: "microsoft-foundry"
platform: "Microsoft"
platform_slug: "microsoft-365"
product: "Microsoft Foundry"
tier: "3"
category: "AI/ML Platform"
description: "Harden Microsoft Foundry account authentication, project identity and agent networking."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

This product is listed under the [Microsoft platform](/guides/microsoft-365/). It requires its own control-plane settings.

## Overview

Harden Microsoft Foundry account authentication, project identity and agent networking.

**Validation status:** Documented control paths and offline Code Pack behavior; no live tenant, credentials, or production changes. License and effective permissions may limit visibility.

### Intended Audience

Platform owners, identity administrators, and security reviewers.

### How to Use This Guide

- **L1 (Crawl):** Establish accountable identities and least privilege.
- **L2 (Walk):** Add narrower access boundaries and independent monitoring.

### Scope

Microsoft Foundry account/project resources using the ARM Cognitive Services AIServices account model. Classic hubs, Azure OpenAI-only account kinds, Microsoft Copilot Studio and other AI services are not assessed. Review region and agent feature availability before applying any change.

## Table of Contents

1. [Access and Administration](#1-access-and-administration)
2. [Sharing, Integrations and Audit](#2-sharing-integrations-and-audit)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Access and Administration

### 1.1 Disable local keys after migrating clients

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-5, AC-6 |

#### Description

Use supported Entra authentication and verify that local keys are disabled for the intended Foundry account.

#### Rationale

**Why This Matters:**

- ARM settings can change before the data plane stops accepting previously valid keys. Other connected services can retain their own credentials.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://learn.microsoft.com/en-us/azure/ai-services/disable-local-auth).
2. Reconcile every approved consumer and transition to Entra identities with the required data-plane roles. Confirm recovery before disabling local auth through approved Azure Policy, ARM or PowerShell workflow.

**Automation:** The read-only Azure CLI example verifies resource identity and reports the configured flags without using result inference as data-plane verification.

#### Code Implementation

{% include pack-code.html vendor="microsoft-foundry" section="1.1" %}

#### Validation & Testing

Check ARM configuration for the exact account. In a test environment verify approved Entra requests and a normal request with a previously approved test key after propagation; do not output the key.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-5, AC-6 |

### 1.2 Scope project identities and connection permissions

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, AC-6 |

#### Description

Review account, project, agent and connected-service roles separately and prefer appropriate managed identities.

#### Rationale

**Why This Matters:**

- A project agent can inherit access to Storage, Search or Cosmos DB through its project identity. Management permissions and data access are not interchangeable.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://learn.microsoft.com/en-us/azure/foundry/agents/how-to/virtual-networks).
2. In the Foundry project and linked service consoles, review identities and connection grants. Remove unnecessary broad grants only after validation of the affected workflow; document where shared identities cannot be avoided.

**Automation:** No agent runs, token creation or role modification are included.

#### Validation & Testing

With benign test data, confirm only intended resources are available and review delegated or on-behalf-of flows separately from managed identities.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, AC-6 |

## 2. Sharing, Integrations and Audit

### 2.1 Validate inbound and outbound isolation independently

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | SC-7, AC-4 |

#### Description

Use approved private access and narrow agent egress where supported.

#### Rationale

**Why This Matters:**

- An account-level public network flag is only an inbound control. Managed networking, private endpoints, dependency DNS and outbound isolation vary by agent setup and region.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://learn.microsoft.com/en-us/azure/foundry/how-to/managed-virtual-network).
2. Map callers and dependencies; establish private endpoints and DNS first. Use the documented managed or bring-your-own network design for the agent. Plan unsupported features and configuration-at-creation constraints as separate deployment decisions.

**Automation:** Reading the account flags does not attest private DNS, egress, agent execution or downstream network policy.

#### Validation & Testing

From expected approved networks, verify endpoints and dependency access; from an approved test network outside the boundary, verify the expected denial without running sensitive workloads.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | SC-7, AC-4 |

## 3. Compliance Quick Reference

These mappings support control design; they are not evidence of certification or operating effectiveness.

| Section | Control | NIST SP 800-53 Rev. 5 |
|---------|---------|-----------------------|
| 1.1 | Disable local keys after migrating clients | IA-5, AC-6 |
| 1.2 | Scope project identities and connection permissions | AC-3, AC-6 |
| 2.1 | Validate inbound and outbound isolation independently | SC-7, AC-4 |

## Changelog

- **0.1.0 (2026-11-27):** Initial guide and documented automation examples.

---
layout: guide
title: "Microsoft Azure Hardening Guide"
vendor: "Microsoft Azure"
slug: "microsoft-azure"
platform: "Microsoft"
platform_slug: "microsoft-365"
product: "Microsoft Azure"
tier: "3"
category: "IT Operations"
description: "Harden commercial Azure management-group governance, inherited access and Azure activity evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

This product is listed under the [Microsoft platform](/guides/microsoft-365/). It requires its own control-plane settings.

## Overview

Harden commercial Azure management-group governance, inherited access and Azure activity evidence.

**Validation status:** Documented control paths and offline Code Pack behavior; no live tenant, credentials, or production changes. License and effective permissions may limit visibility.

### Intended Audience

Platform owners, identity administrators, and security reviewers.

### How to Use This Guide

- **L1 (Crawl):** Establish accountable identities and least privilege.
- **L2 (Walk):** Add narrower access boundaries and independent monitoring.

### Scope

Azure Resource Manager management groups, subscriptions and Azure Policy. The [Microsoft Entra ID guide](/guides/microsoft-entra-id/) covers the separate directory plane; [Microsoft Foundry](/guides/microsoft-foundry/) covers the separate AI service control plane. Not a complete Azure resource or Marketplace application baseline.

## Table of Contents

1. [Access and Administration](#1-access-and-administration)
2. [Sharing, Integrations and Audit](#2-sharing-integrations-and-audit)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Access and Administration

### 1.1 Inventory inherited management-group policies

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | CM-6, AC-3 |

#### Description

Establish a reviewed management-group hierarchy and account for assigned policies and exemptions.

#### Rationale

**Why This Matters:**

- A visible assignment does not necessarily enforce a deny. Effect, enforcement mode, resource selectors, excluded scopes, exemptions and remediation action are separate.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://learn.microsoft.com/en-us/azure/governance/policy/overview).
2. Open Management groups and Azure Policy → Assignments at the relevant scope. Compare policy definitions and initiative parameters, review exceptions and test guardrails in a nonproduction subscription before enforcement.

**Automation:** The CLI pack lists visible management-group/ancestor assignment metadata, not resource compliance, exemption evaluation or effective control outcome.

#### Code Implementation

{% include pack-code.html vendor="microsoft-azure" section="1.1" %}

#### Validation & Testing

Verify the selected tenant and management-group IDs, reconcile the applicable assignments and check compliance or representative affected resources independently.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | CM-6, AC-3 |

### 1.2 Constrain inherited RBAC and reader integrations

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6, AC-2 |

#### Description

Keep role grants at the smallest management scope that meets documented coverage.

#### Rationale

**Why This Matters:**

- Azure RBAC on subscriptions and management groups is distinct from Microsoft Entra directory permissions and workload data-plane roles.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://learn.microsoft.com/en-us/azure/role-based-access-control/role-assignments-list-cli).
2. In Access control (IAM), review direct and inherited privileged users, groups and service principals. [Okta’s Azure integration](https://help.okta.com/ispm/en-us/content/topics/ispm/microsoft-azure.htm) requires the separate Entra connector and Azure Reader at the selected scope; authorize subscriptions before accepting broader root scope.

**Automation:** No grants, policy writes or Entra changes are included.

#### Validation & Testing

Compare group membership and inherited role grants to approvals, test a selected workload identity, and review data-plane access separately.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6, AC-2 |

## 2. Sharing, Integrations and Audit

### 2.1 Retain and review subscription activity

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-6, AU-9 |

#### Description

Route administrative activity to a protected destination on each applicable subscription.

#### Rationale

**Why This Matters:**

- Activity Log reports control-plane events; it is not equivalent to resource diagnostic logs or the Entra sign-in log.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://learn.microsoft.com/en-us/azure/azure-monitor/essentials/activity-log).
2. In Monitor → Activity log look at diagnostic settings and approved destinations for each subscription. Protect retention and access; enable relevant resource logs through separate procedures.

**Automation:** The Azure Policy inventory does not test ingestion.

#### Validation & Testing

Locate an authorized benign change in the intended destination with subscription, actor and operation; record coverage gaps.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-6, AU-9 |

## 3. Compliance Quick Reference

These mappings support control design; they are not evidence of certification or operating effectiveness.

| Section | Control | NIST SP 800-53 Rev. 5 |
|---------|---------|-----------------------|
| 1.1 | Inventory inherited management-group policies | CM-6, AC-3 |
| 1.2 | Constrain inherited RBAC and reader integrations | AC-6, AC-2 |
| 2.1 | Retain and review subscription activity | AU-6, AU-9 |

## Changelog

- **0.1.0 (2026-11-27):** Initial guide and documented automation examples.

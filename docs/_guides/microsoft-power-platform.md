---
layout: guide
title: "Microsoft Power Platform Hardening Guide"
vendor: "Microsoft Power Platform"
slug: "microsoft-power-platform"
platform: "Microsoft"
platform_slug: "microsoft-365"
product: "Microsoft Power Platform"
tier: "3"
category: "Productivity"
description: "Harden tenant-wide Power Platform governance, data policies and cross-tenant connector boundaries."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

This product is listed under the [Microsoft platform](/guides/microsoft-365/). It requires its own control-plane settings.

## Overview

Harden tenant-wide Power Platform governance, data policies and cross-tenant connector boundaries.

**Validation status:** Documented control paths and offline Code Pack behavior; no live tenant, credentials, or production changes. License and effective permissions may limit visibility.

### Intended Audience

Platform owners, identity administrators, and security reviewers.

### How to Use This Guide

- **L1 (Crawl):** Establish accountable identities and least privilege.
- **L2 (Walk):** Add narrower access boundaries and independent monitoring.

### Scope

Power Platform tenant governance across Power Apps and Power Automate environments. [Copilot Studio](/guides/copilot-studio/) covers separate agent controls; [Dynamics 365](/guides/microsoft-dynamics-365/) covers Dataverse-backed apps. Neither product replaces tenant governance.

## Table of Contents

1. [Access and Administration](#1-access-and-administration)
2. [Sharing, Integrations and Audit](#2-sharing-integrations-and-audit)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Access and Administration

### 1.1 Separate and inventory production environments

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | CM-8, AC-2 |

#### Description

Track environment IDs, owners, type, geographic scope and authorized maker populations.

#### Rationale

**Why This Matters:**

- Admin Center visibility depends on role and environment membership; a single operator output may omit environments.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://learn.microsoft.com/en-us/troubleshoot/power-platform/dataverse/environment-app-access/troubleshoot-missing-environments).
2. In the admin center select Manage → Environments and reconcile production, sandbox and default environments to the inventory. Review group access and restrict production makers.

**Automation:** Native CLI counts visible environments and confirms a known environment is present in the current preselected authentication context; no identity is created or elevated.

#### Code Implementation

{% include pack-code.html vendor="microsoft-power-platform" section="1.1" %}

#### Validation & Testing

Compare the results against the tenant owner’s independent inventory and note any environments not visible to the chosen operator.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | CM-8, AC-2 |

### 1.2 Separate connector classes and scope each data policy

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-4, CM-6 |

#### Description

Use reviewed tenant-wide defaults and documented connector grouping and blocked settings.

#### Rationale

**Why This Matters:**

- Non-business grouping is not a universal deny; eligible connector blocking, overlapping policies and applicable environments need separate review.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://learn.microsoft.com/en-us/power-platform/admin/prevent-data-loss?tabs=new).
2. In Policies → Data policies inventory relevant policies, account for included and excluded environments, classify connectors and review custom connectors. Pilot changes to lower environments first.

**Automation:** No policy updates are automated.

#### Validation & Testing

Confirm the intended environment’s policies and run a harmless allowed and prohibited connector combination with approved non-sensitive data.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-4, CM-6 |

## 2. Sharing, Integrations and Audit

### 2.1 Restrict cross-tenant connector use

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-4, AC-17 |

#### Description

Use tenant isolation for applicable Microsoft Entra-authenticated connectors and manage explicit exceptions.

#### Rationale

**Why This Matters:**

- Tenant isolation is not equivalent to inspecting every connection or constraining every authentication mechanism.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://learn.microsoft.com/en-us/power-platform/guidance/adoption/data-protection).
2. Review allowed inbound and outbound tenant requests under the admin center controls. Approve the minimum exception scope and pilot dependencies before setting isolation.

**Automation:** No tenant setting or test flow is changed by the pack.

#### Validation & Testing

Check communication with an approved tenant and the expected denial for a controlled unapproved test tenant. Verify non-Entra connectors independently.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-4, AC-17 |

## 3. Compliance Quick Reference

These mappings support control design; they are not evidence of certification or operating effectiveness.

| Section | Control | NIST SP 800-53 Rev. 5 |
|---------|---------|-----------------------|
| 1.1 | Separate and inventory production environments | CM-8, AC-2 |
| 1.2 | Separate connector classes and scope each data policy | AC-4, CM-6 |
| 2.1 | Restrict cross-tenant connector use | AC-4, AC-17 |

## Changelog

- **0.1.0 (2026-11-27):** Initial guide and documented automation examples.

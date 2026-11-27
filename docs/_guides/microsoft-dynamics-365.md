---
layout: guide
title: "Microsoft Dynamics 365 Hardening Guide"
vendor: "Microsoft Dynamics 365"
slug: "microsoft-dynamics-365"
platform: "Microsoft"
platform_slug: "microsoft-365"
product: "Microsoft Dynamics 365"
tier: "3"
category: "Productivity"
description: "Harden Dataverse-backed Dynamics 365 Online application access and audit settings."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Harden Dataverse-backed Dynamics 365 Online application access and audit settings.

**Validation status:** Documented control paths and offline Code Pack behavior; no live tenant, credentials, or production changes. License and effective permissions may limit visibility.

### Intended Audience

Platform owners, identity administrators, and security reviewers.

### How to Use This Guide

- **L1 (Crawl):** Establish accountable identities and least privilege.
- **L2 (Walk):** Add narrower access boundaries and independent monitoring.

### Scope

Scope: online Dataverse-backed customer engagement apps such as Sales and Customer Service. Not Finance and Operations, Business Central, on-premises, or tenant-wide [Power Platform](/guides/microsoft-power-platform/) governance. Independently apply the [Microsoft 365](/guides/microsoft-365/) and [Entra ID](/guides/microsoft-entra-id/) identity baseline.

## Table of Contents

1. [Access and Administration](#1-access-and-administration)
2. [Sharing, Integrations and Audit](#2-sharing-integrations-and-audit)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Access and Administration

### 1.1 Restrict environment users and effective Dataverse roles

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-2, AC-6 |

#### Description

Gate production environment access with an approved Entra group and review Dataverse business units, teams and app roles.

#### Rationale

**Why This Matters:**

- Dataverse security role rights are cumulative; environment access alone does not define record-level access.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://learn.microsoft.com/en-us/power-platform/admin/security-roles-privileges).
2. In Power Platform admin center select the Dynamics environment and review its security group and Settings → Users + permissions. Use least-privilege application and user roles and review team-derived privileges separately.

**Automation:** The native CLI lists role definitions in the exact Dataverse environment; it does not show membership or effective privileges.

#### Code Implementation

{% include pack-code.html vendor="microsoft-dynamics-365" section="1.1" %}

#### Validation & Testing

Verify account and team membership, an approved record operation and an out-of-scope benign record with representative nonproduction roles. Keep environment and data-plane permissions distinct.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-2, AC-6 |

### 1.2 Confirm the environment audit configuration

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-12, AU-11 |

#### Description

Enable applicable Dataverse environment, table and column auditing, with reviewed retention and access-log settings.

#### Rationale

**Why This Matters:**

- Enabling environment auditing does not prove that a given table or column is audited. Audit data can be sensitive.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://learn.microsoft.com/en-us/power-platform/admin/manage-dataverse-auditing).
2. Under environment Settings → Audit and logs → Audit settings, confirm organization audit and applicable access logging. Review specific tables and columns plus storage and retention requirements.

**Automation:** A read-only Web API pack reports selected organization flags, not records, audit history or effective table coverage.

#### Code Implementation

{% include pack-code.html vendor="microsoft-dynamics-365" section="1.2" %}

#### Validation & Testing

Read the configured organization flags and verify an approved test record change reaches the intended Audit History. Record which access events and tables remain out of scope.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-12, AU-11 |

## 2. Sharing, Integrations and Audit

### 2.1 Constrain Dynamics integration identities

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6, IA-5 |

#### Description

Use named application users with separate credentials, ownership and scoped Dataverse roles.

#### Rationale

**Why This Matters:**

- An Entra registration can acquire data-plane access through its Dataverse application user; lifecycle of the app and local role grants differ.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://learn.microsoft.com/en-us/power-platform/admin/manage-application-users).
2. In the environment’s Users + permissions → Application users, reconcile app IDs and security roles. Use approved managed credentials and change processes when rotating or disabling the app.

**Automation:** No authentication grant, token issuance, or user modification is included.

#### Validation & Testing

Verify an approved workload action and expected denial against representative non-sensitive test records. Reconcile all environment copies separately.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6, IA-5 |

## 3. Compliance Quick Reference

These mappings support control design; they are not evidence of certification or operating effectiveness.

| Section | Control | NIST SP 800-53 Rev. 5 |
|---------|---------|-----------------------|
| 1.1 | Restrict environment users and effective Dataverse roles | AC-2, AC-6 |
| 1.2 | Confirm the environment audit configuration | AU-12, AU-11 |
| 2.1 | Constrain Dynamics integration identities | AC-6, IA-5 |

## Changelog

- **0.1.0 (2026-11-27):** Initial guide and documented automation examples.

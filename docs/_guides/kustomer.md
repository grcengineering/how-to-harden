---
layout: guide
title: "Kustomer Hardening Guide"
vendor: "Kustomer"
slug: "kustomer"
tier: "3"
category: "Productivity"
description: "Harden Kustomer workforce access, workload credentials, network settings and audit monitoring."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Harden Kustomer workforce access, workload credentials, network settings and audit monitoring.

**Validation status:** Documented control paths and offline Code Pack behavior; no live tenant, credentials, or production changes. License and effective permissions may limit visibility.

### Intended Audience

Platform owners, identity administrators, and security reviewers.

### How to Use This Guide

- **L1 (Crawl):** Establish accountable identities and least privilege.
- **L2 (Walk):** Add narrower access boundaries and independent monitoring.

### Scope

Kustomer SaaS administration; distinguish agent sign-in, customer-facing channels and machine-user API access. Entitlements and regional API domains differ.

## Table of Contents

1. [Access and Administration](#1-access-and-administration)
2. [Sharing, Integrations and Audit](#2-sharing-integrations-and-audit)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Access and Administration

### 1.1 Enforce controlled team sign-in

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-2(1), AC-2 |

#### Description

Use supported SAML with IdP MFA and narrow user permission sets.

#### Rationale

**Why This Matters:**

- Enabling SAML does not necessarily disable direct credentials; collaborators may have a separate provisioning path.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://help.kustomer.com/en_us/categories/authenticate-users-S15_8jB48).
2. In Settings → Security → Authentication configure SAML and verify managed access before turning off direct Kustomer login. Review permissions using [Define user access](https://help.kustomer.com/define-user-access-S17nw7IJv). Record approved recovery procedures.

**Automation:** No sign-in enforcement write is included.

#### Validation & Testing

Verify an assigned and unassigned test identity and confirm effective permissions in an approved role.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | IA-2(1), AC-2 |

### 1.2 Review API keys and machine-user roles

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6, IA-5 |

#### Description

Use distinct named machine users and narrowly scoped API-key roles.

#### Rationale

**Why This Matters:**

- Agent restrictions and IdP controls are not proof of API-key scope.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://developer.kustomer.com/docs/get-started/api-keys-and-roles).
2. Review keys, owning workloads, roles and documented expiration or rotation process. Grant only the required actions. Prefer the narrow audit-read role rather than broad admin access for a collector.

**Automation:** No key rotation or role modification is implemented.

#### Validation & Testing

Test the approved workload operation in a safe tenant and reconcile configured permissions to the owner and use case.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6, IA-5 |

## 2. Sharing, Integrations and Audit

### 2.1 Control support and agent network access

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, AC-17 |

#### Description

Review support access and use approved team-member ranges where available.

#### Rationale

**Why This Matters:**

- Agent IP ranges are plan-dependent, and changes apply when a token expires. Do not infer these ranges constrain machine-user API access.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://help.kustomer.com/manage-kustomer-access-Sk9na9x_).
2. Open Settings → Security → Kustomer Access. Verify a working administrator route before narrowing ranges and retain approved egress. Disable unnecessary vendor support access and use temporary approved access when support needs it.

**Automation:** This control does not alter production ranges or support access.

#### Validation & Testing

Test expected team login outcomes with fresh test sessions and verify known changes in the audit log.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, AC-17 |

### 2.2 Validate bounded audit evidence

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-6, AU-12 |

#### Description

Use the documented organization audit log and limit collection to approved events.

#### Rationale

**Why This Matters:**

- Audit attributes can contain personal data, IPs and before/after changes. Retention depends on plan.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://developer.kustomer.com/api/core-resources/query-events-associated-with-your-organization).
2. In Settings → Security → Audit Log review applicable events. Use a dedicated audit-read integration for SIEM if approved; protect data at ingestion and document retention.

**Automation:** The pack counts one page of user audit events without emitting payloads. It does not store events or follow next-page URLs.

#### Code Implementation

{% include pack-code.html vendor="kustomer" section="2.2" %}

#### Validation & Testing

Generate a benign approved user event and verify actor and time in console. Confirm the API can retrieve the expected object-type slice without relying on one page for complete coverage.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-6, AU-12 |

## 3. Compliance Quick Reference

These mappings support control design; they are not evidence of certification or operating effectiveness.

| Section | Control | NIST SP 800-53 Rev. 5 |
|---------|---------|-----------------------|
| 1.1 | Enforce controlled team sign-in | IA-2(1), AC-2 |
| 1.2 | Review API keys and machine-user roles | AC-6, IA-5 |
| 2.1 | Control support and agent network access | AC-3, AC-17 |
| 2.2 | Validate bounded audit evidence | AU-6, AU-12 |

## Changelog

- **0.1.0 (2026-11-27):** Initial guide and documented automation examples.

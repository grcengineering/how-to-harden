---
layout: guide
title: "Tresorit Hardening Guide"
vendor: "Tresorit"
slug: "tresorit"
tier: "3"
category: "Productivity"
description: "Harden Tresorit subscription roles, device and sharing policies, and monitoring."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Harden Tresorit subscription roles, device and sharing policies, and monitoring.

**Validation status:** Documented control paths and offline Code Pack behavior; no live tenant, credentials, or production changes. License and effective permissions may limit visibility.

### Intended Audience

Platform owners, identity administrators, and security reviewers.

### How to Use This Guide

- **L1 (Crawl):** Establish accountable identities and least privilege.
- **L2 (Walk):** Add narrower access boundaries and independent monitoring.

### Scope

Tresorit, [part of Swiss Post](https://tresorit.com/about-us), has its own Admin Center. Scope: Business and Enterprise subscription policies, local Linux client visibility, and approved Business Pro or Enterprise Sentinel integration where entitled.

## Table of Contents

1. [Access and Administration](#1-access-and-administration)
2. [Sharing, Integrations and Audit](#2-sharing-integrations-and-audit)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Access and Administration

### 1.1 Apply least-privilege subscription roles and MFA

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6, IA-2(1) |

#### Description

Limit Owner, Co-Owner and Co-Admin grants and require two-step verification or equivalent IdP policy.

#### Rationale

**Why This Matters:**

- Subscription roles and folder permissions differ. Advanced Control changes which administrators can recover accounts or obtain cryptographic access and should not be turned on merely to collect evidence.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://support.tresorit.com/hc/en-us/articles/360020550214-Admin-roles-in-Tresorit).
2. In Admin Center → Users, review role assignments. In Policies, check the applicable template’s two-step verification and SSO settings. Document recovery and approve any Advanced Control decision separately.

**Automation:** No public tenant-policy API was verified. The S3-compatible storage API does not administer subscription policy.

#### Validation & Testing

Verify role and template assignments for each applicable population and confirm expected sign-in behavior with a benign test user.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-6, IA-2(1) |

### 1.2 Restrict devices and folder sharing by policy

**Profile Level:** L1 (Crawl)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, AC-17 |

#### Description

Set explicit allowed-device, sharing, session and IP rules for each policy template.

#### Rationale

**Why This Matters:**

- A policy change affects only the assigned members and may be awaiting acceptance. A signed-in Linux client does not prove the subscription allowed-device policy.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://support.tresorit.com/hc/en-us/articles/115000237013-Team-Policies-and-Advanced-Control).
2. Open Admin Center → Policies. Apply device and sharing restrictions to a pilot group first. Confirm the active policy template, rollout behavior and legitimate access before broadening. Keep endpoint approval distinct from sharing permissions.

**Automation:** The vendor CLI pack checks local Linux daemon, Drive and session state only. It does not verify subscription compliance.

#### Code Implementation

{% include pack-code.html vendor="tresorit" section="1.2" %}

#### Validation & Testing

Use benign files to check that the intended receiver can access and an unapproved receiver cannot. Verify a pilot client’s signed-in state in the member context and review Admin Center device records.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AC-3, AC-17 |

## 2. Sharing, Integrations and Audit

### 2.1 Validate Sentinel audit visibility

**Profile Level:** L2 (Walk)

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-12 |

#### Description

On Business Pro or Enterprise, have a subscription owner configure approved audit forwarding and verify the received event schema.

#### Rationale

**Why This Matters:**

- A working portal export or an empty query does not establish that the Sentinel pipeline is receiving expected events.

#### ClickOps Implementation

1. Confirm the available plan and applicable permissions in the [vendor documentation](https://support.tresorit.com/hc/en-us/articles/7743328659090-Integrate-Tresorit-with-Microsoft-Sentinel).
2. Confirm the DPA prerequisite and approved Azure resources. Follow the documented Data Collection Endpoint and Rule setup and Tresorit integration flow, and restrict access to the Log Analytics workspace and reference data.

**Automation:** The Sentinel query only summarizes documented event fields. It does not write settings, enumerate users, or prove liveness by itself.

#### Code Implementation

{% include pack-code.html vendor="tresorit" section="2.1" %}

#### Validation & Testing

On an approved benign admin change, verify event reception and type, and separately monitor the expected delivery cadence and gaps.

#### Compliance Mappings

| Framework | Control |
|-----------|---------|
| NIST SP 800-53 Rev. 5 | AU-12 |

## 3. Compliance Quick Reference

These mappings support control design; they are not evidence of certification or operating effectiveness.

| Section | Control | NIST SP 800-53 Rev. 5 |
|---------|---------|-----------------------|
| 1.1 | Apply least-privilege subscription roles and MFA | AC-6, IA-2(1) |
| 1.2 | Restrict devices and folder sharing by policy | AC-3, AC-17 |
| 2.1 | Validate Sentinel audit visibility | AU-12 |

## References

- [Sentinel event schema](https://support.tresorit.com/hc/en-us/articles/36913629530002-Microsoft-Sentinel-event-schema)

## Changelog

- **0.1.0 (2026-11-27):** Initial guide and documented automation examples.

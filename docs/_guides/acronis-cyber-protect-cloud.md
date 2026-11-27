---
layout: guide
title: "Acronis Cyber Protect Cloud Hardening Guide"
vendor: "Acronis Cyber Protect Cloud"
slug: "acronis-cyber-protect-cloud"
tier: "1"
category: "Security"
description: "Acronis Cyber Protect Cloud exposes a multi-tenant Management Portal for managed service providers and customers."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Acronis Cyber Protect Cloud exposes a multi-tenant Management Portal for managed service providers and customers. Harden administrative access and integration credentials separately from endpoint and backup-plan configuration.

### Intended Audience

Tenant administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Establish the essential controls before production rollout.
- **L2 (Walk):** Stage the additional restrictions with a representative pilot and a recovery path.
- **L3 (Run):** Validate applicability, evidence retention, and approval requirements for regulated use.

### Scope

This guide addresses customer-controlled settings, not the vendor's internal service security. Feature availability depends on the contract and tenant. Settings were checked against documentation; no live tenant was tested or modified.

## Table of Contents

1. [Tenant administrative access](#1-tenant-administrative-access)
2. [Integration and evidence](#2-integration-and-evidence)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Tenant administrative access

### 1.1 Verify tenant two-factor authentication

**Profile Level:** L1 (Crawl)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | IA-2, IA-5 |

#### Description

Verify that human administrators enroll in and use tenant 2FA. Acronis made it mandatory for production partners, but customer tenants and legacy service accounts still require review.

#### Rationale

**Why This Matters:**

- An administrative password alone must not be enough to access backup and recovery administration.

#### Prerequisites

An authorized administrator for the selected tenant and a tested account recovery procedure.

#### ClickOps Implementation

1. In Management Portal go to **Settings > Security**. In the Cyber Console the documented equivalent is **Settings > General settings > Security**.
2. Verify **Two-factor authentication** in the selected tenant and enable it where configurable and required. Review the MFA status of human users and reconcile any accounts designated as service accounts.
3. Have customer administrators handle their own settings when partner support access is disabled. Do not activate support access merely to perform this check.

**Automation:** Exact current tenant MFA response and mutation contract for all covered editions was not verified.

#### Validation & Testing

Verify a fresh direct test sign-in requests the second factor and document any federation or service-account paths separately.

#### Monitoring & Maintenance

Review 2FA status and recovery ownership during onboarding and quarterly.

#### Operational Impact & Rollback

Do not disable mandatory 2FA to recover access. Use the documented recovery path and keep at least one separate authorized administrator.

**Sources:** [Acronis Cyber Console security settings](https://www.acronis.com/en/support/documentation/CyberConsoleGuide/se-security-settings.html). [Production partner enforcement](https://dl.acronis.com/u/baas/rn/24.08/en-US/AcronisCyberProtectCloud_relnotes.htm).

### 1.2 Constrain roles and propagation

**Profile Level:** L1 (Crawl)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-2, AC-6 |

#### Description

Assign permissions per tenant and service. Reserve Company Administrator and cross-tenant roles for duties that cannot be done with a narrower role.

#### Rationale

**Why This Matters:**

- A compromised partner administrator can affect more than one customer; a propagated role creates an additional trust boundary.

#### Prerequisites

Company Administrator with a roster of expected service and child-tenant grants.

#### ClickOps Implementation

1. Review existing user role assignments. Determine whether they need Management Portal, Cyber Protection, or a separate service role.
2. Under **Settings > Roles and permissions**, create or review a narrowly targeted custom role. Review the propagation option before saving; it is enabled by default for custom roles.
3. Restrict role assignment to approved tenant boundaries and record any reason for inheritance.

**Automation:** Account Management APIs exist; exact portable custom-role pack was not verified.

#### Validation & Testing

Check a separate test administrator can complete its approved read or write tasks but cannot administer a sibling customer or grant additional permissions.

#### Monitoring & Maintenance

Reconcile roles and descendants after customer onboarding, offboarding and organization restructuring.

#### Operational Impact & Rollback

Correct improperly scoped assignments from an authorized administrator account. Do not remove the only valid administrator in a tenant.

**Sources:** [Custom role scopes and propagation](https://www.acronis.com/en/support/documentation/AcronisCyberCloud/user-roles-custom.html). [Roles by service and tenant](https://www.acronis.com/en/support/documentation/AcronisCyberCloud/user-roles.html).

## 2. Integration and evidence

### 2.1 Review API client tenant boundaries

**Profile Level:** L1 (Crawl)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-6, IA-5 |

#### Description

Give each integration its own client in the narrowest feasible tenant and use short-lived access tokens. Verify which tenant owns the configured client; this alone is not proof of all its effective permissions.

#### Rationale

**Why This Matters:**

- A third-party integration may be able to impersonate an administrator in the client’s tenant hierarchy.

#### Prerequisites

Portal rights to inspect API clients, data-center hostname, client ID, expected tenant UUID and an externally issued API access token.

#### ClickOps Implementation

1. In Management Portal select the intended tenant and open **Settings > API clients**. Inventory each named API client, owner and business purpose.
2. Check the scope before authorizing the integration; avoid creating one credential at partner scope when a single customer is sufficient.
3. For approved integrations obtain an access token using the Acronis client credentials flow. Do not store client secrets or tokens with evidence.

#### Code Implementation

{% include pack-code.html vendor="acronis-cyber-protect-cloud" section="2.1" %}

#### Validation & Testing

Run the pack with the expected tenant ID and compare the results with the Portal record. Separately verify the effective integration scope and allowed calls with the integration owner.

#### Monitoring & Maintenance

Review clients and associated audit events when integrations are introduced or removed.

#### Operational Impact & Rollback

Changing the client can break external backup and reporting jobs. Stage approved replacement settings before retiring any existing credential.

**Sources:** [Acronis partner guide API clients](https://dl.acronis.com/u/pdf/AcronisCyberProtectCloud_partnerguide_en-US.pdf). [Client tenant lookup](https://developer.acronis.com/doc/account-management/v2/guide/getting-started/authenticating.html).

### 2.2 Confirm Management Portal audit coverage

**Profile Level:** L2 (Walk)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AU-2, AU-6 |

#### Description

Review tenant-specific Management Portal changes and supported cloud-to-cloud operations. Do not assume the audit stream includes every endpoint or recovery action.

#### Rationale

**Why This Matters:**

- An unexpected tenant or API client change can be an early sign of integration drift.

#### Prerequisites

Approved audit access and baseline tenant/client inventory.

#### ClickOps Implementation

1. Open **Audit log** in Management Portal and select the intended tenant scope.
2. Filter by time and review administrative changes against approved work. Review source, initiator, and IP when present, without exporting more customer data than needed.
3. Verify the relevant service and cloud-to-cloud event categories are covered before relying on the audit trail.

**Automation:** A current portable API export contract was not verified; use the documented console.

#### Validation & Testing

Identify an approved benign administration event and compare its action, tenant, time and actor to the change record. A quiet or incomplete window does not prove no changes.

#### Monitoring & Maintenance

Schedule periodic review and document missing coverage or retention gaps.

#### Operational Impact & Rollback

Review is read only; keep source evidence when adjusting your review cadence.

**Sources:** [Audit log scope and events](https://www.acronis.com/en/support/documentation/AcronisCyberCloud/audit-log.html).

## 3. Compliance Quick Reference

These are thematic NIST mappings, not a benchmark, certification, or evidence of implementation.

| Control | NIST SP 800-53 Rev. 5 |
|---|---|
| 1.1 Verify tenant two-factor authentication | IA-2, IA-5 |
| 1.2 Constrain roles and propagation | AC-2, AC-6 |
| 2.1 Review API client tenant boundaries | AC-6, IA-5 |
| 2.2 Confirm Management Portal audit coverage | AU-2, AU-6 |

## Appendix A: Automation and applicability

The Account Management REST pack verifies API-client identity and tenant binding only. Tenant role and MFA setting APIs, Terraform, GraphQL, SDK, first-party admin CLI and SIEM coverage are not claimed. Acronis Cyber Protect on-premises and the consumers’ Acronis account portal are separate surfaces. No Acronis product-specific CIS, STIG or SCuBA control was established.

## Changelog

| Date | Version | Maturity | Changes | Author |
|---|---|---|---|---|
| 2026-11-27 | 0.1.0 | ai-drafted | Initial tenant hardening controls and read-only verification | How to Harden Community |

## Contributing

Submit corrections and sanitized verification evidence through [GitHub](https://github.com/grcengineering/how-to-harden). Never attach tenant exports or secrets.

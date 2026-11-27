---
layout: guide
title: "Bitdefender GravityZone Cloud Hardening Guide"
vendor: "Bitdefender GravityZone Cloud"
slug: "bitdefender-gravityzone"
tier: "1"
category: "Security"
description: "Bitdefender GravityZone Cloud Control Center governs customer administrator access and endpoint-security integrations."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Bitdefender GravityZone Cloud Control Center governs customer administrator access and endpoint-security integrations. The artifact identifies the vendor only; this guide covers the documented cloud management plane, not Bitdefender consumer products or GravityZone on-premises.

### Intended Audience

Tenant administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Establish the essential controls before production rollout.
- **L2 (Walk):** Stage the additional restrictions with a representative pilot and a recovery path.
- **L3 (Run):** Validate applicability, evidence retention, and approval requirements for regulated use.

### Scope

This guide addresses customer-controlled settings, not the vendor's internal service security. Feature availability depends on the contract and tenant. Settings were checked against documentation; no live tenant was tested or modified.

## Table of Contents

1. [Identity and access](#1-identity-and-access)
2. [Service integrations and review](#2-service-integrations-and-review)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Identity and access

### 1.1 Verify direct sign-in controls and separate federated identities

**Profile Level:** L1 (Crawl)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | IA-2, IA-5 |

#### Description

Verify the required factor for human Control Center accounts. GravityZone Cloud mandates 2FA for direct accounts; federated access also requires validation of the IdP’s policy.

#### Rationale

**Why This Matters:**

- A compromised human administrator can change endpoint security policies. A configured sign-in path is not evidence that all alternate access uses equivalent protection.

#### Prerequisites

A supported GravityZone Cloud account, independent recovery administrator and a roster of authentication methods.

#### ClickOps Implementation

1. For direct accounts, review **My Account > Login Security** and confirm the 2FA enrollment. If using the GravityZone Identity Provider, review its applicable passkey options and IdP policies.
2. Verify both ordinary and administrative sign-in paths. Reconcile unexpected authentication methods in the accounts inventory.

#### Code Implementation

{% include pack-code.html vendor="bitdefender-gravityzone" section="1.1" %}

#### Validation & Testing

Use a fresh test sign-in for each approved authentication path. In the pack’s bounded sample, treat absent 2FA fields as unknown and evaluate federated records independently. Some API callers cannot see all accounts and a user-derived key may omit its own issuing account.

#### Monitoring & Maintenance

Review identity-provider changes and admin recovery access.

#### Operational Impact & Rollback

Recover through approved direct or federated support procedures rather than trying to turn off the mandatory cloud requirement.

**Sources:** [Cloud 2FA requirements](https://www.bitdefender.com/business/support/en/77211-149659-enforcing-two-factor-authentication--2fa--in-gravityzone-cloud-faq.html). [Account login security](https://www.bitdefender.com/business/support/en/77211-94051-manage-your-account.html). [Account list response](https://www.bitdefender.com/business/support/en/77211-125282-getaccountslist.html).

### 1.2 Use human roles and target scopes deliberately

**Profile Level:** L1 (Crawl)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-2, AC-6 |

#### Description

Assign only the rights and tenant/target scope necessary. Limit who can manage user accounts, endpoint settings or service API keys, and keep report-only roles separate.

#### Rationale

**Why This Matters:**

- Security policy write access and API credential lifecycle authority can change many managed devices or tenants.

#### Prerequisites

An authorized GravityZone Cloud company administrator with documented role and target ownership.

#### ClickOps Implementation

1. In **Control Center > Accounts**, open the account and review its role and rights.
2. Select the narrow scope and use read-only endpoint permissions for monitoring-only jobs where supported.
3. Review **Manage Service API keys** on eligible administrator roles separately; do not grant it for routine user administration.

**Automation:** Accounts JSON-RPC reads and writes exist; the sample in 1.1 is not an effective-rights evaluation.

#### Validation & Testing

Check the approved pilot user can perform the job without edit rights or access to sibling scopes beyond its purpose.

#### Monitoring & Maintenance

Review targets and role grants with affected company owners quarterly.

#### Operational Impact & Rollback

Restore only necessary prior rights after reviewing the incident or failed task.

**Sources:** [GravityZone user rights](https://www.bitdefender.com/business/support/en/77212-124345-user-rights.html).

## 2. Service integrations and review

### 2.1 Prefer dedicated scoped service API keys

**Profile Level:** L1 (Crawl)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-6, IA-5 |

#### Description

Where the cloud service-key feature supports the integration, configure a dedicated key with module, target and expiry limits. These keys are independent of individual Control Center accounts; disabling a human user is not revocation.

#### Rationale

**Why This Matters:**

- Purpose-built credentials can prevent a third-party integration from inheriting a full operator’s account scope.

#### Prerequisites

GravityZone Cloud with the service-key feature and an operator holding Manage service API keys.

#### ClickOps Implementation

1. Open **Accounts > Service API keys**. Create a workload-specific key for an approved integration.
2. Set the minimum required modules, company/folder scope where offered, and expiration within the documented limit.
3. Store the opaque key in protected secret storage and keep personal API keys separately tracked.

**Automation:** The documented X-API-Key authentication path is used for verification. No key-creation or credential change pack is included.

#### Validation & Testing

Inspect the key settings directly. Verify a normal approved read within its scope, and compare against the authorized integration specification; the read alone does not prove the full effective scope.

#### Monitoring & Maintenance

Review scope, ownership and expiry. Include unused, active and suspended keys in reviews.

#### Operational Impact & Rollback

Suspending or removing a key can interrupt the integration. Stage a replacement within approved scope and revert only to an approved prior integration configuration.

**Sources:** [GravityZone service API keys](https://www.bitdefender.com/business/support/en/77211-1658556-service-api-keys.html). [Authentication differences](https://www.bitdefender.com/business/support/en/77211-125277-public-api.html).

### 2.2 Review service credential lifecycle changes

**Profile Level:** L2 (Walk)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AU-2, AU-6 |

#### Description

Use the Control Center activity log to compare service key creation, edit, suspension and expiry-related operations to approved changes.

#### Rationale

**Why This Matters:**

- An unexpected added key can leave access after the associated human operator has been offboarded.

#### Prerequisites

Activity log access, integration key owners and approved change records.

#### ClickOps Implementation

1. Open the **User activity log** from the Accounts area.
2. Review recent key lifecycle changes and their actors against approved tickets. Restrict who may view exported details.
3. Establish expiry notifications and check they reach the intended owner.

**Automation:** A current, portable read contract for administrative key-lifecycle log events was not verified.

#### Validation & Testing

Find a documented approved pilot key operation in the expected scope. An empty view is not proof that no key changed.

#### Monitoring & Maintenance

Investigate unowned keys, unexplained role updates and alert delivery defects.

#### Operational Impact & Rollback

Review is observational; ensure logging remains intact when repairing the process.

**Sources:** [Control Center release note and activity logging](https://www.bitdefender.com/business/support/en/77211-78199-gravityzone-control-center.html).

## 3. Compliance Quick Reference

These are thematic NIST mappings, not a benchmark, certification, or evidence of implementation.

| Control | NIST SP 800-53 Rev. 5 |
|---|---|
| 1.1 Verify direct sign-in controls and separate federated identities | IA-2, IA-5 |
| 1.2 Use human roles and target scopes deliberately | AC-2, AC-6 |
| 2.1 Prefer dedicated scoped service API keys | AC-6, IA-5 |
| 2.2 Review service credential lifecycle changes | AU-2, AU-6 |

## Appendix A: Automation and applicability

The Accounts API pack performs a read-only JSON-RPC method using HTTP POST, required by the vendor transport. A legacy personal key and a supported service key use different authentication headers. SaaS identity and key management are distinct from endpoint and on-premises GravityZone controls. Terraform, first-party admin CLI/SDK, GraphQL and exact SIEM coverage for key-lifecycle events were not verified. No GravityZone Cloud product-specific CIS, STIG or SCuBA control was established.

## Changelog

| Date | Version | Maturity | Changes | Author |
|---|---|---|---|---|
| 2026-11-27 | 0.1.0 | ai-drafted | Initial tenant hardening controls and read-only verification | How to Harden Community |

## Contributing

Submit corrections and sanitized verification evidence through [GitHub](https://github.com/grcengineering/how-to-harden). Never attach tenant exports or secrets.

---
layout: guide
title: "Automox Hardening Guide"
vendor: "Automox"
slug: "automox"
tier: "1"
category: "IT Operations"
description: "Automox is a hosted patch and endpoint automation control plane."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Automox is a hosted patch and endpoint automation control plane. Protect assignment, API, and policy authoring privileges because a single mis-scoped change can reach an entire managed fleet.

### Intended Audience

Tenant administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Establish the essential controls before production rollout.
- **L2 (Walk):** Stage the additional restrictions with a representative pilot and a recovery path.
- **L3 (Run):** Validate applicability, evidence retention, and approval requirements for regulated use.

### Scope

This guide addresses customer-controlled settings, not the vendor's internal service security. Feature availability depends on the contract and tenant. Settings were checked against documentation; no live tenant was tested or modified.

## Table of Contents

1. [Identity and integration access](#1-identity-and-integration-access)
2. [Policy integrity and monitoring](#2-policy-integrity-and-monitoring)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Identity and integration access

### 1.1 Restrict full and account administrator roles

**Profile Level:** L1 (Crawl)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-2, AC-6 |

#### Description

Use global roles only for cross-organization duties and use organization-specific custom roles for local operators. Treat Worklets Create and Execute permissions as privileged.

#### Rationale

**Why This Matters:**

- Overbroad patch or automation privileges can affect endpoints outside the operator’s authorization.

#### Prerequisites

Full or Account Administrator, accurate roster, and separately verified emergency access.

#### ClickOps Implementation

1. Use the organization selector to open **Manage Orgs and Users**. In **Setup & Configuration > Users**, review each user’s Global Roles and expected organization roles.
2. Under **Roles & Permissions > Global (All Organizations)**, reconcile Full Administrator membership.
3. Limit script and policy author/execute grants to designated operators and document why a global role is needed.

**Automation:** API and role management surfaces exist; this guide does not claim complete effective-RBAC data.

#### Validation & Testing

Sign in as a scoped test operator. Confirm normal tasks work in its organization without cross-organization access or unrelated global user-management capabilities. Allow for vendor-documented propagation lag.

#### Monitoring & Maintenance

Review temporary and global grants after changes; track Worklet authoring and execution membership.

#### Operational Impact & Rollback

Restore only the specific required permission through the independent emergency administrator if a legitimate operation was broken.

**Sources:** [Role management](https://docs.automox.com/product/Product_Documentation/Global_Access_Management/Roles_and_Permissions.htm). [Global role verification](https://help.automox.com/hc/en-us/articles/31573276542868-How-to-Assign-a-Full-Administrator-Role-to-a-User).

### 1.2 Prefer organization-scoped integration credentials

**Profile Level:** L1 (Crawl)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-6, IA-5 |

#### Description

Use a named, expiring organization API key when the job only needs one organization. API keys inherit the issuing user’s permissions, so ensure that account itself has the appropriate role.

#### Rationale

**Why This Matters:**

- An organization boundary narrows the effect of a disclosed key; a user’s overbroad role still makes a single-organization key dangerous.

#### Prerequisites

An approved integration owner, role rights to create keys, and protected secret storage.

#### ClickOps Implementation

1. In the target organization open **Settings > Secrets & Keys > Organization API Keys**. Create a labeled integration key with an approved expiration.
2. In **Setup & Configuration > Keys**, review global keys independently and retain them only when a job genuinely spans organizations.
3. Keep enrollment Agent Access Keys separate from API keys and restrict who can create or modify each.

**Automation:** No key creation, secret decryption or revocation automation is provided.

#### Validation & Testing

Compare key and role assignments to the intended organization. A successful read only proves that operation is available, not that writes are prevented.

#### Monitoring & Maintenance

Review keys against workloads after ownership or role changes.

#### Operational Impact & Rollback

Test a scoped replacement integration separately before disabling the prior approved credential.

**Sources:** [Organization API keys](https://docs.automox.com/product/Product_Documentation/Settings/Managing_Keys.htm). [Global API keys](https://docs.automox.com/product/Product_Documentation/Global_Access_Management/Managing_Global_Keys.htm).

## 2. Policy integrity and monitoring

### 2.1 Review deployed Worklet policies and stage signing

**Profile Level:** L2 (Walk)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | CM-3, CM-5, SI-7 |

#### Description

Inventory custom policies and require review before deploying Worklets. For Windows, pilot Automox Script Signing to align with the planned PowerShell execution policy.

#### Rationale

**Why This Matters:**

- A deployed script or policy change can extend software supply-chain and operator compromise to managed endpoints.

#### Prerequisites

Approved test devices, script signing permissions and a compatibility plan for existing PowerShell settings and signatures.

#### ClickOps Implementation

1. In the Automox Console review **Automate** policies and assignments; identify custom Worklets and compare against the approved change records.
2. Use **Settings > Script Signing** and **Opt In & Install** only after reviewing the documented certificates and current execution-policy prerequisites. Start with an authorized pilot.
3. Design separate checks for Windows and other OSes. Do not reduce a stronger existing policy fleet-wide merely to install certificates.

#### Code Implementation

{% include pack-code.html vendor="automox" section="2.1" %}

#### Validation & Testing

Run the read-only policy pack to identify custom policy records. Separately confirm signature and execution-policy behavior on pilot Windows devices. The policy endpoint does not verify actual signing.

#### Monitoring & Maintenance

Review unexpected scripts, policy changes, assignment drift and certificate dependencies.

#### Operational Impact & Rollback

Pause the rollout if trusted existing scripts fail. Restore the previously approved pilot configuration and avoid broad changes to execution policy.

**Sources:** [Worklet type and read operation](https://help.automox.com/hc/en-us/articles/31578714760724-How-to-Create-a-Worklet-through-API). [Automox Script Signing](https://docs.automox.com/product/Product_Documentation/Script_Signing/Automox_Script_Signing.htm).

### 2.2 Verify console and API activity evidence

**Profile Level:** L1 (Crawl)

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AU-2, AU-6 |

#### Description

Review accounts, automation actors, and policy operations through Automox audit evidence. Distinguish authenticated human activities from machine calls.

#### Rationale

**Why This Matters:**

- Unlogged changes to endpoint assignments or scripted policies delay detection of an administrative compromise.

#### Prerequisites

Approved reporting permissions and an expected event or change record.

#### ClickOps Implementation

1. Open **Insights > Reports > Data Extracts** and choose **Generate New > API Activity**.
2. Select the required interval, respecting the documented 90-day extract limit.
3. Correlate a known operation to its user and policy IDs before asserting that the evidence pipeline is complete.

**Automation:** Automox documents a separate Audit Trail API; the scoped pack does not automate audit log collection.

#### Validation & Testing

Confirm the expected operation, time and actor are identifiable. Verify Audit Trail API collection separately if used; a one-day query does not prove broad coverage.

#### Monitoring & Maintenance

Check for missing records, unknown automation actors, unexpected Worklet actions and drift in review scope.

#### Operational Impact & Rollback

Retain source data under the approved policy. Fix reviewer access or time-window selection rather than disabling logs.

**Sources:** [Automox audit evidence](https://help.automox.com/hc/en-us/articles/40735766296340-Auditing-Console-and-API-Activity).

## 3. Compliance Quick Reference

These are thematic NIST mappings, not a benchmark, certification, or evidence of implementation.

| Control | NIST SP 800-53 Rev. 5 |
|---|---|
| 1.1 Restrict full and account administrator roles | AC-2, AC-6 |
| 1.2 Prefer organization-scoped integration credentials | AC-6, IA-5 |
| 2.1 Review deployed Worklet policies and stage signing | CM-3, CM-5, SI-7 |
| 2.2 Verify console and API activity evidence | AU-2, AU-6 |

## Appendix A: Automation and applicability

The starter pack reads policy metadata, not Worklet bodies. Automox documents account and global-key REST, Audit Trail and Cloud Worklets APIs; first-party tenant CLI/SDK and Terraform/GraphQL policy parity were not verified. Endpoint agent commands and Windows PowerShell signing are not equivalent to a hosted admin CLI. No Automox product-specific CIS, STIG or SCuBA control was established.

## Changelog

| Date | Version | Maturity | Changes | Author |
|---|---|---|---|---|
| 2026-11-27 | 0.1.0 | ai-drafted | Initial tenant hardening controls and read-only verification | How to Harden Community |

## Contributing

Submit corrections and sanitized verification evidence through [GitHub](https://github.com/grcengineering/how-to-harden). Never attach tenant exports or secrets.

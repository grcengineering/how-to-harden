---
layout: guide
title: "JupiterOne Hardening Guide"
vendor: "JupiterOne"
slug: "jupiterone"
tier: "1"
category: "Security"
description: "Harden the JupiterOne hosted workspace."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Harden the JupiterOne hosted workspace. This guide covers tenant access, integration credentials and audit evidence, not any connected provider administration.

### Intended Audience

Tenant administrators, security engineers, and control owners.

### How to Use This Guide

- **L1 (Crawl):** Establish the essential controls before production rollout.
- **L2 (Walk):** Stage the additional restrictions with a representative pilot and a recovery path.
- **L3 (Run):** Validate applicability, evidence retention, and approval requirements for regulated use.

### Scope

This guide addresses customer-controlled settings, not the vendor's internal service security. Feature availability depends on the contract and tenant. Settings were checked against documentation; no live tenant was tested or modified.

## Table of Contents

1. [Workspace access](#1-workspace-access)
2. [Integrations and audit evidence](#2-integrations-and-audit-evidence)
3. [Compliance Quick Reference](#3-compliance-quick-reference)

## 1. Workspace access

### 1.1 Protect interactive access and default groups

**Profile Level:** L1

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-2, IA-2 |

#### Description

Enable federated authentication where supported, require MFA for local users that remain, and minimize default groups.

#### Rationale

**Why This Matters:**

- Administrative entitlements and local password access can undermine SSO if left unchecked.

#### Prerequisites

JupiterOne Administrators membership, authorized IdP admin, and tested recovery path.

#### ClickOps Implementation

1. Open Settings > Admin > Security & Access. Review default user groups and assign only intended privileges.
2. For Enterprise SAML, stage and test SP-initiated login and group mapping with the IdP; use phishing-resistant MFA in the IdP where available.
3. Review local users and enable Require MFA for non-SSO users if local access is retained. Verify required recovery accounts separately.

#### Validation & Testing

Verify expected privileges for pilot admin, standard user and local recovery identities without sharing assertion contents.

#### Monitoring & Maintenance

Review default and privileged groups after each IdP mapping change or offboarding.

#### Operational Impact & Rollback

Revert the affected mapping or access setting through the previously verified recovery path only.

**Sources:** [JupiterOne admin settings](https://docs.jupiterone.io/features/admin/admin-settings). [JupiterOne SAML setup](https://docs.jupiterone.io/features/admin/saml-sso).

### 1.2 Stage web and API network allowlisting

**Profile Level:** L2

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AC-17, SC-7 |

#### Description

Use the workspace IP allowlist only after identifying approved stable egress for both interactive users and API clients.

#### Rationale

**Why This Matters:**

- The workspace control covers web and API use; an incomplete list can disrupt both.

#### Prerequisites

Administrator, documented egress for browser/API clients, tested way to recover.

#### ClickOps Implementation

1. Open Security & Access in the target account and review its IP allowlist.
2. Inventory authorized egress for users, automation and recovery before narrowing access.
3. Use an approved change window, verify both browser and API traffic, and roll back if either required path fails.

#### Validation & Testing

Using a pilot identity and designated networks, confirm approved access and the intended denial; verify key integration jobs still run.

#### Monitoring & Maintenance

Review ranges on VPN, CI or network changes and remove retired egress.

#### Operational Impact & Rollback

Restore previously authorized ranges using the retained approved route; investigate unrecognized egress first.

**Sources:** [JupiterOne admin settings](https://docs.jupiterone.io/features/admin/admin-settings).

## 2. Integrations and audit evidence

### 2.1 Separate account keys from integration keys

**Profile Level:** L1

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | IA-5, AC-6 |

#### Description

Keep scoped ingestion keys and account-level keys separate; issue only necessary permissions and expiration.

#### Rationale

**Why This Matters:**

- Using an account key for ingestion can expose sensitive graph data to systems that only need to sync one integration.

#### Prerequisites

Integration owners, key inventory and secure secret manager.

#### ClickOps Implementation

1. Review account API tokens in Admin and user API key eligibility for each group.
2. From Integrations, open the configured instance. Use integration-scoped keys for supported ingestion and a narrowly permitted expiring account key for approved audit queries.
3. Reconcile owners, expiry and access; rotate and revoke stale credentials after validating the replacement.

#### Validation & Testing

Check the approved workflow succeeds with the intended credential and the configured permission policy does not allow unrelated access.

#### Monitoring & Maintenance

Review expiration and access on each workflow change and quarterly.

#### Operational Impact & Rollback

Restore the prior authorized configuration only during a controlled rotation or through the documented key recovery process.

**Sources:** [JupiterOne API authentication](https://docs.jupiterone.io/api/authentication). [JupiterOne integration setup](https://docs.jupiterone.io/integrations/add-an-integration).

### 2.2 Verify workspace audit events

**Profile Level:** L1

| Framework | Relevant controls |
|---|---|
| NIST SP 800-53 Rev. 5 | AU-2, AU-6, AU-9 |

#### Description

Review audit events and optionally stream the audit log to an approved Amazon S3 bucket.

#### Rationale

**Why This Matters:**

- Workspace changes are harder to attribute without verified event delivery and controlled retention.

#### Prerequisites

Authorized event access, expected event and date range, and tightly controlled destination if streaming.

#### ClickOps Implementation

1. Open Settings > Audit Events and confirm a known authorized event is present.
2. Review retention needs; if using Data Streaming, configure only the required stream and restrict access to its approved bucket and prefix.
3. Record source, sample time and pagination status; do not export event payloads unnecessarily.

#### Code Implementation

{% include pack-code.html vendor="jupiterone" section="2.2" %}

#### Validation & Testing

Compare an expected event in the UI with the expected stream delivery where configured. The first-page count proves neither an event identity nor coverage.

#### Monitoring & Maintenance

Track stream freshness, missing event types and evidence retention with the SOC.

#### Operational Impact & Rollback

Correct the destination or disable the affected stream only while preserving evidence already retained.

**Sources:** [JupiterOne admin settings](https://docs.jupiterone.io/features/admin/admin-settings). [JupiterOne audit events query](https://docs.jupiterone.io/api/integrations-operations/#retrieve-jupiterone-audit-events-via-api). [JupiterOne Data Streaming](https://docs.jupiterone.io/features/admin/data-streaming).

## 3. Compliance Quick Reference

These are thematic NIST mappings, not a benchmark, certification, or evidence of implementation.

| Control | NIST SP 800-53 Rev. 5 |
|---|---|
| 1.1 Protect interactive access and default groups | AC-2, IA-2 |
| 1.2 Stage web and API network allowlisting | AC-17, SC-7 |
| 2.1 Separate account keys from integration keys | IA-5, AC-6 |
| 2.2 Verify workspace audit events | AU-2, AU-6, AU-9 |

## Appendix A: Automation and applicability

The GraphQL pack uses a fixed query, not a mutation, and reads one bounded page with a scoped bearer key. It does not retrieve actor identifiers or event payloads.

## Changelog

| Date | Version | Maturity | Changes | Author |
|---|---|---|---|---|
| 2026-11-27 | 0.1.0 | ai-drafted | Initial tenant hardening controls and read-only verification | How to Harden Community |

## Contributing

Submit corrections and sanitized verification evidence through [GitHub](https://github.com/grcengineering/how-to-harden). Never attach tenant exports or secrets.

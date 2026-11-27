---
layout: guide
title: "IDrive Business and Enterprise Hardening Guide"
vendor: "IDrive Business and Enterprise"
slug: "idrive"
tier: "2"
category: "IT Operations"
description: "Protect managed backup sign-in, offboarding, and backup evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

Scope: IDrive managed online backup Business and Enterprise organization administration. IDrive e2 object storage, Personal accounts and endpoint installation are outside scope. IDrive documents different interfaces and SSO entitlements by account creation date.

### Intended Audience

- SaaS administrators and security engineers
- GRC practitioners collecting configuration and access evidence

### How to Use This Guide

- **L1 (Crawl):** Establish identity, least privilege and review basics.
- **L2 (Walk):** Add controls that require staged deployment or split administration.

### Scope

ClickOps and code are documentation-derived; no tenant was accessed. Run inventories only on authorized accounts. They attest the visible configuration, not overall compliance.

## Table of Contents

1. [Control Checklist](#1-control-checklist)
2. [Compliance Quick Reference](#2-compliance-quick-reference)

## 1. Control Checklist

### 1.1 Use Managed Subaccount Sign-In

**Profile Level:** L1 (Crawl)

#### Description

Where entitled, configure SAML for workforce subaccounts and require MFA in the IdP.

#### Rationale

**Why This Matters:**

- Backup access keys and subaccounts must not outlive the identities authorized to use them.

#### Prerequisites

An authorized administrator, supported commercial edition, and current account-cohort UI documentation.

#### ClickOps Implementation

1. For supported newer Business accounts, use **Admin > Single Sign-On**. For the legacy Enterprise UI use **Dashboard > Settings > Security > Single sign-on**. Confirm your exact entitlement and cohort before proceeding.
2. Configure IdP metadata using IDrive's vendor procedure and enable SSO for approved subaccounts; match IdP mappings to IDrive identities.
3. Require MFA at the IdP. Document any non-federated admin paths and protect them separately.

**Source:** [Vendor administration documentation](https://www.bmv.idrive.com/idrive-sso-faq).

**Automation:** No verified pack is supplied for this control. This is not a claim that no automated interface exists.

#### Validation & Testing

Verify assigned and unassigned identities, emergency administrative access, and backup-client continuity in a pilot.

#### Operational Impact

Changing sign-in settings may require clients to reauthenticate. Do not transition all users before validating backups and recovery.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | IA-2 | Supports this objective; configuration alone does not establish compliance. |

### 1.2 Offboard Without Losing Backup Data

**Profile Level:** L1 (Crawl)

#### Description

Reconcile backup users to the authorized roster and suspend access before considering deletion.

#### Rationale

**Why This Matters:**

- A former employee's access should end without deleting backups subject to a retention or legal requirement.

#### Prerequisites

Authorized organization backup admin; determine retention, ownership and legal hold applicability.

#### ClickOps Implementation

1. In the applicable **Users** view, review subaccounts, group membership and owners. Reconcile to approved employee and service-account lists.
2. Use the applicable cohort's user-blocking capability when retention requires keeping backup data. In the legacy dashboard choose the user and **Block Selected Users**.
3. Review retention and transfer requirements before any permanent deletion.

**Source:** [Vendor administration documentation](https://help.idrive.com/dashboard-faq-6series).

**Automation:** No verified pack is supplied for this control. This is not a claim that no automated interface exists.

#### Validation & Testing

For an approved pilot account, verify interactive access is no longer available and an authorized administrator can still locate retained backup data.

#### Operational Impact

Blocking may interrupt agent jobs. Coordinate with workload owners and legal; document the expected backup continuity path.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | AC-2 | Supports this objective; configuration alone does not establish compliance. |

### 1.3 Review Backup Activity Reports

**Profile Level:** L2 (Walk)

#### Description

Review backup outcomes and missing device coverage independently from an individual machine's backup application.

#### Rationale

**Why This Matters:**

- File availability is not guaranteed merely because a device is enrolled.

#### Prerequisites

Administrator report access and a protected local location for CSV evidence.

#### ClickOps Implementation

1. Sign in as admin and open **Reports**, under **Dashboard** where applicable. Select **Backup Activity** and set the approved user/device scope and date range.
2. Generate and save the CSV locally. Compare status against policy and reconcile covered devices against the enrolled inventory.
3. Review exceptions and schedule a separate restore test on synthetic sample data.

**Source:** [Vendor administration documentation](https://www.idrive.com/new-design/dashboard-faq).

#### Code Implementation

{% include pack-code.html vendor="idrive" section="1.3" %}

#### Validation & Testing

Use the local CSV pack with the exact status column and approved status value from the export. Status totals are not proof of freshness, completeness or restorability.

#### Operational Impact

Report data can identify users and devices. Keep the raw export in a controlled location and share aggregate counts instead.

#### Compliance Mappings

| Framework | Reference | Relationship |
|-----------|-----------|--------------|
| NIST SP 800-53 Rev. 5 | AU-6, CP-9 | Supports this objective; configuration alone does not establish compliance. |

## 2. Compliance Quick Reference

| Control | Profile | NIST SP 800-53 Rev. 5 |
|---------|---------|-----------------------|
| 1.1 Use Managed Subaccount Sign-In | L1 | IA-2 |
| 1.2 Offboard Without Losing Backup Data | L1 | AC-2 |
| 1.3 Review Backup Activity Reports | L2 | AU-6, CP-9 |

## References

- [Source and validation notes](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/sspm-fourth-dev-source-coverage.md)

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 0.1.0 | 2026-11-27 | Initial documentation-derived guide and verification packs |

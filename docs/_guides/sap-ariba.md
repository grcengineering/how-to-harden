---
layout: guide
title: "SAP Ariba Hardening Guide"
vendor: "SAP Ariba"
slug: "sap-ariba"
tier: "2"
category: "HR/Finance"
description: "Harden procurement-realm authentication, user provisioning and administrative evidence."
version: "0.1.0"
maturity: ["ai-drafted"]
last_updated: "2026-11-27"
---

## Overview

This guide covers SAP Ariba procurement realms with Intelligent Configuration Manager and the SAP Ariba Applications SCIM API. It does not assume Next-Gen Ariba Invoicing, Category Management, SAP Business Network or SAP SuccessFactors share these tenant settings.

### Intended Audience

- Tenant administrators and owners of the affected integrations
- Security engineers and assurance reviewers collecting configuration evidence

### How to Use This Guide

L1 (Crawl) covers foundational configuration and evidence. Review current controls and owners first, then pilot changes using nonproduction accounts and synthetic records.

### Scope

This starter guide covers the three control areas below. Edition, release, tenant and authorization conditions can affect exact availability. Documentation-derived console paths have not been tested in a live customer tenant. Read-only packs collect narrow evidence; they do not score tenant compliance or apply remediation.

## Table of Contents

1. [Security Configuration](#1-security-configuration)
2. [Compliance Quick Reference](#2-compliance-quick-reference)

## 1. Security Configuration

### 1.1 Stage SAML authentication with separated approval

**Profile Level:** L1 (Crawl)

**NIST 800-53:** IA-2

#### Description

Configure SAML federation through the procurement realm's documented workflow and require MFA at the approved identity provider.

#### Rationale

- An erroneous authentication update can deny the whole realm access. A separate review of metadata and a tested recovery path reduce both lockout and misrouting risk.

#### ClickOps Implementation

In **Intelligent Configuration Manager → Configure SAML authentication**, prepare the SAML 2.0 HTTP POST configuration for the realm using the approved identity provider. Review the realm and returned destination details in the test site. Follow the status workflow to review, approve and apply the production change only after testing both required user populations and recovery.

Source: [SAP Ariba documentation](https://help.sap.com/docs/ariba/aba524a8b2444714b289cee09bd4c377/323a07fae4224882a004ecae07e32032.html) (checked 2026-11-27).

**Automation:** No public Ariba SCIM operation changes this federation configuration.

#### Validation & Testing

Test approved and unassigned enterprise test identities against the intended realm. Verify the authentication configuration event in ICM using **Data modification**. Do not assume supplier sign-in inherits the employee identity policy.

---

### 1.2 Review sensitive groups and provisioning connectors

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AC-6

#### Description

Keep procurement group membership and the authority to change it narrowly scoped and independently reviewed.

#### Rationale

- Group grants can influence buying, approvals and access to supplier or commercial data. SCIM access can change identities when the configured application is authorized for writes.

#### ClickOps Implementation

In the Ariba user and group administration surface, review the approval-related group with its owner. Apply SAP's recommendation to use Identity Provisioning where appropriate, and register a dedicated approved application in **Developer Portal → Manage Applications** for SCIM access. Keep realm-specific credentials separate.

Source: [SAP Ariba documentation](https://help.sap.com/doc/88812c450b43467bb6a0445a1486580a/cloud/en-US/094ff0c1f32e42a1acc0c21e27483ca7.pdf) (checked 2026-11-27).

**Automation:** The SAP Ariba SCIM API documents group reads and writes; this pack performs one read only.

#### Code Implementation

{% include pack-code.html vendor="sap-ariba" section="1.2" %}

#### Validation & Testing

Fetch one specific group using its SCIM ID and compare membership to the approved list. Separate connector-visible data from the tenant's effective authorization; review role mappings and nested grants where present.

---

### 1.3 Review procurement User Management audit events

**Profile Level:** L1 (Crawl)

**NIST 800-53:** AU-6

#### Description

Collect and review procurement audit events for user and group changes; keep ICM authentication evidence separate.

#### Rationale

- Successful sign-in changes and permission changes occur in different management surfaces. Evidence from one does not demonstrate monitoring of the other.

#### ClickOps Implementation

In the procurement site's audit log, filter by time range, account and **User Management** event category. Reconcile approved group or user changes against the change record and investigate unexplained mismatches. Review ICM changes using its own event filters.

Source: [SAP Ariba documentation](https://help.sap.com/docs/ARIBA_PROCUREMENT/e10ed2159560487bb36d1ae89a6e293a/6ac52dc7c1da101486d3bc84b998b1b6.html) (checked 2026-11-27).

**Automation:** No matching public audit export API was verified for this procurement audit category.

#### Validation & Testing

During a controlled test in a nonproduction realm, perform an approved benign membership change and confirm it appears with the right actor and time. Treat empty results as a coverage question when an event was expected.

## 2. Compliance Quick Reference

These mappings support control objectives; they are not claims of certification or compliance.

| HTH control | Objective | NIST SP 800-53 Rev. 5 |
|-------------|-----------|-----------------------|
| 1.1 | Stage SAML authentication with separated approval | IA-2 |
| 1.2 | Review sensitive groups and provisioning connectors | AC-6 |
| 1.3 | Review procurement User Management audit events | AU-6 |

### References

- [Coverage and validation boundaries](https://github.com/grcengineering/how-to-harden/blob/main/docs/research/sspm-data-platform-source-coverage.md)
- [Ariba gateway authentication](https://help.sap.com/docs/ARIBA_APIS/b61dd8c7e22c4fe489f191f66b4c48d6/99ef1f190ff647df8cffd681264c24d0.html)
- [SAP Ariba APIs](https://help.sap.com/docs/ARIBA_APIS)
- [NIST SP 800-53 Rev. 5](https://csrc.nist.gov/pubs/sp/800/53/r5/upd1/final)

## Changelog

| Version | Date | Maturity | Changes |
|---------|------|----------|---------|
| 0.1.0 | 2026-11-27 | ai-drafted | Initial controls and evidence pack; no live tenant verification. |
